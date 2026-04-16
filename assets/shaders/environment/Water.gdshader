shader_type spatial;
render_mode shadows_disabled, cull_back, depth_draw_always;

uniform sampler2D screenTexture : hint_screen_texture, filter_linear, repeat_disable;
uniform sampler2D depthTexture : hint_depth_texture, filter_linear, repeat_disable;

group_uniforms Main;
uniform vec3 color : source_color = vec3(0.12, 0.12, 0.08);
uniform float edgeFade : hint_range(0.0, 10.0) = 10.0;

group_uniforms Waves;
uniform sampler2D waveA : filter_linear_mipmap_anisotropic;
uniform sampler2D waveB : filter_linear_mipmap_anisotropic;
uniform float waveIntensity : hint_range(0.0, 1.0, 0.1) = 0.1;
uniform float waveSpeed : hint_range(0.0, 1.0, 0.1) = 0.2;

group_uniforms ____Rain____;
uniform bool enableRain = false;

group_uniforms ____Reflections____;
uniform bool SSREnabled = true;

global uniform float Rain;
global uniform sampler2D Noise : filter_linear_mipmap;
global uniform sampler2D Ripples : filter_linear_mipmap;

varying vec3 worldCamera;
varying vec3 worldPosition;
varying vec3 worldNormal;
varying vec3 worldVertex;

// Utility ----------------------------------------

vec2 GetUVFromViewPosition(vec3 positionViewSpace, mat4 projectionMatrix)
{
	vec4 positionClipSpace = projectionMatrix * vec4(positionViewSpace.xyz, 1.0);
	vec2 positionNDC = positionClipSpace.xy / positionClipSpace.w;
	return positionNDC.xy * 0.5 + 0.5;
}
float BoundCheck(vec2 uv)
{
	float XBound = min(uv.x, 1.0 - uv.x);
	float YBound = min(uv.y, 1.0 - uv.y);
	float XFade = smoothstep(0.0, 0.5, XBound);
	float YFade = smoothstep(0.0, 1.0, YBound);
	return XFade * YFade;
}

// Vertex ----------------------------------------

void vertex()
{
	worldPosition = VERTEX;
	worldNormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	worldCamera = (inverse(MODELVIEW_MATRIX) * vec4(0, 0, 0, 1)).xyz;
	worldVertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Fragment ----------------------------------------

void fragment()
{
	// Highlights ----------------------------------------

	float roughness = 0.05;
	float specular = 0.2;

	// Depth ----------------------------------------

	float depth = texture(depthTexture, SCREEN_UV, 0.0).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float vertexY = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;
	float depthY = world.y / world.w;
	float verticalDepth = vertexY - depthY;

	// Waves ----------------------------------------

	vec2 normalDirection = vec2(waveSpeed, waveSpeed) / 10.0;
	vec2 waveVector1 = (TIME * -normalDirection);
	vec2 waveVector2 = (TIME * normalDirection / 2.0);
	vec2 baseUV = worldVertex.xz * 0.1;
	vec2 waveUV1 = baseUV + waveVector1;
	vec2 waveUV2 = baseUV * 0.5 + waveVector2;
	vec2 waveUV3 = baseUV * 0.2 + waveVector1 * 0.5;

	vec3 wave1 = texture(waveA, waveUV1).xyz;
	vec3 wave2 = texture(waveB, waveUV2).xyz;
	vec3 wave3 = texture(waveA, waveUV3).xyz;
	vec3 waveBlend = normalize(mix(mix(wave1, wave2, 0.5), wave3, 0.5));

	// Rain ----------------------------------------

	if (enableRain)
	{
		float noise = texture(Noise, UV * 20.0).r;
		float ripples = texture(Ripples, UV * 100.0).r;
		float rippleMask = texture(Noise, UV * 50.0 + TIME / 10.0).r;
		rippleMask = smoothstep(0.5, 1.0, rippleMask);
		float rippleEffect = ripples * rippleMask * 50.0;
		float rain = mix(0.0, rippleEffect, Rain);
		roughness -= rain * 0.2;
	}

	// SSR ----------------------------------------

	vec3 colorSample = vec3(0.0);
	float alphaMask = 0.0;

	if (SSREnabled)
	{
		// Get reflected view
		vec3 reflectedNormal = normalize((mat3(VIEW_MATRIX) * (vec3(NORMAL_MAP.x, 0.0, NORMAL_MAP.y) * 2.0 - 1.0) * 0.1) + NORMAL);
		vec3 reflectedPath = reflect(-VIEW, reflectedNormal);
		reflectedPath = normalize(reflectedPath + (waveBlend - 0.5) * 0.1);

		// Get color sample
		vec2 screenPosition = GetUVFromViewPosition(VERTEX + reflectedPath * 100.0, PROJECTION_MATRIX);
		colorSample = textureLod(screenTexture, screenPosition, 1.0).rgb;

		// Boundary fade
		float boundaryFade = BoundCheck(screenPosition);

		// Apply masks
		alphaMask = boundaryFade * 0.75;
		specular *= 1.0 - alphaMask;
	}

	// Transparency ----------------------------------------

	float UVx = min(UV.x, 1.0 - UV.x);
	float UVy = min(UV.y, 1.0 - UV.y);
	float UVFade = smoothstep(0.0, 0.04, min(UVx, UVy));

	float alphaBlend = -verticalDepth * edgeFade;
	alphaBlend = clamp(1.0 - exp(alphaBlend), 0.0, 1.0);
	float alphaOutput = alphaBlend * UVFade;

	// Output ----------------------------------------

	ALBEDO = mix(color, colorSample, alphaMask);
	ALPHA = alphaOutput;
	SPECULAR = specular;
	ROUGHNESS = roughness;
	NORMAL_MAP = waveBlend;
	NORMAL_MAP_DEPTH = waveIntensity;
	RIM = 0.25;
}