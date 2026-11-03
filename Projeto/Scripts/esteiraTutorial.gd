extends Node2D

const LARGURA_ESTEIRA = 8865.0

# Mudamos para 'var speed' (começando em 0.0) para permitir que o script do tutorial altere a velocidade!
@export var speed: float = 0.0

func _ready() -> void:
	add_to_group("esteira")

func _physics_process(delta: float) -> void:
	# Move o mundo usando a velocidade dinâmica controlada pelo tutorial
	position.x -= speed * delta

	if position.x <= -LARGURA_ESTEIRA:
		position.x += LARGURA_ESTEIRA
