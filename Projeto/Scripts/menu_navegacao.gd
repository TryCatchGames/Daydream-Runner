extends Control

const HOVER_SCALE := 1.08
const HOVER_ANIMATION_DURATION := 0.14
const WOBBLE_ANGLE := deg_to_rad(3.0)
const WOBBLE_SPEED := 3.0

var menu_buttons: Array[Button] = []
var button_status_labels: Dictionary = {}
var button_hover_tweens: Dictionary = {}
var button_wobble_times: Dictionary = {}


func _ready() -> void:
	_collect_buttons(self)
	for button in menu_buttons:
		button_wobble_times[button] = randf_range(0.0, TAU)
		_update_button_pivot(button)
		var status_label := button.get_parent().get_node_or_null(
			"Status" + String(button.name)
		) as Label
		if status_label != null:
			button_status_labels[button] = status_label
			_update_label_pivot(status_label)
			status_label.resized.connect(_update_label_pivot.bind(status_label))
		button.resized.connect(_update_button_pivot.bind(button))
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
		button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
		button.pressed.connect(_on_button_pressed.bind(button))


func _process(delta: float) -> void:
	for button in menu_buttons:
		if is_instance_valid(button):
			button_wobble_times[button] += delta
			var wobble := sin(button_wobble_times[button] * WOBBLE_SPEED) * WOBBLE_ANGLE
			button.rotation = wobble
			if button_status_labels.has(button):
				var status_label: Label = button_status_labels[button]
				if is_instance_valid(status_label):
					status_label.rotation = wobble
					status_label.scale = button.scale


func _collect_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			menu_buttons.append(child as Button)
		_collect_buttons(child)


func _on_button_pressed(button: Button) -> void:
	match button.name:
		"Creditos":
			get_tree().change_scene_to_file(_credits_scene_path())
		"SelecionarFase":
			if bool(get_tree().get_meta("terminou", false)):
				get_tree().change_scene_to_file("res://Scenes/Menus/selecao_fases.tscn")
			else:
				$PopupOverlay.show()
		"Voltar":
			if name == "SelecaoFases":
				get_tree().change_scene_to_file("res://Scenes/Menus/extras.tscn")
			else:
				get_tree().change_scene_to_file("res://Scenes/Menus/menu_principal.tscn")
		"OK":
			$PopupOverlay.hide()
		# Os botões de nível e de save ficam prontos, sem ação por enquanto.


func _credits_scene_path() -> String:
	return "res://Scenes/Menus/cr" + String.chr(233) + "ditos.tscn"


func _update_button_pivot(button: Button) -> void:
	button.pivot_offset = button.size * 0.5


func _update_label_pivot(label: Label) -> void:
	label.pivot_offset = label.size * 0.5


func _on_button_mouse_entered(button: Button) -> void:
	_animate_button_scale(button, HOVER_SCALE)


func _on_button_mouse_exited(button: Button) -> void:
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
