/**
 * @ Version: SCREEN SPACE SHADERS - UPDATE 8
 * @ Description: SSR implementation
 * @ Modified time: 2022-07-15 00:50
 * @ Author: https://www.moddb.com/members/ascii1457
 * @ Mod: https://www.moddb.com/mods/stalker-anomaly/addons/screen-space-shaders
 */

#include "screenspace_common.h"
#include "settings_screenspace_SSR.h"

float4 SSFX_ssr_fast_ray(float3 ray_start_vs, float3 ray_dir_vs, uint iSample : SV_SAMPLEINDEX)
{
	float2 sky_tc = -1;
	float2 behind_hit = 0;

	// Initialize Ray
	RayTrace ssr_ray = SSFX_ray_init(ray_start_vs, ray_dir_vs, 50, G_SSR_STEPS, 1.0f);

	// Depth from the start of the ray
	float ray_depthstart = SSFX_get_depth(ssr_ray.r_start, iSample);
	
	// Ray-march
	[unroll (G_SSR_STEPS)]
	for (int i = 0; i < G_SSR_STEPS; i++)
	{
		// Ray out of screen...
		if (!SSFX_is_valid_uv(ssr_ray.r_pos))
			return 0.0f;

		// Ray intersect check
		float2 ray_check = SSFX_ray_intersect(ssr_ray, iSample);

		ray_check.x *= ray_check.y > 1.3f;

		if (ray_check.x > 0)
		{
			return float4(ssr_ray.r_pos, -1, -1);
		}
		else
		{
			if (sky_tc.x == -1 && is_sky(ray_check.y))
				sky_tc = ssr_ray.r_pos;

			behind_hit = ssr_ray.r_pos;

			// Reset or keep depending on... ( > 1.3f = no interaction with weapons and sky )
			behind_hit *= (ray_depthstart - 2.0f < ray_check.y) && ray_check.y > 1.3f;
		}

		// Step the ray
		ssr_ray.r_pos += ssr_ray.r_step;
	}

	return float4(behind_hit, sky_tc);
}


void SSFX_ScreenSpaceReflections(float2 tc, float4 P, float3 N, float gloss, inout float3 color, uint iSample : SV_SAMPLEINDEX)
{
	// Note: Distance falloff on rain_patch_normal.ps

	// Let's start with pure gloss.
	float refl_power = gloss;

	// Adjust the intensity of MAT_FLORA
	if (abs(P.w - MAT_FLORA) <= 0.05f)
		refl_power *= G_SSR_FLORA_INTENSITY;
	
	// Calc reflection bounce
	float3 inVec = normalize(P.xyz); // Incident
	float3 reVec = (reflect(inVec , N)); // Reflected
	
	// Fade out rays facing the camera
	refl_power *= 1.0f - smoothstep(-1.0f, 0.0f, dot(-inVec, reVec));

	// Discard low reflective pixels
	if (refl_power < 0.001f)
		return;

	// Calc SSR ray
	float4 hit_uv = SSFX_ssr_fast_ray(P.xyz, reVec, iSample);

	float3 RayColor = 0;
	float ray_fade = 1.0f;

	// Valid UV coor? SSFX_trace_ssr_ray return 0.0f if uv is out of bounds or sky.
	if (all(hit_uv.xy))
	{
		RayColor = SSFX_get_scene(hit_uv.xy, iSample);

		// Let's fade the reflection based on ray XY coor to avoid abrupt changes and glitches
		ray_fade = SSFX_calc_SSR_fade(hit_uv.xy, 0.0f, G_SSR_WATER_SCREENFADE);
	}
	else
	{
		// Skybox reflection vector
		float3	nw		= mul(m_inv_V, N);
		float3	v2point	= mul(m_inv_V, inVec);
		
		// Get Sky...
#ifdef G_SSR_CHEAP_SKYBOX
		RayColor = SSFX_calc_env(reflect(v2point, nw)) * G_SSR_SKY_INTENSITY;
#else
		RayColor = SSFX_calc_sky(reflect(v2point, nw)) * G_SSR_SKY_INTENSITY;
#endif

		// Let's fade the sky based on ray ZW coor to avoid abrupt changes and glitches
		ray_fade = SSFX_calc_SSR_fade(hit_uv.zw, 0.0f, G_SSR_WATER_SCREENFADE);

		// Reset gloss.
		refl_power = gloss;
	}
	
	// Weapon Attenuation.
	float WeaponFactor = smoothstep(G_SSR_WEAPON_MAX_LENGTH - 0.2f, G_SSR_WEAPON_MAX_LENGTH, length(P.xyz));
	
	// Apply weapon attenuation and limit max weapon gloss.
#ifndef G_SSR_WEAPON_REFLECT_ONLY_WITH_RAIN
	float weapon_att = clamp( G_SSR_WEAPON_INTENSITY + WeaponFactor, 0, saturate(G_SSR_WEAPON_MAX_INTENSITY + WeaponFactor));
#else
	float weapon_att = clamp( G_SSR_WEAPON_INTENSITY * rain_params.x + WeaponFactor, 0, saturate(G_SSR_WEAPON_MAX_INTENSITY + WeaponFactor));
#endif

	// Final reflection intencity.
	refl_power = saturate(refl_power * ray_fade * weapon_att * G_SSR_INTENSITY);

	// Add the color to the scene.
	color = lerp(color, RayColor, refl_power); 
}