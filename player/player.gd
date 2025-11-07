extends CharacterBody2D


const speed = 300.0

func get_input():
	velocity = Vector2()
	if Input.is_action_pressed('ui_right'):
		velocity.x += 1
	elif Input.is_action_pressed('ui_left'):
		velocity.x -= 1
	elif Input.is_action_pressed('ui_down'):
		velocity.y += 1
	elif Input.is_action_pressed('ui_up'):
		velocity.y -= 1
	velocity = velocity.normalized() * speed
	
	if Input.is_action_just_pressed("ui_accept"):
		$CollisionShape2D.disabled = !$CollisionShape2D.disabled
		
func _physics_process(delta):
	get_input()
	move_and_slide()
