
extends Node2D

const CAR_SPEED = 400.0
const LARGURA_ESTEIRA = 8865.0

func _ready() -> void:
	add_to_group("esteira")

func _physics_process(delta: float) -> void:
	# Move o mundo na mesma etapa de física do personagem.
	position.x -= CAR_SPEED * delta

	if position.x <= -LARGURA_ESTEIRA:
		position.x += LARGURA_ESTEIRA
