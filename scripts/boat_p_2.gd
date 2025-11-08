extends CharacterBody2D

class_name Player2Boat

# Movement parameters
@export var max_speed: float = 200.0
@export var min_base_speed: float = 25.0
@export var acceleration: float = 100.0
@export var deceleration: float = 50.0
@export var drift_factor: float = 0.95

# Turning parameters
@export var turn_speed: float = 2.0
@export var min_turn_speed: float = 0.5
@export var turn_speed_curve: float = 2.0

# Advanced physics
@export var water_resistance: float = 0.98
@export var min_speed_threshold: float = 10.0

# Wind physics
@export var wind_boost_strength: float = 200.0  # Max speed bonus from wind
@export var wind_resistance_strength: float = 20.0  # Speed penalty against wind
@export var wind_angle_threshold: float = 70.0  # Degrees for wind effect

# Sprite parameters
@export var total_sprite_frames: int = 360
@export var sprite_rotation_offset: float = 0.0
@export var invert_sprite_rotation: bool = false

# Internal variables - P2 specific
var p2_current_speed: float = 0.0
var p2_target_rotation: float = 0.0
var p2_momentum_velocity: Vector2 = Vector2.ZERO
var p2_boat_visual_rotation: float = 0.0

# Wind reference
var wind_manager: Node = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	p2_boat_visual_rotation = 0.0
	p2_target_rotation = 0.0
	
	if animated_sprite:
		animated_sprite.stop()
	
	# Find wind manager
	call_deferred("_find_wind_manager")

func _find_wind_manager() -> void:
	# Try to find WindManager in the scene
	var root = get_tree().root
	wind_manager = _find_node_by_class_name(root, "WindManager")

func _find_node_by_class_name(node: Node, target_class: String) -> Node:
	# Check if this node has the class name
	if node.get_script():
		var script = node.get_script()
		if script.has_method("get_global_name"):
			if script.get_global_name() == target_class:
				return node
	
	# Check children recursively
	for child in node.get_children():
		var result = _find_node_by_class_name(child, target_class)
		if result:
			return result
	
	return null

func _physics_process(delta: float) -> void:
	# Get P2 input
	var input_dir := Input.get_axis("P2left", "P2right")
	var throttle := Input.get_action_strength("P2up")
	
	# Calculate wind effect on speed
	var wind_speed_modifier = _calculate_wind_effect()
	
	# P2 acceleration with wind modifier
	if throttle > 0.0:
		p2_current_speed += acceleration * delta
		p2_current_speed = min(p2_current_speed, max_speed + wind_speed_modifier)
	else:
		p2_current_speed -= deceleration * delta
		p2_current_speed = max(p2_current_speed, min_base_speed)
	
	# Apply wind modifier to current speed
	var effective_speed = p2_current_speed + wind_speed_modifier
	effective_speed = max(effective_speed, 0.0)  # Don't go backwards
	
	# P2 turning
	if abs(input_dir) > 0.0 and effective_speed > min_speed_threshold:
		p2_boat_visual_rotation += input_dir * turn_speed * delta
		p2_target_rotation = p2_boat_visual_rotation
	
	# P2 movement
	var forward_direction = Vector2.RIGHT.rotated(p2_boat_visual_rotation)
	velocity = forward_direction * effective_speed
	
	move_and_slide()
	update_sprite_frame()
	
	# P2 collision
	if get_slide_collision_count() > 0:
		p2_current_speed *= 0.5

func _calculate_wind_effect() -> float:
	if not wind_manager:
		return 0.0
	
	# Get wind direction
	var wind_dir = wind_manager.get_wind_direction()
	var wind_strength = wind_manager.get_wind_strength()
	
	# Calculate angle difference between boat and wind
	var angle_diff = wind_dir - p2_boat_visual_rotation
	
	# Normalize angle to -PI to PI
	while angle_diff > PI:
		angle_diff -= TAU
	while angle_diff < -PI:
		angle_diff += TAU
	
	# Convert to degrees for easier understanding
	var angle_diff_degrees = abs(rad_to_deg(angle_diff))
	
	# Calculate alignment (-1 = opposite, 0 = perpendicular, 1 = same direction)
	var _alignment = cos(angle_diff)
	
	# Only apply wind effect if within threshold angle
	var _threshold_radians = deg_to_rad(wind_angle_threshold)
	
	if angle_diff_degrees <= wind_angle_threshold:
		# Going WITH the wind - speed boost
		var boost_factor = 1.0 - (angle_diff_degrees / wind_angle_threshold)
		return (wind_strength / 100.0) * wind_boost_strength * boost_factor
	elif angle_diff_degrees >= (180.0 - wind_angle_threshold):
		# Going AGAINST the wind - speed penalty
		var resistance_factor = 1.0 - ((180.0 - angle_diff_degrees) / wind_angle_threshold)
		return -(wind_strength / 100.0) * wind_resistance_strength * resistance_factor
	else:
		# Perpendicular to wind - minimal effect
		return 0.0

func update_sprite_frame() -> void:
	if not animated_sprite:
		return
	
	var degrees = rad_to_deg(p2_boat_visual_rotation)
	
	if invert_sprite_rotation:
		degrees = -degrees
	
	degrees = fmod(degrees + sprite_rotation_offset, 360.0)
	if degrees < 0:
		degrees += 360.0
	
	var frame_index = int(round(degrees)) % total_sprite_frames
	frame_index = clampi(frame_index, 0, total_sprite_frames - 1)
	
	animated_sprite.frame = frame_index

func get_current_speed() -> float:
	return p2_current_speed

func get_speed_percentage() -> float:
	return (p2_current_speed / max_speed) * 100.0

func apply_external_force(force: Vector2) -> void:
	p2_momentum_velocity += force

func _draw() -> void:
	if Engine.is_editor_hint() or OS.is_debug_build():
		draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(p2_boat_visual_rotation) * 50, Color.GREEN, 2.0)
		draw_line(Vector2.ZERO, velocity.normalized() * 50, Color.BLUE, 2.0)
