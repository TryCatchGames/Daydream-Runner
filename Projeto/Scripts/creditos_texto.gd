extends Label

const WOBBLE_ANGLE := deg_to_rad(2.0)
const WOBBLE_SPEED := 1.2
const SCALE_PULSE := 0.04

var wobble_time := 0.0
var original_scale := Vector2.ONE

func _ready() -> void:
	original_scale = scale
	pivot_offset = size * 0.5
	resized.connect(_update_pivot)


func _process(delta: float) -> void:
	wobble_time += delta
	var movement := sin(wobble_time * WOBBLE_SPEED)
	rotation = movement * WOBBLE_ANGLE
	scale = original_scale * (1.0 + movement * SCALE_PULSE)


func _update_pivot() -> void:
	pivot_offset = size * 0.5
