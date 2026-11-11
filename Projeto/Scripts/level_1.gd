extends Node2D
## Integração local da corrida; nunca muda para a cena de teste FaseBatalha.

const PICKUP = preload("res://Scenes/Items/power_up.tscn")

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
			_spawn_pickup()
			pickup_countdown = rng.randf_range(pickup_interval_min, maxf(pickup_interval_min, pickup_interval_max))


func _spawn_pickup() -> void:
	if get_tree().get_nodes_in_group("power_up").size() >= max_pickups:
		return
	var pickup := PICKUP.instantiate()
	# O relógio só entra no sorteio quando há uma parada ativa.
	pickup.kind = rng.randi_range(0, 3 if session.stop_active else 2)
	pickup.position = Vector2(rng.randf_range(550.0, 1050.0), rng.randf_range(500.0, 555.0))
	add_child(pickup)


func _on_run_ended() -> void:
	for pickup in get_tree().get_nodes_in_group("power_up"):
		pickup.queue_free()
