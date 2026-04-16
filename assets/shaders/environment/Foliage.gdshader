shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;

group_uniforms ____Main____;
uniform sampler2D albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal : hint_normal, filter_linear_mipmap;
uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);
uniform float YNormal : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float highlight : hint_range(0.0, 1.0, 0.05) = 0.5;

group_uniforms ____Grading____;
uniform sampler2D variationNoise : source_color, filter_linear_mipmap;
uniform bool enableNoise = false;
uniform bool enableVariation = false;
uniform bool groundGradient = false;

group_uniforms ____Clipping____;
uniform float nearClip : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float farClip : hint_range(0.0, 1.0, 0.01) = 0.01;
uniform float clipDistance = 20.0;
uniform float fadeDistance = 80.0;

group_uniforms ____Wind____;
uniform sampler2D windNoise : source_color, filter_linear_mipmap;
uniform bool enableWind = false;
uniform float windIntensity = 0.1;
uniform float windSpeed = 1.5;

group_uniforms ____Weather____;
uniform float rainEffect : hint_range(0.0, 1.0, 0.05) = 0.25;
uniform bool enableSnow = false;
uniform bool snowNoise = false;
uniform float snowTop : hint_range(0.0, 1.0, 0.05) = 0.0;
uniform float snowSide : hint_range(0.0, 1.0, 0.05) = 0.0;
uniform float snowBottom : hint_range(0.0, 1.0, 0.05) = 0.0;

// Globals & varyings
global uniform float Wind;
global uniform float Rain;
global uniform float Snow;
varying float cameraDistance;
varying vec3 worldNormal;
varying vec3 worldPosition;

// Vertex ----------------------------------------

void vertex()
{
	// Wind speed
	float time = TIME * windSpeed;

	// Parameters
	vec3 chunkPosition = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	worldPosition = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	cameraDistance = length(worldPosition - CAMERA_POSITION_WORLD);
	worldNormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);

	// Sample wind
	vec2 windUV = (chunkPosition.xz + VERTEX.xz) * 0.1 + TIME * windSpeed * vec2(0.1, 0.0);
	vec3 wind = texture(windNoise, windUV).rgb;

	// Remap wind from RGB
	float windX = wind.r * 2.0 - 1.0;
	float windZ = wind.g * 2.0 - 1.0;
	float windPhase = wind.b * 2.0 - 1.0;

	// Oscillation
	float windBase = sin(time + chunkPosition.x * 0.5 + chunkPosition.z * 0.5 + windPhase);
	float windEffect = windBase * windIntensity * (1.0 - COLOR.r) * Wind;
	vec3 windOffset = vec3(0.0);
	windOffset.x = windEffect * (1.0 + windX);
	windOffset.z = windEffect * (0.5 + windZ);

	// Disable wind beyond fade distance
	if (enableWind)
	{
		if (cameraDistance < fadeDistance * 0.8)
		{
			VERTEX += windOffset;
		}
	}
}

// Fragment ----------------------------------------

void fragment()
{
	// Sample textures
	vec3 color = texture(albedo, UV).rgb * tint.rgb;
	vec3 detail = texture(normal, UV).rgb;
	float alpha = texture(albedo, UV).a;
	float roughness = 1.0;
	float specular = 0.1;

	// Dynamic clipping
	float dynamicClip = nearClip;
	if (cameraDistance > 0.0)
	{
		float distanceFactor = clamp(cameraDistance / clipDistance, 0.0, 1.0);
		dynamicClip = mix(nearClip, farClip, distanceFactor);
	}

	// Fading
	float fadeStart = fadeDistance - 10.0;
	if (cameraDistance > fadeStart)
	{
		float fadeFactor = clamp((cameraDistance - fadeStart) / 10.0, 0.0, 1.0);
		dynamicClip = mix(dynamicClip, 1.0, fadeFactor);
	}

	// Snow
	if (enableSnow)
	{
		vec2 snowUV = worldPosition.xz * 0.05;
		float snowVariation = snowNoise ? texture(variationNoise, snowUV).r * 0.5 : 0.0;
		float topCoverage = worldNormal.y + color.r - (1.0 - snowTop);
		float topOutput = smoothstep(0.5, 1.0, topCoverage + color.r);
		float sideCoverage = 1.0 + color.r - (1.0 - snowSide);
		float sideOutput = smoothstep(0.5, 1.0, sideCoverage + color.r) + snowVariation;
		float bottomCoverage = 1.0 + color.r - (1.0 - snowBottom);
		float bottomOutput = smoothstep(0.5, 1.0, bottomCoverage * COLOR.r + color.r);
		color += vec3(0.4, 0.4, 0.4) * (topOutput + sideOutput + bottomOutput) * Snow;
	}

	// Highlights
	roughness = mix(1.0, 0.8, Rain);
	specular = mix(smoothstep(0.0, highlight, color.r), smoothstep(0.0, rainEffect, color.r), Rain);

	// Variation
	if (enableNoise)
	{
		vec2 variationUV = worldPosition.xz * 0.1;
		float noise = texture(variationNoise, variationUV).r;
		color *= 1.0 - noise * 0.7;
	}
	if (enableVariation)
	{
		vec2 variationUV = worldPosition.xz * 0.05;
		float noise = texture(variationNoise, variationUV).r;
		color = mix(color, vec3(0.05, 0.06, 0.03), noise * 1.0);
	}

	// Ground gradient
	if (groundGradient)
	{
		color -= vec3(0.01, 0.015, 0.01) * COLOR.r;
	}

	// Desaturation (Winter)
	float desaturation = mix(0.0, 0.5, Snow);
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(luminance), desaturation);

	// Output
	ALBEDO = color;
	NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), YNormal));
	NORMAL_MAP = detail;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	ALPHA = alpha;
	ALPHA_SCISSOR_THRESHOLD = dynamicClip;
}