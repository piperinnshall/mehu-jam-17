extends Camera2D

# Camera settings
@export var min_zoom: float = 0.3
@export var max_zoom: float = 1.5
@export var zoom_smoothing: float = 5.0
@export var position_smoothing: float = 8.0
@export var margin: float = 200.0  # Extra space around boats

# Target nodes
@export var player1_path: NodePath
@export var player2_path: NodePath

var player1: Node2D
var player2: Node2D

func _ready() -> void:
	# Get references to both players
	if player1_path:
		player1 = get_node(player1_path)
	if player2_path:
		player2 = get_node(player2_path)
	
	# Enable camera smoothing
	position_smoothing_enabled = true
	position_smoothing_speed = position_smoothing

func _process(delta: float) -> void:
	if not player1 or not player2:
		return
	
	# Calculate midpoint between both players
	var midpoint = (player1.global_position + player2.global_position) / 2.0
	
	# Smoothly move camera to midpoint
	global_position = global_position.lerp(midpoint, position_smoothing * delta)
	
	# Calculate distance between players
	var distance = player1.global_position.distance_to(player2.global_position)
	
	# Get viewport size
	var viewport_size = get_viewport_rect().size
	var screen_diagonal = viewport_size.length()
	
	# Calculate required zoom to fit both boats
	# Add margin so boats aren't at screen edges
	var required_distance = distance + margin * 2
	var target_zoom_value = screen_diagonal / (required_distance * 2.0)
	
	# Clamp zoom to min/max values
	target_zoom_value = clamp(target_zoom_value, min_zoom, max_zoom)
	
	# Smoothly interpolate zoom
	var current_zoom_value = zoom.x
	var new_zoom_value = lerp(current_zoom_value, target_zoom_value, zoom_smoothing * delta)
	
	zoom = Vector2(new_zoom_value, new_zoom_value)
