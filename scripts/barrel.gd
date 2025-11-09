extends Area2D

func _ready() -> void:
	# CRITICAL: Set collision layers
	collision_layer = 4  # Barrel is on layer 3 (bit 2, which is value 4)
	collision_mask = 2   # Barrel detects layer 2 (boats)
	
	print("Barrel spawned at: ", global_position)
	print("Barrel collision_layer: ", collision_layer)
	print("Barrel collision_mask: ", collision_mask)
	
	# Connect to signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Debug: List all collision shapes
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			print("Barrel has collision child: ", child.name, " disabled=", child.disabled)

func _on_body_entered(body: Node2D) -> void:
	print("Barrel: body_entered signal! Body: ", body.name, " class: ", body.get_class())
	
	# Check if it's a player boat
	if body.has_method("apply_rapid_fire_powerup"):
		print("Barrel: ✓ Collected by player boat!")
		body.apply_rapid_fire_powerup()
		queue_free()
	else:
		print("Barrel: Body doesn't have apply_rapid_fire_powerup method")

func _on_area_entered(area: Area2D) -> void:
	print("Barrel: area_entered signal! Area: ", area.name)
