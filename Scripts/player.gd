extends CharacterBody3D

const SPEED_RIGHT = 5.0
const SPEED_LEFT = 8.0
const DRAG_SPEED = 2.0
const FRICTION = 4.0
const JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Agora pegamos a referência do AnimatedSprite3D
@onready var sprite = $AnimatedSprite3D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction_x = Input.get_axis("mover_esquerda", "mover_direita")
	
	if direction_x:
		var target_speed = SPEED_RIGHT if direction_x > 0 else SPEED_LEFT
		velocity.x = direction_x * target_speed
		
		# Chama a animação direto no próprio sprite
		sprite.play("correr")
		
		if direction_x < 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, -DRAG_SPEED, FRICTION * delta * SPEED_RIGHT)
		
		# Volta para a pose parada
		sprite.play("parado")

	velocity.z = 0
	move_and_slide()
