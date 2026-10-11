extends Node2D

const CAR_SPEED = 400.0 # Ajuste a velocidade que o cenário se move

func _process(delta: float) -> void:
	# Move o cenário (chão e obstáculos) constantemente para a esquerda
	position.x -= CAR_SPEED * delta
