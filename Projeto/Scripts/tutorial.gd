extends Node2D

enum State { MOVE_STEP, WAITING_CAR, JUMP_STEP, FINISHED }
var current_state: State = State.MOVE_STEP

@export var esteira: Node2D
@export var player: CharacterBody2D
@export var normal_speed: float = 400.0
@export var label_tutorial: Label

func _ready() -> void:
	add_to_group("tutorial_manager")
	# Permite que APENAS este nó funcione enquanto o jogo estiver em get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if player == null:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	
	_set_esteira_speed(0.0)
	if player:
		player.can_move = false
	if label_tutorial:
		label_tutorial.text = "Aperte D para se mover para frente"
		label_tutorial.visible = true

func _process(_delta: float) -> void:
	match current_state:
		State.MOVE_STEP:
			if Input.is_action_just_pressed("mover_frente") or Input.is_key_pressed(KEY_D):
				_set_esteira_speed(normal_speed)
				if player:
					player.can_move = true
				if label_tutorial:
					label_tutorial.visible = false
				current_state = State.WAITING_CAR

		State.JUMP_STEP:
			if Input.is_action_just_pressed("pular") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_SPACE):
				_set_esteira_speed(normal_speed) # Descongelar o jogo inteiro
				if player:
					player.can_move = true
				if label_tutorial:
					label_tutorial.visible = false
				current_state = State.FINISHED

func _set_esteira_speed(new_speed: float) -> void:
	if esteira and "speed" in esteira:
		esteira.speed = new_speed

func trigger_car_tutorial() -> void:
	if current_state == State.WAITING_CAR:
		current_state = State.JUMP_STEP
		_set_esteira_speed(0.0)
		if player:
			player.can_move = false
		if label_tutorial:
			label_tutorial.text = "Aperte Espaço/W para pular"
			label_tutorial.visible = true
