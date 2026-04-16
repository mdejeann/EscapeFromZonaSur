shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;

group_uniforms ____Main____;
uniform sampler2D albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal : hint_normal, filter_linear_mipmap;
uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);
uniform float YNormal : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform bool highlights = false;

group_uniforms ____Wind____;
uniform bool enableWind = false;
uniform float windHeight = 5.0;
const float windSpeed = 0.5;
const float windIntensity = 0.01;
const float branchIntensity = 0.05;
const float branchSpeed = 1.0;

group_uniforms ____Weather____;
uniform bool enableSnow = false;
uniform float snowTop : hint_range(0.0, 1.0, 0.05) = 0.0;
uniform float snowSide : hint_range(0.0, 1.0, 0.05) = 0.0;
uniform float snowBottom : hint_range(0.0, 1.0, 0.05) = 0.0;
uniform float rainEffect : hint_range(0.0, 1.0, 0.05) = 0.25;

group_uniforms ____Clipping____;
uniform float clip : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform bool inverseClip = false;
uniform bool shadowClip = false;

group_uniforms ____Billboard____;
uniform bool billboard = false;
uniform float nearExposure : hint_range(0.0, 2.0, 0.1) = 1.2;
uniform float farExposure : hint_range(0.0, 2.0, 0.1) = 0.8;
uniform float farDistance = 150.0;

// Globals & varyings
global uniform float Wind;
global uniform float Rain;
global uniform float Snow;
varying float objectDistance;
varying float localHeight;
varying vec3 worldNormal;
varying float bottomMask;
varying vec3 viewDirection;

// Utility ----------------------------------------

float proceduralNoise(vec3 position, float time)
{
	float noise = sin(position.x * 0.5 + position.z * 0.7 + time) * cos(position.z * 0.3 + position.x * 0.4 + time * 0.8);
	return noise * 0.5 + 0.5;
}

// Vertex ----------------------------------------

void vertex()
{
	// Get position
	vec3 position = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	localHeight = VERTEX.y;
	bottomMask = smoothstep(1.0, 0.0, VERTEX.y);

	// Time & noise
	float time = TIME * windSpeed;
	float noiseValue = proceduralNoise(position, time);
	float noiseX = sin(noiseValue * 5.0) * 2.0 - 1.0;
	float noiseZ = cos(noiseValue * 5.0) * 2.0 - 1.0;

	// Wind (Bend)
	float windBase = sin(time + position.x * 0.5 + position.z * 0.5);
	float windEffect = windBase * windIntensity * Wind;
	float heightFactor = clamp(VERTEX.y / windHeight, 0.0, 1.0);
	float bendX = windEffect * noiseX * heightFactor;
	float bendY = windEffect * noiseZ * heightFactor;
	vec3 bendOffset = vec3(0.0);
	bendOffset.x = VERTEX.y * sin(bendX);
	bendOffset.z = VERTEX.y * sin(bendY);
	bendOffset.y = VERTEX.y * (cos(bendX) * cos(bendY) - 1.0);

	// Wind (Branches)
	float branchTime = TIME * branchSpeed;
	float branchNoiseValue = proceduralNoise(position + vec3(VERTEX.x, 0.0, VERTEX.z), branchTime);
	float branchNoise = sin(branchNoiseValue * 10.0);
	float branchWindBase = sin(branchTime + VERTEX.x + VERTEX.z);
	float branchEffect = branchWindBase * branchIntensity * Wind;
	float branchMask = 1.0 - COLOR.r;
	vec2 branchDirection = normalize(vec2(VERTEX.x, VERTEX.z));
	vec3 branchOffset = vec3(0.0);
	float branch_angle = branchEffect * branchMask * heightFactor * branchNoise;
	branchOffset.y = sin(branch_angle) * heightFactor;
	branchOffset.x = sin(branch_angle) * branchDirection.x;
	branchOffset.z = sin(branch_angle) * branchDirection.y;

	// Apply wind
	if (enableWind)
	{
		VERTEX += bendOffset + branchOffset;
	}

	// Parameters for fragment
	objectDistance = length(position - CAMERA_POSITION_WORLD);
	worldNormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);

	// Pass world-space view lightDirection
	vec3 worldPosition = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	viewDirection = normalize(CAMERA_POSITION_WORLD - worldPosition);
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
	
	// Fading
	float dynamicClip = clip;
	float fadePoint = 70.0;
	float fadeStart = inverseClip ? 60.0 : 80.0;
	float fadeFactor = clamp((objectDistance - fadePoint) / abs(fadeStart - fadePoint), 0.0, 1.0);
	if (!inverseClip && !shadowClip) { dynamicClip = mix(dynamicClip, 1.0, fadeFactor); }
	else if (inverseClip && !shadowClip) { dynamicClip = mix(1.0, dynamicClip, fadeFactor); }
	
	// Highlights
	if (highlights)
	{
		roughness = mix(1.0, 0.9, Rain);
		specular = mix(smoothstep(0.0, 0.3, color.r), smoothstep(0.0, rainEffect, color.r), Rain);
	}

	// Snow
	if (enableSnow)
	{
		float topCoverage = worldNormal.y + color.r - (1.0 - snowTop);
		float topOutput = smoothstep(0.9, 1.0, topCoverage + color.r);
		float sideCoverage = 1.0 + color.r - (1.0 - snowSide);
		float sideOutput = smoothstep(0.5, 1.0, sideCoverage + color.r);
		float bottomCoverage = 1.0 + color.r - (1.0 - snowBottom);
		float bottomOutput = smoothstep(0.9, 1.0, bottomCoverage * bottomMask + color.r);
		color += vec3(0.2, 0.2, 0.2) * (topOutput + sideOutput + bottomOutput) * Snow;
	}

	// Billboard
	if (billboard)
	{
		float exposureFactor = clamp((objectDistance - farDistance) / 50.0, 0.0, 1.0);
		float appliedExposure = mix(nearExposure, farExposure, exposureFactor);
		color *= appliedExposure;
		color = clamp(color, 0.0, 1.0);
		NORMAL = mix(VIEW, vec3(0.0, 1.0, 0.0), YNormal);
	}
	else
	{
		NORMAL = mix(NORMAL, vec3(0.0, 1.0, 0.0), YNormal);
	}

	// Output
	ALBEDO = color;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	NORMAL_MAP = detail;
	ALPHA = alpha;
	ALPHA_SCISSOR_THRESHOLD = dynamicClip;
}