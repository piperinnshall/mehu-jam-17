extends CharacterBody2D

# Movement parameters
@export var max_speed: float = 400.0
@export var min_base_speed: float = 50.0  # Minimum constant speed
@export var acceleration: float = 200.0
@export var deceleration: float = 150.0
@export var drift_factor: float = 0.95  # How much the boat slides (1.0 = no drift, 0.0 = ice)

# Turning parameters
@export var turn_speed: float = 2.0  # Radians per second at max speed
@export var min_turn_speed: float = 0.5  # Minimum turn speed when stationary
@export var turn_speed_curve: float = 2.0  # How turn speed scales with velocity (higher = tighter at high speed)

# Advanced physics
@export var water_resistance: float = 0.98  # Gradual slowdown
@export var min_speed_threshold: float = 10.0  # Speed below which boat stops completely

# Sprite parameters
@export var total_sprite_frames: int = 360  # Total number of rotation frames
@export var sprite_rotation_offset: float = 0.0  # Adjust if sprite sheet doesn't start at 0° right
@export var invert_sprite_rotation: bool = false  # Flip animation direction if needed

# Internal variables
var current_speed: float = 0.0
var target_rotation: float = 0.0
var momentum_velocity: Vector2 = Vector2.ZERO
var boat_visual_rotation: float = 0.0  # Track visual rotation separately

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Set initial rotation (sprite starts facing right = 0 degrees)
	boat_visual_rotation = 0.0
	target_rotation = 0.0
	
	# Make sure AnimatedSprite2D doesn't auto-play
	if animated_sprite:
		animated_sprite.stop()

func _physics_process(delta: float) -> void:
	# Get input
	var input_dir := Input.get_axis("ui_left", "ui_right")
	var throttle := Input.get_action_strength("ui_up")
	
	# Simple acceleration - forward only
	if throttle > 0.0:
		current_speed += acceleration * delta
		current_speed = min(current_speed, max_speed)
	else:
		# Decelerate when not pressing forward, but maintain base speed
		current_speed -= deceleration * delta
		current_speed = max(current_speed, min_base_speed)
	
	# Handle turning
	if abs(input_dir) > 0.0 and current_speed > min_speed_threshold:
		boat_visual_rotation += input_dir * turn_speed * delta
		target_rotation = boat_visual_rotation
	
	# Calculate movement direction
	var forward_direction = Vector2.RIGHT.rotated(boat_visual_rotation)
	
	# Set velocity directly
	velocity = forward_direction * current_speed
	
	# Move the boat
	move_and_slide()
	
	# Update sprite frame based on rotation
	update_sprite_frame()
	
	# Simple collision handling
	if get_slide_collision_count() > 0:
		current_speed *= 0.5

func update_sprite_frame() -> void:
	if not animated_sprite:
		return
	
	# Convert rotation to degrees
	var degrees = rad_to_deg(boat_visual_rotation)
	
	# Invert rotation direction if needed
	if invert_sprite_rotation:
		degrees = -degrees
	
	# Add offset and normalize to 0-360
	degrees = fmod(degrees + sprite_rotation_offset, 360.0)
	if degrees < 0:
		degrees += 360.0
	
	# Calculate frame index (sprite starts facing right = 0 degrees)
	var frame_index = int(round(degrees)) % total_sprite_frames
	
	# Clamp to valid range
	frame_index = clampi(frame_index, 0, total_sprite_frames - 1)
	
	# Set the frame directly
	animated_sprite.frame = frame_index

# Helper function to get current speed (useful for UI/debugging)
func get_current_speed() -> float:
	return current_speed

# Helper function to get speed as percentage
func get_speed_percentage() -> float:
	return (current_speed / max_speed) * 100.0

# Function to apply external force (e.g., currents, wind)
func apply_external_force(force: Vector2) -> void:
	momentum_velocity += force

# Debug drawing (optional - enable in editor)
func _draw() -> void:
	if Engine.is_editor_hint() or OS.is_debug_build():
		# Draw forward direction
		draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(boat_visual_rotation) * 50, Color.GREEN, 2.0)
		# Draw velocity vector
		draw_line(Vector2.ZERO, velocity.normalized() * 50, Color.BLUE, 2.0)
