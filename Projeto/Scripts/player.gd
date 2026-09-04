extends CharacterBody3D

const SPEED_RIGHT = 3.0
const SPEED_LEFT = 10.0
const SPEED_Z = 4.0 # Velocidade para desviar no eixo Z (profundidade)
const DRAG_SPEED = 8.0
const FRICTION = 4.0
const JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var sprite = $AnimatedSprite3D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Captura os botões WASD de uma vez (X e Y)
	var input_dir = Input.get_vector("mover_esquerda", "mover_direita", "mover_frente", "mover_trás")
	
	# 1. Lógica do Eixo X (Esquerda / Direita e a Esteira)
	if input_dir.x != 0:
		var target_speed = SPEED_RIGHT if input_dir.x > 0 else SPEED_LEFT
		velocity.x = input_dir.x * target_speed
		sprite.flip_h = (input_dir.x < 0)
	else:
		# É arrastado para trás pela "esteira"
		velocity.x = move_toward(velocity.x, -DRAG_SPEED, FRICTION * delta * SPEED_RIGHT)

	# 2. Lógica do Eixo Z (Ir para o fundo ou para a frente da tela)
	if input_dir.y != 0:
		velocity.z = input_dir.y * SPEED_Z
	else:
		velocity.z = move_toward(velocity.z, 0, FRICTION * delta * SPEED_Z)

	# 3. Lógica das Animações
	if input_dir != Vector2.ZERO:
		sprite.play("correr")
	else:
		sprite.play("parado")

	move_and_slide()
