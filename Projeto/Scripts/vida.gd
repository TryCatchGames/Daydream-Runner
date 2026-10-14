
extends HBoxContainer

# Texturas dos corações.
const HEART_FULL: Texture2D = preload("res://Sprites/HUD/full_heart.png")
const HEART_HALF: Texture2D = preload("res://Sprites/HUD/half_heart.png")
const HEART_EMPTY: Texture2D = preload("res://Sprites/HUD/empty_heart.png")
const HEART_BLINK_FULL: Texture2D = preload("res://Sprites/HUD/blink_full_heart.png")
const HEART_BLINK_HALF: Texture2D = preload("res://Sprites/HUD/blink_half_heart.png")

# Aparência dos corações.
@export var heart_size: Vector2 = Vector2(32, 32)
@export var heart_spacing: int = 4

# Configurações da animação.
@export_range(0.03, 0.5, 0.01) var blink_interval: float = 0.10
@export_range(1, 10, 1) var blink_cycles: int = 3

var player: Node
var previous_health: int = -1

# Identifica animações antigas para que possam ser canceladas.
var blink_versions: Dictionary = {}


func _ready() -> void:
	add_theme_constant_override("separation", heart_spacing)
	call_deferred("_connect_to_player")


func _connect_to_player() -> void:
	player = get_tree().get_first_node_in_group("player")

	if player == null:
		push_error("HUD: nenhum jogador encontrado no grupo 'player'.")
		return

	var callback := Callable(self, "_on_health_changed")

	if not player.is_connected("health_changed", callback):
		player.connect("health_changed", callback)

	# Inicializa os corações sem executar a animação de dano.
	_on_health_changed(
		int(player.get("health")),
		int(player.call("get_max_health"))
	)


func _on_health_changed(current_health: int, max_health: int) -> void:
	var tomou_dano := (
		previous_health >= 0
		and current_health < previous_health
	)

	var safe_max_health := maxi(max_health, 0)
	var safe_health := clampi(current_health, 0, safe_max_health)

	# Cada coração representa 2 pontos de vida.
	var heart_count := int(ceil(float(safe_max_health) / 2.0))

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

	# Atualiza o estado normal de todos os corações.
	for i in range(heart_count):
		var heart := get_child(i) as TextureRect
		heart.texture = _get_heart_texture(i, safe_health)

	# Se a vida diminuiu, pisca o coração atingido.
	if tomou_dano and heart_count > 0:
		var damaged_index := clampi(
			floori(float(safe_health) / 2.0),
			0,
			heart_count - 1
		)

		_blink_heart(damaged_index, safe_health)

	previous_health = safe_health


func _get_heart_texture(
	heart_index: int,
	current_health: int
) -> Texture2D:
	var heart_health := current_health - heart_index * 2

	if heart_health >= 2:
		return HEART_FULL
	elif heart_health == 1:
		return HEART_HALF

	return HEART_EMPTY


func _get_blink_texture(
	heart_index: int,
	current_health: int
) -> Texture2D:
	var heart_health := current_health - heart_index * 2

	if heart_health >= 2:
		return HEART_BLINK_FULL

	# Não existe blink_empty_heart.png.
	# Usamos o coração piscante pela metade quando ele esvazia.
	return HEART_BLINK_HALF


func _blink_heart(index: int, current_health: int) -> void:
	if index < 0 or index >= get_child_count():
		return

	var heart := get_child(index) as TextureRect

	if heart == null:
		return

	var heart_id: int = heart.get_instance_id()

	# Invalida uma animação anterior deste mesmo coração.
	var version := int(blink_versions.get(heart_id, 0)) + 1
	blink_versions[heart_id] = version

	var blink_texture := _get_blink_texture(index, current_health)
	var normal_texture := _get_heart_texture(index, current_health)

	# Alterna entre a textura piscante e a textura normal.
	for cycle in range(blink_cycles):
		if not _blink_is_current(heart, heart_id, version):
			return

		heart.texture = blink_texture
		await get_tree().create_timer(blink_interval).timeout

		if not _blink_is_current(heart, heart_id, version):
			return

		heart.texture = normal_texture
		await get_tree().create_timer(blink_interval).timeout

	# Garante que a textura termine no estado correto.
	if _blink_is_current(heart, heart_id, version):
		heart.texture = normal_texture
		blink_versions.erase(heart_id)


func _blink_is_current(
	heart: TextureRect,
	heart_id: int,
	version: int
) -> bool:
	return (
		is_instance_valid(heart)
		and int(blink_versions.get(heart_id, -1)) == version
	)
