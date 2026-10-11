extends CharacterBody2D

# --- VARIÁVEIS DE BALANCEAMENTO ---
const SPEED_RIGHT = 200.0
const SPEED_LEFT = 450.0 # Mais rápido para a esquerda (aceleração assimétrica)
const DRAG_SPEED = 400.0 # Força que puxa o ninjinha para trás quando parado
const FRICTION = 6.0 # Quão suave o ninjinha "escorrega" até ser puxado
const JUMP_VELOCITY = -400.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# 1. Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Pulo
	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Direção do Eixo X
	var direction := Input.get_axis("mover_frente", "mover_tras") # A e D / Esquerda e Direita
	
	# 4. Lógica de Movimento Assimétrico e Inércia
	if direction:
		# Se vai pra direita (>0), usa SPEED_RIGHT. Se esquerda, usa SPEED_LEFT.
		var target_speed = SPEED_RIGHT if direction > 0 else SPEED_LEFT
		velocity.x = direction * target_speed
	else:
		# Quando não aperta nada, desliza suavemente até o DRAG_SPEED (para a esquerda/negativo)
		velocity.x = move_toward(velocity.x, -DRAG_SPEED, FRICTION * delta * SPEED_RIGHT)
	
	# 5. Flip do Sprite
	if direction != 0:
		animated_sprite.flip_h = direction < 0

	move_and_slide()
	
	# 6. Máquina de Estados da Animação (Já configurada pelo seu colega)
	if not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("Jump")
		else:
			animated_sprite.play("Fall")
	elif direction != 0: # Só toca "Running" se o jogador estiver apertando o botão
		animated_sprite.play("Running")
	else:
		animated_sprite.play("Idle")
