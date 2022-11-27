#ifndef	LMODEL_H
#define LMODEL_H

#include "common.h"
#include "common_brdf.h"
#include "pbr_brdf.h"

//////////////////////////////////////////////////////////////////////////////////////////
// Lighting formulas

float4 compute_lighting(float3 N, float3 V, float3 L, float4 alb_gloss, float mat_id)
{
	float3 albedo = calc_albedo(alb_gloss.rgb, mat_id);
	float3 f0 = calc_f0(alb_gloss.a, mat_id);
	float rough = calc_rough(alb_gloss.a, mat_id);
	bool m_flora = abs(mat_id - 0.47451) <= 0.05f;

#ifdef USE_PBR
	float4 light = float4(Lit_BRDF(rough, albedo, f0, V, N, L, mat_id), 0);
#else
	float spec = SRGBToLinear(alb_gloss.w*Ldynamic_color.w);
	float4 light = float4(Lit_BRDF(rough, 0, f0, V, N, L, mat_id), 0);
	light *= spec;
	light.rgb += max(0,dot(N,L))*albedo;
	light = float4(light.rgb,0);
#endif

	//if(mat_id == MAT_FLORA)
	if(m_flora) //Be aware of precision loss/errors
	{
		//Simple subsurface scattering
		float subsurface = SSS(N,V,L);
		light.rgb += saturate(subsurface*albedo);
	}

	return light;
}

float4 plight_infinity(float m, float3 pnt, float3 normal, float4 c_tex, float3 light_direction )
{
	//gsc vanilla stuff
	float3 N = normalize(normal);							// normal
	float3 V = -normalize(pnt);					// vector2eye
	float3 L = -normalize(light_direction);						// vector2light

	float4 light = compute_lighting(N,V,L,c_tex,m);

	return light; // output (albedo.gloss)
}

float4 plight_local(float m, float3 pnt, float3 normal, float4 c_tex, float3 light_position, float light_range_rsq, out float rsqr )
{
	float3 N = normalize(normal);							// normal
	float3 L2P = pnt - light_position;                       		// light2point
	float3 V = -normalize(pnt);					// vector2eye
	float3 L = -normalize((float3)L2P);					// vector2light
	float3 H = normalize(L+V);						// float-angle-vector
		rsqr = dot(L2P,L2P);					// distance 2 light (squared)
	float att = SRGBToLinear(saturate(1 - rsqr*light_range_rsq));			// q-linear attenuate

	float4 light = compute_lighting(N,V,L,c_tex,m);

	return saturate(att*light);		// output (albedo.gloss)
}

float3 specular_phong(float3 pnt, float3 normal, float3 light_direction)
{
	float3 H = normalize(pnt + light_direction );
	float nDotL = max(0, dot(normal, light_direction));
	float nDotH = max(0, dot(normal, H));
	float nDotV = max(0, dot(normal, pnt));
	float lDotH = max(0, dot(light_direction, H));
	return L_sun_color.rgb * Lit_Specular(nDotL, nDotH, nDotV, lDotH, 0.052, 0.1);
}

//	TODO: DX10: Remove path without blending
half4 blendp(half4 value, float4 tcp)
{
	return 	value;
}

half4 blend(half4 value, float2 tc)
{
	return 	value;
}

#endif
