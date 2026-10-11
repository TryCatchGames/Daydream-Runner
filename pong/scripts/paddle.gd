extends Area2D

@export var is_ai = false
@export var is_player_one = false

@onready var cshape = $CollisionShape2D

var active = true
var up_input = "paddle_up"
var down_input = "paddle_down"

const MAX_VELOCITY = 18.0
var velocity = 0.0
var acceleration = 50.0
var slow_down_delta = 2.5
var ai_target_ypos = 110

func _ready() -> void:
	if is_player_one == false:
		up_input += "_two"
		down_input += "_two"

func _physics_process(delta: float) -> void:
	if !active: return
	
	var move_dir = 0.0
	
	if !is_ai:
		move_dir = Input.get_axis(up_input, down_input)
	else:
		move_dir = get_ai_move_dir()
	
	velocity += move_dir * acceleration * delta
	if move_dir == 0.0:
		velocity = move_toward(velocity, 0.0, slow_down_delta)
	
	velocity = clampf(velocity, -MAX_VELOCITY, MAX_VELOCITY)
	
	var half_height = $MeshInstance2D.scale.y / 2.0

	var min_y = half_height
	var max_y = get_window().size.y - half_height

	global_position.y += velocity
	global_position.y = clampf(global_position.y, min_y, max_y)

	if global_position.y == min_y or global_position.y == max_y:
		velocity = 0.0
		


func _on_body_entered(body: Node2D) -> void:
	if body is Ball:
		body.bounce_from_paddle(global_position.y, cshape.shape.get_rect().size.y)
		
func get_ai_move_dir():
	var dist_to_target = abs(ai_target_ypos - global_position.y)
	var accuracy_dist = 25.0
	var ball = get_tree().get_first_node_in_group("balls")
	ai_target_ypos = ball.global_position.y
	
	if (dist_to_target > accuracy_dist):
		if ai_target_ypos > global_position.y:
			return 1
		else:
			return -1
	else:
		return 0
