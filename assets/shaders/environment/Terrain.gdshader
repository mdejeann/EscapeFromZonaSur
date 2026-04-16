shader_type spatial;

group_uniforms ____Black____;
uniform sampler2D ABaseAlbedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D ABaseNormal : hint_normal, filter_linear_mipmap;
uniform sampler2D AOverlayAlbedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D AOverlayNormal : hint_normal, filter_linear_mipmap;
uniform float ADryLimiter : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float AWetLimiter : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float ABump : hint_range(0.0, 1.0, 0.1) = 0.5;

group_uniforms ____Red____;
uniform sampler2D RBaseAlbedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D RBaseNormal : hint_normal, filter_linear_mipmap;
uniform sampler2D ROverlayAlbedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D ROverlayNormal : hint_normal, filter_linear_mipmap;
uniform float RBlend : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float RDryLimiter : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float RWetLimiter : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float RBump : hint_range(0.0, 1.0, 0.1) = 0.5;

group_uniforms ____Green____;
uniform sampler2D GBaseAlbedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D GBaseNormal : hint_normal, filter_linear_mipmap;
uniform sampler2D GOverlayAlbedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D GOverlayNormal : hint_normal, filter_linear_mipmap;
uniform float GBlend : hint_range(0.0, 1.0, 0.05) = 1.0;
uniform float GDryLimiter : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float GWetLimiter : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float GBump : hint_range(0.0, 1.0, 0.1) = 0.5;

group_uniforms ____Blue____;
uniform sampler2D BBaseAlbedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D BBaseNormal : hint_normal, filter_linear_mipmap;
uniform sampler2D BOverlayAlbedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D BOverlayNormal : hint_normal, filter_linear_mipmap;
uniform float BBlend : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float BDryLimiter : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float BWetLimiter : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float BBump : hint_range(0.0, 1.0, 0.1) = 0.5;

group_uniforms ____Far____;
uniform bool enableGrass = false;
uniform bool enableHay = false;
uniform float farDistance : hint_range(0.0, 100.0, 1.0) = 40.0;
uniform sampler2D grassFar : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D hayFar : source_color, filter_linear_mipmap_anisotropic;

group_uniforms ____Roads____;
uniform bool enableRoads = true;
uniform bool enableBump = true;
uniform bool enableTrash = true;
uniform sampler2D roadMask : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D roadBump : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D trash : source_color, filter_linear_mipmap_anisotropic;

group_uniforms ____Weather____;
uniform bool enableRain = false;
uniform bool enableSnow = false;
uniform sampler2D snowNormal : hint_normal, filter_linear_mipmap_anisotropic;

group_uniforms ____Debug____;
uniform bool debug = false;
uniform sampler2D checkerMap : source_color, filter_linear_mipmap;

// Globals & varyings
global uniform sampler2D Noise : filter_linear_mipmap;
global uniform sampler2D Overlay : filter_linear_mipmap;
global uniform sampler2D Ripples : filter_linear_mipmap;
global uniform float Snow;
global uniform float Rain;
varying vec3 worldNormal;
varying vec3 worldPosition;

// Vertex ----------------------------------------

void vertex()
{
	worldNormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	worldPosition = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Fragment ----------------------------------------

void fragment()
{
	// Sample textures
	float tiling = 120.0;
	float noise = texture(Noise, UV * 20.0).r;
	float overlay = texture(Overlay, UV * 10.0).r;
	vec3 roads = texture(roadMask, UV).rgb;
	vec3 ABaseColor = texture(ABaseAlbedo, UV * tiling).rgb;
	vec3 ABaseDetail = texture(ABaseNormal, UV * tiling).rgb;
	vec3 AOverlayColor = texture(AOverlayAlbedo, UV * tiling).rgb;
	vec3 AOverlayDetail = texture(AOverlayNormal, UV * tiling).rgb;
	vec3 RBaseColor = texture(RBaseAlbedo, UV * tiling).rgb;
	vec3 RBaseDetail = texture(RBaseNormal, UV * tiling).rgb;
	vec3 ROverlayColor = texture(ROverlayAlbedo, UV * tiling).rgb;
	vec3 ROverlayDetail = texture(ROverlayNormal, UV * tiling).rgb;
	vec3 GBaseColor = texture(GBaseAlbedo, UV * tiling).rgb;
	vec3 GBaseDetail = texture(GBaseNormal, UV * tiling).rgb;
	vec3 GOverlayColor = texture(GOverlayAlbedo, UV * tiling).rgb;
	vec3 GOverlayDetail = texture(GOverlayNormal, UV * tiling).rgb;
	vec3 BBaseColor = texture(BBaseAlbedo, UV * tiling).rgb;
	vec3 BBaseDetail = texture(BBaseNormal, UV * tiling).rgb;
	vec3 BOverlayColor = texture(BOverlayAlbedo, UV * tiling).rgb;
	vec3 BOverlayDetail = texture(BOverlayNormal, UV * tiling).rgb;

	// Roughness & specular
	float roughness = 1.0;
	float specular = 0.1;

	// Mix overlays
	vec3 AColor = mix(ABaseColor, AOverlayColor, overlay);
	vec3 ADetail = mix(ABaseDetail, AOverlayDetail, overlay);
	vec3 RColor = mix(RBaseColor, ROverlayColor, overlay);
	vec3 RDetail = mix(RBaseDetail, ROverlayDetail, overlay);
	vec3 GColor = mix(GBaseColor, GOverlayColor, overlay);
	vec3 GDetail = mix(GBaseDetail, GOverlayDetail, overlay);
	vec3 BColor = mix(BBaseColor, BOverlayColor, overlay);
	vec3 BDetail = mix(BBaseDetail, BOverlayDetail, overlay);

	// Distance grass
	if (enableGrass)
	{
		float distanceToCamera = length(CAMERA_POSITION_WORLD - worldPosition);
		float grassBlend = smoothstep(farDistance, farDistance + 20.0, distanceToCamera);
		vec3 grassColor = texture(grassFar, UV * 40.0).rgb;
		AColor = mix(AColor, grassColor, grassBlend);
	}
	// Distance hay
	if (enableHay)
	{
		float distanceToCamera = length(CAMERA_POSITION_WORLD - worldPosition);
		float hayBlend = smoothstep(farDistance, farDistance + 20.0, distanceToCamera);
		vec3 hayColor = texture(hayFar, UV * 40.0).rgb;
		BColor = mix(BColor, hayColor, hayBlend);
		BColor = mix(BColor, vec3(0.02, 0.03, 0.01), hayBlend * smoothstep(0.0, 1.0, noise) * 0.5);
	}

	// Create masks
	float RMask = smoothstep(0.0, RBlend, COLOR.r);
	float GMask = smoothstep(0.0, GBlend, COLOR.g);
	float BMask = smoothstep(0.0, BBlend, COLOR.b);

	// Mix colors
	vec3 color = AColor;
	color = mix(color, RColor, RMask);
	color = mix(color, GColor, GMask);
	color = mix(color, BColor, BMask);

	// Mix details
	vec3 detail = ADetail;
	detail = mix(detail, RDetail, RMask);
	detail = mix(detail, GDetail, GMask);
	detail = mix(detail, BDetail, BMask);

	// Roads
	if (enableRoads)
	{
		float dirtMask = smoothstep(0.0, 0.5, roads.r) * RMask;
		float asphaltMask = smoothstep(0.0, 1.0, roads.g) * GMask;
		color = mix(color, RBaseColor, dirtMask);
		color *= mix(1.0, 1.4, dirtMask);
		color *= mix(1.0, 0.7, asphaltMask);
		float edgeMask = roads.b;
		color *= mix(1.0, 0.5, smoothstep(0.0, 1.0, edgeMask));
		detail = mix(detail, RBaseDetail, dirtMask);
	}
	
	// Bump
	if (enableBump)
	{
		float baseMask = clamp(1.0 - (RMask + GMask + BMask), 0.0, 1.0);
		float bumpMask = (baseMask * ABump) + (RMask * RBump) + (GMask * GBump) + (BMask * BBump);
		vec3 bump = texture(roadBump, UV * 50.0).rgb;
		detail = mix(detail, vec3(detail.xy + bump.xy - 0.5, 1.0), bumpMask);
	}
	
	// Trash
	if (enableTrash)
	{
		vec4 scatter = texture(trash, UV * 100.0).rgba;
		float trashMask = overlay * (RMask + GMask + BMask);
		float blend = scatter.a * trashMask;
		color = mix(color, scatter.rgb, blend);
		detail = mix(detail, vec3(0.5, 0.5, 1.0), blend);
	}
	
	// Snow
	if (enableSnow)
	{
		float snowMask = (1.0 - roads.r * COLOR.r) * (1.0 - roads.g * COLOR.g);
		vec3 snowDetail = texture(snowNormal, UV * 50.0).rgb;
		float snowDirection = worldNormal.y;
		float snowCoverage = snowDirection * detail.g + 1.0;
		float snowBlending = smoothstep(0.0, 1.0, snowCoverage - detail.r - noise);
		color += vec3(0.4) * snowBlending * Snow * snowMask;
		detail = mix(detail, snowDetail, snowBlending * Snow);
	}

	// Apply limiters
	float ALimiter = mix(ADryLimiter, AWetLimiter, Rain);
	float RLimiter = mix(RDryLimiter, RWetLimiter, Rain);
	float GLimiter = mix(GDryLimiter, GWetLimiter, Rain);
	float BLimiter = mix(BDryLimiter, BWetLimiter, Rain);

	// Mix specular
	specular = smoothstep(0.0, ALimiter, color.r);
	specular = mix(specular, smoothstep(0.0, RLimiter, color.r), RMask);
	specular = mix(specular, smoothstep(0.0, GLimiter, color.r), GMask);
	specular = mix(specular, smoothstep(0.0, BLimiter, color.r), BMask);

	// Rain
	if (enableRain)
	{
		// Ripples
		float ripples = texture(Ripples, UV * 300.0).r;
		float rippleMask = texture(Noise, UV * 200.0 + TIME / 10.0).r;
		rippleMask = smoothstep(0.5, 1.0, rippleMask);
		float rain = ripples * rippleMask * 1000.0 * Rain;

		// Wet road
		float roadNoise = texture(Noise, UV * 40.0).r;
		float wetRoad = smoothstep(0.0, roadNoise * 2.0, (roads.r * COLOR.r) + (roads.g * COLOR.g)) * Rain;
		roughness *= 1.0 - wetRoad - rain;
		specular *= 1.0 - wetRoad;
		specular += wetRoad * 0.15;

		// Puddles
		float puddleNoise = texture(Noise, UV * 10.0).r - wetRoad;
		float puddles = smoothstep(0.0, 1.0, puddleNoise) * Rain;
		roughness *= 1.0 - puddles - rain;
		specular *= 1.0 - puddles;
		specular += puddles * 0.1;

		// Reduction
		detail = mix(detail, vec3(0.5, 0.5, 1.0), wetRoad);
		color = mix(color, color * 0.5, wetRoad + puddles);
	}

	// Noise
	color *= mix(1.0, noise, 0.5);

	// Desaturation (Winter)
	float desaturation = mix(0.0, 0.5, Snow);
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(luminance), desaturation);
	
	if (debug)
	{
		ALBEDO = texture(checkerMap, UV * 60.0).rgb + smoothstep(0.1, 0.2, COLOR.rgb);
	}
	else
	{
		// Output
		ALBEDO = color;
		NORMAL_MAP = detail;
		NORMAL_MAP_DEPTH = 2.0;
		ROUGHNESS = roughness;
		SPECULAR = specular;
	}
}