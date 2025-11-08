extends Line2D
class_name BoatWakeTrail

@export var max_points: int = 50
@export var min_distance: float = 5.0  # Minimum distance before adding new point
@export var boat: CharacterBody2D
@export var wake_marker: Marker2D  # Position on boat where wake starts
@export var smallest_tip_width: float = 2.0
@export var largest_tip_width: float = 30.0
@export var distance_at_largest_width: float = 96.0
@export var speed_threshold: float = 20.0  # Minimum speed to create wake

var point_queue: Array[Vector2] = []
var total_length: float = 0.0
var last_point: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Set up the line properties
	width = 20.0
	default_color = Color(1.0, 1.0, 1.0, 0.9)  # Bright white
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND
	antialiased = true
	
	# Create width curve for tapering
	width_curve = Curve.new()
	width_curve.add_point(Vector2(0, 1.0))  # Tip (at boat)
	width_curve.add_point(Vector2(0.3, 0.8))  # Middle
	width_curve.add_point(Vector2(1, 0.2))  # End (fades out)
	
	# Set render order - render on top to debug
	z_index = 100
	z_as_relative = false
	
	# Create a gradient texture programmatically
	create_gradient_texture()
	
	if not boat:
		push_error("BoatWakeTrail: No boat assigned!")
		return
	
	if not wake_marker:
		push_error("BoatWakeTrail: No wake_marker assigned!")
		return
	
	last_point = wake_marker.global_position

func create_gradient_texture() -> void:
	# Create a gradient that fades the wake
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 1.0, 1.0, 1.0))  # Solid white at start
	gradient.add_point(0.5, Color(0.9, 0.95, 1.0, 0.6))  # Middle fade
	gradient.add_point(1.0, Color(0.8, 0.9, 1.0, 0.0))  # Transparent at end
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0, 0.5)
	gradient_texture.fill_to = Vector2(1, 0.5)
	gradient_texture.width = 256
	gradient_texture.height = 32
	
	texture = gradient_texture
	texture_mode = Line2D.LINE_TEXTURE_STRETCH

func _process(_delta: float) -> void:
	if not boat or not wake_marker:
		return
	
	# Check if boat is moving fast enough
	var boat_speed = 0.0
	if boat.has_method("get_current_speed"):
		boat_speed = boat.get_current_speed()
	
	if boat_speed < speed_threshold:
		# Fade out wake when stationary
		_fade_wake()
		return
	
	var current_pos = wake_marker.global_position
	
	# Only add point if we've moved enough distance
	if last_point.distance_to(current_pos) >= min_distance:
		point_queue.push_back(current_pos)
		last_point = current_pos
		
		# Remove old points
		if point_queue.size() > max_points:
			point_queue.pop_front()
	
	# Update the line
	_update_line()

func _update_line() -> void:
	clear_points()
	
	if point_queue.size() < 2:
		return
	
	# Calculate total length
	total_length = 0.0
	for i in range(point_queue.size() - 1):
		total_length += point_queue[i].distance_to(point_queue[i + 1])
	
	# Add all points in local coordinates
	for i in range(point_queue.size()):
		var local_pos = to_local(point_queue[i])
		add_point(local_pos)
	
	# Update width based on total length
	var width_value = lerp(smallest_tip_width, largest_tip_width, 
		clamp(total_length / distance_at_largest_width, 0.0, 1.0))
	
	if width_curve:
		width_curve.set_point_value(0, width_value / largest_tip_width)

func _fade_wake() -> void:
	# Gradually remove points when boat stops
	if point_queue.size() > 0:
		point_queue.pop_front()
		_update_line()

func reset_wake() -> void:
	point_queue.clear()
	clear_points()
	if wake_marker:
		last_point = wake_marker.global_position
