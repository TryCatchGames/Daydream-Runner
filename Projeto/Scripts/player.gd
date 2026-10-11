extends CharacterBody2D

# --- VARIÁVEIS DE BALANCEAMENTO ---
const SPEED_RIGHT = 200.0
const SPEED_LEFT = 450.0 # Mais rápido para a esquerda (aceleração assimétrica)
const DRAG_SPEED = 400.0 # Força que puxa o ninjinha para trás quando parado
const FRICTION = 6.0 # Quão suave o ninjinha "escorrega" até ser puxado
const JUMP_VELOCITY = -400.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

const COLLISIONS_OFFSETS = {
	"Idle": Vector2(17.0, -19.0),
	"Running": Vector2(27.0, -19.0),
	"Jump": Vector2(25.0, -23.0),
	"Fall": Vector2(20, -21.0)
}

var facing_direction = 1

func update_collision() -> void:
	var anim: String = animated_sprite.animation
	
	if not COLLISIONS_OFFSETS.has(anim):
		return
	
	var offset: Vector2 = COLLISIONS_OFFSETS[anim]
	
	if animated_sprite.flip_h and anim == "Idle":
		offset.x = (-offset.x + 50)
		
	collision.position = offset
		
		
func _ready() -> void:
	animated_sprite.animation_changed.connect(update_collision)
	update_collision()

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
		update_collision()
		
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
