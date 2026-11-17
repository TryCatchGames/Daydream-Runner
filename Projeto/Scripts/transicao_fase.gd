class_name PhaseTransition
extends Control

const TRANSITION_SCENE_PATH := "res://Scenes/Transicoes/transicao_fase.tscn"
const TRANSITION_DATA_META: StringName = &"phase_transition_data"
const PHASE_NAMES := [
	"Tutorial",
	"Ida à escola",
	"Janela da escola",
	"Volta para casa",
	"Janela de casa",
]
#TODO: trocar o mapa para o verdadeiro

# para quando tiver as fases, já tem as conexões
# const PHASE_SCENE_PATHS := {
# 	1: "res://Scenes/Fases/Fase1.tscn",
# 	2: "res://Scenes/Fases/Fase2.tscn",
# 	3: "res://Scenes/Fases/Fase3.tscn",
# 	4: "res://Scenes/Fases/Fase4.tscn",
# 	5: "res://Scenes/Fases/Fase5.tscn",
# }

# conexões para descomentar no ponto de conclusão de cada fase:
# Fase1 -> Fase2: PhaseTransition.begin(get_tree(), 1, 2)
# Fase2 -> Fase3: PhaseTransition.begin(get_tree(), 2, 3)
# Fase3 -> Fase4: PhaseTransition.begin(get_tree(), 3, 4)
# Fase4 -> Fase5: PhaseTransition.begin(get_tree(), 4, 5)
# Fase5 encerra a campanha; não há próxima fase definida.
# Para iniciar a campanha pelo menu: get_tree().change_scene_to_file("res://Scenes/Fases/Fase1.tscn")

@export_range(1, 5, 1) var current_phase := 1
@export_range(1, 5, 1) var next_phase := 2
@export_range(0.5, 10.0, 0.1) var travel_duration := 3.0
@export_file("*.tscn") var destination_scene_path := ""

@onready var map_overlay: Node2D = $MapOverlay
@onready var routes: Node2D = $MapOverlay/Routes
@onready var title_label: Label = $Header/Title
@onready var destination_label: Label = $Header/Destination

var _active_route: Path2D
var _active_follower: PathFollow2D
var _active_ninjinha: AnimatedSprite2D


static func begin(
	tree: SceneTree,
	completed_phase: int,
	upcoming_phase: int,
	destination_path: String = ""
) -> void:
	# descomentar dps de declarar PHASE_SCENE_PATHS acima para carregar a fase destino.
	# if destination_path.is_empty():
	# 	destination_path = str(PHASE_SCENE_PATHS.get(upcoming_phase, ""))
	tree.set_meta(TRANSITION_DATA_META, {
		"current_phase": completed_phase,
		"next_phase": upcoming_phase,
		"destination_scene_path": destination_path,
	})
	tree.change_scene_to_file(TRANSITION_SCENE_PATH)


func _ready() -> void:
	_apply_transition_data()
	current_phase = clampi(current_phase, 1, PHASE_NAMES.size())
	next_phase = clampi(next_phase, 1, PHASE_NAMES.size())
	_update_header()
	_create_phase_markers()

	if not _prepare_routes():
		return

	_active_follower.progress_ratio = 0.0
	_active_ninjinha.flip_h = _active_route.curve.get_point_position(
		_active_route.curve.point_count - 1
	).x < _active_route.curve.get_point_position(0).x
	var running_animation := "RunningKatana" if current_phase >= 3 else "RunningKunai"
	_active_ninjinha.play(running_animation)
	_animate_travel()


func _process(_delta: float) -> void:
	if _active_route == null or _active_follower == null or _active_ninjinha == null:
		return

	var current_distance := _active_follower.progress
	var path_length := _active_route.curve.get_baked_length()
	var look_ahead := minf(current_distance + 6.0, path_length)
	var current_point := _active_route.curve.sample_baked(current_distance)
	var next_point := _active_route.curve.sample_baked(look_ahead)
	if absf(next_point.x - current_point.x) > 0.01:
		_active_ninjinha.flip_h = next_point.x < current_point.x


func _apply_transition_data() -> void:
	var transition_data: Variant = get_tree().get_meta(TRANSITION_DATA_META, {})
	if transition_data is Dictionary and not transition_data.is_empty():
		current_phase = int(transition_data.get("current_phase", current_phase))
		next_phase = int(transition_data.get("next_phase", next_phase))
		destination_scene_path = str(
			transition_data.get("destination_scene_path", destination_scene_path)
		)
		get_tree().remove_meta(TRANSITION_DATA_META)


func _update_header() -> void:
	title_label.text = "FASE %d CONCLUÍDA" % current_phase
	destination_label.text = "PRÓXIMA: FASE %d — %s" % [
		next_phase,
		String(PHASE_NAMES[next_phase - 1]).to_upper(),
	]


func _route_name(from_phase: int, to_phase: int) -> String:
	return "Fase%dPara%d" % [from_phase, to_phase]


func _get_route(from_phase: int, to_phase: int) -> Path2D:
	return routes.get_node_or_null(_route_name(from_phase, to_phase)) as Path2D


func _prepare_routes() -> bool:
	var selected_name := _route_name(current_phase, next_phase)
	for child in routes.get_children():
		if not child is Path2D:
			continue

		var route := child as Path2D
		var selected := route.name == selected_name
		var route_points := route.curve.get_baked_points()
		var shadow := route.get_node("RouteShadow") as Line2D
		var line := route.get_node("RouteLine") as Line2D
		shadow.points = route_points
		line.points = route_points
		shadow.visible = selected
		line.visible = selected

		var follower := route.get_node("PathFollow2D") as PathFollow2D
		follower.loop = false
		follower.rotates = false
		var ninjinha := follower.get_node("Ninjinha") as AnimatedSprite2D
		ninjinha.visible = selected
		if selected:
			_active_route = route
			_active_follower = follower
			_active_ninjinha = ninjinha

	if _active_route == null:
		push_error("Rota não encontrada: %s" % selected_name)
		return false
	if _active_route.curve.point_count < 2:
		push_error("A rota %s precisa de pelo menos dois pontos." % selected_name)
		return false
	return true


func _phase_position_on_map(phase_number: int) -> Vector2:
	var route: Path2D
	var point_index: int
	if phase_number <= 1:
		route = _get_route(1, 2)
		point_index = 0
	else:
		route = _get_route(phase_number - 1, phase_number)
		point_index = route.curve.point_count - 1

	var curve_position := route.curve.get_point_position(point_index)
	return map_overlay.to_local(route.to_global(curve_position))


func _create_phase_markers() -> void:
	for phase_number in [current_phase, next_phase]:
		var point := _phase_position_on_map(phase_number)
		var marker := ColorRect.new()
		marker.position = point - Vector2(10.0, 10.0)
		marker.size = Vector2(20.0, 20.0)
		marker.z_index = 8
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if phase_number == current_phase:
			marker.color = Color("#f7e7b0")
		elif phase_number == next_phase:
			marker.color = Color("#f4bd4f")
		else:
			marker.color = Color("#a8c7b5")
		map_overlay.add_child(marker)

		var number_label := Label.new()
		number_label.position = point + Vector2(12.0, -20.0)
		number_label.size = Vector2(36.0, 30.0)
		number_label.text = str(phase_number)
		number_label.z_index = 9
		number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		number_label.add_theme_font_override(
			"font",
			preload("res://Sprites/Fonts/PressStart2P-Regular.ttf")
		)
		number_label.add_theme_font_size_override("font_size", 16)
		number_label.add_theme_color_override("font_color", Color("#fff4d5"))
		number_label.add_theme_color_override("font_outline_color", Color("#10201d"))
		number_label.add_theme_constant_override("outline_size", 4)
		map_overlay.add_child(number_label)


func _animate_travel() -> void:
	var tween := create_tween()
	tween.tween_property(
		_active_follower,
		"progress_ratio",
		1.0,
		travel_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	_active_ninjinha.stop()
	if destination_scene_path.is_empty():
		return

	await get_tree().create_timer(0.45).timeout
	if ResourceLoader.exists(destination_scene_path):
		get_tree().change_scene_to_file(destination_scene_path)
	else:
		push_error("Cena de destino não encontrada: %s" % destination_scene_path)
