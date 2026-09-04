extends Node3D

const CAR_SPEED = 8 # A velocidade que o mundo se move para a esquerda

func _process(delta: float) -> void:
	# Move todos os filhos (chão e obstáculos) para a esquerda no Eixo X
	position.x -= CAR_SPEED * delta
