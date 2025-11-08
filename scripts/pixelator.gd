extends CanvasLayer

@export var pixel_size: int = 2

var color_rect: ColorRect

func _ready() -> void:
	# Create ColorRect
	color_rect = ColorRect.new()
	add_child(color_rect)
	
	# Make it cover the whole screen
	color_rect.anchor_right = 1.0
	color_rect.anchor_bottom = 1.0
	
	
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
