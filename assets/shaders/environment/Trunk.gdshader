shader_type spatial;

group_uniforms ____Main____;
uniform sampler2D albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal : hint_normal, filter_linear_mipmap;
uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);

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

group_uniforms ____Trunk____;
uniform bool trunkBlend = false;
uniform sampler2D trunkTexture : source_color, filter_linear_mipmap;

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
	
	// Apply wind
	if (enableWind)
	{
		VERTEX += bendOffset;
	}
	
	// Parameters for fragment
	objectDistance = length(position - CAMERA_POSITION_WORLD);
	worldNormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	// Pass world-space view direction
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
	
	// Snow
	if (enableSnow)
	{
		float topCoverage = worldNormal.y + color.r - (1.0 - snowTop);
		float topOutput = smoothstep(0.8, 1.0, topCoverage + color.r);
		float sideCoverage = 1.0 + color.r - (1.0 - snowSide);
		float sideOutput = smoothstep(0.8, 1.0, sideCoverage + color.r);
		float bottomCoverage = 1.0 + color.r - (1.0 - snowBottom);
		float bottomOutput = smoothstep(0.8, 1.0, bottomCoverage * bottomMask + color.r);
		color += vec3(0.2, 0.2, 0.2) * (topOutput + sideOutput + bottomOutput) * Snow;
	}
	
	// Trunk blending
	if (trunkBlend)
	{
		vec3 trunkColor = texture(trunkTexture, UV).rgb;
		float heightBlend = smoothstep(localHeight / 5.0, 0.0, 1.0);
		color = mix(color, trunkColor, heightBlend);
	}
	
	// Output
	ALBEDO = color;
	ROUGHNESS = 0.8;
	SPECULAR = smoothstep(0.0, 0.2, color.r);
	NORMAL_MAP = detail;
}