
extends Node2D

@export_range(0.0, 1000.0, 0.1, "or_greater") var CAR_SPEED = 400.0
@export_range(0.1, 99999.0, 0.1, "or_greater") var LARGURA_ESTEIRA = 8865.0

func _ready() -> void:
	add_to_group("esteira")

func get_scroll_speed() -> float:
	return CAR_SPEED

func _physics_process(delta: float) -> void:
	# Move o mundo na mesma etapa de física do personagem.
	position.x -= CAR_SPEED * delta

	if position.x <= -LARGURA_ESTEIRA:
		position.x += LARGURA_ESTEIRA
