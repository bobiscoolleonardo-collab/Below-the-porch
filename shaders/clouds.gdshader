shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, unshaded, shadows_disabled;

global uniform float cloud_intensity;

uniform sampler2D cloud_noise : source_color, repeat_enable, filter_linear_mipmap;

uniform vec4 cloud_color : source_color = vec4(1.0, 0.86, 0.72, 1.0);
uniform vec4 cloud_shadow_color : source_color = vec4(0.55, 0.36, 0.32, 1.0);

uniform vec3 sun_direction = vec3(0.4, 0.7, 0.25);

uniform float coverage : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform float softness : hint_range(0.01, 0.5, 0.01) = 0.16;
uniform float opacity : hint_range(0.0, 1.0, 0.01) = 0.65;

uniform float scale : hint_range(0.01, 10.0, 0.01) = 1.0;
uniform vec2 wind_direction = vec2(1.0, 0.25);
uniform float wind_speed : hint_range(0.0, 2.0, 0.01) = 0.05;

uniform float detail_strength : hint_range(0.0, 1.0, 0.01) = 0.55;
uniform float edge_breakup : hint_range(0.0, 1.0, 0.01) = 0.45;

uniform float light_wrap : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform float shadow_strength : hint_range(0.0, 1.0, 0.01) = 0.35;

float noise_layer(vec2 uv) {
	float n = 0.0;

	n += texture(cloud_noise, uv * 0.55).r * 0.50;
	n += texture(cloud_noise, uv * 1.25 + vec2(13.7, 4.2)).r * 0.30;
	n += texture(cloud_noise, uv * 2.80 + vec2(2.8, 21.9)).r * 0.15;
	n += texture(cloud_noise, uv * 6.00 + vec2(31.1, 8.6)).r * 0.05;

	return n;
}

void fragment() {
	vec2 wind = wind_direction / max(length(wind_direction), 0.001);
	vec2 uv = UV * scale + wind * TIME * wind_speed;

	float base_noise = noise_layer(uv);
	float detail_noise = noise_layer(uv * 2.3 + base_noise * 1.5);

	float cloud_shape = mix(base_noise, detail_noise, detail_strength);

	float threshold = mix(0.82, 0.28, coverage);
	float alpha = smoothstep(threshold, threshold + softness, cloud_shape);

	float broken_edge = smoothstep(0.22, 0.85, detail_noise);
	alpha *= mix(1.0, broken_edge, edge_breakup);

	alpha *= opacity;

	vec3 sun_dir = normalize(sun_direction);

	float sun_light = clamp(sun_dir.y * 0.5 + 0.5, 0.0, 1.0);
	sun_light = mix(sun_light, 1.0, light_wrap);

	vec3 final_color = mix(cloud_shadow_color.rgb, cloud_color.rgb, sun_light);
	final_color = mix(final_color, cloud_color.rgb, 1.0 - shadow_strength);

	ALBEDO = final_color * cloud_intensity;
	ALPHA = alpha;
}