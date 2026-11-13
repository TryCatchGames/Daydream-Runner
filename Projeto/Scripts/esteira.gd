extends Node2D
## Controla o deslocamento; cada faixa visual determina o próprio período.

@export_range(0.0, 1000.0, 0.1, "or_greater") var CAR_SPEED = 400.0
@export var scrolling_enabled := true

var _layers: Array[SceneryLoopLayer] = []
@onready var _event_visuals := get_node_or_null("EventosVisuais") as Node2D

func _ready() -> void:
	add_to_group("esteira")
	for child in get_children():
		if child is SceneryLoopLayer:
			_layers.append(child)


func set_scrolling_enabled(enabled: bool) -> void:
	scrolling_enabled = enabled


func get_scroll_speed() -> float:
	return CAR_SPEED if scrolling_enabled and is_physics_processing() else 0.0


func _physics_process(delta: float) -> void:
	var distance := get_scroll_speed() * delta
	for layer in _layers:
		layer.advance(distance)
	# Cruzamentos e semáforos passam uma vez; nunca voltam por causa do loop.
	if _event_visuals != null:
		_event_visuals.position.x -= distance
