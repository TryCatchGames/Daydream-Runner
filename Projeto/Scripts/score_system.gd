class_name ScoreSystem
extends Node
## Estado local da fase. O HUD pode ser substituído sem alterar as fontes.

signal score_changed(total: int, maximum: int)
signal points_awarded(source_id: StringName, amount: int, total: int)

@export_range(0, 99999, 1, "or_greater") var max_score: int = 99999:
	set(value):
		max_score = maxi(value, 0)
		_score = mini(_score, max_score)
		score_changed.emit(_score, max_score)
@export var sources: Array[ScoreSource] = []

var _score: int = 0
var _enabled_overrides: Dictionary = {}


func _enter_tree() -> void:
	add_to_group("score_system")


## Retorna o ganho efetivo (inclusive quando o teto limita o ganho).
## Fontes ausentes/desativadas e valores negativos não concedem pontos.
func award(source_id: StringName, amount_override: int = -1) -> int:
	for source in sources:
		if source == null or source.id != source_id:
			continue
		if not bool(_enabled_overrides.get(source_id, source.enabled)):
			return 0
		var amount := source.points if amount_override == -1 else amount_override
		if source_id == &"enemy_defeated":
			var player := get_tree().get_first_node_in_group("player")
			var effects := player.get_node_or_null("PowerUps") as PlayerPowerUps if player != null else null
			if effects != null and effects.double_points_remaining > 0.0:
				amount *= 2
		var gained := mini(maxi(amount, 0), max_score - _score)
		if gained > 0:
			_score += gained
			score_changed.emit(_score, max_score)
			points_awarded.emit(source_id, gained, _score)
		return gained
	return 0


func set_source_enabled(source_id: StringName, enabled: bool) -> void:
	# Não modifica Resources compartilhados com outra instância da fase.
	_enabled_overrides[source_id] = enabled


func get_score() -> int:
	return _score


func export_score() -> Dictionary:
	# Snapshot independente, pronto para JSON.stringify ou uma tela de resultados.
	return {"score": _score, "max_score": max_score}


func reset() -> void:
	_score = 0
	score_changed.emit(_score, max_score)
