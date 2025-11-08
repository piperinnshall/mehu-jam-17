extends CharacterBody2D

class_name Player2Boat

# Movement parameters
@export var max_speed: float = 150.0
@export var min_base_speed: float = 25.0
@export var acceleration: float = 50.0
@export var deceleration: float = 40.0
@export var drift_factor: float = 0.95

# Turning parameters
@export var turn_speed: float = 2.0
@export var min_turn_speed: float = 0.5
@export var turn_speed_curve: float = 2.0

# Advanced physics
@export var water_resistance: float = 0.98
@export var min_speed_threshold: float = 10.0

# Wind physics
@export var wind_boost_strength: float = 120.0
@export var wind_resistance_strength: float = 20.0
@export var wind_angle_threshold: float = 70.0

# Sprite parameters
@export var total_sprite_frames: int = 360
@export var sprite_rotation_offset: float = 0.0
@export var invert_sprite_rotation: bool = false

# Cannon parameters
@export var cannon_cooldown: float = 2.0
@export var cannon_ball_speed: float = 400.0
@export var cannon_offset: float = 30.0
var cannon_ball_scene: PackedScene = preload("res://scenes/cannon_ball.tscn")
var cannon_fire_scene: PackedScene = preload("res://scenes/cannon_fire.tscn")

# Wake parameters
@export var wake_spawn_rate: float = 0.03  # Time between wake particles
@export var wake_speed_threshold: float = 20.0  # Minimum speed to create wake
@export var wake_spread_angle: float = 95.0  # Angle of V wake in degrees
@export var wake_lateral_speed: float = 90.0  # Speed particles move outward
var wake_particle_scene: PackedScene = preload("res://scenes/wake_particle.tscn")
var wake_timer: float = 0.0
var wake_container: Node2D = null

# Internal variables - P2 specific
var p2_current_speed: float = 0.0
var p2_target_rotation: float = 0.0
var p2_momentum_velocity: Vector2 = Vector2.ZERO
var p2_boat_visual_rotation: float = 0.0
var cannon_cooldown_timer: float = 0.0
var player1_boat: Node = null

# Wind reference
var wind_manager: Node = null

# Map reference for water detection
var map_generator: Node = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var wake_marker: Marker2D = $WakeMarker

func _ready() -> void:
	p2_boat_visual_rotation = 0.0
	p2_target_rotation = 0.0
	
	if animated_sprite:
		animated_sprite.stop()
	
	# Create wake container that renders below the boat
	wake_container = Node2D.new()
	wake_container.name = "WakeContainer"
	wake_container.z_index = -1  # Render behind boat
	call_deferred("_add_wake_container")
	
	call_deferred("_find_wind_manager")
	call_deferred("_find_player1")
	call_deferred("_find_map_generator")

func _add_wake_container() -> void:
	get_parent().add_child(wake_container)

func _find_wind_manager() -> void:
	var root = get_tree().root
	wind_manager = _find_node_by_class_name(root, "WindManager")

func _find_player1() -> void:
	var root = get_tree().root
	player1_boat = _find_node_by_class_name(root, "Player1Boat")

func _find_map_generator() -> void:
	var root = get_tree().root
	map_generator = _find_node_by_name(root, "MapGenerator")

func _find_node_by_class_name(node: Node, target_class: String) -> Node:
	if node.get_script():
		var script = node.get_script()
		if script.has_method("get_global_name"):
			if script.get_global_name() == target_class:
				return node
	
	for child in node.get_children():
		var result = _find_node_by_class_name(child, target_class)
		if result:
			return result
	
	return null

func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_by_name(child, target_name)
		if result:
			return result
	
	return null

func _is_on_water() -> bool:
	if not map_generator:
		return true  # Default to true if map not found
	
	return true  # For now, assume always on water

func _physics_process(delta: float) -> void:
	# Update cannon cooldown
	if cannon_cooldown_timer > 0.0:
		cannon_cooldown_timer -= delta
	
	# Get P2 input
	var input_dir := Input.get_axis("P2left", "P2right")
	var throttle := Input.get_action_strength("P2up")
	var fire := Input.is_action_just_pressed("P2down")
	
	# Fire cannon
	if fire and cannon_cooldown_timer <= 0.0:
		_fire_cannon()
		cannon_cooldown_timer = cannon_cooldown
	
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
	effective_speed = max(effective_speed, 0.0)
	
	# P2 turning
	if abs(input_dir) > 0.0 and effective_speed > min_speed_threshold:
		p2_boat_visual_rotation += input_dir * turn_speed * delta
		p2_target_rotation = p2_boat_visual_rotation
	
	# P2 movement
	var forward_direction = Vector2.RIGHT.rotated(p2_boat_visual_rotation)
	velocity = forward_direction * effective_speed
	
	move_and_slide()
	update_sprite_frame()
	
	# Update wake system
	_update_wake(delta, effective_speed)
	
	# P2 collision
	if get_slide_collision_count() > 0:
		p2_current_speed *= 0.5

func _update_wake(delta: float, effective_speed: float) -> void:
	# Only spawn wake if on water and moving fast enough
	if not _is_on_water() or effective_speed < wake_speed_threshold:
		return
	
	wake_timer -= delta
	
	if wake_timer <= 0.0:
		wake_timer = wake_spawn_rate
		_spawn_wake_particles()

func _spawn_wake_particles() -> void:
	if not wake_marker:
		return
	
	# Get the boat's forward direction
	var forward = Vector2.RIGHT.rotated(p2_boat_visual_rotation)
	var backward = -forward
	
	# Calculate perpendicular direction (right side of boat)
	var right = forward.rotated(PI / 2.0)
	
	# Convert wake spread angle to radians
	var spread_rad = deg_to_rad(wake_spread_angle)
	
	# Spawn left wake particle (angled to the left)
	var left_direction = backward.rotated(-spread_rad)
	_create_wake_particle(wake_marker.global_position, left_direction)
	
	# Spawn right wake particle (angled to the right)
	var right_direction = backward.rotated(spread_rad)
	_create_wake_particle(wake_marker.global_position, right_direction)

func _create_wake_particle(pos: Vector2, direction: Vector2) -> void:
	if not wake_particle_scene or not wake_container:
		return
	
	var wake = wake_particle_scene.instantiate()
	wake_container.add_child(wake)
	wake.global_position = pos
	
	# Set velocity in the specified direction
	if "velocity" in wake:
		wake.velocity = direction.normalized() * wake_lateral_speed

func _fire_cannon() -> void:
	if not player1_boat:
		_find_player1()
	
	if not player1_boat:
		return
	
	# Calculate which side P1 is on relative to P2
	var to_p1 = player1_boat.global_position - global_position
	var forward = Vector2.RIGHT.rotated(p2_boat_visual_rotation)
	var right = forward.rotated(PI / 2.0)
	
	# Determine which side to fire from
	var dot_product = to_p1.dot(right)
	var fire_direction: Vector2
	var spawn_offset: Vector2
	var fire_rotation: float
	
	if dot_product > 0:
		# P1 is on the right side
		fire_direction = right
		spawn_offset = right * cannon_offset
		fire_rotation = p2_boat_visual_rotation + PI / 2.0
	else:
		# P1 is on the left side
		fire_direction = -right
		spawn_offset = -right * cannon_offset
		fire_rotation = p2_boat_visual_rotation - PI / 2.0
	
	# Spawn cannon ball
	var cannon_ball = cannon_ball_scene.instantiate()
	get_parent().add_child(cannon_ball)
	cannon_ball.global_position = global_position + spawn_offset
	
	# Set cannon ball velocity
	var cannon_velocity = fire_direction * cannon_ball_speed
	cannon_ball.initialize(cannon_velocity)
	
	# Spawn cannon fire animation
	var cannon_fire = cannon_fire_scene.instantiate()
	get_parent().add_child(cannon_fire)
	cannon_fire.global_position = global_position + spawn_offset
	cannon_fire.global_rotation = fire_rotation

func _calculate_wind_effect() -> float:
	if not wind_manager:
		return 0.0
	
	var wind_dir = wind_manager.get_wind_direction()
	var wind_strength = wind_manager.get_wind_strength()
	
	var angle_diff = wind_dir - p2_boat_visual_rotation
	
	while angle_diff > PI:
		angle_diff -= TAU
	while angle_diff < -PI:
		angle_diff += TAU
	
	var angle_diff_degrees = abs(rad_to_deg(angle_diff))
	var _alignment = cos(angle_diff)
	var _threshold_radians = deg_to_rad(wind_angle_threshold)
	
	if angle_diff_degrees <= wind_angle_threshold:
		var boost_factor = 1.0 - (angle_diff_degrees / wind_angle_threshold)
		return (wind_strength / 100.0) * wind_boost_strength * boost_factor
	elif angle_diff_degrees >= (180.0 - wind_angle_threshold):
		var resistance_factor = 1.0 - ((180.0 - angle_diff_degrees) / wind_angle_threshold)
		return -(wind_strength / 100.0) * wind_resistance_strength * resistance_factor
	else:
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

func hit_by_cannonball() -> void:
	# Player 2 gets hit - remove from scene
	queue_free()

func _draw() -> void:
	if Engine.is_editor_hint() or OS.is_debug_build():
		draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(p2_boat_visual_rotation) * 50, Color.GREEN, 2.0)
		draw_line(Vector2.ZERO, velocity.normalized() * 50, Color.BLUE, 2.0)
