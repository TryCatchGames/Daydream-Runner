extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

const COLLISIONS_OFFSETS = {
	"Idle": Vector2(17.0, -19.0),
	"Running": Vector2(27.0, -19.0),
	"Jump": Vector2(25.0, -23.0),
	"Fall": Vector2(20, -21.0)
}

var facing_direction = 1

func update_collision() -> void:
	var anim: String = animated_sprite.animation
	
	if not COLLISIONS_OFFSETS.has(anim):
		return
	
	var offset: Vector2 = COLLISIONS_OFFSETS[anim]
	
	if animated_sprite.flip_h and anim == "Idle":
		offset.x = (-offset.x + 50)
		
	collision.position = offset
		
		
func _ready() -> void:
	animated_sprite.animation_changed.connect(update_collision)
	update_collision()

func _physics_process(delta: float) -> void:
	print(global_position)
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("mover_frente", "mover_tras")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if direction != 0:
		animated_sprite.flip_h = direction < 0
		update_collision()
		
	move_and_slide()
	
	if not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("Jump")
		else:
			animated_sprite.play("Fall")
			
	elif velocity.x != 0:
		animated_sprite.play("Running")
	else:
		animated_sprite.play("Idle")
	
