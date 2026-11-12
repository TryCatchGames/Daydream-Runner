extends Area2D
## Base das cenas herdadas. Instancie como irmã da esteira, em coordenadas da fase.

enum Kind { DOUBLE_POINTS, HEART, INVINCIBILITY }
@export var kind: Kind = Kind.DOUBLE_POINTS
@export_range(0.1, 120.0, 0.1, "or_greater") var duration := 10.0
@export_range(0.0, 100.0, 0.5, "or_greater") var float_amplitude := 15.0
@export_range(0.0, 20.0, 0.1, "or_greater") var float_speed := 2.0
@export_range(0.0, 1500.0, 1.0, "or_greater") var scroll_speed := 390.0

var _collected := false
var _elapsed := 0.0
var _origin_y := 0.0

func _ready() -> void:
	add_to_group("power_up")
	_origin_y = position.y
	body_entered.connect(_collect)

func _physics_process(delta: float) -> void:
	_elapsed += delta
	position.y = _origin_y + sin(_elapsed * float_speed) * float_amplitude
	var conveyor := get_tree().get_first_node_in_group("esteira")
	if conveyor != null and conveyor.is_physics_processing():
		if conveyor.has_method("get_scroll_speed") and conveyor.call("get_scroll_speed") > 0.0:
			position.x -= scroll_speed * delta
	if global_position.x < -100.0:
		queue_free()

func _collect(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	var effects := body.get_node_or_null("PowerUps") as PlayerPowerUps
	if effects == null or int(body.get("health")) <= 0:
		return
	_collected = true
	set_deferred("monitoring", false)
	match kind:
		Kind.DOUBLE_POINTS: effects.activate_double_points(duration)
		Kind.HEART: effects.restore_heart()
		Kind.INVINCIBILITY: effects.activate_invincibility(duration)
	hide()
	queue_free()
