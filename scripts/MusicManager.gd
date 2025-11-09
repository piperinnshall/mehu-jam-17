extends Node

# This is an autoload singleton that plays background music throughout the game

var music_player: AudioStreamPlayer

# Volume control (in dB)
@export var music_volume_db: float = -20.0

func _ready() -> void:
	# Create the audio player
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	# Load the music
	var music = load("res://assets/The Krakens Call.mp3")
	music_player.stream = music
	
	# Set volume
	music_player.volume_db = music_volume_db
	
	# Set to loop and play immediately
	music_player.autoplay = true
	music_player.bus = "Master"
	
	# Play the music
	music_player.play()
	
	print("MusicManager: Background music started at ", music_volume_db, " dB")

func _process(_delta: float) -> void:
	# Safety check - if music stops for any reason, restart it
	if not music_player.playing:
		print("MusicManager: Music stopped unexpectedly, restarting...")
		music_player.play()

# Function to change volume at runtime
func set_volume(db: float) -> void:
	music_volume_db = db
	if music_player:
		music_player.volume_db = db
		print("MusicManager: Volume changed to ", db, " dB")

# Function to get current volume
func get_volume() -> float:
	return music_volume_db
