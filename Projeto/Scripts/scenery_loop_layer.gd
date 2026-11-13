@tool
class_name SceneryLoopLayer
extends Node2D
## Faixa visual editável: mede a composição e usa Parallax2D somente para renderizar.
## Os filhos diretos são sprites ou grupos Node2D, sem lógica de gameplay.

@export_range(0.0, 4.0, 0.05, "or_greater") var speed_multiplier := 1.0
@export var warn_overlaps := true
@export var warn_vertical_seams := false
@export_range(0.01, 10.0, 0.01) var seam_tolerance := 0.25
@export var show_editor_bounds := true
@export_tool_button("Encaixar trechos no eixo X") var align_action := align_segments

var runtime_renderer: Parallax2D
var _repeat_bounds := Rect2()
var _content: Node2D
var _editor_refresh := 0.0
var _runtime_warnings := PackedStringArray()
var _scroll_phase := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	set_process(false)
	var layout := _measure_layout()
	_repeat_bounds = layout.bounds
	_runtime_warnings = _layout_warnings(layout)
	for message in _runtime_warnings:
		push_warning("%s: %s" % [get_path(), message])
	if not layout.issues.is_empty() or _repeat_bounds.size.x <= 0.0:
		return
	# Não instanciamos cópias de cenas: o servidor de render repete os CanvasItems.
	var visuals := get_children()
	runtime_renderer = Parallax2D.new()
	runtime_renderer.name = "RepeticaoVisual"
	runtime_renderer.ignore_camera_scroll = true
	runtime_renderer.follow_viewport = false
	runtime_renderer.use_parent_material = true
	runtime_renderer.y_sort_enabled = y_sort_enabled
	add_child(runtime_renderer)
	_content = Node2D.new()
	_content.name = "Conteudo"
	_content.use_parent_material = true
	_content.y_sort_enabled = y_sort_enabled
	runtime_renderer.add_child(_content)
	for visual in visuals:
		visual.reparent(_content, false)
	# Normaliza apenas X; o desenho original e suas alturas continuam iguais.
	_content.position.x = -_repeat_bounds.position.x
	runtime_renderer.repeat_size = Vector2(_repeat_bounds.size.x, 0.0)
	_scroll_phase = fposmod(_repeat_bounds.position.x, _repeat_bounds.size.x)
	runtime_renderer.scroll_offset.x = _scroll_phase
	_update_repeat_times()


func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	_editor_refresh += delta
	if _editor_refresh >= 0.3:
		_editor_refresh = 0.0
		update_configuration_warnings()
		queue_redraw()


func advance(distance: float) -> void:
	if not is_instance_valid(runtime_renderer):
		return
	# Uma única fase limitada evita acumular posições enormes e perder precisão.
	_scroll_phase = fposmod(
		_scroll_phase - distance * speed_multiplier,
		_repeat_bounds.size.x
	)
	runtime_renderer.scroll_offset.x = _scroll_phase
	_update_repeat_times()


func get_repeat_bounds() -> Rect2:
	return _measure_layout().bounds if Engine.is_editor_hint() or _content == null else _repeat_bounds


func get_layout_warnings() -> PackedStringArray:
	return _layout_warnings(_measure_layout()) if _content == null else _runtime_warnings.duplicate()


func align_segments() -> void:
	if _content != null:
		return
	var layout := _measure_layout()
	if not layout.issues.is_empty() or layout.entries.is_empty():
		return
	var history: EditorUndoRedoManager
	if Engine.is_editor_hint():
		history = EditorInterface.get_editor_undo_redo()
		history.create_action("Encaixar trechos do cenário", UndoRedo.MERGE_DISABLE, self)
	var cursor: float = layout.entries[0].rect.position.x
	for entry in layout.entries:
		var segment: Node2D = entry.node
		var aligned := segment.position + Vector2(cursor - entry.rect.position.x, 0.0)
		if history != null:
			history.add_do_property(segment, &"position", aligned)
			history.add_undo_property(segment, &"position", segment.position)
		else:
			segment.position = aligned
		cursor += entry.rect.size.x
	if history != null:
		history.commit_action()
	update_configuration_warnings()
	queue_redraw()


func _update_repeat_times() -> void:
	# Também cobre faixas menores que a janela, escalas e zoom da câmera.
	var canvas_transform := get_global_transform_with_canvas()
	if is_zero_approx(canvas_transform.determinant()):
		return
	var view := canvas_transform.affine_inverse() * get_viewport_rect()
	var extent := maxf(absf(view.position.x), absf(view.end.x))
	runtime_renderer.repeat_times = maxi(3, 2 * ceili(extent / _repeat_bounds.size.x) + 1)


func _measure_layout() -> Dictionary:
	var entries: Array[Dictionary] = []
	var issues := PackedStringArray()
	var notices := PackedStringArray()
	var bounds := Rect2()
	var first := true
	for segment in get_children():
		if not segment is Node2D:
			issues.append("%s: use Sprite2D ou um grupo Node2D como trecho." % segment.name)
			continue
		var rectangles: Array[Rect2] = []
		_collect_rects(segment, Transform2D.IDENTITY, true, rectangles, issues, notices)
		if rectangles.is_empty():
			continue
		_check_internal_gaps(segment, rectangles, notices)
		var segment_rect := rectangles[0]
		for rect in rectangles:
			segment_rect = segment_rect.merge(rect)
		entries.append({"node": segment, "rect": segment_rect})
		bounds = segment_rect if first else bounds.merge(segment_rect)
		first = false
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.rect.position.x < b.rect.position.x)
	return {"entries": entries, "bounds": bounds, "issues": issues, "notices": notices}


func _check_internal_gaps(segment: Node, rectangles: Array[Rect2], notices: PackedStringArray) -> void:
	rectangles.sort_custom(func(a: Rect2, b: Rect2) -> bool:
		return a.position.x < b.position.x)
	var covered_end := rectangles[0].end.x
	for rect in rectangles:
		if rect.position.x - covered_end > seam_tolerance:
			notices.append("Lacuna interna de %.2f px no trecho %s; confira seus sprites filhos." % [rect.position.x - covered_end, segment.name])
		covered_end = maxf(covered_end, rect.end.x)


func _collect_rects(node: Node, parent_transform: Transform2D, parent_visible: bool,
		rectangles: Array[Rect2], issues: PackedStringArray, notices: PackedStringArray) -> void:
	# Lista explícita: uma Area2D, corpo, Timer ou script nunca ganha cópias visuais
	# enganosas nem é movido para a faixa nativa junto de objetos decorativos.
	if node.get_class() not in ["Node2D", "Sprite2D", "TextureRect"] or node.get_script() != null:
		issues.append("%s: nó incompatível com repetição visual (%s ou script). Mova gameplay para fora da camada." % [node.name, node.get_class()])
		return
	var item := node as CanvasItem
	if item.is_set_as_top_level():
		issues.append("%s: Top Level ignora a transformação da camada; desative-o." % node.name)
		return
	var transform := parent_transform * item.get_transform()
	var shown := parent_visible and item.visible
	if shown and (node is Sprite2D or node is TextureRect):
		if node.texture == null:
			notices.append("%s: sem textura; não contribui para os limites." % node.name)
		elif not is_zero_approx(transform.x.y) or not is_zero_approx(transform.y.x):
			notices.append("%s: rotação ou inclinação usa limites retangulares; confira áreas transparentes na emenda." % node.name)
	if shown and node is Sprite2D and node.texture != null:
		var rect: Rect2 = transform * node.get_rect()
		if rect.size.x > 0.0:
			rectangles.append(rect)
	elif shown and node is TextureRect and node.texture != null:
		if node.stretch_mode not in [TextureRect.STRETCH_SCALE, TextureRect.STRETCH_TILE]:
			issues.append("%s: TextureRect deve usar Scale ou Tile para medir a área desenhada." % node.name)
		else:
			rectangles.append(transform * Rect2(Vector2.ZERO, node.size))
	for child in node.get_children():
		_collect_rects(child, transform, shown, rectangles, issues, notices)


func _layout_warnings(layout: Dictionary) -> PackedStringArray:
	var messages: PackedStringArray = layout.issues.duplicate()
	messages.append_array(layout.notices)
	var entries: Array = layout.entries
	if entries.is_empty():
		messages.append("A camada precisa de pelo menos um Sprite2D visível com textura.")
		return messages
	var previous: Dictionary = entries[0]
	var covered_end: float = previous.rect.end.x
	for index in range(1, entries.size()):
		var entry: Dictionary = entries[index]
		var gap: float = entry.rect.position.x - covered_end
		if gap > seam_tolerance:
			messages.append("Lacuna de %.2f px antes de %s. Reposicione ou use Encaixar trechos no eixo X." % [gap, entry.node.name])
		elif warn_overlaps and gap < -seam_tolerance:
			messages.append("Sobreposição de %.2f px em %s; confira se é intencional." % [-gap, entry.node.name])
		if warn_vertical_seams and (absf(entry.rect.position.y - previous.rect.position.y) > seam_tolerance or absf(entry.rect.end.y - previous.rect.end.y) > seam_tolerance):
			messages.append("Alturas diferentes entre %s e %s; confira a emenda vertical." % [previous.node.name, entry.node.name])
		covered_end = maxf(covered_end, entry.rect.end.x)
		previous = entry
	return messages


func _get_configuration_warnings() -> PackedStringArray:
	return get_layout_warnings()


func _draw() -> void:
	if not Engine.is_editor_hint() or not show_editor_bounds:
		return
	var layout := _measure_layout()
	if layout.entries.is_empty():
		return
	draw_rect(layout.bounds, Color(0.2, 0.85, 1.0, 0.8), false, 2.0)
	var covered_end: float = layout.entries[0].rect.end.x
	for entry in layout.entries:
		draw_rect(entry.rect, Color(0.2, 0.85, 1.0, 0.35), false, 1.0)
		if entry.rect.position.x - covered_end > seam_tolerance:
			var gap := Rect2(Vector2(covered_end, layout.bounds.position.y),
				Vector2(entry.rect.position.x - covered_end, layout.bounds.size.y))
			draw_rect(gap, Color(1.0, 0.15, 0.1, 0.2))
		covered_end = maxf(covered_end, entry.rect.end.x)
