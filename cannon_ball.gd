extends Area2D

class_name CannonBall

# Cannon ball parameters
@export var speed: float = 400.0
@export var lifetime: float = 5.0
@export var wind_effect_strength: float = 0.3

var velocity: Vector2 = Vector2.ZERO
var time_alive: float = 0.0
var wind_manager: Node = null

func _ready() -> void:
	# Connect to detect collisions
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Find wind manager
	call_deferred("_find_wind_manager")

func _find_wind_manager() -> void:
	var root = get_tree().root
	wind_manager = _find_node_by_class_name(root, "WindManager")

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

func initialize(initial_velocity: Vector2) -> void:
	velocity = initial_velocity

func _process(delta: float) -> void:
	# Apply wind effect
	if wind_manager:
		var wind_velocity = wind_manager.get_wind_velocity()
		velocity += wind_velocity * wind_effect_strength * delta
	
	# Move the cannon ball
	position += velocity * delta
	
	# Track lifetime
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Check if hit a player
	if body is Player1Boat:
		body.hit_by_cannonball()
		queue_free()
	elif body is Player2Boat:
		body.hit_by_cannonball()
		queue_free()
	else:
		# Hit something else (terrain, etc)
		queue_free()

func _on_area_entered(_area: Area2D) -> void:
	# Hit another cannon ball or area
	queue_free()
