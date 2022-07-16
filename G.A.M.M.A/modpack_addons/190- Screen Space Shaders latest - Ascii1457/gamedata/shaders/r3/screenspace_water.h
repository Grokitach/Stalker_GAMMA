// Screen Space Shaders - Water File
// Update 7 [ 2022/06/27 ]

#include "screenspace_common.h"
#include "settings_screenspace_WATER.h"

static const int2 q_steps[5] =
{
	int2(8,3),
	int2(16,2),
	int2(24,2),
	int2(32,2),
	int2(64,1)
};

float3 SSFX_ssr_water_ray(float3 ray_start_vs, float3 ray_dir_vs, float noise, uint iSample : SV_SAMPLEINDEX)
{
	// Some vars to use later...
	float4 prev_step;
	int prev_sign;
	float3 behind_hit = 0;

	float RayThick = clamp( 48.0f / q_steps[G_SSR_WATER_QUALITY].x, 1.0f, 3.0f);

	// Initialize Ray
	RayTrace ssr_ray = SSFX_ray_init(ray_start_vs, ray_dir_vs, 150, q_steps[G_SSR_WATER_QUALITY].x, noise); // 300?

	// Depth from the start of the ray
	float ray_depthstart = SSFX_get_depth(ssr_ray.r_start, iSample);

	// Ray-march
	[unroll (q_steps[G_SSR_WATER_QUALITY].x)]
	for (int step = 1; step <= q_steps[G_SSR_WATER_QUALITY].x; step++)
	{
		// Ray out of screen...
		if (!SSFX_is_valid_uv(ssr_ray.r_pos))
			return 0;

		// Ray intersect check ( x = difference | y = depth sample )
		float2 ray_check = SSFX_ray_intersect(ssr_ray, iSample);

		// Don't want interaction with weapons and sky ( SKY_EPS float(0.001) )
		ray_check.x *= ray_check.y > 1.3f;

		// Depth difference positive...
		if (ray_check.x > 0)
		{
			// Conditions to use as reflections...
			if (ray_check.x <= RayThick || (ray_depthstart + 40.0f < ray_check.y))
				return float3(ssr_ray.r_pos, ray_check.y);

			// Current ray pos & step to use later...
			prev_step.xy = ssr_ray.r_pos;
			prev_step.zw = ssr_ray.r_step;

			prev_sign = -1;

			// Binary Search
			for (int x = 0; x < q_steps[G_SSR_WATER_QUALITY].y; x++)
			{
				// Half and flip depending on depth difference sign
				if (sign(ray_check.x) != prev_sign)
				{
					ssr_ray.r_step *= -0.5f;
					prev_sign = sign(ray_check.x);
				}

				// Step ray
				ssr_ray.r_pos += ssr_ray.r_step;

				// Ray intersect check
				ray_check = SSFX_ray_intersect(ssr_ray, iSample);

				// Depth test... Conditions to use as reflections...
				if (abs(ray_check.x) <= RayThick)
					return float3(ssr_ray.r_pos, ray_check.y);
			}

			// Restore previous ray position & step
			ssr_ray.r_pos = prev_step.xy;
			ssr_ray.r_step = prev_step.zw;
			ssr_ray.r_pos += ssr_ray.r_step;
		}
		else
		{
			// Sample behind... Let's use this coor to fill...
			behind_hit = float3(ssr_ray.r_pos, ray_check.y);

			// Reset or keep depending on... ( > 1.3f = no interaction with weapons and sky )
			behind_hit *= (ray_depthstart - 2.0f < ray_check.y) && ray_check.y > 1.3f;
		}

		// Step ray
		ssr_ray.r_pos += ssr_ray.r_step;
	}

	return behind_hit;
}
