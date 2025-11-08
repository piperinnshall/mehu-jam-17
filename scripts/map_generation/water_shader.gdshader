shader_type canvas_item;

uniform sampler2D water_mask;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float time_scale : hint_range(0.0, 2.0) = 0.3;
uniform float caustic_scale : hint_range(0.0, 50.0) = 15.0;
uniform float caustic_strength : hint_range(0.0, 1.0) = 0.4; // slightly brighter
uniform vec2 light_direction = vec2(0.3, -0.5);
uniform float specular_strength : hint_range(0.0, 2.0) = 0.8;
uniform float specular_shininess : hint_range(1.0, 128.0) = 32.0;
uniform float foam_strength : hint_range(0.0, 1.0) = 0.2;
uniform float refraction_strength : hint_range(0.0, 0.1) = 0.03;

// Hash function for noise
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.13);
	p3 += dot(p3, p3.yzx + 3.333);
	return fract((p3.x + p3.y) * p3.z);
}

// Noise function
float noise(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Layered caustics (slightly brighter max peaks)
float caustics(vec2 uv, float time) {
    vec2 p = uv * caustic_scale;
    vec2 p1 = p + vec2(time * 0.5, time * 0.3);
    float n1 = noise(p1);
    vec2 p2 = p - vec2(time * 0.4, time * 0.6);
    float n2 = noise(p2);

    float raw = n1 + n2 - 1.0;
    raw = max(raw, 0.0);

    // slightly increase brightness of strongest peaks
    float peak = pow(raw, 4.0) * 0.9; // was 0.8
    return peak;
}

// Crosshatch caustic overlay (slightly brighter)
float caustic_crosshatch(vec2 uv, float time) {
    vec2 p = uv * caustic_scale * 2.0;
    float lineX = sin(p.x + time * 2.0);
    float lineY = sin(p.y + time * 2.5);
    float hatch = abs(lineX * lineY);
    return pow(hatch, 2.5) * 0.09; // was 0.08
}


// Water wave normals
vec2 water_normal(vec2 uv, float time) {
	float n1 = noise(uv * 8.0 + time * 0.2);
	float n2 = noise(uv * 12.0 - time * 0.15);
	return vec2(n1, n2) * 0.1 - 0.05;
}

// Small fast ripples
float ripples(vec2 uv, float time) {
	return sin(dot(uv * 20.0, vec2(1.0, 1.0)) + time * 3.0) * 0.05;
}

void fragment() {
	vec4 original = COLOR;
	float mask = texture(water_mask, UV).r;

	if (mask > 0.01) {
		float time = TIME * time_scale;

		// Base caustics
		float base_caustics = caustics(UV, time);
		float hatch = caustic_crosshatch(UV, time);

		// Water normals
		vec2 normal_offset = water_normal(UV, time);

		// Refraction of underlying pixels
		vec2 refract_uv = UV + normal_offset * refraction_strength;
		vec3 underneath = texture(SCREEN_TEXTURE, refract_uv).rgb;

		// Combine base color with refraction
		vec3 water_color = mix(original.rgb, underneath, 0.3);

		// Add caustics and crosshatch
		water_color += vec3(base_caustics) * caustic_strength;
		water_color += vec3(hatch);

		// Add ripples
		water_color += vec3(ripples(UV, time));

		// Foam along crests
		float foam = smoothstep(0.4, 0.6, base_caustics);
		water_color += vec3(1.0) * foam * foam_strength;

		// Specular highlights
		vec2 light_dir = normalize(light_direction);
		vec3 normal = normalize(vec3(normal_offset.x, normal_offset.y, 1.0));
		vec3 light_dir_3d = normalize(vec3(light_dir.x, light_dir.y, -1.0));
		vec3 view_dir = vec3(0.0, 0.0, 1.0);
		vec3 halfway = normalize(light_dir_3d + view_dir);
		float spec = pow(max(dot(normal, halfway), 0.0), specular_shininess);
		spec = clamp(spec, 0.0, 0.3);
		water_color += vec3(1.0, 1.0, 0.9) * spec * specular_strength;

		COLOR = vec4(water_color, original.a);
	} else {
		COLOR = original;
	}
}
