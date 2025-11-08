shader_type canvas_item;

uniform float InitialAlpha : hint_range(0.0, 1.0) = 0.6;
uniform float Speed : hint_range(0.0, 1.0) = 0.09;
uniform float QuantizeColourAmount : hint_range(1.0, 10.0) = 3.0;
uniform float BrightnessOffset : hint_range(-1.0, 1.0) = 0.0;
uniform float UpperCutoff : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	// Get the texture color
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Calculate sine wave animation
	float animated_value = tex_color.r * 15.0 + TIME / Speed;
	float sine_wave = sin(animated_value);
	
	// Remap sine from [-1, 1] to [-0.1, 0.1]
	float wave_offset = (sine_wave * 0.1);
	
	// Calculate base alpha from texture and initial alpha
	float base_alpha = tex_color.r * InitialAlpha;
	
	// Subtract wave offset
	float adjusted_alpha = base_alpha - wave_offset;
	
	// Quantize the alpha value
	float quantized = floor(adjusted_alpha * QuantizeColourAmount) / QuantizeColourAmount;
	
	// Apply texture alpha squared for softer edges
	float final_alpha = quantized * (tex_color.a * tex_color.a);
	
	// Add brightness offset
	final_alpha += BrightnessOffset;
	
	// Clamp to upper cutoff
	final_alpha = clamp(final_alpha, 0.0, UpperCutoff);
	
	// Output white color with animated alpha
	COLOR = vec4(1.0, 1.0, 1.0, final_alpha);
}