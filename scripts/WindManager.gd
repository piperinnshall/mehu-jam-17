extends Node2D

class_name WindManager

# Wind parameters
@export var min_wind_strength: float = 0.0
@export var max_wind_strength: float = 100.0
@export var wind_change_speed: float = 0.4  # How fast wind changes
@export var direction_change_speed: float = 0.3  # How fast direction changes

# Visual settings
@export var draw_wind_lines: bool = true
@export var base_line_length: float = 40.0
@export var max_line_length: float = 120.0
@export var line_thickness: float = 2.0
@export var line_color: Color = Color(1, 1, 1, 0.7)
@export var lines_spawn_rate: float = 0.1  # Time between spawning new lines
@export var line_lifetime: float = 3.0  # How long lines last
@export var line_speed_multiplier: float = 1.5  # How fast lines move with wind

# Current wind state (PUBLIC - easy to access)
var wind_strength: float = 50.0  # 0 to 100
var wind_direction: float = 0.0  # In radians
var wind_velocity: Vector2 = Vector2.ZERO  # Combined vector

# Internal targets for smooth transitions
var _target_strength: float = 50.0
var _target_direction: float = 0.0
var _time_until_next_change: float = 0.0
var _change_interval: float = 3.0  # How often to pick new targets

# Wind lines system
var _wind_lines: Array[Dictionary] = []
var _time_since_last_spawn: float = 0.0
var _camera: Camera2D

func _ready() -> void:
	_pick_new_wind_target()
	# Find the camera in the scene
	_find_camera()

func _find_camera() -> void:
	# Try to find camera in parent or root
	var root = get_tree().root
	_camera = _find_camera_recursive(root)
	
func _find_camera_recursive(node: Node) -> Camera2D:
	if node is Camera2D:
		return node as Camera2D
	for child in node.get_children():
		var result = _find_camera_recursive(child)
		if result:
			return result
	return null

func _process(delta: float) -> void:
	_update_wind(delta)
	_update_wind_velocity()
	_update_wind_lines(delta)
	_spawn_wind_lines(delta)
	
	if draw_wind_lines:
		queue_redraw()

func _update_wind(delta: float) -> void:
	# Smoothly interpolate to target values
	wind_strength = lerp(wind_strength, _target_strength, wind_change_speed * delta)
	wind_direction = lerp_angle(wind_direction, _target_direction, direction_change_speed * delta)
	
	# Countdown to next random change
	_time_until_next_change -= delta
	if _time_until_next_change <= 0.0:
		_pick_new_wind_target()

func _pick_new_wind_target() -> void:
	# Pick new random targets
	_target_strength = randf_range(min_wind_strength, max_wind_strength)
	_target_direction = randf_range(0.0, TAU)
	_time_until_next_change = randf_range(_change_interval * 0.5, _change_interval * 1.5)

func _update_wind_velocity() -> void:
	# Convert polar to cartesian coordinates
	var direction_vector = Vector2.RIGHT.rotated(wind_direction)
	wind_velocity = direction_vector * wind_strength

func _spawn_wind_lines(delta: float) -> void:
	if not _camera:
		return
		
	var strength_normalized = wind_strength / max_wind_strength
	
	# Spawn more lines when wind is stronger
	var adjusted_spawn_rate = lines_spawn_rate / max(strength_normalized, 0.2)
	
	_time_since_last_spawn += delta
	
	if _time_since_last_spawn >= adjusted_spawn_rate:
		_time_since_last_spawn = 0.0
		
		# Spawn lines randomly within the camera view
		var spawn_pos = _get_random_position_in_camera()
		
		_wind_lines.append({
			"position": spawn_pos,
			"lifetime": 0.0,
			"wave_offset": randf_range(0, TAU),
			"speed_variation": randf_range(0.8, 1.2)
		})

func _get_random_position_in_camera() -> Vector2:
	if not _camera:
		return Vector2.ZERO
	
	# Get camera bounds
	var viewport_size = get_viewport_rect().size
	var camera_pos = _camera.global_position
	var zoom_level = _camera.zoom.x
	
	# Calculate visible area in world coordinates
	var visible_size = viewport_size / zoom_level
	var half_size = visible_size / 2.0
	
	# Random position within camera view
	var random_offset = Vector2(
		randf_range(-half_size.x, half_size.x),
		randf_range(-half_size.y, half_size.y)
	)
	
	return camera_pos + random_offset

func _update_wind_lines(delta: float) -> void:
	if not _camera:
		return
		
	var direction_vector = Vector2.RIGHT.rotated(wind_direction)
	
	# Get camera bounds for culling
	var viewport_size = get_viewport_rect().size
	var camera_pos = _camera.global_position
	var zoom_level = _camera.zoom.x
	var visible_size = viewport_size / zoom_level
	var half_size = visible_size / 2.0
	
	var camera_rect = Rect2(
		camera_pos - half_size,
		visible_size
	)
	
	var margin = 200.0
	var culling_rect = camera_rect.grow(margin)
	
	# Update and remove old lines
	for i in range(_wind_lines.size() - 1, -1, -1):
		var line = _wind_lines[i]
		
		# Age the line
		line.lifetime += delta
		
		# Move line with wind
		var move_speed = wind_strength * line_speed_multiplier * line.speed_variation
		line.position += direction_vector * move_speed * delta
		
		# Remove if too old or outside camera view
		if line.lifetime > line_lifetime or not culling_rect.has_point(line.position):
			_wind_lines.remove_at(i)

func _draw() -> void:
	if not draw_wind_lines:
		return
	
	var strength_normalized = wind_strength / max_wind_strength
	var direction_vector = Vector2.RIGHT.rotated(wind_direction)
	
	# Calculate line length based on wind strength
	var line_length = lerp(base_line_length, max_line_length, strength_normalized)
	
	# Draw each wind line
	for line_data in _wind_lines:
		var start_pos = line_data.position
		var lifetime_normalized = line_data.lifetime / line_lifetime
		
		# Fade in and out
		var alpha = 1.0
		if lifetime_normalized < 0.2:
			alpha = lifetime_normalized / 0.2  # Fade in
		elif lifetime_normalized > 0.8:
			alpha = 1.0 - (lifetime_normalized - 0.8) / 0.2  # Fade out
		
		alpha *= lerp(0.3, 0.8, strength_normalized)
		var draw_color = Color(line_color.r, line_color.g, line_color.b, alpha * line_color.a)
		
		# Add wave motion to the line
		var wave_offset = sin(Time.get_ticks_msec() / 1000.0 + line_data.wave_offset) * 8.0
		var perpendicular = direction_vector.orthogonal() * wave_offset
		
		# Draw a curved line using multiple segments
		var segments = 5
		for seg in segments:
			var t1 = float(seg) / segments
			var t2 = float(seg + 1) / segments
			
			var curve1 = sin(t1 * PI) * 0.5
			var curve2 = sin(t2 * PI) * 0.5
			
			var p1 = start_pos + direction_vector * (line_length * t1) + perpendicular * curve1
			var p2 = start_pos + direction_vector * (line_length * t2) + perpendicular * curve2
			
			draw_line(p1, p2, draw_color, line_thickness)

# PUBLIC HELPER FUNCTIONS for ships to use

# Get wind force that should be applied to an object moving in a direction
func get_wind_force_for_direction(object_direction: float) -> float:
	# Calculate how aligned the object is with wind (-1 to 1)
	var direction_diff = wind_direction - object_direction
	var alignment = cos(direction_diff)
	
	# Return force (positive = boost, negative = resistance)
	return alignment * wind_strength

# Get wind velocity as Vector2
func get_wind_velocity() -> Vector2:
	return wind_velocity

# Get wind direction in radians
func get_wind_direction() -> float:
	return wind_direction

# Get wind strength (0-100)
func get_wind_strength() -> float:
	return wind_strength

# Get wind as normalized direction vector
func get_wind_direction_vector() -> Vector2:
	return Vector2.RIGHT.rotated(wind_direction)

# Check if moving with the wind (returns 0.0 to 1.0)
func get_wind_alignment(object_direction: float) -> float:
	var direction_diff = wind_direction - object_direction
	var alignment = cos(direction_diff)
	return (alignment + 1.0) / 2.0  # Convert from -1,1 to 0,1
