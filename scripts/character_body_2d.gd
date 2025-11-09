extends CharacterBody2D

class_name Player1Boat

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
@export var starting_rotation: float = 180.0  # New: Starting rotation in degrees

# Cannon parameters
@export var cannon_cooldown: float = 2.0
@export var cannon_ball_speed: float = 400.0
@export var cannon_offset: float = 30.0
var cannon_ball_scene: PackedScene = preload("res://scenes/cannon_ball.tscn")
var cannon_fire_scene: PackedScene = preload("res://scenes/cannon_fire.tscn")

# Powerup parameters
var rapid_fire_active: bool = false
var rapid_fire_timer: float = 0.0
var rapid_fire_duration: float = 5.0
var rapid_fire_cooldown: float = 0.4

# Explosion parameters
var boat_explosion_scene: PackedScene = preload("res://scenes/boat_explosion.tscn")
@export var explosion_delay_before_removal: float = 0.75

# Wake parameters
@export var wake_spawn_rate: float = 0.03
@export var wake_speed_threshold: float = 20.0
@export var wake_spread_angle: float = 95.0
@export var wake_lateral_speed: float = 90.0
var wake_particle_scene: PackedScene = preload("res://scenes/wake_particle.tscn")
var wake_timer: float = 0.0
var wake_container: Node2D = null

# Internal variables - P1 specific
var p1_current_speed: float = 0.0
var p1_target_rotation: float = 0.0
var p1_momentum_velocity: Vector2 = Vector2.ZERO
var p1_boat_visual_rotation: float = 0.0
var cannon_cooldown_timer: float = 0.0
var player2_boat: Node = null
var is_destroyed: bool = false

# References
var wind_manager: Node = null
var map_generator: Node = null
var game_manager: Node = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var wake_marker: Marker2D = $WakeMarker
@onready var cannon_audio: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	# Apply starting rotation
	p1_boat_visual_rotation = deg_to_rad(starting_rotation)
	p1_target_rotation = p1_boat_visual_rotation
	
	if animated_sprite:
		animated_sprite.stop()
	
	wake_container = Node2D.new()
	wake_container.name = "WakeContainer"
	wake_container.z_index = -1
	call_deferred("_add_wake_container")
	
	call_deferred("_find_wind_manager")
	call_deferred("_find_player2")
	call_deferred("_find_map_generator")
	call_deferred("_find_game_manager")

func _add_wake_container() -> void:
	get_parent().add_child(wake_container)

func _find_wind_manager() -> void:
	var root = get_tree().root
	wind_manager = _find_node_by_class_name(root, "WindManager")

func _find_player2() -> void:
	var root = get_tree().root
	player2_boat = _find_node_by_class_name(root, "Player2Boat")

func _find_map_generator() -> void:
	var root = get_tree().root
	map_generator = _find_node_by_name(root, "MapGenerator")

func _find_game_manager() -> void:
	var root = get_tree().root
	game_manager = _find_node_by_class_name(root, "GameManager")
	if game_manager:
		print("P1: Found GameManager!")
	else:
		print("P1: Could not find GameManager!")

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
		return true
	return true

func _physics_process(delta: float) -> void:
	if is_destroyed:
		return
	
	# Handle rapid fire timer
	if rapid_fire_active:
		rapid_fire_timer -= delta
		if rapid_fire_timer <= 0.0:
			rapid_fire_active = false
			print("P1: Rapid fire expired")
	
	if cannon_cooldown_timer > 0.0:
		cannon_cooldown_timer -= delta
	
	# Swapped input mappings - P1 now uses P2 controls
	var input_dir := Input.get_axis("P2left", "P2right")
	var throttle := Input.get_action_strength("P2up")
	var fire := Input.is_action_just_pressed("P2down")
	
	if fire and cannon_cooldown_timer <= 0.0:
		_fire_cannon()
		# Use rapid fire cooldown if active
		if rapid_fire_active:
			cannon_cooldown_timer = rapid_fire_cooldown
		else:
			cannon_cooldown_timer = cannon_cooldown
	
	var wind_speed_modifier = _calculate_wind_effect()
	
	if throttle > 0.0:
		p1_current_speed += acceleration * delta
		p1_current_speed = min(p1_current_speed, max_speed + wind_speed_modifier)
	else:
		p1_current_speed -= deceleration * delta
		p1_current_speed = max(p1_current_speed, min_base_speed)
	
	var effective_speed = p1_current_speed + wind_speed_modifier
	effective_speed = max(effective_speed, 0.0)
	
	if abs(input_dir) > 0.0 and effective_speed > min_speed_threshold:
		p1_boat_visual_rotation += input_dir * turn_speed * delta
		p1_target_rotation = p1_boat_visual_rotation
	
	var forward_direction = Vector2.RIGHT.rotated(p1_boat_visual_rotation)
	velocity = forward_direction * effective_speed
	
	move_and_slide()
	update_sprite_frame()
	_update_wake(delta, effective_speed)
	
	if get_slide_collision_count() > 0:
		p1_current_speed *= 0.5

func apply_rapid_fire_powerup() -> void:
	rapid_fire_active = true
	rapid_fire_timer = rapid_fire_duration
	print("P1: Rapid fire activated!")
	
	# Visual feedback - flash the sprite
	if animated_sprite:
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color(0.147, 1.176, 0.171, 1.0), 0.2)
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)
	
	# Show powerup text
	_show_powerup_text()

func _show_powerup_text() -> void:
	var label = Label.new()
	label.text = "ATTACK SPEED UP\nFOR 5 SECONDS"
	label.add_theme_font_size_override("font_size", 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = Color(1.0, 1.0, 0.0, 0.0)  # Start transparent yellow
	label.z_index = 100
	
	# Position label above the boat
	label.position = Vector2(-100, -80)
	add_child(label)
	
	# Animate the text
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in
	tween.tween_property(label, "modulate", Color(1.0, 1.0, 0.0, 1.0), 0.3)
	# Move up slightly
	tween.tween_property(label, "position", label.position + Vector2(0, -20), 0.3)
	
	# Hold visible
	tween.chain().tween_interval(2.0)
	
	# Fade out
	tween.chain().tween_property(label, "modulate", Color(1.0, 1.0, 0.0, 0.0), 0.5)
	
	# Clean up
	tween.finished.connect(func(): label.queue_free())

func _update_wake(delta: float, effective_speed: float) -> void:
	if not _is_on_water() or effective_speed < wake_speed_threshold:
		return
	
	wake_timer -= delta
	
	if wake_timer <= 0.0:
		wake_timer = wake_spawn_rate
		_spawn_wake_particles()

func _spawn_wake_particles() -> void:
	if not wake_marker:
		return
	
	var forward = Vector2.RIGHT.rotated(p1_boat_visual_rotation)
	var backward = -forward
	var right = forward.rotated(PI / 2.0)
	var spread_rad = deg_to_rad(wake_spread_angle)
	
	var left_direction = backward.rotated(-spread_rad)
	_create_wake_particle(wake_marker.global_position, left_direction)
	
	var right_direction = backward.rotated(spread_rad)
	_create_wake_particle(wake_marker.global_position, right_direction)

func _create_wake_particle(pos: Vector2, direction: Vector2) -> void:
	if not wake_particle_scene or not wake_container:
		return
	
	var wake = wake_particle_scene.instantiate()
	wake_container.add_child(wake)
	wake.global_position = pos
	
	if "velocity" in wake:
		wake.velocity = direction.normalized() * wake_lateral_speed

func _fire_cannon() -> void:
	# Play cannon sound
	if cannon_audio:
		cannon_audio.play()
	
	if not player2_boat:
		_find_player2()
	
	if not player2_boat:
		return
	
	var to_p2 = player2_boat.global_position - global_position
	var forward = Vector2.RIGHT.rotated(p1_boat_visual_rotation)
	var right = forward.rotated(PI / 2.0)
	
	var dot_product = to_p2.dot(right)
	var fire_direction: Vector2
	var spawn_offset: Vector2
	var fire_rotation: float
	
	if dot_product > 0:
		fire_direction = right
		spawn_offset = right * cannon_offset
		fire_rotation = p1_boat_visual_rotation + PI / 2.0
	else:
		fire_direction = -right
		spawn_offset = -right * cannon_offset
		fire_rotation = p1_boat_visual_rotation - PI / 2.0
	
	var cannon_ball = cannon_ball_scene.instantiate()
	get_parent().add_child(cannon_ball)
	cannon_ball.global_position = global_position + spawn_offset
	
	var cannon_velocity = fire_direction * cannon_ball_speed
	cannon_ball.initialize(cannon_velocity)
	
	var cannon_fire = cannon_fire_scene.instantiate()
	get_parent().add_child(cannon_fire)
	cannon_fire.global_position = global_position + spawn_offset
	cannon_fire.global_rotation = fire_rotation

func _calculate_wind_effect() -> float:
	if not wind_manager:
		return 0.0
	
	var wind_dir = wind_manager.get_wind_direction()
	var wind_strength = wind_manager.get_wind_strength()
	
	var angle_diff = wind_dir - p1_boat_visual_rotation
	
	while angle_diff > PI:
		angle_diff -= TAU
	while angle_diff < -PI:
		angle_diff += TAU
	
	var angle_diff_degrees = abs(rad_to_deg(angle_diff))
	
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
	
	var degrees = rad_to_deg(p1_boat_visual_rotation)
	
	if invert_sprite_rotation:
		degrees = -degrees
	
	degrees = fmod(degrees + sprite_rotation_offset, 360.0)
	if degrees < 0:
		degrees += 360.0
	
	var frame_index = int(round(degrees)) % total_sprite_frames
	frame_index = clampi(frame_index, 0, total_sprite_frames - 1)
	
	animated_sprite.frame = frame_index

func get_current_speed() -> float:
	return p1_current_speed

func get_speed_percentage() -> float:
	return (p1_current_speed / max_speed) * 100.0

func apply_external_force(force: Vector2) -> void:
	p1_momentum_velocity += force

func hit_by_cannonball() -> void:
	if is_destroyed:
		return
	
	print("P1: hit_by_cannonball called")
	
	if not game_manager:
		_find_game_manager()
	
	if game_manager and game_manager.has_method("player_hit"):
		print("P1: Calling game_manager.player_hit(1)")
		game_manager.player_hit(1)
	else:
		print("P1: No game manager found, exploding immediately")
		_trigger_explosion()

func _trigger_explosion() -> void:
	print("P1: _trigger_explosion called")
	is_destroyed = true
	velocity = Vector2.ZERO
	p1_current_speed = 0.0
	
	if animated_sprite:
		animated_sprite.visible = false
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	var explosion = boat_explosion_scene.instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	
	get_tree().create_timer(explosion_delay_before_removal).timeout.connect(queue_free)
