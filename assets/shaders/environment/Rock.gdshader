shader_type spatial;

group_uniforms ____Main____;
uniform sampler2D albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D moss : source_color, filter_linear_mipmap_anisotropic;
uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);
uniform float limiter : hint_range(0.0, 1.0, 0.1) = 0.1;

group_uniforms ___Weather____;
uniform bool enableMoss = false;
uniform bool enableRain = false;
uniform bool enableSnow = false;
uniform float snowTop : hint_range(0.0, 1.0, 0.05) = 0.0;
uniform float snowSide : hint_range(0.0, 1.0, 0.05) = 0.0;
uniform float snowBottom : hint_range(0.0, 1.0, 0.05) = 0.0;

// Globals
global uniform sampler2D Noise : filter_linear_mipmap;
global uniform sampler2D Ripples : filter_linear_mipmap;
global uniform float Snow;
global uniform float Rain;

// Varyings
varying vec3 worldNormal;
varying vec3 worldPosition;
varying float bottomMask;

// Vertex ----------------------------------------

void vertex()
{
	worldNormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	worldPosition = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	bottomMask = smoothstep(1.0, 0.0, VERTEX.y);
}

// Fragment ----------------------------------------

void fragment()
{
	// Scaling ----------------------------------------

	float dynamicScale = (length(MODEL_MATRIX[0].xyz) + length(MODEL_MATRIX[1].xyz) + length(MODEL_MATRIX[2].xyz)) / 3.0;

	// Sample ----------------------------------------

	vec3 color = texture(albedo, UV * dynamicScale).rgb * tint.rgb;
	vec3 detail = texture(normal, UV * dynamicScale).rgb;
	vec3 mossy = texture(moss, UV * dynamicScale).rgb;
	float roughness = 0.5;

	// Snow ----------------------------------------

	if (enableSnow)
	{
		// Snow mask
		float snowMask = 1.0;

		// Snow output
		float topCoverage = worldNormal.y + color.r - (1.0 - snowTop);
		float topOutput = smoothstep(0.8, 1.0, topCoverage + color.r);
		float sideCoverage = 1.0 + color.r - (1.0 - snowSide);
		float sideOutput = smoothstep(0.8, 1.0, sideCoverage + color.r);
		float bottomCoverage = 1.0 + color.r - (1.0 - snowBottom);
		float bottomOutput = smoothstep(0.8, 1.0, bottomCoverage * bottomMask + color.r);
		float snowOutput = topOutput + sideOutput + bottomOutput;
		color += vec3(0.2, 0.2, 0.2) * snowOutput * Snow * snowMask;
	}

	if (enableMoss)
	{
		// Snow output
		float mossCoverage = smoothstep(0.8, 1.0, worldNormal.y);
		float mossOutput = smoothstep(0.8, 1.0, mossCoverage + color.r);
		color = mix(color, mossy, mossOutput * (1.0 - Snow));
	}

	// Rain ----------------------------------------

	if (enableRain)
	{
		// Rain mask
		float rainMask = 1.0;
		float wetness;

		// Rain output
		float rippleProjection = smoothstep(0.0, 0.5, worldNormal.y);
		float ripples = texture(Ripples, UV * dynamicScale * 5.0).r;
		float rippleUV = texture(Noise, UV * dynamicScale * 5.0 + TIME / 10.0).r;
		float rippleMask = smoothstep(0.5, 1.0, rippleUV * rippleProjection);
		float rainOutput = ripples * rippleMask * 1000.0;

		// Rain type
		wetness = mix(roughness, (roughness / 1.5) - rainOutput, Rain * rainMask);
		roughness = wetness;
	}
	
	// Detail ----------------------------------------
	
	float distanceToCamera = length(CAMERA_POSITION_WORLD - worldPosition);
	float detailBlend = smoothstep(10.0, 20.0, distanceToCamera);
	NORMAL_MAP = detail;
	NORMAL_MAP_DEPTH = mix(1.5, 2.0, detailBlend);
	
	// Occlusion ----------------------------------------
	
	color *= mix(1.0, 0.6, (1.0 - COLOR.r));
	
	// Output ----------------------------------------
	
	ALBEDO = color;
	ROUGHNESS = roughness;
	SPECULAR = smoothstep(0.0, limiter, color.r);
}