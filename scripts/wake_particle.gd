extends Node2D

class_name WakeParticle

var lifetime: float = 1.0
var max_lifetime: float = 1.3
var initial_scale: float = 0.1
var final_scale: float = 1.5
var velocity: Vector2 = Vector2.ZERO
var drag: float = 0.92

func _ready() -> void:
	modulate = Color(1.0, 1.0, 1.0, 0.243)
	scale = Vector2(initial_scale, initial_scale)
	z_index = 1  # Ensure it renders below everything

func _process(delta: float) -> void:
	lifetime -= delta
	
	if lifetime <= 0:
		queue_free()
		return
	
	# Update position with velocity and drag
	position += velocity * delta
	velocity *= drag
	
	# Calculate fade and scale based on lifetime
	var progress = 1.0 - (lifetime / max_lifetime)
	var current_scale = lerp(initial_scale, final_scale, progress)
	scale = Vector2(current_scale, current_scale)
	
	# Fade out over time
	var alpha = lifetime / max_lifetime
	modulate.a = alpha * 0.7

func _draw() -> void:
	# Draw a foam/wake circle
	draw_circle(Vector2.ZERO, 12.0, Color(0.9, 0.95, 1.0, 0.6))
	draw_circle(Vector2.ZERO, 8.0, Color(1.0, 1.0, 1.0, 0.8))
