extends TextureRect

@onready var system: ScoreSystem = $"../ScoreSystem"
@onready var value_label: Label = $Value
var pulse: Tween
var previous_score: int = 0


func _ready() -> void:
	system.score_changed.connect(_update_score)
	_update_score(system.get_score(), system.max_score)


func _update_score(total: int, maximum: int) -> void:
	var digits := maxi(5, str(maximum).length())
	value_label.text = str(total).pad_zeros(digits)
	# Reduz a fonte para limites maiores sem cortar os algarismos.
	value_label.add_theme_font_size_override("font_size", mini(37, int(220.0 / digits)))
	if total > previous_score:
		if pulse:
			pulse.kill()
		value_label.modulate = Color(1.0, 0.65, 0.25)
		pulse = create_tween()
		pulse.tween_property(value_label, "modulate", Color.WHITE, 0.25)
	previous_score = total
