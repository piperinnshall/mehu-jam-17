extends CanvasLayer

@export var pixel_size: int = 2

var color_rect: ColorRect

func _ready() -> void:
	# Set layer to be on top (above game UI at layer 0)
	layer = 100
	
	# Create ColorRect
	color_rect = ColorRect.new()
	add_child(color_rect)
	
	# Make it cover the whole screen
	color_rect.anchor_right = 1.0
	color_rect.anchor_bottom = 1.0
	
	# Use nearest neighbor filtering for crisp pixels
	color_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Load and apply shader
	var shader = load("res://pixelator.gdshader")
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("pixel_size", pixel_size)
	
	color_rect.material = shader_material
	
	# Move to back so it doesn't block input
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_pixel_size(size: int) -> void:
	pixel_size = size
	if color_rect and color_rect.material:
		color_rect.material.set_shader_parameter("pixel_size", pixel_size)
