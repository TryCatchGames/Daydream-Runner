extends Node

const MENU_SCENE_PREFIX := "res://Scenes/Menus/"

var _player: AudioStreamPlayer


func _ready() -> void:
	var music := load("res://Sound Effects/musica_menu.mp3") as AudioStreamMP3
	if music == null:
		push_error("Could not load the menu music.")
		return

	music.loop = true
	_player = AudioStreamPlayer.new()
	_player.stream = music
	add_child(_player)

	get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("_sync_with_current_scene")


func _sync_with_current_scene() -> void:
	_update_playback(get_tree().current_scene)


func _on_scene_changed(scene: Node) -> void:
	_update_playback(scene)


func _update_playback(scene: Node) -> void:
	if scene == null or _player == null:
		return

	if scene.scene_file_path.begins_with(MENU_SCENE_PREFIX):
		if not _player.playing:
			_player.play()
	elif _player.playing:
		_player.stop()
