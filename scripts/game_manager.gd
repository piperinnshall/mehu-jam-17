extends Node2D

class_name GameManager

# References to players
@export var player1_path: NodePath
@export var player2_path: NodePath
@export var camera_path: NodePath

var player1: Node2D
var player2: Node2D
var camera: Camera2D

# Health tracking
var player1_health: int = 3
var player2_health: int = 3

# Screen shake parameters
@export var shake_intensity: float = 15.0
@export var shake_duration: float = 0.4

var is_shaking: bool = false
var shake_timer: float = 0.0
var original_camera_offset: Vector2 = Vector2.ZERO

# UI elements
var ui_layer: CanvasLayer
var p1_health_label: Label
var p2_health_label: Label
var victory_label: Label

# Game state
var game_over: bool = false
var victory_timer: float = 0.0
var victory_duration: float = 4.0

func _ready() -> void:
	# Get player references
	if player1_path:
		player1 = get_node(player1_path)
	if player2_path:
		player2 = get_node(player2_path)
	if camera_path:
		camera = get_node(camera_path)
	
	# Setup UI
	_setup_ui()

func _setup_ui() -> void:
	# Create UI layer - set to layer 0 so pixelator affects it
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 0  # Changed from 100 to 0 so pixelator works
	add_child(ui_layer)
	
	# Player 1 health label (top-left)
	p1_health_label = Label.new()
	p1_health_label.position = Vector2(20, 20)
	p1_health_label.add_theme_font_size_override("font_size", 36)
	p1_health_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1))
	p1_health_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.3, 0.5, 1))
	p1_health_label.add_theme_color_override("font_outline_color", Color(0.1, 0.3, 0.5, 1))
	p1_health_label.add_theme_constant_override("shadow_offset_x", 2)
	p1_health_label.add_theme_constant_override("shadow_offset_y", 2)
	p1_health_label.add_theme_constant_override("outline_size", 5)
	p1_health_label.text = "P1 HEALTH: 3"
	ui_layer.add_child(p1_health_label)
	
	# Player 2 health label (top-right)
	p2_health_label = Label.new()
	p2_health_label.position = Vector2(get_viewport().get_visible_rect().size.x - 300, 20)
	p2_health_label.add_theme_font_size_override("font_size", 36)
	p2_health_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1))
	p2_health_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.3, 0.5, 1))
	p2_health_label.add_theme_color_override("font_outline_color", Color(0.1, 0.3, 0.5, 1))
	p2_health_label.add_theme_constant_override("shadow_offset_x", 2)
	p2_health_label.add_theme_constant_override("shadow_offset_y", 2)
	p2_health_label.add_theme_constant_override("outline_size", 5)
	p2_health_label.text = "P2 HEALTH: 3"
	ui_layer.add_child(p2_health_label)
	
	# Victory label (centered, hidden initially)
	victory_label = Label.new()
	victory_label.add_theme_font_size_override("font_size", 72)
	victory_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1))
	victory_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.3, 0.5, 1))
	victory_label.add_theme_color_override("font_outline_color", Color(0.1, 0.3, 0.5, 1))
	victory_label.add_theme_constant_override("shadow_offset_x", 3)
	victory_label.add_theme_constant_override("shadow_offset_y", 3)
	victory_label.add_theme_constant_override("outline_size", 8)
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory_label.visible = false
	victory_label.modulate = Color(1, 1, 1, 0)  # Start transparent
	ui_layer.add_child(victory_label)

func _process(delta: float) -> void:
	# Handle victory countdown
	if game_over and victory_timer > 0.0:
		victory_timer -= delta
		if victory_timer <= 0.0:
			_return_to_menu()
		return
	
	if game_over:
		return
	
	# Update health UI positions to follow viewport
	var viewport_size = get_viewport().get_visible_rect().size
	p2_health_label.position.x = viewport_size.x - 300
	
	# Update victory label position if visible
	if victory_label.visible:
		var label_size = victory_label.size
		if label_size.x > 0 and label_size.y > 0:
			victory_label.position = Vector2(
				(viewport_size.x - label_size.x) / 2,
				(viewport_size.y - label_size.y) / 2
			)
	
	# Handle screen shake
	if is_shaking:
		shake_timer -= delta
		if shake_timer <= 0:
			is_shaking = false
			if camera:
				camera.offset = original_camera_offset
		else:
			if camera:
				var shake_offset = Vector2(
					randf_range(-shake_intensity, shake_intensity),
					randf_range(-shake_intensity, shake_intensity)
				)
				camera.offset = original_camera_offset + shake_offset

func player_hit(player_number: int) -> void:
	if game_over:
		return
	
	print("Player %d hit! Game Manager received hit." % player_number)
	
	# Apply damage
	if player_number == 1:
		player1_health -= 1
		print("P1 Health now: %d" % player1_health)
		_update_health_display()
		_start_screen_shake()
		
		if player1_health <= 0:
			print("P1 defeated!")
			_player_defeated(1)
		
	elif player_number == 2:
		player2_health -= 1
		print("P2 Health now: %d" % player2_health)
		_update_health_display()
		_start_screen_shake()
		
		if player2_health <= 0:
			print("P2 defeated!")
			_player_defeated(2)

func _update_health_display() -> void:
	p1_health_label.text = "P1 HEALTH: %d" % player1_health
	p2_health_label.text = "P2 HEALTH: %d" % player2_health

func _start_screen_shake() -> void:
	if not camera:
		print("No camera found for shake!")
		return
	
	print("Starting screen shake")
	is_shaking = true
	shake_timer = shake_duration
	original_camera_offset = camera.offset

func _player_defeated(player_number: int) -> void:
	game_over = true
	victory_timer = victory_duration
	
	# Trigger explosion on the defeated player
	if player_number == 1 and player1:
		if player1.has_method("_trigger_explosion"):
			player1._trigger_explosion()
	elif player_number == 2 and player2:
		if player2.has_method("_trigger_explosion"):
			player2._trigger_explosion()
	
	# Show victory message
	var winner = 2 if player_number == 1 else 1
	_show_victory_message(winner)

func _show_victory_message(winner: int) -> void:
	victory_label.text = "PLAYER %d WINS!" % winner
	victory_label.visible = true
	
	# Force size recalculation
	victory_label.reset_size()
	
	# Center the label
	var viewport_size = get_viewport().get_visible_rect().size
	var label_size = victory_label.size
	if label_size.x > 0 and label_size.y > 0:
		victory_label.position = Vector2(
			(viewport_size.x - label_size.x) / 2,
			(viewport_size.y - label_size.y) / 2
		)
		victory_label.pivot_offset = label_size / 2
	
	# Create tween for victory text
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in
	tween.tween_property(victory_label, "modulate:a", 1.0, 0.5)
	
	# Scale animation
	victory_label.scale = Vector2(0.5, 0.5)
	tween.tween_property(victory_label, "scale", Vector2(1.2, 1.2), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _return_to_menu() -> void:
	print("Returning to menu...")
	
	set_process(false)
	set_physics_process(false)
	
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
