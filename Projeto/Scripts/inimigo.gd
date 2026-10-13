extends CharacterBody2D

enum State { SPAWN, IDLE, CHASE, ATTACK, HURT, DEAD }

const MAX_HEALTH := 2
const DAMAGE := 1
const KNOCKBACK_STRENGTH := 400.0
const KNOCKBACK_DECAY := 500.0

var speed := 120.0
var attack_distance := 70.0
var current_state: State = State.IDLE
var health := MAX_HEALTH
var player: Node2D = null
var knockback_velocity := Vector2.ZERO
var attack_targets: Dictionary = {}

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("inimigo")
	animated_sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)
	change_state(State.SPAWN)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = _find_player()

	match current_state:
		State.SPAWN, State.HURT, State.DEAD:
			velocity = Vector2.ZERO

		State.IDLE:
			velocity = Vector2.ZERO
			if is_instance_valid(player):
				change_state(State.CHASE)

		State.CHASE:
			if not is_instance_valid(player):
				change_state(State.IDLE)
			else:
				var distance := global_position.distance_to(player.global_position)
				if distance <= attack_distance:
					change_state(State.ATTACK)
				else:
					_move_toward_player()

		State.ATTACK:
			velocity = Vector2.ZERO
			if not is_instance_valid(player):
				change_state(State.IDLE)
			elif not attack_targets.has(player.get_instance_id()):
				_move_toward_player()

	velocity += knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	move_and_slide()
	_check_player_body_collision()

func _find_player() -> Node2D:
	var target := get_tree().get_first_node_in_group("player")
	if target is Node2D:
		return target as Node2D
	return null

func _move_toward_player() -> void:
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		return

	var direction := (player.global_position - global_position).normalized()
	velocity = direction * speed
	if direction.x != 0.0:
		# O sprite original olha para a esquerda; espelha quando vai para a direita.
		animated_sprite.flip_h = direction.x > 0.0

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	match current_state:
		State.SPAWN:
			animated_sprite.play("Aparecendo")
		State.IDLE:
			animated_sprite.play("Parado")
		State.CHASE:
			animated_sprite.play("Voando")
		State.ATTACK:
			_start_attack()
		State.HURT:
			animated_sprite.play("Dano")
		State.DEAD:
			animated_sprite.play("Morte")

func _start_attack() -> void:
	attack_targets.clear()
	animated_sprite.play("Ataque")

func _check_player_body_collision() -> void:
	if current_state != State.CHASE and current_state != State.ATTACK:
		return

	for index in range(get_slide_collision_count()):
		var collider := get_slide_collision(index).get_collider() as Node2D
		if collider == null or not collider.is_in_group("player"):
			continue

		if current_state == State.CHASE:
			change_state(State.ATTACK)
		_damage_player(collider)

func _damage_player(body: Node2D) -> void:
	if current_state != State.ATTACK:
		return
	if body == self or not body.is_in_group("player"):
		return
	if not body.has_method("take_damage"):
		return

	var body_id := body.get_instance_id()
	if attack_targets.has(body_id):
		return

	attack_targets[body_id] = true
	var player_position := body.global_position
	body.call("take_damage", DAMAGE, self)
	_apply_knockback_away_from(player_position)

func take_damage(amount: int = 1, attacker: Node2D = null) -> void:
	if current_state == State.DEAD or amount <= 0:
		return

	health = maxi(health - amount, 0)
	var source_position := global_position
	if is_instance_valid(attacker):
		source_position = attacker.global_position
	elif is_instance_valid(player):
		source_position = player.global_position
	else:
		if animated_sprite.flip_h:
			source_position.x += 1.0
		else:
			source_position.x -= 1.0
	_apply_knockback_away_from(source_position)

	if health == 0:
		change_state(State.DEAD)
	elif current_state == State.HURT:
		animated_sprite.play("Dano")
	else:
		change_state(State.HURT)

func _apply_knockback_away_from(source_position: Vector2) -> void:
	var direction := global_position - source_position
	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT if animated_sprite.flip_h else Vector2.LEFT
	knockback_velocity = direction.normalized() * KNOCKBACK_STRENGTH

func _on_animated_sprite_2d_animation_finished() -> void:
	match current_state:
		State.SPAWN:
			change_state(State.IDLE)
		State.ATTACK:
			if is_instance_valid(player):
				if global_position.distance_to(player.global_position) <= attack_distance:
					_start_attack()
				else:
					change_state(State.CHASE)
			else:
				change_state(State.IDLE)
		State.HURT:
			if is_instance_valid(player):
				change_state(State.CHASE)
			else:
				change_state(State.IDLE)
		State.DEAD:
			queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
