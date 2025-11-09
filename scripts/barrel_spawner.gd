extends Node2D
class_name BarrelSpawner

# Spawning parameters
@export var spawn_interval: float = 20.0
@export var spawn_radius: float = 200.0  # How far from center to spawn

var barrel_scene: PackedScene = preload("res://scenes/barrel.tscn")
var spawn_timer: float = 0.0

# Center of map
const MAP_CENTER_X: float = 700.0
const MAP_CENTER_Y: float = 700.0

func _ready() -> void:
	spawn_timer = spawn_interval
	
	await get_tree().create_timer(6.0).timeout
	_spawn_barrel()

func _process(delta: float) -> void:
	spawn_timer -= delta
	
	if spawn_timer <= 0.0:
		_spawn_barrel()
		spawn_timer = spawn_interval

func _spawn_barrel() -> void:
	# Random position within radius of map center
	var random_angle = randf() * TAU  # Random angle in radians
	var random_distance = randf() * spawn_radius  # Random distance from center
	
	var x = MAP_CENTER_X + cos(random_angle) * random_distance
	var y = MAP_CENTER_Y + sin(random_angle) * random_distance
	
	var spawn_pos = Vector2(x, y)
	
	var barrel = barrel_scene.instantiate()
	get_parent().add_child(barrel)
	barrel.global_position = spawn_pos
	
	print("BarrelSpawner: Spawned barrel at ", spawn_pos)
