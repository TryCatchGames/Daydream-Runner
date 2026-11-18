extends Node2D
## AW - Fire Demon: example scene. Press F6 to run it.
## The node "Demon" sits at the FEET pivot (both sprites use offset -59, -108, centered off).
## Swap the palette by dropping Demon_Azure.tres / Demon_Venom.tres / Demon_Obsidian.tres on Body > Sprite Frames.
## It plays every animation in order and shows the Attack -> Attack2 combo inside the cancel window.

const SEQUENCE := ["Idle", "Walk", "IdleToRun", "Run", "RunToIdle", "Attack", "Attack2", "Taunt", "Hurt", "Death"]
const LOOP_TIME := 2.0             # seconds each looping animation (Idle, Walk, Run) is shown
const COMBO_FRAME := 11            # Attack frame index 11 = frame 12, start of the cancel window (12-14)
const SPEED := {"Walk": 74.0, "Run": 193.0}   # px/s at 1x so the feet do not slide (move your node at this speed)

@onready var body: AnimatedSprite2D = $Demon/Body
@onready var shadow: AnimatedSprite2D = $Demon/Shadow
@onready var label: Label = $Label
var step := 0


func _ready() -> void:
	body.frame_changed.connect(func() -> void: shadow.frame = body.frame)
	_play_step()


func _play(anim: String) -> void:
	body.play(anim)
	shadow.play(anim)
	shadow.frame = body.frame
	label.text = anim


func _play_step() -> void:
	var anim: String = SEQUENCE[step]
	_play(anim)
	if anim == "Attack":
		# combo: as soon as the cancel window opens, chain Attack2 from its frame 1
		while body.animation == "Attack" and body.frame < COMBO_FRAME:
			await body.frame_changed
		step += 1
		_play_step()
		return
	if body.sprite_frames.get_animation_loop(anim):
		await get_tree().create_timer(LOOP_TIME).timeout
	else:
		await body.animation_finished
		if anim == "Death":
			await get_tree().create_timer(1.0).timeout   # the last frame is already held 900 ms
	step = (step + 1) % SEQUENCE.size()
	_play_step()
