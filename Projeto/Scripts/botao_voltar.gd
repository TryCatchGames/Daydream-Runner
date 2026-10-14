extends Button

const HOVER_SCALE := 1.08
const HOVER_ANIMATION_DURATION := 0.14
const WOBBLE_ANGLE := deg_to_rad(2.0)
const WOBBLE_SPEED := 3

var is_hovered := false
var wobble_time := 0.0
var hover_tween: Tween

func _ready() -> void:
	pivot_offset = size * 0.5
	resized.connect(_update_pivot)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)


func _process(delta: float) -> void:
	if is_hovered:
		wobble_time += delta
		rotation = sin(wobble_time * WOBBLE_SPEED) * WOBBLE_ANGLE
	else:
		wobble_time = 0.0
		rotation = 0.0


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _on_mouse_entered() -> void:
	is_hovered = true
	_animate_scale(HOVER_SCALE)


func _on_mouse_exited() -> void:
	is_hovered = false
	_animate_scale(1.0)


func _animate_scale(target_scale: float) -> void:
	if hover_tween and hover_tween.is_running():
		hover_tween.kill()

	hover_tween = create_tween()
	hover_tween.tween_property(
		self,
		"scale",
		Vector2.ONE * target_scale,
		HOVER_ANIMATION_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/menu_principal.tscn")
