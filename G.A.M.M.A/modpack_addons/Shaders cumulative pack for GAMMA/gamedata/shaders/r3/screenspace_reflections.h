/**
 * @ Version: SCREEN SPACE SHADERS - UPDATE 11
 * @ Description: SSR implementation
 * @ Modified time: 2022-09-20 03:20
 * @ Author: https://www.moddb.com/members/ascii1457
 * @ Mod: https://www.moddb.com/mods/stalker-anomaly/addons/screen-space-shaders
 */

#include "screenspace_common.h"
#include "settings_screenspace_SSR.h"

static const int2 q_ssr_steps[6] =
{
	int2(8,200),
	int2(16,35),
	int2(24,18),
	int2(32,5),
	int2(48,1),
	int2(64,1),
};

static const float q_ssr_noise[6] =
{
	float(0.04f),
	float(0.04f),
	float(0.04f),
	float(0.06f),
	float(0.08f),
	float(0.08f),
};

float4 SSFX_ssr_fast_ray(float3 ray_start_vs, float3 ray_dir_vs, float2 tc, uint iSample : SV_SAMPLEINDEX)
{
	float2 sky_tc = 0;
	float2 behind_hit = 0;

	// Noise to "improve" consistency between steps
	float3 noise = SSFX_noise(tc * float2(70,35) * 20) * q_ssr_noise[G_SSR_QUALITY];

	// Initialize Ray
	RayTrace ssr_ray = SSFX_ray_init(ray_start_vs, ray_dir_vs, 150, q_ssr_steps[G_SSR_QUALITY].x, 1.0f);

	// Depth from the start of the ray
	float ray_depthstart = SSFX_get_depth(ssr_ray.r_start, iSample);
	
	// Ray-march
	[unroll (q_ssr_steps[G_SSR_QUALITY].x)]
	for (int i = 0; i < q_ssr_steps[G_SSR_QUALITY].x; i++)
	{
		// Ray out of screen...
		if (!SSFX_is_valid_uv(ssr_ray.r_pos))
			return 0;

		// Ray intersect check
		float2 ray_check = SSFX_ray_intersect(ssr_ray, iSample);

		// Sampled depth is not weapon or sky ( SKY_EPS float(0.001) )
		bool NoWpnSky = ray_check.y > 1.3f;

		// Disable weapon and sky
		ray_check.x *= NoWpnSky;

		// Return if ray is not reflecting backward
		if (ray_check.x > 0)
		{
			if (ray_check.x <= q_ssr_steps[G_SSR_QUALITY].y)
				return float4(ssr_ray.r_pos, 0, 0);

#if G_SSR_QUALITY > 2 // 1 Binary Search step in higher quality options ( Quality 4 & 5 )
			
			// Current ray pos & step to restore later...
			float4 prev_step = 0;
			prev_step.xy = ssr_ray.r_pos;
			prev_step.zw = ssr_ray.r_step;

			// Half and flip
			ssr_ray.r_step *= -0.5f;

			// Step ray
			ssr_ray.r_pos += ssr_ray.r_step;

			// Ray intersect check
			ray_check = SSFX_ray_intersect(ssr_ray, iSample);

			// Depth test... Conditions to use as reflections...
			if (abs(ray_check.x) <= 1.25f)
				return float4(ssr_ray.r_pos, 0, 0);

			// Restore previous ray position & step
			ssr_ray.r_pos = prev_step.xy;
			ssr_ray.r_step = prev_step.zw;

#endif

		}
		else
		{
			// TexCoor for sky ( Used to fade "SSFX_calc_SSR_fade" )
			if (ray_check.y <= SKY_EPS)
				sky_tc = ssr_ray.r_pos;
			
			behind_hit = ssr_ray.r_pos;

			// Reset or keep depending on... ( > 1.3f = no interaction with weapons and sky )
			behind_hit *= (ray_depthstart - 2.0f < ray_check.y) && NoWpnSky;
		}

		// Step the ray
		ssr_ray.r_pos += ssr_ray.r_step * (1.0f + noise.x * (1.0f - smoothstep(0, q_ssr_steps[G_SSR_QUALITY].x * 0.33f, i)));
	}

	return float4(behind_hit, sky_tc);
}


void SSFX_ScreenSpaceReflections(float2 tc, float4 P, float3 N, float gloss, inout float3 color, uint iSample : SV_SAMPLEINDEX)
{
	// Note: Distance falloff on "rain_patch_normal.ps"
	
	// Material conditions ( MAT_FLORA and Terrain for now... )
	bool m_skyalways = abs(P.w - 0.95f) <= 0.02f;
	bool m_flora = abs(P.w - MAT_FLORA) <= 0.02f;

	// Let's start with pure gloss.
	float refl_power = gloss;
	
	// Calc reflection bounce
	float3 inVec = normalize(P.xyz); // Incident
	float3 reVec = reflect(inVec , N); // Reflected

	// Transform space and calc reflection vector ( Skybox & Fresnel )
	float3 nw		 = mul(m_inv_V, N);
	float3 v2point	 = mul(m_inv_V, inVec);
	float3 v2reflect = reflect(v2point, nw);

	// Fresnel
	float fresnel = saturate (dot(v2reflect, v2point));
	float fresnel_amount = pow(fresnel, 3);
	refl_power *= fresnel_amount;

	float4 hit_uv = 0;

	// Calc SSR ray. Discard low reflective pixels
	if (refl_power > 0.02f)
		hit_uv = SSFX_ssr_fast_ray(P.xyz, reVec, tc, iSample);

	float3 refl_ray;
	float3 reflection = 0;
	float2 uvcoor = 0;

	// Sky is the reflection base...
#ifdef G_SSR_CHEAP_SKYBOX
	reflection = SSFX_calc_env(v2reflect) * G_SSR_SKY_INTENSITY;
#else
	reflection = SSFX_calc_sky(v2reflect) * G_SSR_SKY_INTENSITY;
#endif

	// Valid UV coor? SSFX_trace_ssr_ray return 0.0f if uv is out of bounds or sky.
	if (all(hit_uv.xy))
	{
		// Get scene reflection
		refl_ray = SSFX_get_scene(hit_uv.xy, iSample);

		// Limit extremely bright pixels
		refl_ray *= saturate(0.25f + (length(refl_ray) < 1.8f));

		// Set reflection UV
		uvcoor = hit_uv.xy;

		// Let's fade the reflection based on ray XY coor to avoid abrupt changes and glitches
		float HitFade = SSFX_calc_SSR_fade(hit_uv.xy, 0.0f, G_SSR_SCREENFADE);

		// Mix base reflection ( skybox ) with ray reflection
		reflection = lerp(reflection, refl_ray, HitFade);
	}
	else
	{
		// Reset gloss.
		refl_power = gloss * fresnel_amount;

		// Set reflection UV
		uvcoor = hit_uv.zw;
	}

	// Fade sky if !skyalways ( Terrain MAT )
	float ray_fade = saturate(SSFX_calc_SSR_fade(uvcoor, 0.0f, G_SSR_SCREENFADE) + 1.0f * m_skyalways);

	// Adjust the intensity of MAT_FLORA
	refl_power *= saturate(G_SSR_FLORA_INTENSITY + 1.0f * !m_flora);

	// Weapon Attenuation factor.
	float WeaponFactor = smoothstep(G_SSR_WEAPON_MAX_LENGTH - 0.2f, G_SSR_WEAPON_MAX_LENGTH, length(P.xyz));
	
	// Global intensity and limit max value.
	float main_clamp = clamp(refl_power * G_SSR_INTENSITY, 0, G_SSR_MAX_INTENSITY);
	
	// Raise reflection intensity and max limit using wetness accumulation (rain_params.y)
	float rain_extra = G_SSR_WEAPON_RAIN_FACTOR * rain_params.y;

	// Weapon intensity and limit max value.
	float wpn_clamp = clamp((refl_power + rain_extra) * G_SSR_WEAPON_INTENSITY, 0, G_SSR_WEAPON_MAX_INTENSITY + rain_extra);

	#ifdef G_SSR_WEAPON_REFLECT_ONLY_WITH_RAIN
		wpn_clamp *= rain_params.x;
	#endif

	// Lerp between general reflections and weapon reflections.
	refl_power = lerp(wpn_clamp, main_clamp, WeaponFactor);

	// Apply SSR fade to reflection.
	refl_power *= ray_fade;

	// Add the reflection to the scene.
	color = lerp(color, reflection, refl_power);
}