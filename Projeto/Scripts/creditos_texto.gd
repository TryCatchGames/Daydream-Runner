extends Label

const WOBBLE_ANGLE := deg_to_rad(2.0)
const WOBBLE_SPEED := 1.2

var wobble_time := 0.0

func _ready() -> void:
	pivot_offset = size * 0.5
	resized.connect(_update_pivot)


func _process(delta: float) -> void:
	wobble_time += delta
	rotation = sin(wobble_time * WOBBLE_SPEED) * WOBBLE_ANGLE


func _update_pivot() -> void:
	pivot_offset = size * 0.5
