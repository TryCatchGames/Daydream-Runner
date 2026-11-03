extends AnimatableBody2D

const DAMAGE := 1
const CAR_SPEED := 700.0

@onready var front_damage_area: Area2D = $FrontDamageArea
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var esteira_node: Node2D = null
var tutorial_triggered := false
var was_tutorial_triggered: bool = false


@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	animated_sprite.stop()
	animated_sprite.frame = 0
	front_damage_area.monitoring = false
	front_damage_area.body_entered.connect(_on_front_damage_area_body_entered)
	
	# Conecta o sinal de entrar na tela automaticamente
	if has_node("VisibleOnScreenNotifier2D"):
		$VisibleOnScreenNotifier2D.screen_entered.connect(_on_visible_on_screen_notifier_2d_screen_entered)
	else:
		print("AVISO: O nó VisibleOnScreenNotifier2D não foi encontrado na cena do Carro!")
		
	call_deferred("_configure_conveyor_state")

func _configure_conveyor_state() -> void:
	esteira_node = get_tree().get_first_node_in_group("esteira")
	var tem_esteira := esteira_node != null
	if tem_esteira:
		animated_sprite.play("Andando")
	else:
		animated_sprite.stop()
		animated_sprite.frame = 0
	front_damage_area.monitoring = tem_esteira

func _physics_process(delta: float) -> void:
	if esteira_node == null:
		return
		
	# Lê a velocidade atual da esteira. Se for 0.0 (tutorial parado), o carro não anda.
	var esteira_speed: float = esteira_node.get("speed") if "speed" in esteira_node else 400.0
	if esteira_speed <= 0.0:
		return

	global_position.x -= CAR_SPEED * delta

func _on_front_damage_area_body_entered(body: Node2D) -> void:
	if esteira_node == null:
		return
	if not body.is_in_group("player") or not body.has_method("take_damage"):
		return

	body.call("take_damage", DAMAGE, self)

# Sinal do VisibleOnScreenNotifier2D para pausar o jogo no tutorial
func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	if not was_tutorial_triggered:
		was_tutorial_triggered = true
		var tutorial = get_tree().get_first_node_in_group("tutorial_manager")
		if tutorial and tutorial.has_method("trigger_car_tutorial"):
			tutorial.trigger_car_tutorial()
