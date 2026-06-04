shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform bool pixelate = true;
uniform bool use_virtual_resolution = true;
uniform vec2 virtual_resolution = vec2(320.0, 180.0);
uniform float pixel_size : hint_range(1.0, 32.0, 1.0) = 4.0;

uniform bool limit_colors = true;
uniform float color_levels : hint_range(2.0, 64.0, 1.0) = 16.0;

uniform bool dither = true;
uniform float dither_strength : hint_range(0.0, 1.0, 0.01) = 0.22;
uniform float dither_scale : hint_range(1.0, 8.0, 1.0) = 2.0;

uniform bool protect_dark_areas = true;
uniform float dark_protect_start : hint_range(0.0, 1.0, 0.01) = 0.04;
uniform float dark_protect_end : hint_range(0.0, 1.0, 0.01) = 0.22;

uniform bool protect_flat_areas = true;
uniform float flat_area_strength : hint_range(0.0, 1.0, 0.01) = 0.65;

float bayer_8x8(vec2 p) {
	ivec2 ip = ivec2(mod(floor(p), 8.0));

	int x = ip.x;
	int y = ip.y;

	int value = 0;

	if (y == 0) {
		int row[8] = int[8](0, 48, 12, 60, 3, 51, 15, 63);
		value = row[x];
	} else if (y == 1) {
		int row[8] = int[8](32, 16, 44, 28, 35, 19, 47, 31);
		value = row[x];
	} else if (y == 2) {
		int row[8] = int[8](8, 56, 4, 52, 11, 59, 7, 55);
		value = row[x];
	} else if (y == 3) {
		int row[8] = int[8](40, 24, 36, 20, 43, 27, 39, 23);
		value = row[x];
	} else if (y == 4) {
		int row[8] = int[8](2, 50, 14, 62, 1, 49, 13, 61);
		value = row[x];
	} else if (y == 5) {
		int row[8] = int[8](34, 18, 46, 30, 33, 17, 45, 29);
		value = row[x];
	} else if (y == 6) {
		int row[8] = int[8](10, 58, 6, 54, 9, 57, 5, 53);
		value = row[x];
	} else {
		int row[8] = int[8](42, 26, 38, 22, 41, 25, 37, 21);
		value = row[x];
	}

	return (float(value) + 0.5) / 64.0 - 0.5;
}

vec2 pixel_uv(vec2 uv, vec2 screen_size) {
	if (!pixelate) {
		return uv;
	}

	if (use_virtual_resolution) {
		vec2 res = max(virtual_resolution, vec2(1.0));
		return (floor(uv * res) + vec2(0.5)) / res;
	}

	float size = max(pixel_size, 1.0);
	vec2 pixel_pos = floor((uv * screen_size) / size) * size + size * 0.5;
	return pixel_pos / screen_size;
}

float luminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

float edge_amount(vec2 uv, vec2 pixel_size_uv) {
	vec3 center = texture(screen_texture, uv).rgb;
	vec3 right = texture(screen_texture, uv + vec2(pixel_size_uv.x, 0.0)).rgb;
	vec3 up = texture(screen_texture, uv + vec2(0.0, pixel_size_uv.y)).rgb;

	float edge = distance(center, right) + distance(center, up);
	return clamp(edge * 8.0, 0.0, 1.0);
}

void fragment() {
	vec2 screen_size = vec2(textureSize(screen_texture, 0));
	vec2 sample_uv = pixel_uv(SCREEN_UV, screen_size);

	vec4 color = texture(screen_texture, sample_uv);
	vec3 original = color.rgb;

	if (limit_colors) {
		float steps = max(color_levels - 1.0, 1.0);
		float luma = luminance(original);

		float dark_fade = 1.0;
		if (protect_dark_areas) {
			dark_fade = smoothstep(dark_protect_start, dark_protect_end, luma);
		}

		float flat_fade = 1.0;
		if (protect_flat_areas) {
			vec2 pixel_size_uv = 1.0 / screen_size;
			float edge = edge_amount(sample_uv, pixel_size_uv);
			flat_fade = mix(1.0 - flat_area_strength, 1.0, edge);
		}

		float effect_fade = dark_fade * flat_fade;

		vec3 processed = original;

		if (dither) {
			vec2 dither_pos = floor(SCREEN_UV * screen_size / max(dither_scale, 1.0));
			float pattern = bayer_8x8(dither_pos);
			processed += pattern * dither_strength * effect_fade / steps;
		}

		processed = clamp(processed, vec3(0.0), vec3(1.0));
		processed = floor(processed * steps + vec3(0.5)) / steps;

		color.rgb = mix(original, processed, effect_fade);
	}

	COLOR = vec4(color.rgb, 1.0);
}