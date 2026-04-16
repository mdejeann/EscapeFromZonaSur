shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal : hint_normal, filter_linear_mipmap;
global uniform float Wind;

void vertex()
{
	float displacement = 1.0;
	float UVx = UV.x;
	float windDisplacement = displacement * UVx * (1.0 - UVx);
	float windEffect = mix(0.1, 1.0, Wind);
	float windOffset = sin(TIME * 2.0 + UVx * 5.0) * windDisplacement * windEffect;
	vec3 windOutput = vec3(0.1, 0.1, 0.1) * windOffset;
	VERTEX += windOutput;
}

void fragment()
{
	vec3 color = texture(albedo, UV * vec2(10.0, 1.0)).rgb;
	vec3 detail = texture(normal, UV * vec2(5.0, 1.0)).rgb;
	ALBEDO = color;
	NORMAL_MAP = detail;
	ROUGHNESS = 0.4;
	SPECULAR = 0.2;
}