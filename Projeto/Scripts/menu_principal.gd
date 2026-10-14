
extends Control

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/mundo_teste.tscn")


func _on_options_button_pressed() -> void:
	print("Abrir opções")


func _on_exit_button_pressed() -> void:
	get_tree().quit()
