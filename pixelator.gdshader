shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 32.0) = 2.0;

void fragment() {
	// Get screen texture size
	vec2 size = vec2(textureSize(SCREEN_TEXTURE, 0));
	
	// Calculate pixelated UV coordinates
	vec2 uv = floor(SCREEN_UV * size / pixel_size) * pixel_size / size;
	
	// Sample and output
	COLOR = texture(SCREEN_TEXTURE, uv);
}