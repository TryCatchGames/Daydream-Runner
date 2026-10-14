extends AnimatableBody2D

const DAMAGE := 1
const CAR_SPEED := 500.0

@onready var front_damage_area: Area2D = $FrontDamageArea

func _ready() -> void:
	front_damage_area.body_entered.connect(_on_front_damage_area_body_entered)

#func _physics_process(delta: float) -> void:
	# Corpo animável: o carro se move sem disputar o movimento com o player.
#	global_position.x -= CAR_SPEED * delta

func _on_front_damage_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or not body.has_method("take_damage"):
		return

	body.call("take_damage", DAMAGE, self)
