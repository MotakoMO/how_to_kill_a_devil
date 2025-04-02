extends Control

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_start_game_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu/loading_screen.tscn")

func _on_fuck_you_pressed() -> void:
	pass

func _on_exit_pressed() -> void:
	get_tree().quit()
