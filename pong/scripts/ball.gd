extends CharacterBody2D
class_name Ball

@export var debug_mode = false
@export var speed_increase_per_bounce = 15

const START_SPEED = 800
var active = false
var speed = START_SPEED
var move_dir = Vector2(-1, 0)

func _physics_process(delta: float) -> void:
	if !active: return
	
	if debug_mode:
		var vertical_dir = Input.get_axis("ball_up", "ball_down")
		var horizontal_dir = Input.get_axis("ball_left", "ball_right")
		move_dir = Vector2(horizontal_dir, vertical_dir)
		if move_dir != Vector2.ZERO:
			velocity = move_dir.normalized() * speed
		else:
			velocity = Vector2.ZERO
		print(move_dir)
	else:
		velocity = move_dir * speed
		
	var collided = move_and_slide()
	
	if collided:
		#move_dir.y *= -1  --can be used for flat walls
		move_dir = move_dir.bounce(get_last_slide_collision().get_normal())  #used for walls in any direction
	

func bounce_from_paddle(paddle_y_pos, paddle_height):
	var new_move_dir_y = (global_position.y - paddle_y_pos) / (paddle_height/2.0)
	move_dir.y = new_move_dir_y
	move_dir.x *= -1
	move_dir = move_dir.normalized()
	
	speed += speed_increase_per_bounce

func reset(reset_pos):
	global_position = reset_pos
	speed = START_SPEED
	
	move_dir.x = [-1, 1].pick_random()
	move_dir.y = randf() * [-1, 1].pick_random()
	move_dir = move_dir.normalized()
	
	active = false

#No longer used since wall collision was added
	#if debug_mode:
		#var half_height = $MeshInstance2D.scale.y / 2.0
		#var half_width = $MeshInstance2D.scale.x / 2.0
#
		#var min_y = half_height
		#var max_y = get_window().size.y - half_height
		#var min_x = half_width
		#var max_x = get_window().size.x - half_width
#
		#global_position.x = clampf(global_position.x, min_x, max_x)
		#global_position.y = clampf(global_position.y, min_y, max_y)
