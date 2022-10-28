//=================================================================================================
//Pseudo PBR shading for STALKER Anomaly 
//Roughness is controlled with r2_gloss_min
//GGX unfucked by LVutner
//=================================================================================================
#include "pbr_settings.h" //load settings files
#define CUBE_MIPS 5 //mipmaps for ambient shading and specular
#define MAT_FLORA 0.47451
static const float Pi = 3.14159265359;

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
float rough = lerp(0.5, 1.25, material_ID); // All materials will be affected by shiny GGX, mostly guns with the various filters afterwards

if (abs(material_ID - MAT_FLORA) <= 0.02f)  // folliage materials
     rough = lerp(0.4, 2.7, material_ID); 

if (abs(material_ID - 0.196) <= 0.02f)   // hands, maybe NPCs and some annoying models like swamp tall grass
     rough = lerp(0.8, 2.7, material_ID); 

if (abs(material_ID - 0.95) <= 0.02f)    // ground, walls, etc
	rough = lerp(0.4, 1.9, material_ID); 
	
rough = pow(rough, 1/(1.01-Ldynamic_color.w));
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
	float3 specular = SPECULAR_BASE;
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

//Normal distribution function for GGX
float NDF_GGX(float NdotH, float alpha)
{
    alpha *= alpha;
    float denominator = (NdotH * alpha - NdotH) * NdotH + 1.0;
    return alpha / (3.14 * denominator * denominator);
}

//Lambda used in G2-G1 functions
float Lambda_Smith(float NdotX, float alpha)
{    
    float alpha_sqr = alpha * alpha;
    float NdotX_sqr = NdotX * NdotX;
    return (-1.0 + sqrt(alpha_sqr * (1.0 - NdotX_sqr) / NdotX_sqr + 1.0)) * 0.5;
}

//Height Correlated Masking-shadowing function
float G2_Smith(float NdotL, float NdotV, float alpha)
{
	float lambdaV = Lambda_Smith(NdotV, alpha);
	float lambdaL = Lambda_Smith(NdotL, alpha);

	return 1.0 / (1.0 + lambdaV + lambdaL);
}

float3 GGX(float NdotL, float NdotH, float NdotV, float VdotH, float3 F0, float roughness)
{
	//Alpha
	float alpha = clamp(roughness * roughness, 1.0/255.0, 1.0);

    //Normal distribution function
    float NDF = NDF_GGX(NdotH, alpha);
    
    //Masking-shadowing
    float G2 = G2_Smith(NdotL, NdotV, alpha);
    
    //Fresnel
    float3 F = F_Shlick(F0, 1.0, VdotH);
    
    //Numerator
    float3 numerator = NDF * G2 * F;
    
    //Denominator
    float denominator = max(4.0 * NdotV, 1e-8);
    
    //Output
    return numerator / denominator;
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
	return pow(nDotL, lerp(1.125, 0.75, rough)*0.3); // aesthetic tweak to roughness
}

float3 Lit_Specular(float nDotL, float nDotH, float nDotV, float lDotH, float3 f0, float rough)
{
#ifdef USE_GGX_SPECULAR
	return GGX(nDotL, nDotH, nDotV, lDotH, f0, rough*1.15); //GGX is much more expensive but looks nicer
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

float3 CubeSpecular (float rough, TextureCube cubeMap, float3 vreflect)
{
	float RoughMip = rough * CUBE_MIPS;
	float3 SpecularColor = cubeMap.SampleLevel(smp_rtlinear, vreflect, RoughMip); 

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