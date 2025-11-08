extends Node2D

# ========================
# CONFIGURATION
# ========================

const WIDTH: int = 512  # start small for testing
const HEIGHT: int = 512

var base_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()

var water_colors = [
	Color(0.0, 0.0, 0.2),  # deep
	Color(0.0, 0.1, 0.4),
	Color(0.0, 0.3, 0.6)   # shallow
]

var sand_colors = [
	Color(0.9, 0.85, 0.6),
	Color(0.95, 0.9, 0.5),
	Color(0.8, 0.75, 0.5)
]

var land_colors = [
	Color(0.1, 0.4, 0.1),
	Color(0.2, 0.5, 0.1),
	Color(0.3, 0.6, 0.2)
]

# ========================
# READY FUNCTION
# ========================

func _ready():
	randomize()
	_setup_noise()
	
	# Static Image.create() in Godot 4
	var img: Image = Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGB8)
	print("Image created with size: ", img.get_width(), "x", img.get_height())
	
	_generate_map(img)
	
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = tex
	sprite.position = Vector2(WIDTH/2, HEIGHT/2)
	add_child(sprite)

# ========================
# NOISE SETUP
# ========================

func _setup_noise():
	base_noise.seed = randi()
	base_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX_SMOOTH
	base_noise.frequency = 0.003
	base_noise.fractal_octaves = 4
	base_noise.fractal_lacunarity = 2
	base_noise.fractal_gain = 0.5

	detail_noise.seed = randi()
	detail_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX_SMOOTH
	detail_noise.frequency = 0.02
	detail_noise.fractal_octaves = 3
	detail_noise.fractal_lacunarity = 2
	detail_noise.fractal_gain = 0.5

# ========================
# MAP GENERATION
# ========================

func _generate_map(img: Image) -> void:
	var center_x = WIDTH / 2
	var center_y = HEIGHT / 2
	var max_dist = min(center_x, center_y)

	for y in range(HEIGHT):
		for x in range(WIDTH):
			var dx = (x - center_x) / max_dist
			var dy = (y - center_y) / max_dist
			var distance = sqrt(dx*dx + dy*dy)
			
			var base_val = (base_noise.get_noise_2d(x, y) + 1.0) / 2.0
			var mask = 1.0 - distance
			var height_val = base_val * mask
			var detail_val = (detail_noise.get_noise_2d(x, y) + 1.0) / 2.0
			height_val += detail_val * 0.1
			height_val = clamp(height_val, 0.0, 1.0)

			# Adjusted thresholds: more water, narrow sand
			var color: Color
			if height_val < 0.4:
				color = water_colors[0].lerp(water_colors[2], height_val / 0.4)
			elif height_val < 0.42:
				var t = (height_val - 0.4) / 0.02
				color = sand_colors[0].lerp(sand_colors[2], t)
			else:
				var t = (height_val - 0.42) / 0.58
				color = land_colors[0].lerp(land_colors[2], t)

			img.set_pixel(x, y, color)
