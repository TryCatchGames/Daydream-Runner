extends CharacterBody2D

# --- VARIÁVEIS DE BALANCEAMENTO ---
const SPEED_RIGHT = 200.0
const SPEED_LEFT = 600.0
const SPEED_NO_CONVEYOR = 400.0
const DRAG_SPEED = 400.0
const DRAG_ACCELERATION = 8000.0
const JUMP_VELOCITY = -450.0
const MAX_HEALTH := 6
const SWORD_DAMAGE := 1
const ATTACK_HIT_FRAME := 3 # Quarto frame da animação (os índices começam em 0).
const DAMAGE_FLASH_DURATION := 0.12
const PLAYER_KNOCKBACK_STRENGTH := 200.0
const PLAYER_KNOCKBACK_DECAY := 800.0
const DEATH_FRAGMENT_COLUMNS := 16
const DEATH_FRAGMENT_ROWS := 32

# --- VARIÁVEIS DE ARRUMAMENTO --- #
const FLIP_FIX = 17.0
const SWORD_FLIP_FIX = 26.0
const ATTACK1_OFFSET_LEFT = Vector2(-32, 0)
const ATTACK2_OFFSET_LEFT = Vector2(-32, 0)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sword_hitbox: Area2D = $SwordHitBox
@onready var sword_hitbox_shape: CollisionShape2D = $SwordHitBox/CollisionShape2D
@onready var audio_slash: AudioStreamPlayer = $AudioStreamPlayer

const COLLISIONS_OFFSETS = {
	"Idle": Vector2(0.0, -20.0),
	"Running": Vector2(12.0, -20.0),
	"Jump": Vector2(3.0, -20.0),
	"Fall": Vector2(3.0, -20.0),
	"Attack1Sword": Vector2(0.0, -20.0),
	"Attack2Sword": Vector2(0.0, -20.0)
}

var facing_direction = 1
var attacking := false
var combo_request := false
var attack_held := false
var sword_hitbox_shape_origin: Vector2
var health := MAX_HEALTH
var sword_hit_targets: Dictionary = {}
var damage_flash_tween: Tween
var knockback_velocity := Vector2.ZERO
var tem_esteira := false

signal health_changed(current_health: int, max_health: int)
signal died

func update_collision() -> void:
	var anim: String = animated_sprite.animation

	if not COLLISIONS_OFFSETS.has(anim):
		return

	var offset: Vector2 = COLLISIONS_OFFSETS[anim]

	if animated_sprite.flip_h and anim == "Idle":
		offset.x = -offset.x + FLIP_FIX

	if animated_sprite.flip_h and anim == "Jump":
		offset.x = -offset.x + FLIP_FIX

	if animated_sprite.flip_h and anim == "Fall":
		offset.x = -offset.x + FLIP_FIX
		
	if animated_sprite.flip_h and anim == "Attack1Sword":
		offset.x = -offset.x + FLIP_FIX	
		
	if animated_sprite.flip_h and anim == "Attack2Sword":
		offset.x = -offset.x + FLIP_FIX	

	collision.position = offset


func update_sprite_offset() -> void:
	var anim := animated_sprite.animation

	if animated_sprite.flip_h:
		if anim == "Attack1Sword":
			animated_sprite.offset = ATTACK1_OFFSET_LEFT
		elif anim == "Attack2Sword":
			animated_sprite.offset = ATTACK2_OFFSET_LEFT
			
		else:
			animated_sprite.offset = Vector2.ZERO
	else:
		animated_sprite.offset = Vector2.ZERO


func attack() -> void:
	attack_held = true

	if not attacking:
		attacking = true
		combo_request = false
		animated_sprite.play("Attack1Sword")
		audio_slash.play()

	elif animated_sprite.animation == "Attack1Sword":
		combo_request = true


func _on_animation_finished() -> void:
	if animated_sprite.animation == "Aparecendo":
		animated_sprite.play("Idle")
	elif animated_sprite.animation == "Attack1Sword":
		if combo_request:
			combo_request = false
			animated_sprite.play("Attack2Sword")
			audio_slash.play()
		else:
			attacking = false
			update_sword_hitbox()

	elif animated_sprite.animation == "Attack2Sword":
		if attack_held:
			combo_request = false
			animated_sprite.play("Attack1Sword")
			audio_slash.play()
		else:
			attacking = false
			combo_request = false
			update_sword_hitbox()

func enable_sword_hitbox() -> void:
	sword_hitbox.monitoring = true
	sword_hitbox_shape.set_deferred("disabled", false)
	
func disable_sword_hitbox() -> void:
	sword_hitbox.monitoring = false
	sword_hitbox_shape.set_deferred("disabled", true)

func update_sword_hitbox() -> void:
	var anim := animated_sprite.animation
	var attack_animation := anim == "Attack1Sword" or anim == "Attack2Sword" or anim == "Attack3Sword"
	if attacking and attack_animation and animated_sprite.frame == ATTACK_HIT_FRAME:
		enable_sword_hitbox()
	else:
		disable_sword_hitbox()
		
func update_sword_hitbox_direction() -> void:
	var shape_position := sword_hitbox_shape_origin
	if animated_sprite.flip_h:
		shape_position.x = -SWORD_FLIP_FIX
	else:
		shape_position.x = abs(shape_position.x)
	sword_hitbox_shape.position = shape_position

func take_damage(amount: int = 1, attacker: Node2D = null) -> void:
	if health <= 0 or amount <= 0:
		return

	if is_instance_valid(attacker):
		_apply_knockback_from(attacker)

	health = maxi(health - amount, 0)
	_flash_white()
	health_changed.emit(health, MAX_HEALTH)
	if health == 0:
		_explode_body()
		died.emit()
		queue_free()

func get_max_health() -> int:
	return MAX_HEALTH

func _apply_knockback_from(attacker: Node2D) -> void:
	var direction := signf(global_position.x - attacker.global_position.x)
	if is_zero_approx(direction):
		direction = -1.0 if animated_sprite.flip_h else 1.0
	knockback_velocity.x = direction * PLAYER_KNOCKBACK_STRENGTH

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

func _explode_body() -> void:
	var frames := animated_sprite.sprite_frames
	if frames == null or not frames.has_animation(animated_sprite.animation):
		return

	var frame_texture := frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame)
	if frame_texture == null:
		return

	var explosion_parent := get_parent()
	if explosion_parent == null:
		explosion_parent = get_tree().current_scene
	if explosion_parent == null:
		return

	var texture_size := Vector2(frame_texture.get_size())
	var piece_size := texture_size / Vector2(DEATH_FRAGMENT_COLUMNS, DEATH_FRAGMENT_ROWS)
	var explosion_center := animated_sprite.to_global(animated_sprite.offset + texture_size * 0.5)

	for row in range(DEATH_FRAGMENT_ROWS):
		for column in range(DEATH_FRAGMENT_COLUMNS):
			var source_position := Vector2(column, row) * piece_size
			var displayed_x := source_position.x
			if animated_sprite.flip_h:
				displayed_x = texture_size.x - source_position.x - piece_size.x

			var atlas := AtlasTexture.new()
			atlas.atlas = frame_texture
			atlas.region = Rect2(source_position, piece_size)
			atlas.filter_clip = true

			var fragment := Sprite2D.new()
			fragment.texture = atlas
			fragment.centered = true
			fragment.flip_h = animated_sprite.flip_h
			fragment.modulate = animated_sprite.modulate
			fragment.z_index = animated_sprite.z_index + 1
			explosion_parent.add_child(fragment)
			fragment.global_position = animated_sprite.to_global(
				animated_sprite.offset + Vector2(displayed_x, source_position.y) + piece_size * 0.5
			)
			fragment.global_rotation = animated_sprite.global_rotation
			fragment.global_scale = animated_sprite.global_scale

			var direction := fragment.global_position - explosion_center
			if direction.length_squared() < 0.001:
				direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
			direction = (direction.normalized() + Vector2(
				randf_range(-0.35, 0.35),
				randf_range(-0.35, 0.35)
			)).normalized()

			var target_position := fragment.global_position + direction * randf_range(45.0, 100.0)
			target_position.y += randf_range(10.0, 35.0)
			var duration := randf_range(0.35, 0.6)
			var tween := fragment.create_tween()
			tween.set_parallel(true)
			tween.tween_property(fragment, "global_position", target_position, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(fragment, "rotation", randf_range(-PI, PI), duration)
			tween.tween_property(fragment, "modulate:a", 0.0, duration * 0.6).set_delay(duration * 0.4)
			tween.set_parallel(false)
			tween.tween_callback(fragment.queue_free)

func _on_sword_hitbox_body_entered(body: Node2D) -> void:
	_damage_enemy(body)

func _on_attack_animation_changed() -> void:
	var anim := animated_sprite.animation
	if anim != "Attack1Sword" and anim != "Attack2Sword":
		return

	# Cada animação é um golpe separado.
	sword_hit_targets.clear()

func _damage_enemy(body: Node2D) -> void:
	var anim := animated_sprite.animation
	if not sword_hitbox.monitoring or not attacking:
		return
	if anim != "Attack1Sword" and anim != "Attack2Sword":
		return
	if animated_sprite.frame != ATTACK_HIT_FRAME:
		return
	if body == self or not body.is_in_group("inimigo"):
		return
	if not body.has_method("take_damage"):
		return

	var body_id := body.get_instance_id()
	if sword_hit_targets.has(body_id):
		return

	sword_hit_targets[body_id] = true
	body.call("take_damage", SWORD_DAMAGE, self)

func _ready() -> void:
	add_to_group("player")
	tem_esteira = get_tree().get_first_node_in_group("esteira") != null
	animated_sprite.animation_changed.connect(update_collision)
	animated_sprite.animation_changed.connect(update_sprite_offset)
	animated_sprite.animation_changed.connect(update_sword_hitbox)
	animated_sprite.animation_changed.connect(_on_attack_animation_changed)
	animated_sprite.frame_changed.connect(update_sword_hitbox)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	sword_hitbox.body_entered.connect(_on_sword_hitbox_body_entered)
	sword_hitbox_shape_origin = sword_hitbox_shape.position

	update_collision()
	update_sprite_offset()
	update_sword_hitbox()
	update_sword_hitbox_direction()
	animated_sprite.play("Aparecendo")


func _physics_process(delta: float) -> void:
	if animated_sprite.animation == "Aparecendo":
		velocity = Vector2.ZERO
		return

	# 1. Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Pulo
	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Ataque
	if Input.is_action_just_pressed("attack"):
		attack()

	if Input.is_action_just_released("attack"):
		attack_held = false

	# 4. Direção do eixo X
	var direction := Input.get_axis("mover_frente", "mover_tras")
	
	
	# 5. Movimento horizontal.
	# Durante o knockback, ele age independentemente da esteira.
	if not is_zero_approx(knockback_velocity.x):
		velocity.x = knockback_velocity.x
	elif direction != 0:
		var target_speed := SPEED_NO_CONVEYOR
		if tem_esteira:
			target_speed = SPEED_RIGHT if direction > 0 else SPEED_LEFT
		velocity.x = direction * target_speed
	else:
		var target_speed_x := -DRAG_SPEED if tem_esteira else 0.0
		velocity.x = move_toward(
			velocity.x,
			target_speed_x,
			DRAG_ACCELERATION * delta
		)


	# 6. Flip do sprite
	if direction != 0:
		animated_sprite.flip_h = direction < 0
		update_collision()
		update_sprite_offset()
		update_sword_hitbox_direction()

	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, PLAYER_KNOCKBACK_DECAY * delta)
	move_and_slide()

	# 7. Máquina de estados da animação
	if not attacking:
		if not is_on_floor():
			if velocity.y < 0:
				animated_sprite.play("Jump")
			else:
				animated_sprite.play("Fall")

		elif direction != 0:
			animated_sprite.play("Running")

		else:
			animated_sprite.play("Idle")
