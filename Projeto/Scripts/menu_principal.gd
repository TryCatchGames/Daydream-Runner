extends Control

const HOVER_SCALE := 1.08
const HOVER_ANIMATION_DURATION := 0.14
const WOBBLE_ANGLE := deg_to_rad(4.0)
const WOBBLE_SPEED := 3
const TITLE_LETTER_SCALE := 1.3
const TITLE_LETTER_ANIMATION_DURATION := 0.05
const TITLE_LETTER_GAP := 0.025

@onready var title_label: Label = $Label

var menu_buttons: Array[Button] = []
var title_letters: Array[Label] = []
var button_hover_tweens: Dictionary = {}
var button_wobble_times: Dictionary = {}

func _ready() -> void:
	_setup_title_letters()

	for child in get_children():
		if child is Button:
			var button := child as Button
			button_wobble_times[button] = float(menu_buttons.size()) * 0.8
			menu_buttons.append(button)
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
			button_wobble_times[button] += delta
			button.rotation = sin(button_wobble_times[button] * WOBBLE_SPEED) * WOBBLE_ANGLE


func _setup_title_letters() -> void:
	var title_text := title_label.text
	var title_settings := title_label.label_settings
	var title_font: Font
	var title_font_size := 16
	if title_settings != null:
		title_font = title_settings.font
		title_font_size = title_settings.font_size
	if title_font == null:
		title_font = title_label.get_theme_font("font")
		title_font_size = title_label.get_theme_font_size("font_size")

	title_label.text = ""
	var letters_row := HBoxContainer.new()
	letters_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	letters_row.add_theme_constant_override("separation", 0)
	letters_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.add_child(letters_row)

	for index in range(title_text.length()):
		var glyph := title_text.substr(index, 1)
		var letter := Label.new()
		letter.text = glyph
		letter.label_settings = title_settings
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if title_font != null:
			letter.custom_minimum_size.x = title_font.get_string_size(
				glyph,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				title_font_size
			).x
		letters_row.add_child(letter)
		title_letters.append(letter)

	_animate_title_letters()


func _animate_title_letters() -> void:
	await get_tree().process_frame
	for letter in title_letters:
		letter.pivot_offset = letter.size * 0.5

	while is_inside_tree():
		for letter in title_letters:
			if letter.text.strip_edges().is_empty():
				continue
			var tween := create_tween()
			tween.tween_property(
				letter,
				"scale",
				Vector2.ONE * TITLE_LETTER_SCALE,
				TITLE_LETTER_ANIMATION_DURATION
			).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(
				letter,
				"scale",
				Vector2.ONE,
				TITLE_LETTER_ANIMATION_DURATION
			).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			await tween.finished
			await get_tree().create_timer(TITLE_LETTER_GAP).timeout


func _update_button_pivot(button: Button) -> void:
	button.pivot_offset = button.size * 0.5


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


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Fases/Level_1.tscn")


func _on_options_button_pressed() -> void:
	print("Abrir opções")


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_créditos_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/créditos.tscn")
