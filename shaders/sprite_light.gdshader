shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha, depth_test_disabled;

uniform sampler2D sprite_texture : source_color, filter_nearest;
uniform vec2 atlas_size;
uniform float highlight_amount;
instance uniform bool always_on_top;
instance uniform vec2 offset;
instance uniform vec3 damage_color : source_color = vec3(0.0f);
instance uniform int billboard : hint_enum("Disabled", "Enabled", "Y-Billboard");
instance uniform bool flip;

void vertex()
{
	// Makes the sprite a billboard if true
	if (billboard == 1)
	{
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	}
	else if (billboard == 2)
	{
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	}
}

void fragment()
{
	// Depth test
	if (always_on_top)
	{
		DEPTH = 1.0f;
	}
	else
	{
		DEPTH = FRAGCOORD.z;
	}

	// Damage color and albedo color
	vec2 offset_uv;
	if (flip)
	{
		offset_uv = (vec2(-UV.x, UV.y) / atlas_size) + ((vec2(1.0f, 0.0f) + offset) / atlas_size);
	}
	else
	{
		offset_uv = (UV / atlas_size) + (offset / atlas_size);
	}

	vec4 color = texture(sprite_texture, offset_uv);
	ALBEDO = vec3(max(color.r, damage_color.r), max(color.g, damage_color.g), max(color.b, damage_color.b));
	ALPHA = color.a;
}

void light()
{
	// Damage effect light
	float damage_light = length(damage_color);
	DIFFUSE_LIGHT += damage_light;

	// Standard lighting
	if (billboard == 1)
	{
		DIFFUSE_LIGHT += clamp(dot(vec3(0.0f,0.0f,1.0f), LIGHT), 0.0f, 1.0f) * ATTENUATION * LIGHT_COLOR / PI;
	}
	else if (billboard == 2)
	{
		DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR / 10.0f;
	}
	else
	{
		DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0f, 1.0f) * ATTENUATION * LIGHT_COLOR / PI;
	}

	// Rim lighting
	vec3 camera_vector = normalize(-VIEW_MATRIX[2].xyz);
	vec3 light_vector = normalize((INV_VIEW_MATRIX * vec4(LIGHT, 0.0)).xyz);
	vec2 rim_offset = vec2(-((light_vector.x * camera_vector.z) + (light_vector.z * camera_vector.x)), -light_vector.y) * highlight_amount;

	vec2 offset_uv;
	if (flip)
	{
		offset_uv = (vec2(-UV.x, UV.y) / atlas_size) + ((vec2(1.0f, 0.0f) + offset) / atlas_size);
		offset_uv = offset_uv + rim_offset / vec2(-atlas_size.x, atlas_size.y);
	}
	else
	{
		offset_uv = (UV / atlas_size) + (offset / atlas_size);
		offset_uv = offset_uv + rim_offset / atlas_size;
	}

	float rim = (1.0f - texture(sprite_texture, offset_uv).a);

	if ((offset_uv.y < (offset / atlas_size).y || offset_uv.y > (1.0f / atlas_size.y) + (offset / atlas_size).y) || (offset_uv.x < (offset / atlas_size).x || offset_uv.x > (1.0f / atlas_size.x) + (offset / atlas_size).x))
	{
		rim = 1.0f;
	}

	DIFFUSE_LIGHT += rim * LIGHT_COLOR * ATTENUATION;
}