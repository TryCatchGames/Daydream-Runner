class_name PlayerPowerUps
extends Node2D
## Efeitos locais ao jogador; a vida e a pontuação continuam nos sistemas existentes.

@export_range(0, 20, 1, "or_greater") var max_extra_hearts := 3
var double_points_remaining := 0.0
var invincibility_remaining := 0.0
var _contact: Area2D
var _contact_shape: CollisionShape2D
@onready var player: CharacterBody2D = get_parent()
@onready var body_shape: CollisionShape2D = player.get_node("CollisionShape2D")
@onready var base_health: int = player.get_script().get_script_constant_map()["MAX_HEALTH"]

func _ready() -> void:
	player.connect("died", clear_effects)
	player.tree_exiting.connect(clear_effects)
	_contact = Area2D.new()
	_contact.collision_layer = 0
	_contact.collision_mask = 2
	_contact_shape = CollisionShape2D.new()
	_contact_shape.shape = body_shape.shape.duplicate()
	# Uma margem pequena detecta também corpos que a física mantém separados.
	_contact_shape.scale = Vector2(1.1, 1.1)
	_contact.add_child(_contact_shape)
	add_child(_contact)
	_contact.body_entered.connect(_defeat_on_contact)

func _physics_process(delta: float) -> void:
	double_points_remaining = maxf(0.0, double_points_remaining - delta)
	invincibility_remaining = maxf(0.0, invincibility_remaining - delta)
	_contact_shape.global_transform = body_shape.global_transform
	_contact_shape.scale *= 1.1
	if is_invincible():
		for body in _contact.get_overlapping_bodies():
			_defeat_on_contact(body)
	queue_redraw()

func activate_double_points(duration: float) -> void:
	double_points_remaining = maxf(duration, 0.0)

func activate_invincibility(duration: float) -> void:
	invincibility_remaining = maxf(duration, 0.0)
	queue_redraw()

func is_invincible() -> bool:
	return invincibility_remaining > 0.0

func get_health_capacity(base_health: int) -> int:
	# Um coração extra pela metade continua visível; ao esvaziar, desaparece.
	var extra := maxi(0, int(player.get("health")) - base_health)
	return base_health + ceili(extra / 2.0) * 2

func restore_heart() -> void:
	var health := int(player.get("health"))
	var capacity := get_health_capacity(base_health)
	if health < capacity:
		health = mini(health + 2, capacity)
	else:
		health = maxi(health, mini(health + 2, base_health + max_extra_hearts * 2))
	player.set("health", health)
	player.emit_signal("health_changed", health, get_health_capacity(base_health))

func _defeat_on_contact(body: Node2D) -> void:
	if is_invincible() and body.is_in_group("inimigo") and body.has_method("take_damage"):
		body.call("take_damage", int(body.get("health")), player)

## Chamar também ao concluir uma fase sem remover o jogador da árvore.
func clear_effects() -> void:
	double_points_remaining = 0.0
	invincibility_remaining = 0.0
	if is_instance_valid(player):
		player.set("health", mini(int(player.get("health")), base_health))
		player.emit_signal("health_changed", int(player.get("health")), base_health)
	queue_redraw()

func _exit_tree() -> void:
	double_points_remaining = 0.0
	invincibility_remaining = 0.0

func _draw() -> void:
	if not is_invincible() or not is_instance_valid(body_shape):
		return
	var center := to_local(body_shape.global_position)
	# Halo translúcido independente do material usado pelo feedback de dano.
	for ring in range(8):
		draw_circle(center, 24.0 + ring * 1.8, Color(1.0, 0.078, 0.078, 0.059))
