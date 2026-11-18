extends Node2D
## Integração local da corrida; nunca muda para a cena de teste FaseBatalha.

@export_group("Power-ups — ajustes iniciais")
@export var spawn_power_ups := true
@export_range(1.0, 60.0, 0.5) var pickup_interval_min := 4.0
@export_range(1.0, 60.0, 0.5) var pickup_interval_max := 8.0
@export_range(1, 12, 1) var max_pickups := 3

@onready var session: Node = $RunSession
@onready var player: CharacterBody2D = $Player

var pickup_countdown := 3.0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	player.died.connect(session.end_run)
	session.run_ended.connect(_on_run_ended)
	for enemy in get_tree().get_nodes_in_group("inimigo"):
		session.register_enemy(enemy)


func _physics_process(delta: float) -> void:
	if not session.active:
		return
	if spawn_power_ups:
		pickup_countdown -= delta
		if pickup_countdown <= 0.0:
			pickup_countdown = rng.randf_range(pickup_interval_min, maxf(pickup_interval_min, pickup_interval_max))


func _on_run_ended() -> void:
	for pickup in get_tree().get_nodes_in_group("power_up"):
		pickup.queue_free()
