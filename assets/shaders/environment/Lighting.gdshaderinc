// Custom lighting ----------------------------------------

float diffuse_burley(float cNdotL, float cNdotV, float cHdotL, float sigma)
{
	float FD90 = 2.0 * sigma * cHdotL * cHdotL - 0.5;
	float fd_L = 1.0 + (FD90) * pow(1.0 - cNdotL, 5.0);
	float fd_V = 1.0 + (FD90) * pow(1.0 - cNdotV, 5.0);
	return  fd_V * fd_L * cNdotL * 0.318309;
}
vec3 specular_schlick_ggx(float cNdotL, float cNdotV, float cHdotN, float cHdotL, vec3 rho, float sigma, float m, float s)
{
	float a = sigma * sigma;
	float a2 = a * a;
	float D = 1.0 + (a2 - 1.0) * cHdotN * cHdotN;
	D = a2 / (PI * D * D);
	float G = 0.5 / mix(2.0 * cNdotL * cNdotV, cNdotL + cNdotV, a);
	float dielectric = 0.16 * s * s;
	vec3 f0 = mix(vec3( dielectric ), rho, vec3( m ));
	float f90 = clamp(dot(f0, vec3(16.5)), m, 1.0);
	vec3 F = f0 + (f90 - f0) * pow(1.0 - cHdotL, 5.0);
	return max(D * G * F * cNdotL, 0.0);
}
void custom(vec3 color, vec3 tint, float limiter, float specular, bool metal, float roughness, float metallic, vec3 normal, vec3 light, vec3 view, vec3 albedo, float attenuation, vec3 lightColor, inout vec3 _DIFFUSE, inout vec3 _SPEC)
{
	color * tint.rgb;
	vec3 n = normalize(normal);
	vec3 l = normalize(light);
	vec3 v = normalize(view);
	vec3 h = normalize(v + l);
	float NdotL = dot(n, l);
	float NdotV = dot(n, v);
	float HdotN = dot(h, n);
	float HdotL = dot(h, l);
	float cNdotL = max(NdotL, 0.0);
	float cNdotV = max(NdotV, 0.0);
	float cHdotN = max(HdotN, 0.0);
	float cHdotL = max(HdotL, 0.0);
	float diff = diffuse_burley(cNdotL, cNdotV, cHdotL, roughness);
	vec3 spec = specular_schlick_ggx(cNdotL, cNdotV, cHdotN, cHdotL, albedo, roughness, metallic, specular * smoothstep(0.0, limiter, color.r));
	
	if (metal)
	{
		_DIFFUSE += lightColor * attenuation * smoothstep(0.0, 1.0, diff);
		_SPEC += lightColor * attenuation * spec * 5.0;
	}
	else
	{
		_DIFFUSE += lightColor * attenuation * diff;
		_SPEC += lightColor * attenuation * spec;
	}
}