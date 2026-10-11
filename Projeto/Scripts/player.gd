extends CharacterBody2D

# --- VARIÁVEIS DE BALANCEAMENTO ---
const SPEED_RIGHT = 200.0
const SPEED_LEFT = 450.0
const DRAG_SPEED = 400.0
const FRICTION = 6.0
const JUMP_VELOCITY = -400.0

const FLIP_FIX = 17.0
const SWORD_FLIP_FIX = 26.0
const ATTACK1_OFFSET_LEFT = Vector2(-32, 0)
const ATTACK2_OFFSET_LEFT = Vector2(-32, 0)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sword_hitbox: Area2D = $SwordHitBox
@onready var sword_hitbox_shape: CollisionShape2D = $SwordHitBox/CollisionShape2D

const COLLISIONS_OFFSETS = {
	"Idle": Vector2(0.0, -20.0),
	"Running": Vector2(12.0, -20.0),
	"Jump": Vector2(3.0, -22.0),
	"Fall": Vector2(3.0, -22.0),
	"Attack1Sword": Vector2(0.0, -20.0),
	"Attack2Sword": Vector2(0.0, -20.0)
}

var facing_direction = 1
var attacking := false
var combo_request := false
var attack_held := false
var sword_hitbox_shape_origin: Vector2

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

	elif animated_sprite.animation == "Attack1Sword":
		combo_request = true


func _on_animation_finished() -> void:
	if animated_sprite.animation == "Attack1Sword":
		if combo_request:
			combo_request = false
			animated_sprite.play("Attack2Sword")
		else:
			attacking = false
			update_sword_hitbox()

	elif animated_sprite.animation == "Attack2Sword":
		if attack_held:
			combo_request = false
			animated_sprite.play("Attack1Sword")
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
	if attacking and attack_animation:
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

func _ready() -> void:
	animated_sprite.animation_changed.connect(update_collision)
	animated_sprite.animation_changed.connect(update_sprite_offset)
	animated_sprite.animation_changed.connect(update_sword_hitbox)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	sword_hitbox_shape_origin = sword_hitbox_shape.position

	update_collision()
	update_sprite_offset()
	update_sword_hitbox()
	update_sword_hitbox_direction()


func _physics_process(delta: float) -> void:
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
	
	 #5. Lógica de Movimento Assimétrico e Inércia
	if direction:
		 #Se vai pra direita (>0), usa SPEED_RIGHT. Se esquerda, usa SPEED_LEFT.
		var target_speed = SPEED_RIGHT if direction > 0 else SPEED_LEFT
		velocity.x = direction * target_speed
	else:
		 #Quando não aperta nada, desliza suavemente até o DRAG_SPEED (para a esquerda/negativo)
		velocity.x = move_toward(velocity.x, -DRAG_SPEED, FRICTION * delta * SPEED_RIGHT)

	# 6. Flip do sprite
	if direction != 0:
		animated_sprite.flip_h = direction < 0
		update_collision()
		update_sprite_offset()
		update_sword_hitbox_direction()

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
