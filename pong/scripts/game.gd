extends Node2D

@export var final_score = 10

@onready var ball = $Ball
@onready var paddle_one = $PaddleOne
@onready var paddle_two = $PaddleTwo
@onready var detector_left = $DetectorLeft
@onready var detector_right = $DetectorRight
@onready var start_delay = $StartDelay
@onready var hud = $CanvasLayer/HUD
@onready var victory_screen = $CanvasLayer/HUD/VictoryOverlay
@onready var victory_label= $CanvasLayer/HUD/VictoryOverlay/VictoryLabel
@onready var l2d = $BallMovement

var game_area_size = Vector2(1280,720)
var score = Vector2i.ZERO

func _ready() -> void:
	detector_left.ball_out.connect(_on_detector_ball_out)
	detector_right.ball_out.connect(_on_detector_ball_out)
	victory_screen.hide()

	randomize()
	reset_game()
	
	var test_points = [Vector2(200, 300), Vector2(300, 500), Vector2(500, 700)]
	update_l2d(test_points)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
		
	if ball.debug_mode:
		paddle_one.active = !ball.debug_mode
		paddle_two.active = !ball.debug_mode
		if !ball.debug_mode:
			ball.move_dir = Vector2(-1, 0)
	
	if Input.is_action_just_pressed("ball_control"):
		ball.debug_mode = !ball.debug_mode
		paddle_one.active = !ball.debug_mode
		paddle_two.active = !ball.debug_mode
		if !ball.debug_mode:
			ball.move_dir = Vector2(-1, 0)

func _draw() -> void:
	var line_start = Vector2(game_area_size.x/2, 0)
	var line_finish = Vector2(game_area_size.x/2, game_area_size.y)
	draw_dashed_line(line_start, line_finish, Color.WHITE, 8.0, 32.0, true)

func reset_game():
	score = Vector2i.ZERO
	hud.reset_score()
	reset_round()

func reset_round():
	var reset_pos = game_area_size / 2.0
	ball.reset(reset_pos)
	start_delay.start()
	await start_delay.timeout
	ball.active = true
	

func _on_detector_ball_out(is_left):
	if is_left:
		score.y += 1  #left scored
	else:
		score.x += 1  #right scored
	
	hud.set_new_score(score)
	
	l2d.clear_points()
	
	if score.x >= final_score || score.y >= final_score:
		ball.active = false
		paddle_one.active = false
		paddle_two.active = false
		
		await get_tree().create_timer(0.4).timeout
		victory_screen.show()
		victory_label.text = "Player 1 Venceu" if score.x >= final_score else "Player 2 Venceu"

		await get_tree().create_timer(5.0).timeout
		reset_game()
		victory_screen.hide()
	else:
		reset_round()
		
func update_l2d(points):
	l2d.clear_points()
	l2d.global_position = ball.global_position
	for point in points:
		var localized_point = l2d.to_local(point)
		l2d.add_point(localized_point)
