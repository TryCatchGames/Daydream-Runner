extends AnimatableBody2D

const DAMAGE := 1
const CAR_SPEED := 300.0

@onready var front_damage_area: Area2D = $FrontDamageArea
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var tem_esteira := false

func _ready() -> void:
	animated_sprite.stop()
	animated_sprite.frame = 0
	front_damage_area.monitoring = false
	front_damage_area.body_entered.connect(_on_front_damage_area_body_entered)
	call_deferred("_configure_conveyor_state")

func _configure_conveyor_state() -> void:
	tem_esteira = get_tree().get_first_node_in_group("esteira") != null
	if tem_esteira:
		animated_sprite.play("Andando")
	else:
		animated_sprite.stop()
		animated_sprite.frame = 0
	front_damage_area.monitoring = tem_esteira

func _physics_process(delta: float) -> void:
	if not tem_esteira:
		return
	global_position.x -= CAR_SPEED * delta

func _on_front_damage_area_body_entered(body: Node2D) -> void:
	if not tem_esteira:
		return
	if not body.is_in_group("player") or not body.has_method("take_damage"):
		return

	body.call("take_damage", DAMAGE, self)
