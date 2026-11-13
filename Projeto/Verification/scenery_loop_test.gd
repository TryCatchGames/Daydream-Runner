extends SceneTree
## Godot --headless --path Projeto --script res://Verification/scenery_loop_test.gd
## Verifica geometria e integração; não substitui a inspeção visual das artes.

const LOOP_LAYER = preload("res://Scripts/scenery_loop_layer.gd")
const LEVEL = preload("res://Scenes/Fases/Level_1.tscn")

var failures := 0
var assertions := 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error(description)


func close(actual: float, expected: float, description: String, tolerance := 0.02) -> void:
	check(absf(actual - expected) <= tolerance, "%s: esperado %.4f, recebido %.4f" % [description, expected, actual])


func rect_close(actual: Rect2, expected: Rect2, description: String) -> void:
	check(actual.position.is_equal_approx(expected.position) and actual.size.is_equal_approx(expected.size),
		"%s: esperado %s, recebido %s" % [description, expected, actual])


func make_texture(width: int, height: int) -> GradientTexture2D:
	var texture := GradientTexture2D.new()
	texture.width = width
	texture.height = height
	return texture


func make_sprite(width: int, height: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = make_texture(width, height)
	return sprite


func node_ids(node: Node) -> Array[int]:
	var ids: Array[int] = [node.get_instance_id()]
	for child in node.get_children():
		ids.append_array(node_ids(child))
	ids.sort()
	return ids


func check_phase(actual: float, expected: float, period: float, description: String) -> void:
	var error := fposmod(actual - expected + period * 0.5, period) - period * 0.5
	close(error, 0.0, description)


func run() -> void:
	test_transformed_bounds()
	test_editing_and_alignment()
	test_invalid_content()
	test_runtime_loop()
	test_long_running_phase()
	await test_level_integration()
	if failures == 0:
		print("SCENERY_LOOP_TESTS: PASS (%d verificações)" % assertions)
	else:
		push_error("SCENERY_LOOP_TESTS: FAIL (%d/%d)" % [failures, assertions])
	quit(0 if failures == 0 else 1)


func test_transformed_bounds() -> void:
	var layer = LOOP_LAYER.new()
	var sprite := make_sprite(100, 40)
	sprite.position = Vector2(120, 45)
	sprite.offset = Vector2(7, -3)
	sprite.scale = Vector2(-2, 1.5)
	layer.add_child(sprite)
	rect_close(layer.get_repeat_bounds(), Rect2(6, 10.5, 200, 60),
		"Sprite centralizado: offset e escala negativa entram nos limites")
	layer.free()

	layer = LOOP_LAYER.new()
	layer.position = Vector2(700, -900)
	layer.scale = Vector2(3, 2)
	var group := Node2D.new()
	group.position = Vector2(20, 30)
	group.scale = Vector2(1.5, 2)
	layer.add_child(group)
	sprite = make_sprite(100, 40)
	sprite.position = Vector2(40, 5)
	sprite.scale = Vector2(-2, 0.5)
	sprite.centered = false
	sprite.offset = Vector2(3, -4)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(10, 2, 30, 12)
	group.add_child(sprite)
	rect_close(layer.get_repeat_bounds(), Rect2(-19, 36, 90, 12),
		"Região e grupo escalado são medidos no espaço local da camada")
	layer.free()

	layer = LOOP_LAYER.new()
	group = Node2D.new()
	group.position = Vector2(100, 50)
	group.rotation = PI * 0.5
	layer.add_child(group)
	sprite = make_sprite(10, 20)
	sprite.centered = false
	sprite.position = Vector2(5, 7)
	group.add_child(sprite)
	rect_close(layer.get_repeat_bounds(), Rect2(73, 55, 20, 10),
		"Rotação de grupo transforma os quatro cantos do sprite")
	layer.free()

	layer = LOOP_LAYER.new()
	group = Node2D.new()
	layer.add_child(group)
	var texture_rect := TextureRect.new()
	texture_rect.texture = make_texture(1, 1)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.position = Vector2(11, -8)
	texture_rect.size = Vector2(60, 30)
	texture_rect.scale = Vector2(2, 0.5)
	group.add_child(texture_rect)
	rect_close(layer.get_repeat_bounds(), Rect2(11, -8, 120, 15),
		"TextureRect também contribui com seus limites transformados")
	layer.free()


func test_editing_and_alignment() -> void:
	var layer = LOOP_LAYER.new()
	var first := make_sprite(50, 20)
	first.name = "Primeiro"
	first.centered = false
	first.position = Vector2(100, 20)
	var middle := make_sprite(40, 10)
	middle.name = "Meio"
	middle.position = Vector2(280, 80)
	var last := make_sprite(70, 15)
	last.name = "Ultimo"
	last.centered = false
	last.position = Vector2(500, 100)
	last.scale.x = -1
	layer.add_child(middle)
	layer.add_child(last)
	layer.add_child(first)
	check(layer.get_layout_warnings().size() > 0,
		"Lacunas na composição produzem diagnóstico antes de executar")
	var original_order: Array[Node] = layer.get_children()
	layer.align_segments()
	close(first.position.x, 100, "O encaixe preserva o começo da faixa")
	close(middle.position.x, 170, "Trecho central encaixa usando sua largura real")
	close(last.position.x, 260, "Trecho espelhado encaixa pela borda desenhada")
	check(first.position.y == 20 and middle.position.y == 80 and last.position.y == 100,
		"Encaixe horizontal preserva todas as posições verticais")
	check(last.scale == Vector2(-1, 1), "Encaixe preserva escala e espelhamento")
	check(layer.get_children() == original_order, "Encaixe preserva a ordem de desenho da árvore")
	close(layer.get_repeat_bounds().size.x, 160,
		"Período resulta das larguras de tamanhos diferentes, sem valor fixo")

	var extra := make_sprite(25, 20)
	extra.centered = false
	extra.position = Vector2(260, 20)
	layer.add_child(extra)
	close(layer.get_repeat_bounds().size.x, 185, "Adicionar sprite expande os limites automaticamente")
	layer.remove_child(extra)
	extra.free()
	close(layer.get_repeat_bounds().size.x, 160, "Remover sprite recalcula os limites automaticamente")
	first.position.x = 300
	layer.align_segments()
	close(layer.get_repeat_bounds().size.x, 160,
		"Reorganizar visualmente e encaixar mantém o comprimento calculado")
	check(first.position.x > middle.position.x and first.position.x >= last.position.x,
		"Encaixe segue a ordem espacial editada, sem impor ordem de árvore")
	layer.free()

	layer = LOOP_LAYER.new()
	var group := Node2D.new()
	group.name = "TrechoComLacunaInterna"
	layer.add_child(group)
	var left_visual := make_sprite(30, 20)
	left_visual.centered = false
	group.add_child(left_visual)
	var right_visual := make_sprite(50, 20)
	right_visual.name = "VisualAfastado"
	right_visual.centered = false
	right_visual.position.x = 100
	group.add_child(right_visual)
	check(layer.get_layout_warnings().size() > 0,
		"Lacuna interna de um grupo é identificada mesmo quando há um único trecho")
	layer.free()


func test_invalid_content() -> void:
	var layer = LOOP_LAYER.new()
	var sprite := make_sprite(100, 20)
	layer.add_child(sprite)
	var collision := Area2D.new()
	collision.name = "EventoDeGameplay"
	sprite.add_child(collision)
	check(layer.get_layout_warnings().size() > 0,
		"Área de gameplay dentro de conteúdo repetível é identificada")
	root.add_child(layer)
	check(layer.runtime_renderer == null,
		"Conteúdo com colisão bloqueia a repetição, preservando o objeto de gameplay")
	layer.free()

	layer = LOOP_LAYER.new()
	layer.add_child(make_sprite(100, 20))
	var timer := Timer.new()
	timer.name = "GatilhoDeBatalha"
	layer.add_child(timer)
	check(layer.get_layout_warnings().size() > 0,
		"Timer de evento dentro de conteúdo repetível é identificado")
	root.add_child(layer)
	check(layer.runtime_renderer == null,
		"Conteúdo com Timer não entra no repetidor visual")
	layer.free()


func test_runtime_loop() -> void:
	var layer = LOOP_LAYER.new()
	layer.name = "CamadaReutilizada"
	var sprite := make_sprite(20, 15)
	sprite.centered = false
	sprite.position = Vector2(-7, 30)
	layer.add_child(sprite)
	root.add_child(layer)
	var renderer: Parallax2D = layer.runtime_renderer
	check(renderer != null, "Camada reutilizável cria repetidor nativo")
	if renderer == null:
		layer.free()
		return
	close(renderer.repeat_size.x, 20, "Período nativo usa a largura detectada")
	check(renderer.repeat_size.y == 0, "Repetição não altera a faixa vertical")
	check(renderer.repeat_times >= ceili(root.get_visible_rect().size.x / 20),
		"Faixa menor que a tela recebe repetições visuais suficientes")
	var original_ids := node_ids(layer)
	var phase := renderer.scroll_offset.x
	var original_y := sprite.global_position.y
	layer.advance(20 * 27 + 3.5)
	check_phase(renderer.scroll_offset.x, phase - 3.5, 20,
		"Um passo pode atravessar vários loops preservando o deslocamento restante")
	phase = renderer.scroll_offset.x
	layer.advance(20)
	check_phase(renderer.scroll_offset.x, phase, 20,
		"Uma volta completa termina na mesma fase visual")
	layer.speed_multiplier = 0.5
	layer.advance(6)
	check_phase(renderer.scroll_offset.x, phase - 3, 20,
		"Velocidade por camada é configurável sem alterar o período")
	for index in range(500):
		layer.advance(400.0 / 60.0)
	check(node_ids(layer) == original_ids,
		"Muitas repetições não instanciam nem reciclam objetos da árvore")
	close(sprite.global_position.y, original_y, "Loop mantém a posição vertical")
	layer.free()


func test_long_running_phase() -> void:
	var layer = LOOP_LAYER.new()
	for index in range(5):
		var sprite := make_sprite(8865, 20)
		sprite.centered = false
		sprite.position.x = index * 8865
		layer.add_child(sprite)
	root.add_child(layer)
	var renderer: Parallax2D = layer.runtime_renderer
	check(renderer != null, "Faixa longa cria repetidor nativo")
	if renderer == null:
		layer.free()
		return
	var initial_phase := renderer.scroll_offset.x
	var step_distance := 400.0 / 60.0
	var steps := 18000
	for index in range(steps):
		layer.advance(step_distance)
	check_phase(renderer.scroll_offset.x, initial_phase - step_distance * steps,
		renderer.repeat_size.x,
		"Cinco minutos a 60 passos/s não acumulam erro de fase em faixa longa")
	layer.free()


func test_level_integration() -> void:
	var level: Node2D = LEVEL.instantiate()
	# O fixture não precisa iniciar áudio: evita deixar playback na thread de áudio.
	level.get_node("AudioStreamPlayer").autoplay = false
	root.add_child(level)
	current_scene = level
	var conveyor = level.get_node("Esteira")
	conveyor.set_physics_process(false)
	level.get_node("Player").set_physics_process(false)
	for car in level.get_node("Carros").get_children():
		car.set_physics_process(false)
	for pickup in get_nodes_in_group("power_up"):
		pickup.set_physics_process(false)
	await process_frame
	# Sem novos awaits, habilitamos o flag usado pela API e avançamos manualmente.
	# Nenhum passo automático da SceneTree intercala estas verificações.
	conveyor.set_physics_process(true)
	check(conveyor.is_in_group("esteira"), "Grupo usado por carros e power-ups é preservado")
	close(conveyor.get_scroll_speed(), 400, "Velocidade do cenário permanece 400 px/s")
	var floor_node: StaticBody2D = conveyor.get_node("Chao")
	var floor_transform := floor_node.global_transform
	var conveyor_transform: Transform2D = conveyor.global_transform
	var event_visual: Node2D = conveyor.get_node("EventosVisuais")
	var event_start := event_visual.position
	var crossing: Node = event_visual.get_node("Esquina")
	var signal_visual: Node = event_visual.get_node("Semáforo")
	var crossing_id := crossing.get_instance_id()
	var signal_id := signal_visual.get_instance_id()
	var car_ids := node_ids(level.get_node("Carros"))
	var pickup_ids: Array[int] = []
	for pickup in get_nodes_in_group("power_up"):
		pickup_ids.append(pickup.get_instance_id())
	var layers: Array[Node] = []
	var phases: Array[float] = []
	var periods: Array[float] = []
	for layer_name in ["Ceu", "Predios", "Estrada"]:
		var layer = conveyor.get_node(layer_name)
		layers.append(layer)
		check(layer.runtime_renderer != null, "%s tem repetição visual ativa" % layer_name)
		if layer.runtime_renderer == null:
			level.free()
			return
		phases.append(layer.runtime_renderer.scroll_offset.x)
		periods.append(layer.runtime_renderer.repeat_size.x)
	var scene_ids := node_ids(level)
	var elapsed := 300.0
	conveyor._physics_process(elapsed)
	for index in range(layers.size()):
		check_phase(layers[index].runtime_renderer.scroll_offset.x,
			phases[index] - 400 * elapsed, periods[index],
			"%s mantém a fase após longa corrida e múltiplas voltas" % layers[index].name)
	check(event_visual.position.is_equal_approx(event_start - Vector2(400 * elapsed, 0)),
		"Cruzamento percorre a fase uma vez, sem voltar com o loop visual")
	check(crossing.get_instance_id() == crossing_id and signal_visual.get_instance_id() == signal_id,
		"Loop não recria o cruzamento nem o semáforo")
	check(floor_node.global_transform == floor_transform and conveyor.global_transform == conveyor_transform,
		"Chão físico e raiz da esteira não são teletransportados")
	check(node_ids(level) == scene_ids, "Loop não duplica nenhum nó da fase")
	check(node_ids(level.get_node("Carros")) == car_ids,
		"Veículos ficam fora das camadas recicladas")
	var pickups_after: Array[int] = []
	for pickup in get_nodes_in_group("power_up"):
		pickups_after.append(pickup.get_instance_id())
	check(pickups_after == pickup_ids, "Power-ups mantêm identidade após voltas visuais")

	conveyor.set_scrolling_enabled(false)
	close(conveyor.get_scroll_speed(), 0, "Pausa é exposta aos sistemas que consultam velocidade")
	var paused_phases: Array[float] = []
	for layer in layers:
		paused_phases.append(layer.runtime_renderer.scroll_offset.x)
	var paused_events := event_visual.position
	conveyor._physics_process(20)
	for index in range(layers.size()):
		close(layers[index].runtime_renderer.scroll_offset.x, paused_phases[index],
			"%s permanece parada" % layers[index].name)
	check(event_visual.position == paused_events, "Cruzamento e semáforo permanecem parados")
	conveyor.set_scrolling_enabled(true)
	conveyor._physics_process(0.25)
	for index in range(layers.size()):
		check_phase(layers[index].runtime_renderer.scroll_offset.x,
			paused_phases[index] - 100, periods[index],
			"%s retoma a partir da mesma fase" % layers[index].name)
	close(event_visual.position.x, paused_events.x - 100, "Eventos visuais retomam sem reinicialização")

	conveyor.CAR_SPEED = 0
	var zero_speed_phase: float = layers[0].runtime_renderer.scroll_offset.x
	conveyor._physics_process(4)
	close(layers[0].runtime_renderer.scroll_offset.x, zero_speed_phase,
		"Zerar CAR_SPEED também interrompe o cenário")
	conveyor.CAR_SPEED = 400
	conveyor.set_physics_process(false)
	close(conveyor.get_scroll_speed(), 0,
		"Desativar a física expõe velocidade zero aos power-ups")
	var disabled_phases: Array[float] = []
	for layer in layers:
		disabled_phases.append(layer.runtime_renderer.scroll_offset.x)
	var disabled_events := event_visual.position
	conveyor._physics_process(15)
	for index in range(layers.size()):
		close(layers[index].runtime_renderer.scroll_offset.x, disabled_phases[index],
			"%s não avança com física desativada" % layers[index].name)
	check(event_visual.position == disabled_events,
		"Física desativada preserva a posição dos eventos visuais")
	conveyor.set_physics_process(true)
	conveyor._physics_process(0.25)
	for index in range(layers.size()):
		check_phase(layers[index].runtime_renderer.scroll_offset.x,
			disabled_phases[index] - 100, periods[index],
			"%s retoma sem reiniciar após reativar física" % layers[index].name)
	close(event_visual.position.x, disabled_events.x - 100,
		"Eventos retomam da posição preservada ao reativar física")
	var pickup := level.get_node("Invincibility") as Node2D
	var pickup_start := pickup.position.x
	var pickup_scroll_speed := float(pickup.get("scroll_speed"))
	conveyor.set_scrolling_enabled(false)
	pickup.call("_physics_process", 0.25)
	close(pickup.position.x, pickup_start,
		"Power-up real mantém X durante a pausa da esteira")
	conveyor.set_scrolling_enabled(true)
	pickup.call("_physics_process", 0.25)
	close(pickup.position.x, pickup_start - pickup_scroll_speed * 0.25,
		"Power-up real retoma com sua própria velocidade configurada")
	pickup_start = pickup.position.x
	conveyor.set_physics_process(false)
	pickup.call("_physics_process", 0.25)
	close(pickup.position.x, pickup_start,
		"Desativar física da esteira também pausa o movimento horizontal do power-up")
	conveyor.set_physics_process(true)
	pickup.call("_physics_process", 0.25)
	close(pickup.position.x, pickup_start - pickup_scroll_speed * 0.25,
		"Power-up real retoma do mesmo X ao reativar física da esteira")
	var car = level.get_node("Carros").get_child(0)
	check(car is AnimatableBody2D and car.is_in_group("car_platform"),
		"Veículo mantém corpo físico e grupo da plataforma")
	# Apenas o fixture desliga a sincronização para medir esta chamada isolada.
	car.sync_to_physics = false
	var car_start: float = car.global_position.x
	car._physics_process(0.25)
	close(car.global_position.x, car_start - 175,
		"Carro preserva seus 700 px/s, independentes dos 400 px/s da estrada")
	check(floor_node.global_transform == floor_transform,
		"Parada, retomada e movimento de veículo preservam o chão físico")
	level.free()
