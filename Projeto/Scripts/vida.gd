
extends HBoxContainer

# Texturas dos três estados do coração.
const HEART_FULL: Texture2D = preload("res://Sprites/HUD/full_heart.png")
const HEART_HALF: Texture2D = preload("res://Sprites/HUD/half_heart.png")
const HEART_EMPTY: Texture2D = preload("res://Sprites/HUD/empty_heart.png")

# Aparência do HUD, ajustável pelo Inspetor.
@export var heart_size: Vector2 = Vector2(70, 70)
@export var heart_spacing: int = 0

var player: Node


func _ready() -> void:
	add_theme_constant_override("separation", heart_spacing)

	# Espera os nós da cena terminarem de inicializar.
	call_deferred("_connect_to_player")


func _connect_to_player() -> void:
	player = get_tree().get_first_node_in_group("player")

	if player == null:
		push_error("HUD: nenhum jogador encontrado no grupo 'player'.")
		return

	var callback := Callable(self, "_on_health_changed")

	if not player.is_connected("health_changed", callback):
		player.connect("health_changed", callback)

	# Desenha os corações já com a vida inicial do jogador.
	_on_health_changed(
		int(player.get("health")),
		int(player.call("get_max_health"))
	)


func _on_health_changed(current_health: int, max_health: int) -> void:
	# Cada coração representa 2 pontos de vida.
	var heart_count: int = int(ceil(float(max_health) / 2.0))

	# Cria os corações que estiverem faltando.
	while get_child_count() < heart_count:
		var heart := TextureRect.new()

		heart.custom_minimum_size = heart_size
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE

		add_child(heart)

	# Remove os corações excedentes.
	while get_child_count() > heart_count:
		var last_heart := get_child(get_child_count() - 1)
		remove_child(last_heart)
		last_heart.queue_free()

	# Impede valores fora do intervalo da vida.
	var safe_health := clampi(current_health, 0, max_health)

	# Atualiza o estado de cada coração.
	for i in range(heart_count):
		var heart := get_child(i) as TextureRect
		var health_for_heart := safe_health - (i * 2)

		if health_for_heart >= 2:
			heart.texture = HEART_FULL
		elif health_for_heart == 1:
			heart.texture = HEART_HALF
		else:
			heart.texture = HEART_EMPTY
