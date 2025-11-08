extends AnimatedSprite2D

func _ready() -> void:
	# Play the explosion animation once
	play("default")
	
	# Auto-remove when animation finishes
	animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	queue_free()
