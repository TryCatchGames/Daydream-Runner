extends Node2D

@export var damage: int = 1

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitt_box: Area2D = $HittBox
@onready var shape_topo: CollisionShape2D = $HittBox/Topo
@onready var shape_inicial: CollisionShape2D = $HittBox/Inicial
@onready var shape_final: CollisionShape2D = $HittBox/Final

var has_hit_player := false


func _ready() -> void:
	_disable_all_hitboxes()
	
	hitt_box.body_entered.connect(_on_hitt_box_body_entered)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.animation_finished.connect(queue_free)
	
	animated_sprite.play("Spell") # Coloque o nome exato da animação da spell


func _disable_all_hitboxes() -> void:
	shape_topo.set_deferred("disabled", true)
	shape_inicial.set_deferred("disabled", true)
	shape_final.set_deferred("disabled", true)


func _on_frame_changed() -> void:
	match animated_sprite.frame:
		0, 1, 2, 3, 4:
			shape_topo.set_deferred("disabled", false)
		5:
			# Ativa a parte do meio
			shape_inicial.set_deferred("disabled", false)
		6, 7, 8, 9, 10, 11, 12:
			# Ativa a ponta de baixo (impacto total)
			shape_final.set_deferred("disabled", false)
		13:
			# Magia dissipando: desativa as hitboxes no final
			_disable_all_hitboxes()

	# Garante acerto caso o player já estivesse parado dentro da área quando o frame ativou
	_check_overlapping_player()


func _on_hitt_box_body_entered(body: Node2D) -> void:
	_try_damage_player(body)


func _check_overlapping_player() -> void:
	if has_hit_player:
		return
	for body in hitt_box.get_overlapping_bodies():
		_try_damage_player(body)


func _try_damage_player(body: Node2D) -> void:
	if has_hit_player:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		has_hit_player = true
		body.take_damage(damage, self)
