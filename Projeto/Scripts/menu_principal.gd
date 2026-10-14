extends Control

const HOVER_SCALE := 1.08
const HOVER_ANIMATION_DURATION := 0.14
const WOBBLE_ANGLE := deg_to_rad(2.0)
const WOBBLE_SPEED := 1.2

var menu_buttons: Array[Button] = []
var button_hover_tweens: Dictionary = {}
var button_wobble_times: Dictionary = {}
var button_is_hovered: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is Button:
			var button := child as Button
			menu_buttons.append(button)
			button_wobble_times[button] = 0.0
			button_is_hovered[button] = false
			_update_button_pivot(button)
			button.resized.connect(_update_button_pivot.bind(button))
			button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
			button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
			if button.name == "Jogar":
				button.pressed.connect(_on_play_button_pressed)
			elif button.name == "Sair":
				button.pressed.connect(_on_exit_button_pressed)


func _process(delta: float) -> void:
	for button in menu_buttons:
		if is_instance_valid(button):
			if button_is_hovered[button]:
				button_wobble_times[button] += delta
				button.rotation = sin(button_wobble_times[button] * WOBBLE_SPEED) * WOBBLE_ANGLE
			else:
				button_wobble_times[button] = 0.0
				button.rotation = 0.0


func _update_button_pivot(button: Button) -> void:
	button.pivot_offset = button.size * 0.5


func _on_button_mouse_entered(button: Button) -> void:
	button_is_hovered[button] = true
	_animate_button_scale(button, HOVER_SCALE)


func _on_button_mouse_exited(button: Button) -> void:
	button_is_hovered[button] = false
	_animate_button_scale(button, 1.0)


func _animate_button_scale(button: Button, target_scale: float) -> void:
	if button_hover_tweens.has(button):
		var previous_tween: Tween = button_hover_tweens[button]
		if previous_tween.is_running():
			previous_tween.kill()

	var tween := create_tween()
	button_hover_tweens[button] = tween
	tween.tween_property(
		button,
		"scale",
		Vector2.ONE * target_scale,
		HOVER_ANIMATION_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Level_1.tscn")


func _on_options_button_pressed() -> void:
	print("Abrir opções")


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_créditos_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/créditos.tscn")
