//=================================================================================================
//Pseudo PBR shading for STALKER Anomaly 
//Roughness is controlled with r2_gloss_min
//=================================================================================================
#include "pbr_settings.h" //load settings files
#define CUBE_MIPS 5 //mipmaps for ambient shading and specular
const float Pi = 3.14159265359;

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
#ifdef USE_PBR
	float rough = lerp(ROUGHNESS_HIGH, ROUGHNESS_LOW, pow(gloss, ROUGHNESS_POW)); //gloss to roughness
	rough = pow(rough, 1/(1.01-Ldynamic_color.w)); //gloss factor
#else
	float rough = lerp(0.5, .25, material_ID);
	rough *= rough;
#endif
	return saturate(rough);
}

float3 calc_f0(float gloss, float material_ID)
{

	float foliage = saturate(20*(abs(material_ID-0.47)-0.05)); //foliage
	//gloss *= foliage;
	material_ID *= foliage;

#ifdef USE_PBR
	float3 specular = SPECULAR_BASE; //base fresnel to tweak
	specular *= SPECULAR_RANGE * max(0,((0.5+material_ID) * (0.5+gloss)) - 0.25); //0.0 - 2.0 fresnel multiplier
	specular = pow(specular, SPECULAR_POW);
#else
	float3 specular = SPECULAR_BASE; //non-PBR use f0 as specmap
#endif

	return saturate(specular);
}

float3 F_Shlick(float3 f0, float3 f90, float lDotH)
{
	return lerp(f0, f90, pow(1-lDotH, 5));
}

float G_GGX(float m2, float nDotX)
{
	return 1.0 / (nDotX + sqrt(m2 + (1 - m2) * nDotX * nDotX));
}

float3 GGX(float nDotL, float nDotH, float nDotV, float lDotH, float3 f0, float rough)
{
	float a_2 = rough * rough;
	
	float d = a_2 / (pow(nDotH * nDotH * (a_2 - 1) + 1, 2)); //no pi in denom
	
	float visL = G_GGX(a_2, nDotL);
	float visV = G_GGX(a_2, nDotV);
	float vis = visL * visV;
	
	float3 f = F_Shlick(f0, 1.0, lDotH);
	return d * f * vis * nDotL;
}

float G_Smith(float m2, float nDotX)
{
	//m2 = m2*0.5; //remapping for GGX
	m2 = m2 * 0.797884560802865; //remapping for beckmann/blinn (sqrt(2/pi))
	return nDotX / (nDotX * (1 - m2) + m2);
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
	
	float3 f = F_Shlick(f0, 1, lDotH);

	return d * f * vis;
}

float3 Lit_Diffuse(float nDotL, float nDotH, float nDotV, float lDotH, float3 f0, float rough)
{
	return pow(nDotL, lerp(1.125, 0.75, rough)*1.5); // aesthetic tweak to roughness
}

float3 Lit_Specular(float nDotL, float nDotH, float nDotV, float lDotH, float3 f0, float rough)
{
#ifdef USE_GGX_SPECULAR
	return GGX(nDotL, nDotH, nDotV, lDotH, f0, rough); //GGX is much more expensive but looks nicer
#else
	return Blinn(nDotL, nDotH, nDotV, lDotH, f0, rough); //much cheaper pbr blinn 
#endif
}

float3 Lit_BRDF(float rough, float3 albedo, float3 f0, float3 V, float3 N, float3 L )
{
	float3 H = normalize(V + L );
	
	float nDotL = max(0, dot(N, L));
	float nDotH = max(0, dot(N, H));
	float nDotV = max(0, dot(N, V));
	float lDotH = max(0, dot(L, H));
	
	float3 diffuse_term = Lit_Diffuse(nDotL, nDotH, nDotV, lDotH, f0, rough);
	diffuse_term *= albedo;
	
	float3 specular_term = Lit_Specular(nDotL, nDotH, nDotV, lDotH, f0, rough);
	
	return diffuse_term + specular_term;
}

//=================================================================================================
//Ambient
//

float3 CubeDiffuse (float rough, samplerCUBE cubeMap, float3 nw)
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
	DiffuseColor  += nSquared.x * texCUBEbias(cubeMap , float4(nwRemap.x, Epsilon, Epsilon, CUBE_MIPS));
	DiffuseColor  += nSquared.y * texCUBEbias(cubeMap , float4(Epsilon, nwRemap.y, Epsilon, CUBE_MIPS)); 
	DiffuseColor  += nSquared.z * texCUBEbias(cubeMap , float4(Epsilon, Epsilon, nwRemap.z, CUBE_MIPS));
	
	return DiffuseColor;
}

float3 CubeSpecular (float rough, samplerCUBE cubeMap, float3 vreflect)
{
	float RoughMip = rough * CUBE_MIPS; 
	//float3 SpecularColor = texCUBEbias(cubeMap , float4(vreflect.xyz, RoughMip));
	float3 SpecularColor = texCUBElod(cubeMap , float4(vreflect.xyz, RoughMip));

	return SpecularColor;
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

float3 Amb_BRDF(float rough, float3 albedo, float3 f0, float3 env_d, float3 env_s, float3 V, float3 N)
{
	float nDotV = max(0, dot(N, V));
	
	float3 diffuse_term = env_d * albedo; 
	
	float3 specular_term = env_s * EnvBRDFApprox(f0, rough, nDotV );
	
	return diffuse_term + specular_term;
}