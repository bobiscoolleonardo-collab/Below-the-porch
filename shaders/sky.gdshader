shader_type sky;
render_mode use_half_res_pass, use_debanding;

global uniform vec4 sky_color;
global uniform vec4 horizon_color;

uniform float horizonHeight : hint_range(-1.0, 1.0, 0.01) = -0.2;
uniform float rayleighCoefficient : hint_range(0.0, 1.0, 0.01) = 0.2;
uniform float mieCoefficient : hint_range(0.0, 1.0, 0.01);
uniform float mieEccentricity : hint_range(-1.0, 1.0, 0.01) = 0.8; 

uniform float sunDiskScale: hint_range(0.0, 1.0, 0.01) = 0.2;
uniform float sunSmoothing : hint_range(0.0, 1.0, 0.1) = 0.5;

uniform sampler2D cloudTexture;
uniform sampler2D cloudCoverageTexture;

uniform float sky_intensity : hint_range(0.0, 1.0, 0.1);

// Calculate the total amount of light scattered by Rayleigh scattering for all lights
vec3 rayleighScattering(float cos_theta) {
	float rayleighSunPhase = 0.75 * (1.0 + cos_theta * cos_theta);
	vec3 rayleighColor = horizon_color.rgb * rayleighCoefficient * rayleighSunPhase;
	
	return rayleighColor;
}

// Calculate the total amount of light scattered by Mie scattering for all lights
vec3 mieScattering(float cos_theta, float g) {
	float mieSunPhase = ((1.0 - g * g) / (4.0 * PI)) * (1.0 + g * g - 2.0 * g * cos_theta) / pow(1.0 + g * g - 2.0 * g * cos_theta, 1.5);
	vec3 mieColor = horizon_color.rgb * mieCoefficient * mieSunPhase;
	
	return mieColor;
}

void sky() {
	// compute stereographic coordinates
	float theta = acos(dot(EYEDIR, vec3(0, 1, 0)));
	float phi = atan(EYEDIR.z, EYEDIR.x);
	float r = 2.0 * tan(theta / 2.0);
	vec2 stereographic = r * vec2(cos(phi), sin(phi));
	vec2 texCoords = vec2(0.5, 0.5) + stereographic * vec2(0.5, -0.5);
	
	float cos_theta = dot(EYEDIR, LIGHT0_DIRECTION);
	
	// Solar disk
	float sunDir = distance(EYEDIR, LIGHT0_DIRECTION);
	float sunPos = 1.0 - clamp(sunDir / sunDiskScale, 0.0, 1.0);
	float sunAngularDiameterCos = cos(sunPos * sunDiskScale);
	float sunAngularDiameterCos2 = cos(sunPos * sunDiskScale * sunSmoothing);
	float sunDisk = smoothstep(sunAngularDiameterCos, sunAngularDiameterCos2, cos_theta);
	vec4 sun = vec4(LIGHT0_COLOR * LIGHT0_ENERGY, sunDisk);
	
	vec3 totalScattering = mieScattering(cos_theta, mieEccentricity) + rayleighScattering(cos_theta);
	
	vec4 clouds = mix(texture(cloudTexture, texCoords), vec4(0), texture(cloudCoverageTexture, texCoords));
	float colorGradient = EYEDIR.y - horizonHeight;
	vec3 skyColor;
	skyColor = mix(horizon_color.rgb, sky_color.rgb, colorGradient);
	skyColor = mix(skyColor.rgb, sun.rgb, sun.a);
	skyColor = mix(skyColor.rgb, clouds.xyz, clouds.rgb * sky_intensity);
	
	COLOR = skyColor + totalScattering;
}