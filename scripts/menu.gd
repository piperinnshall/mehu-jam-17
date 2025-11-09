extends Control

@onready var tutorial_popup: Panel = $TutorialPopup

func _ready() -> void:
	# Connect button signals using $ shorthand
	$CenterContainer/VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$CenterContainer/VBoxContainer/TutorialButton.pressed.connect(_on_tutorial_pressed)
	$CenterContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	
	# Connect close button on popup
	$TutorialPopup/MarginContainer/VBoxContainer/CloseButton.pressed.connect(_on_close_tutorial_pressed)
	
	# Hide tutorial popup initially
	if tutorial_popup:
		tutorial_popup.visible = false

func _on_play_pressed() -> void:
	# Load the main game scene
	get_tree().change_scene_to_file("res://main.tscn")

func _on_tutorial_pressed() -> void:
	# Show the tutorial popup
	if tutorial_popup:
		tutorial_popup.visible = true

func _on_close_tutorial_pressed() -> void:
	# Hide the tutorial popup
	if tutorial_popup:
		tutorial_popup.visible = false

func _on_quit_pressed() -> void:
	# Quit the game
	get_tree().quit()
