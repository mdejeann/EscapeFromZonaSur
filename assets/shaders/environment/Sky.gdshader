shader_type sky;
render_mode use_half_res_pass;

group_uniforms Sky;
uniform vec4 skyColor : source_color;
uniform vec4 horizonColor : source_color;
uniform vec4 groundColor : source_color;
uniform float overcast : hint_range(0.0, 1.0) = 0.0;
uniform float reflection : hint_range(0.0, 10.0, 0.1) = 1.0;
uniform float horizonBlur : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform sampler2D neutralTexture : filter_linear, source_color, hint_default_white;
uniform sampler2D overcastTexture : filter_linear, source_color, hint_default_white;

group_uniforms Sun;
uniform vec3 sunColor : source_color;
uniform float sunSize = 0.05;
uniform float sunBlur = 1.0;
uniform float sunGlowSize = 0.5;
uniform float sunGlowIntensity = 1.0;
uniform float sunReflection = 20.0;

group_uniforms Moon;
uniform sampler2D moonTexture : filter_linear_mipmap, source_color;
uniform vec3 moonColor : source_color;
uniform float moonSize = 0.05;
uniform float moonGlowSize = 0.5;
uniform float moonGlowIntensity = 0.05;
uniform float moonReflection = 20.0;

group_uniforms Stars;
uniform sampler2D starsTexture : filter_linear, source_color;
uniform float starsReflection = 5.0;

group_uniforms Aurora;
uniform sampler2D auroraTexture : filter_linear, source_color;
uniform vec3 auroraColor : source_color;
uniform float auroraIntensity : hint_range(0.0, 1.0) = 1.0;
uniform float auroraMovement : hint_range(0.0, 1.0) = 0.5;
uniform float auroraReflection = 10.0;

// Simple hash for noise
float hash(float n) { return fract(sin(n) * 43758.5453123); }

void sky() {
	// Get eye direction
	vec3 eyeDirection = normalize(EYEDIR);

	// Mix sky & ground colors
	vec3 baseColor;
	if (eyeDirection.y > 0.1) { baseColor = skyColor.rgb; }
	else if (eyeDirection.y < -0.1) { baseColor = groundColor.rgb; }
	else { baseColor = mix(groundColor.rgb, skyColor.rgb, smoothstep(-0.1, 0.1, eyeDirection.y)); }

	// Mix clouds
	vec2 cloudCoords = vec2(SKY_COORDS.x + TIME * 0.0005, SKY_COORDS.y);
	vec4 neutralClouds = texture(neutralTexture, cloudCoords);
	vec4 darkClouds = texture(overcastTexture, cloudCoords);
	vec4 clouds = mix(neutralClouds, darkClouds, overcast);
	vec3 skyWithClouds = mix(baseColor, baseColor * clouds.rgb, smoothstep(-0.1, 0.1, eyeDirection.y));

	// Horizon glow
	float horizonMask = pow(1.0 - abs(eyeDirection.y), 1.0 / horizonBlur);
	vec3 horizonGlow = horizonColor.rgb * horizonMask;
	
	// Sun core
	vec3 sunDirection = normalize(LIGHT0_DIRECTION);
	float sunAngle = dot(sunDirection, vec3(0.0, 1.0, 0.0));
	float sunMask = smoothstep(-0.1, 0.0, sunAngle);
	float sunDistance = distance(EYEDIR, LIGHT0_DIRECTION);
	float sunPower = 1.0 - clamp(sunDistance / sunSize, 0.0, 1.0);
	float sunOutput = clamp(sunPower / sunBlur, sunPower, 1.0);
	vec3 sunCore = sunColor * sunOutput * sunMask * (1.0 - overcast);

	// Sun glow
	float sunGlowDistance = distance(EYEDIR, LIGHT0_DIRECTION);
	float sunGlowPower = 1.0 - clamp(sunGlowDistance / sunGlowSize, 0.0, 1.0);
	float sunGlowOutput = pow(sunGlowPower, 2.0) * sunGlowIntensity;
	vec3 sunGlow = sunColor * sunGlowOutput * sunMask * (1.0 - overcast);

	// Moon core
	vec3 moonDirection = normalize(LIGHT1_DIRECTION);
	float moonAngle = dot(moonDirection, vec3(0.0, 1.0, 0.0));
	float moonMask = smoothstep(-0.1, 0.0, moonAngle);
	float moonDistance = distance(EYEDIR, LIGHT1_DIRECTION);
	float moonPower = 1.0 - clamp(moonDistance / moonSize, 0.0, 1.0);
	float moonDot = dot(eyeDirection, moonDirection);
	float moonDisc = sqrt(1.0 - moonSize * moonSize);
	vec3 moonCore = vec3(0.0);

	if (moonDot > moonDisc - 0.01)
	{
		vec3 moonRight = normalize(cross(vec3(0.0, 1.0, 0.0), moonDirection));
		vec3 moonUp = normalize(cross(moonDirection, moonRight));
		vec3 moonLocal = eyeDirection - moonDirection * moonDot;
		vec2 moonCoords = vec2(dot(moonLocal, moonRight), dot(moonLocal, moonUp)) / (moonSize * 2.0) + 0.5;
		vec4 moonTex = texture(moonTexture, moonCoords);
		float moonFade = smoothstep(moonDisc - 0.01, moonDisc, moonDot);
		moonCore = moonColor * moonTex.rgb * moonPower * moonMask * moonFade * (1.0 - overcast);
	}

	// Moon glow
	float moonGlowDistance = distance(EYEDIR, LIGHT1_DIRECTION);
	float moonGlowPower = 1.0 - clamp(moonGlowDistance / moonGlowSize, 0.0, 1.0);
	float moonGlowOutput = pow(moonGlowPower, 2.0) * moonGlowIntensity;
	vec3 moonGlow = moonColor * moonGlowOutput * moonMask * (1.0 - overcast);

	// Night fade
	float nightFade = smoothstep(0.0, 0.5, -sunAngle);

	// Stars
	vec2 starCoords = vec2(SKY_COORDS.x + TIME * 0.0005, SKY_COORDS.y);
	vec4 stars = texture(starsTexture, starCoords);
	vec3 starsLayer = stars.rgb * 0.5 * clouds.rgb * (1.0 - overcast);
	float starMask = smoothstep(0.0, 0.75, eyeDirection.y);
	starsLayer *= starMask * nightFade;

	// Aurora
	vec2 auroraCoords = vec2(SKY_COORDS.x + TIME * 0.0005, SKY_COORDS.y);
	vec4 auroraSample = texture(auroraTexture, auroraCoords);
	float intensityVariation = sin(eyeDirection.x * 5.0 + TIME) * sin(eyeDirection.z * 10.0 + TIME) + 1.0;
	float variedIntensity = auroraIntensity * (1.0 - auroraMovement + intensityVariation * auroraMovement * 2.0);
	vec3 auroraLayer = auroraColor * auroraSample.rgb * variedIntensity;
	float auroraHeightMask = smoothstep(0.0, 0.01, eyeDirection.y);
	auroraLayer *= auroraHeightMask * nightFade;

	// Reflection output
	vec3 reflectionOutput = skyWithClouds + horizonGlow + sunGlow + sunCore * sunReflection +
	                        moonGlow + moonCore * moonReflection + starsLayer * starsReflection +
	                        auroraLayer * auroraReflection;
	// Color output
	vec3 colorOutput = skyWithClouds + horizonGlow + sunGlow + sunCore + moonGlow +
	                    moonCore + starsLayer + auroraLayer;

	// Output
	if(AT_CUBEMAP_PASS)
	{
		COLOR = reflectionOutput * reflection;
	}
	else
	{
		COLOR = colorOutput;
	}
}