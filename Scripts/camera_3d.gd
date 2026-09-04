extends Camera3D

@export var player: Node3D 
const SUAVIDADE = 8.0

# A altura mínima que o player precisa alcançar para a criança "olhar para cima"
const LIMITE_ALTURA = -200.5

var altura_olhar: float = 0.0

func _process(delta: float) -> void:
	if player:
		var alvo_y = 1.5 # Altura base da visão (focada na rua/chão)
		
		# Se o ninjinha pular mais alto que o limite, a visão acompanha ele
		if player.global_position.y > LIMITE_ALTURA:
			alvo_y = player.global_position.y
			
		# A câmera faz a transição suave entre a rua (0.0) e as sacadas (alvo_y)
		altura_olhar = lerp(altura_olhar, alvo_y, SUAVIDADE * delta)
		
		var ponto_falso = Vector3(global_position.x, altura_olhar, 0)
		look_at(ponto_falso, Vector3.UP)
