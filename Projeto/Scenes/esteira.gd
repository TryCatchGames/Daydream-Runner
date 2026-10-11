extends Node2D

const CAR_SPEED = 400.0 # Ajuste a velocidade que o cenário se move

# Valor com a largura exata da imagem do chão/esteira (em pixels).
# Por exemplo, se o chão tem 1000 pixels de largura, colocar 1000.0
const LARGURA_ESTEIRA = 8865.0

func _process(delta: float) -> void:
	# Move o cenário (chão e obstáculos) constantemente para a esquerda
	position.x -= CAR_SPEED * delta
	
	# Verifica se a esteira já andou para trás o suficiente
	if position.x <= -LARGURA_ESTEIRA:
		# Em vez de zerar (position.x = 0), nós somamos a largura.
		# Isso impede pequenos "pulos" ou engasgos caso o delta time 
		# faça a posição passar um pouquinho do limite naquele frame.
		position.x += LARGURA_ESTEIRA
