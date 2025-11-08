extends Control

func _ready() -> void:
	# Connect button signals using $ shorthand
	$CenterContainer/VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$CenterContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	# Load the main game scene
	get_tree().change_scene_to_file("res://main.tscn")

func _on_quit_pressed() -> void:
	# Quit the game
	get_tree().quit()
