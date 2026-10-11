extends CharacterBody2D

# Estados do Inimigo
enum State { SPAWN, IDLE, CHASE, ATTACK, HURT, DEAD }
var current_state: State = State.SPAWN

@export var speed: float = 120.0
@export var max_health: int = 3
@export var attack_distance: float = 35.0

var health: int
var player: Node2D = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	health = max_health
	change_state(State.SPAWN)

func _physics_process(_delta: float) -> void:
	match current_state:
		State.SPAWN, State.HURT, State.DEAD:
			# Para o movimento durante animações de transição/morte
			velocity = Vector2.ZERO

		State.IDLE:
			velocity = Vector2.ZERO
			if player and is_instance_valid(player):
				change_state(State.CHASE)

		State.CHASE:
			if not player or not is_instance_valid(player):
				change_state(State.IDLE)
				return
			
			var distance = global_position.distance_to(player.global_position)
			
			if distance <= attack_distance:
				change_state(State.ATTACK)
			else:
				# Persegue o jogador na direção (X e Y) por ser voador
				var direction = (player.global_position - global_position).normalized()
				velocity = direction * speed
				
				# Espelha o sprite na direção do movimento
				if direction.x != 0:
					animated_sprite.flip_h = direction.x < 0

		State.ATTACK:
			velocity = Vector2.ZERO

	move_and_slide()

func change_state(new_state: State) -> void:
	current_state = new_state
	
	match current_state:
		State.SPAWN:
			animated_sprite.play("Aparecendo")
		State.IDLE:
			animated_sprite.play("Parado")
		State.CHASE:
			animated_sprite.play("Voando")
		State.ATTACK:
			animated_sprite.play("Atacando")
		State.HURT:
			animated_sprite.play("Dano")
		State.DEAD:
			animated_sprite.play("Morte")

# Função para aplicar dano ao inimigo (chame no script do ataque do jogador)
func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return
		
	health -= amount
	if health <= 0:
		change_state(State.DEAD)
	else:
		change_state(State.HURT)

# --- SINAIS DO ANIMATEDSPRITE2D ---
# Conecte o sinal animation_finished do AnimatedSprite2D neste script
func _on_animated_sprite_2d_animation_finished() -> void:
	match current_state:
		State.SPAWN:
			change_state(State.IDLE)
		State.ATTACK, State.HURT:
			if player and is_instance_valid(player):
				change_state(State.CHASE)
			else:
				change_state(State.IDLE)
		State.DEAD:
			queue_free() # Remove o nó da cena após terminar a animação de morte

# --- SINAIS DA AREA2D DE DETECÇÃO ---
# Conecte os sinais da DetectionArea no Inspetor
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"): # Certifique-se de que o jogador está no grupo "player"
		player = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
