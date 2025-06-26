/**
 * @ Version: SCREEN SPACE SHADERS - UPDATE 22
 * @ Description: SSS implementation
 * @ Modified time: 2024-11-25 02:19
 * @ Author: https://www.moddb.com/members/ascii1457
 * @ Mod: https://www.moddb.com/mods/stalker-anomaly/addons/screen-space-shaders
 */

uniform float4 ssfx_sss; // Dir Len, Omni Len, Grass Shadows, -

#include "screenspace_common.h"
#include "settings_screenspace_SSS.h"

Texture2D 	s_hud_mask;

float SSFX_ScreenSpaceShadows(float4 P, float3 N, float2 tc, float HudMask, uint iSample)
{
	// Weapon Mask
	bool IsHUD = HudMask <= 0;

	float pLen = length(P.xyz);

	// Distance Factor
	float DFactor = saturate((pLen - 80) * 0.01f);

	// Adjust Settings for weapons and scene.
	float ray_detail	= lerp(G_SSS_DETAIL, 0.05f, pLen * 0.02f);
	float ray_thick		= lerp(0.2f, 10, DFactor);
	float ray_len		= lerp(1.0, 20, DFactor);

	ray_len *= saturate(P.z); // Limit the ray_len to avoid issues when surfaces are extremely close

	if (IsHUD)
	{
		ray_detail = 0;
		ray_len = G_SSS_WEAPON_LENGTH;
		ray_thick = 1.0f;
	}

	RayTrace sss_ray = SSFX_ray_init(P, -L_sun_dir_e, ray_len * ssfx_sss.x, SSFX_SSS_DIR_QUALITY, hash12(tc * 100 + timers.xx * 100));

	[unroll (SSFX_SSS_DIR_QUALITY)]
	for (int i = 0; i < SSFX_SSS_DIR_QUALITY; i++)
	{
		// Break the march if ray go out of screen...
		if (!SSFX_is_valid_uv(sss_ray.r_pos))
			return 1;

		// Sample current ray pos ( x = difference | y = sample depth | z = current ray len )
		float3 depth_ray = SSFX_ray_intersect(sss_ray, iSample);
		
		// Check depth difference
		float diff = depth_ray.x;
		
		// No Sky
		if (depth_ray.y <= SKY_EPS)
			return 1;

		// Disable weapons at some point to avoid wrong shadows on the ground
		if (!IsHUD)
			diff *= depth_ray.y >= 1.0f;

		// Negative: Ray is closer to the camera ( not occluded )
		// Positive: Ray is beyond the depth sample ( occluded )
		if (diff > ray_detail && diff < ray_thick)
			return saturate(1.0f - G_SSS_INTENSITY);

		// Step the ray + Noise
		sss_ray.r_pos += sss_ray.r_step * (1.0f + hash12((tc * 100) + timers.xx * 100));
	}

	// None
	return 1;
}



float SSFX_ScreenSpaceShadows_Point(float4 P, float2 tc, float3 LightPos, float HudMask, uint iSample)
{
	// Light vector
	float3 L_dir = -normalize(P.xyz - LightPos);

	// Material conditions...
	bool mat_flora = abs(P.w - MAT_FLORA) <= 0.04f;

	// Weapon Mask
	bool IsHUD = HudMask <= 0;

	// Adjust Settings for weapons and scene.
	float ray_detail	= G_SSS_DETAIL;
	float ray_thick		= 0.2f;
	float ray_len		= 0.5f;

	// Grass overwrite.
	if (IsHUD)
	{
		ray_thick = 1.0f;
		ray_len = 0.06f;
	}
	else
	{
		if (mat_flora)
		{
			ray_thick = 10.0f;
			ray_len = 0.5f;
		}
	}

	RayTrace sss_ray = SSFX_ray_init(P, L_dir, ray_len * ssfx_sss.y, SSFX_SSS_OMNI_QUALITY, hash12(tc * 100 + timers.xx * 100));

	[unroll (SSFX_SSS_OMNI_QUALITY)]
	for (int i = 0; i < SSFX_SSS_OMNI_QUALITY; i++)
	{
		// Break the march if ray go out of screen...
		if (!SSFX_is_valid_uv(sss_ray.r_pos))
			return 1;

		// Sample current ray pos ( x = difference | y = sample depth | z = current ray len )
		float3 depth_ray = SSFX_ray_intersect(sss_ray, iSample);
		
		// Check depth difference
		float diff = depth_ray.x;
		
		// No Sky
		if (depth_ray.y <= SKY_EPS)
			return 1;

		// Disable weapons at some point to avoid wrong shadows on the ground
		if (!IsHUD)
			diff *= depth_ray.y >= 1.0f;

		// Negative: Ray is closer to the camera ( not occluded )
		// Positive: Ray is beyond the depth sample ( occluded )
		if (diff > ray_detail && diff < ray_thick)
			return 1.0f - saturate(G_SSS_INTENSITY - smoothstep( SSFX_SSS_OMNI_QUALITY * 0.5f, SSFX_SSS_OMNI_QUALITY + 1, i));

		// Step the ray
		sss_ray.r_pos += sss_ray.r_step * (1.0f + hash12((tc * 100) + timers.xx * 100));
	}

	return 1;
}