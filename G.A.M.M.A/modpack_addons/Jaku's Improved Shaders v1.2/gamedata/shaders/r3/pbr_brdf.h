//=================================================================================================
//Pseudo PBR shading for STALKER Anomaly
//Roughness is controlled with r2_gloss_min
//GGX unfucked by LVutner
//GGX un-unfucked by Jaku
//=================================================================================================
#include "pbr_settings.h" //load settings files
#define CUBE_MIPS 5 //mipmaps for ambient shading and specular
static const float Pi = 3.141592653589;

float3 calc_albedo(float3 diffuse, float material_ID)
{
#ifdef USE_PBR
	float3 albedo = SRGBToLinear(diffuse) * ALBEDO_AMOUNT;
#else
	float3 albedo = SRGBToLinear(diffuse);
#endif
	return saturate(albedo);
}

float calc_rough(float gloss, float material_ID)
{
	float rough = 0.0;
	bool m_terrain = abs(material_ID - 0.95) <= 0.02f;
	bool m_weapon = abs(material_ID - 0.323) <= 0.0279f;
	bool m_flora = abs(material_ID - 0.47451) <= 0.05f;

	#ifdef USE_PBR
		rough = lerp(ROUGHNESS_HIGH, ROUGHNESS_LOW, pow(gloss, ROUGHNESS_POW)); //gloss to roughness
		rough = pow(rough, 1/(1.0-(Ldynamic_color.w))); //gloss factor
		rough *= 1.0f + (0.22f * m_terrain) + (0.16f * m_flora); // Increase roughness if terrain or flora

		if (rain_params.y >= 0.01 && m_weapon)
				rough -= lerp(0.0,0.1,rain_params.y);  // Decrease roughness based on wetness

	#else
		rough = lerp(0.5, .25, material_ID);
		rough *= rough;
	#endif

	return clamp(0.001, 1.0, rough);
}

float3 calc_f0(float gloss, float material_ID)
{
	#ifdef USE_PBR
		float3 specular = SPECULAR_BASE; //base fresnel to tweak
		specular *= SPECULAR_RANGE * max(0,((0.5+material_ID) * (0.5+gloss)) - 0.25); //0.0 - 2.0 fresnel multiplier
		//specular *= SPECULAR_RANGE * max(0, (1-material_ID) + (gloss));
		specular = pow(specular, SPECULAR_POW);
	#else
		float3 specular = SPECULAR_BASE;
	#endif

	return saturate(specular);
}

float3 F_Schlick(float3 f0, float3 f90, float lDotH)
{
	return f0 + (1 - f0) * pow(1 - lDotH, 5);
}

//Normal distribution function for GGX (Trowbridge-Reitz)
float NDF_GGX(float NdotH, float alpha)
{
    alpha *= alpha;
    float denominator = NdotH * NdotH * (alpha - 1.0) + 1.0;
    return alpha / (Pi * denominator * denominator);
}

float G_Smith(float m2, float nDotX)
{
	//m2 = m2*0.5; //remapping for GGX
	m2 = m2 * 0.797884560802865; //remapping for beckmann/blinn (sqrt(2/pi))
	return nDotX / (nDotX * (1 - m2) + m2);
}

float G2_Smith(float NdotL, float NdotV, float alpha)
{
	alpha *= alpha;
	float GGXV = NdotL / (NdotL * (1.0 - alpha) + alpha);
	float GGXL = NdotV / (NdotV * (1.0 - alpha) + alpha);
	return GGXV * GGXL;
}

//https://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html
float G2_Smith_Optimized(float NoL, float NoV, float a)
{
	float a2 = a*a;
	float G_V = NoV + sqrt( (NoV - NoV * a2) * NoV + a2 );
	float G_L = NoL + sqrt( (NoL - NoL * a2) * NoL + a2 );
	return G_V * G_L;
}

float3 GGX(float NdotL, float NdotH, float NdotV, float LdotH, float3 F0, float roughness)
{
	float alpha = roughness*roughness;

	//Normal distribution
	float D = NDF_GGX(NdotH, alpha);

	//Fresnel
	float3 F = F_Schlick(F0, 1.0, LdotH);

	//Shadowing
	float G = G2_Smith(NdotL,NdotV,alpha);

	return D * G * F;
}

float3 Blinn(float nDotL, float nDotH, float nDotV, float lDotH, float3 f0, float rough)
{
	float gloss = 1-rough;
	gloss = gloss*gloss;
	gloss = exp2(gloss*10);

	float d = pow(nDotH, gloss);
	d *= (gloss+8)/(8); //blinn normalized without pi, (n+6)/8 might be better?

	float m2 = rough * rough;
	float v1i = G_Smith(m2, nDotL);
	float v1o = G_Smith(m2, nDotV);
	float vis = v1i * v1o;

	//float vis = ceil(nDotL); //don't bother with vis

	float3 f = F_Schlick(f0, 1, lDotH);

	return d * f * vis;
}

float3 Lit_Diffuse(float nDotL, float nDotH, float nDotV, float lDotH, float3 f0, float rough)
{
	return pow(nDotL, lerp(1.125, 0.75, rough));
}

float3 Lit_Specular(float nDotL, float nDotH, float nDotV, float lDotH, float3 f0, float rough)
{
	#ifdef USE_GGX_SPECULAR
		return GGX(nDotL, nDotH, nDotV, lDotH, f0, rough); //GGX is much more expensive but looks nicer
	#else
		return Blinn(nDotL, nDotH, nDotV, lDotH, f0, rough); //much cheaper pbr blinn
	#endif
}

float3 Lit_BRDF(float rough, float3 albedo, float3 f0, float3 V, float3 N, float3 L, float mat_id)
{
	bool m_weapon = abs(mat_id - 0.323) <= 0.0279f;

	float3 H = normalize(V + L);
	float nDotL = max(0, dot(N, L));
	float nDotV = max(0 + (0.068 * m_weapon), dot(N, V)); // Fix shadows on some problematic weapons
	float lDotH = max(1e-5, dot(L, H));
	float nDotH = max(0, dot(N, H));

	float3 F = F_Schlick(f0, 1.0, nDotL);

	float3 diffuse_term = (1 - F) * (1.05 / Pi) * (1 - pow(1 - nDotL, 5)) * albedo;
	float3 specular_term = Lit_Specular(nDotL, nDotH, nDotV, lDotH, f0, rough);

	return diffuse_term + specular_term;
}

//=================================================================================================
//Ambient
//

float3 CubeDiffuse (float rough, TextureCube cubeMap, float3 nw)
{
	float3 nwRemap = nw;
	float3 vnormabs    = abs(nwRemap);
	float  vnormmax    = max(vnormabs.x, max(vnormabs.y, vnormabs.z));
        nwRemap      /= vnormmax;

        if (nwRemap.y < 0.999)
        nwRemap.y= nwRemap.y*2-1;     // fake remapping

	nwRemap = normalize(nwRemap);

	float3 nSquared = nw * nw;
	const float Epsilon = 0.000001;
	float3 DiffuseColor = 0;
	DiffuseColor += nSquared.x * cubeMap.SampleLevel(smp_rtlinear, float3(nwRemap.x, Epsilon, Epsilon), CUBE_MIPS);
	DiffuseColor += nSquared.y * cubeMap.SampleLevel(smp_rtlinear, float3(Epsilon, nwRemap.y, Epsilon), CUBE_MIPS);
	DiffuseColor += nSquared.z * cubeMap.SampleLevel(smp_rtlinear, float3(Epsilon, Epsilon, nwRemap.z), CUBE_MIPS);

	return DiffuseColor;
}

float3 CubeSpecular (float rough, TextureCube cubeMap, float3 vreflect, float3 mat_id)
{
	float RoughMip = rough * CUBE_MIPS;
	float3 SpecularColor = cubeMap.SampleLevel(smp_rtlinear, vreflect, RoughMip);
	bool m_weapon = abs(mat_id - 0.323) <= 0.0279f;
	//return SpecularColor;
	return SpecularColor * (0.45 + (0.15 * m_weapon)); // Reduce effects of cube specular, helps with SSR not reflecting too much cubemap color
}

//UE4 mobile approx
float3 EnvBRDFApprox(float3 SpecularColor, float Roughness, float NoV )
{
	const float4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const float4 c1 = { 1, 0.0425, 1.04, -0.04 };
	float4 r = Roughness * c0 + c1;
	float a004 = min(r.x * r.x, exp2(-9.28 * NoV ) ) * r.x + r.y;
	float2 AB = float2(-1.04, 1.04 ) * a004 + r.zw;
	return SpecularColor * AB.x + AB.y;
}

//Black Ops 2 approximation https://blog.selfshadow.com/publications/s2013-shading-course/lazarov/s2013_pbs_black_ops_2_notes.pdf
float3 EnvironmentBRDF(float g, float NoV, float3 rf0)
{
  float4 t = float4(1 / 0.96, 0.475, (0.0275 - 0.25 * 0.04) / 0.96, 0.25);
  t *= float4(g, g, g, g);
  t += float4(0, 0, (0.015 - 0.75 * 0.04) / 0.96, 0.75);
  float a0 = t.x * min(t.y, exp2(-9.28 * NoV)) + t.z;
  float a1 = t.w;
  return saturate(lerp(a0, a1, rf0));
}

//https://learnopengl.com/PBR/IBL/Diffuse-irradiance
float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
    return F0 + (max(1.0 - roughness, F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

float3 Amb_BRDF(float rough, float3 albedo, float3 f0, float3 env_d, float3 env_s, float3 V, float3 N)
{
	float nDotV = max(0.0, dot(N, V));
	//float3 kS = fresnelSchlickRoughness(max(dot(N, V), 0.0), f0, rough);
	//float3 kD = 1.0 - kS;

	float3 diffuse_term = env_d * albedo;
	float3 specular_term = env_s * EnvironmentBRDF(1.0-rough, nDotV, f0);

	return saturate(diffuse_term + specular_term);
}
