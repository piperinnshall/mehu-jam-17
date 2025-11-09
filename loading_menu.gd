extends Control

# Duration to show the loading screen
var load_for_seconds: float = 4.0

# Reference to the ProgressBar
@onready var progress_bar = $CenterContainer/VBoxContainer/ProgressBar

func _ready():
	# Start the loading process
	show_loading_screen()

func show_loading_screen():
	# Pause the game
	get_tree().paused = true
	
	# Make sure the loading menu is visible
	self.visible = true

	# Reset progress bar
	progress_bar.value = 0

	# Start the progress bar animation
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = false
	add_child(timer)
	timer.start()

	var elapsed = 0.0
	timer.connect("timeout", Callable(self, "_on_progress_timeout").bind(timer, elapsed))

func _on_progress_timeout(timer: Timer, elapsed: float):
	elapsed += timer.wait_time
	progress_bar.value = (elapsed / load_for_seconds) * 100
	
	if elapsed >= load_for_seconds:
		# Stop timer
		timer.stop()
		timer.queue_free()
		
		# Hide the loading menu
		self.visible = false
		
		# Unpause the game
		get_tree().paused = false
