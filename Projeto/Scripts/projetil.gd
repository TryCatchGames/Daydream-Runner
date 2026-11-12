extends Area2D

@export var speed: float = 650.0
@export var damage: int = 1

var direction: Vector2 = Vector2.RIGHT
var hit_done := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Auto-destrói após 3 segundos caso não acerte nada
	get_tree().create_timer(3.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	var spin_dir := 1.0 if direction.x >= 0.0 else -1.0
	rotation += 15.0 * delta * spin_dir

func _on_body_entered(body: Node2D) -> void:
	if hit_done or body.is_in_group("player"):
		return

	if body.is_in_group("inimigo") and body.has_method("take_damage"):
		hit_done = true
		body.call("take_damage", damage, self)
		queue_free()
	elif body is TileMap or body is TileMapLayer or body is StaticBody2D:
		# Destrói ao bater na parede/chão
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if hit_done:
		return
	
	# Caso o inimigo tenha uma HurtBox (Area2D) filha do corpo principal
	var target := area.get_parent()
	if area.is_in_group("inimigo") and area.has_method("take_damage"):
		hit_done = true
		area.call("take_damage", damage, self)
		queue_free()
	elif target and target.is_in_group("inimigo") and target.has_method("take_damage"):
		hit_done = true
		target.call("take_damage", damage, self)
		queue_free()
