class_name ScoreSource
extends Resource
## Uma regra de ganho, editável no Inspector do sistema de score.

@export var id: StringName = &""
@export var enabled: bool = true
@export_range(0, 99999, 1, "or_greater") var points: int = 100
