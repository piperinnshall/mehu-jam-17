extends Node2D

# ========================
# CONFIGURATION
# ========================
const WIDTH: int = 1700
const HEIGHT: int = 1700

# Noise generators
var base_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()

# Color palettes
var water_colors = [
	Color(0.4, 0.7, 0.9), # deep
	Color(0.2, 0.5, 0.7),
	Color(0.1, 0.3, 0.5)  # shallow
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
# HEIGHT RANGES
# ========================
const LAND_MAX: float = 0.36
const SAND_MAX: float = 0.39
const WATER_MAX: float = 1.0

# ========================
# RADIAL FALL-OFF (islands)
# ========================
const FALLOFF_START: float = 0.35
const FALLOFF_END: float   = 0.9
const FALLOFF_EXPONENT: float = 1.6
var invert_falloff: bool = false

# ========================
# SQUARE BORDER CONFIGURATION
# ========================
const BORDER_WIDTH: int = 200

# ========================
# READY FUNCTION
# ========================
func _ready():
	randomize()
	_setup_noise()

	# Create images
	var img: Image = Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGB8)
	var mask_img: Image = Image.create(WIDTH, HEIGHT, false, Image.FORMAT_L8)
	print("Image created with size: ", img.get_width(), "x", img.get_height())
	
	var start_time = Time.get_ticks_msec()

	# Generate the map + hitbox mask simultaneously
	_generate_map(img, mask_img)

	# Convert map to texture and display
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = tex
	sprite.position = Vector2(WIDTH / 2, HEIGHT / 2)
	add_child(sprite)
	
	# Water shader
	var water_mask_tex: ImageTexture = ImageTexture.create_from_image(mask_img)
	var shader_material = ShaderMaterial.new()
	shader_material.shader = preload("res://scripts/map_generation/water_shader.gdshader")
	shader_material.set_shader_parameter("water_mask", water_mask_tex)
	sprite.material = shader_material
	
	var time = Time.get_ticks_msec() - start_time
	print("Map generation complete in ", time, " ms")

# ========================
# NOISE SETUP
# ========================
func _setup_noise():
	# Base noise (large scale)
	base_noise.seed = randi()
	base_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX_SMOOTH
	base_noise.frequency = 0.003
	base_noise.fractal_octaves = 4
	base_noise.fractal_lacunarity = 2
	base_noise.fractal_gain = 0.5

	# Detail noise (small scale)
	detail_noise.seed = randi()
	detail_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX_SMOOTH
	detail_noise.frequency = 0.02
	detail_noise.fractal_octaves = 3
	detail_noise.fractal_lacunarity = 2
	detail_noise.fractal_gain = 0.5

# ========================
# HELPER FUNCTIONS
# ========================
func _smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t = clamp((x - edge0) / max(edge1 - edge0, 0.00001), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _border_mask(x: int, y: int) -> float:
	var nx = min(x, WIDTH - 1 - x) / float(BORDER_WIDTH)
	var ny = min(y, HEIGHT - 1 - y) / float(BORDER_WIDTH)
	return clamp(min(nx, ny), 0.0, 1.0)

# ========================
# MAP GENERATION
# ========================
func _generate_map(img: Image, mask_img: Image) -> void:
	var center_x = WIDTH / 2
	var center_y = HEIGHT / 2
	var max_dist = min(center_x, center_y)

	# Create BitMap for grass mask (for hitbox)
	var bm := BitMap.new()
	bm.create(Vector2i(WIDTH, HEIGHT))


	for y in range(HEIGHT):
		for x in range(WIDTH):
			# ------------------------
			# RADIAL DISTANCE (island falloff)
			# ------------------------
			var dx = (x - center_x) / max_dist
			var dy = (y - center_y) / max_dist
			var distance = sqrt(dx * dx + dy * dy)

			# ------------------------
			# NOISE GENERATION
			# ------------------------
			var base_val = (base_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var detail_val = (detail_noise.get_noise_2d(x, y) + 1.0) * 0.5

			# ------------------------
			# RADIAL FALL-OFF MASK
			# ------------------------
			var fall_t = _smoothstep(FALLOFF_START, FALLOFF_END, distance)
			var mask = pow(1.0 - fall_t, FALLOFF_EXPONENT)
			if invert_falloff:
				mask = 1.0 - mask

			var height_val = base_val * mask
			height_val += detail_val * 0.08 * mask
			height_val = clamp(height_val, 0.0, 1.0)

			# ------------------------
			# BORDER ENFORCEMENT
			# ------------------------
			var border_t = _border_mask(x, y)
			if border_t < 1.0:
				var target = LAND_MAX * 0.8
				height_val = lerp(target, height_val, border_t)
				
			# ------------------------
			# WATER MASK GENERATION
			# ------------------------
			var is_water = 1.0 if height_val > SAND_MAX else 0.0
			mask_img.set_pixel(x, y, Color(is_water, is_water, is_water))
				
			# ------------------------
			# COLOR + GRASS MASK
			# ------------------------
			var color: Color
			if height_val <= LAND_MAX:
				var t = height_val / LAND_MAX
				color = land_colors[0].lerp(land_colors[2], t)

				# Record grass hitbox points every 2 pixels for speed
				if (x % 2 == 0 and y % 2 == 0):
					bm.set_bit(x, y, true)

			elif height_val <= SAND_MAX:
				var t = (height_val - LAND_MAX) / (SAND_MAX - LAND_MAX)
				color = sand_colors[0].lerp(sand_colors[2], t)
			else:
				var t = (height_val - SAND_MAX) / (WATER_MAX - SAND_MAX)
				color = water_colors[0].lerp(water_colors[2], t)

			img.set_pixel(x, y, color)

	# ========================
	# BUILD GRASS HITBOX FROM MASK
	# ========================
	print("Generating grass hitbox polygons...")
	var polys = bm.opaque_to_polygons(Rect2(Vector2.ZERO, Vector2(WIDTH, HEIGHT)), 4.0)

	var static_body := StaticBody2D.new()
	static_body.name = "GrassHitbox"
	add_child(static_body)

	for poly in polys:
		var shape := CollisionPolygon2D.new()
		shape.polygon = poly
		static_body.add_child(shape)

	print("Grass hitbox generated: ", polys.size(), " polygons.")
