extends CharacterBody2D

# --- VARIÁVEIS DE BALANCEAMENTO ---
const MAX_HEALTH := 20
const MELEE_DAMAGE := 2
const SPELL_DAMAGE := 2
const MOVE_SPEED := 130.0
const MELEE_RANGE := 105.0         # Distância para iniciar o ataque corpo a corpo
const SPELL_RANGE := 650.0         # Distância máxima para conjurar a magia no player
const STOP_DISTANCE := 75.0        # Distância mínima para não colar dentro do player
const DIRECTION_TOLERANCE := 14.0  # Evita que o boss fique virando freneticamente se o player pular por cima

const MELEE_COOLDOWN := 1.4        # Tempo de espera entre ataques corpo a corpo
const SPELL_COOLDOWN := 5.5        # Tempo de espera entre cada conjuração da spell
const SPELL_HEIGHT_OFFSET := -65.0 # Altura acima do player onde o portal da spell aparece

# Frames da animação "Attack" em que os 2 CollisionShapes ficam ativos (índices começam em 0)
const MELEE_HIT_START_FRAME := 2
const MELEE_HIT_END_FRAME := 4

const DAMAGE_FLASH_DURATION := 0.12
const SPELL_SCENE := preload("res://Scenes/Outros/Spell.tscn") # Ajuste o caminho se necessário

# --- REFERÊNCIAS DOS NÓS ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $Area2D
@onready var attack_shape_1: CollisionShape2D = $Area2D/CollisionShape2D
@onready var attack_shape_2: CollisionShape2D = $Area2D/CollisionShape2D2

# --- POSIÇÕES ORIGINAIS (PARA ESPELHAMENTO) ---
var body_collision_origin: Vector2
var attack_shape_1_origin: Vector2
var attack_shape_2_origin: Vector2

# --- ESTADO DO BOSS ---
var health := MAX_HEALTH
var facing_left := true # Sprite base desenhado olhando para a esquerda
var is_attacking := false
var is_casting := false
var is_hurt := false
var is_dead := false

var melee_cooldown_timer := 0.0
var spell_cooldown_timer := 2.5 # Atraso inicial para não soltar a spell logo no início da luta
var melee_hit_targets: Dictionary = {}
var damage_flash_tween: Tween

signal health_changed(current_health: int, max_health: int)
signal died


func _ready() -> void:
	add_to_group("inimigo")

	# Salva as posições originais configuradas no editor (olhando para a esquerda)
	body_collision_origin = body_collision.position
	attack_shape_1_origin = attack_shape_1.position
	attack_shape_2_origin = attack_shape_2.position

	_disable_melee_hitboxes()

	attack_area.body_entered.connect(_on_attack_area_body_entered)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.animation_finished.connect(_on_animation_finished)

	_update_facing_direction(true)
	animated_sprite.play("Idle")


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Atualiza os timers de recarga
	if melee_cooldown_timer > 0.0:
		melee_cooldown_timer = maxf(melee_cooldown_timer - delta, 0.0)
	if spell_cooldown_timer > 0.0:
		spell_cooldown_timer = maxf(spell_cooldown_timer - delta, 0.0)

	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Trava movimento e virada durante ataque, conjuração ou animação de dano
	if is_attacking or is_casting or is_hurt:
		velocity.x = 0.0
		move_and_slide()
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		velocity.x = 0.0
		_play_anim("Idle")
		move_and_slide()
		return

	var dx := player.global_position.x - global_position.x
	var distance_x := absf(dx)

	# Atualiza o lado para onde o boss olha
	if distance_x > DIRECTION_TOLERANCE:
		_update_facing_direction(dx < 0.0)

	# 1. Prioridade: Conjurar a Spell se o cooldown acabou e o player está no alcance
	if spell_cooldown_timer <= 0.0 and distance_x <= SPELL_RANGE:
		_start_spell_cast()
		move_and_slide()
		return

	# 2. Ataque corpo a corpo se o player estiver perto
	if melee_cooldown_timer <= 0.0 and distance_x <= MELEE_RANGE:
		_start_melee_attack()
		move_and_slide()
		return

	# 3. Perseguição ao player
	if distance_x > STOP_DISTANCE:
		var dir := signf(dx)
		velocity.x = dir * MOVE_SPEED
		_play_anim("Walk")
	else:
		velocity.x = 0.0
		_play_anim("Idle")

	move_and_slide()


# --- ESPELHAMENTO DO SPRITE E DAS COLISÕES ---

func _update_facing_direction(look_left: bool) -> void:
	facing_left = look_left
	animated_sprite.flip_h = not look_left

	var mirror := 1.0 if look_left else -1.0
	body_collision.position.x = body_collision_origin.x * mirror
	attack_shape_1.position.x = attack_shape_1_origin.x * mirror
	attack_shape_2.position.x = attack_shape_2_origin.x * mirror


# --- ATAQUE CORPO A CORPO (ATIVA OS DOIS COLLISION SHAPES) ---

func _start_melee_attack() -> void:
	is_attacking = true
	melee_cooldown_timer = MELEE_COOLDOWN
	melee_hit_targets.clear()
	velocity.x = 0.0

	_disable_melee_hitboxes()
	animated_sprite.play("Attack")

	if MELEE_HIT_START_FRAME == 0:
		_enable_melee_hitboxes()


func _enable_melee_hitboxes() -> void:
	attack_area.monitoring = true
	attack_shape_1.set_deferred("disabled", false)
	attack_shape_2.set_deferred("disabled", false)

	for body in attack_area.get_overlapping_bodies():
		_try_damage_player(body, MELEE_DAMAGE)


func _disable_melee_hitboxes() -> void:
	attack_area.monitoring = false
	attack_shape_1.set_deferred("disabled", true)
	attack_shape_2.set_deferred("disabled", true)


func _on_attack_area_body_entered(body: Node2D) -> void:
	_try_damage_player(body, MELEE_DAMAGE)


func _try_damage_player(body: Node2D, amount: int) -> void:
	if not is_attacking or not attack_area.monitoring:
		return
	if not body.is_in_group("player") or not body.has_method("take_damage"):
		return

	var body_id := body.get_instance_id()
	if melee_hit_targets.has(body_id):
		return

	melee_hit_targets[body_id] = true
	body.call("take_damage", amount, self)


# --- CONJURAÇÃO DA SPELL ("Cast" -> Spawna a Spell ao terminar) ---

func _start_spell_cast() -> void:
	is_casting = true
	spell_cooldown_timer = SPELL_COOLDOWN
	velocity.x = 0.0
	_disable_melee_hitboxes()
	animated_sprite.play("Cast")


func _cast_spell_on_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or SPELL_SCENE == null:
		return

	var spell := SPELL_SCENE.instantiate()
	spell.global_position = player.global_position + Vector2(0.0, SPELL_HEIGHT_OFFSET)

	if "damage" in spell:
		spell.damage = SPELL_DAMAGE

	get_parent().add_child(spell)


# --- SINAIS DE ANIMAÇÃO ---

func _on_frame_changed() -> void:
	if is_attacking and animated_sprite.animation == "Attack":
		var frame := animated_sprite.frame
		if frame >= MELEE_HIT_START_FRAME and frame <= MELEE_HIT_END_FRAME:
			_enable_melee_hitboxes()
		else:
			_disable_melee_hitboxes()


func _on_animation_finished() -> void:
	match animated_sprite.animation:
		"Attack":
			is_attacking = false
			_disable_melee_hitboxes()
			_play_anim("Idle")

		"Cast":
			_cast_spell_on_player()
			is_casting = false
			_play_anim("Idle")

		"Hurt":
			is_hurt = false
			_play_anim("Idle")

		"Death":
			queue_free()


# --- RECEBER DANO E MORTE ---

func take_damage(amount: int = 1, _attacker: Node2D = null) -> void:
	if is_dead or health <= 0 or amount <= 0:
		return

	health = maxi(health - amount, 0)
	_flash_white()
	health_changed.emit(health, MAX_HEALTH)

	if health == 0:
		_die()
		return

	# Toca "Hurt" apenas se não estiver atacando ou conjurando (evita stun-lock no boss)
	if not is_attacking and not is_casting:
		is_hurt = true
		velocity.x = 0.0
		animated_sprite.play("Hurt")


func _die() -> void:
	is_dead = true
	is_attacking = false
	is_casting = false
	is_hurt = false
	velocity = Vector2.ZERO
	_disable_melee_hitboxes()
	body_collision.set_deferred("disabled", true)
	died.emit()
	animated_sprite.play("Death")


func _flash_white() -> void:
	var flash_material := animated_sprite.material as ShaderMaterial
	if flash_material == null:
		return

	if damage_flash_tween and damage_flash_tween.is_running():
		damage_flash_tween.kill()

	flash_material.set_shader_parameter("flash_amount", 1.0)
	damage_flash_tween = create_tween()
	damage_flash_tween.tween_method(_set_damage_flash, 1.0, 0.0, DAMAGE_FLASH_DURATION)


func _set_damage_flash(amount: float) -> void:
	var flash_material := animated_sprite.material as ShaderMaterial
	if flash_material != null:
		flash_material.set_shader_parameter("flash_amount", amount)


func _play_anim(anim_name: String) -> void:
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)
