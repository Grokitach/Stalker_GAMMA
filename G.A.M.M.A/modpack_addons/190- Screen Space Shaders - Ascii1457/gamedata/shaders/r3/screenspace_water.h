#include "screenspace_common.h"

// [ SETTINGS ]
#define G_SSR_WATER_STEPS				8		// Max ray steps. More steps = "better" quality / poor performance. ( 8 = low | 16 = medium | 32 = high )
#define G_SSR_WATER_BINARYSEARCH		4		// Steps to check if reflection is correct. ( 4 = low | 8 = high )

#define G_SSR_WATER_WAVES		 		2.0f	// Water waves intensity
#define G_SSR_WATER_REFRACTION		 	0.05f	// Intensity of refraction distortion
#define G_SSR_WATER_REFLECTION			0.35f	// Reflection intensity
#define G_SSR_WATER_TEX_DISTORTION		0.1f	// Water texture distortion

#define G_SSR_WATER_RAIN			 	0.4f	// Max intensity of rain drops
#define G_SSR_WATER_SPECULAR		 	6.0f	// Sun/Moon specular intensity

#define G_SSR_WATER_CAUSTICS		 	0.3f	// Caustics intensity
#define G_SSR_WATER_SOFTBORDER			0.1f	// Soft border factor. 0.0f = hard edge

#define G_SSR_WATER_CHEAPFRESNEL				// Uncomment/comment this if you want to use a faster/accurate fresnel calc


float3 SSFX_ssr_water_ray(float3 ray_start_vs, float3 ray_dir_vs, float noise, uint iSample : SV_SAMPLEINDEX)
{
	// Initialize Ray
	RayTrace ssr_ray = SSFX_ray_init(ray_start_vs, ray_dir_vs, 200.0f, G_SSR_WATER_STEPS, noise);
	
	// Depth from the start of the ray
	float ray_depthstart = SSFX_get_depth(ssr_ray.r_start, iSample);
	
    // Ray-march
	[unroll (G_SSR_WATER_STEPS)]
    for (int i = 0; i < G_SSR_WATER_STEPS; i++)
    {
        // Ray out of screen...
        if (!SSFX_is_valid_uv(ssr_ray.r_pos))
            return 0.0f;
			
        // Ray intersect check	
		float2 ray_check = SSFX_ray_intersect(ssr_ray, iSample);
		
		if (is_sky(ray_check.y))
			return float3(0.0f, 0.0f, 0.0f);
			
        if (ray_check.x >= 0)
        {		
			// If depth_scene is in front for a good amount, use this reflection...
			if (ray_depthstart + 10.0f < ray_check.y)
				return float3(ssr_ray.r_pos, 1.0f);
				
            float previous_sign = -1.0f;
			
			// Binary Search
			[unroll (G_SSR_WATER_BINARYSEARCH)]
            for (int x = 0; x < G_SSR_WATER_BINARYSEARCH; x++)
            {
                // Depth test
                if (abs(ray_check.x) <= 1.0)
                    return float3(ssr_ray.r_pos, 1.0f);

                // Half and flip
                if (sign(ray_check.x) != previous_sign)
                {
                    ssr_ray.r_step *= -0.5f;
                    previous_sign = sign(ray_check.x);
                }

                // Step ray
                ssr_ray.r_pos += ssr_ray.r_step;
				
                // Ray intersect check
				ray_check = SSFX_ray_intersect(ssr_ray, iSample);
            }

			// Discarted
			return 0.0f;
        }
			
        // Step the ray
        ssr_ray.r_pos += ssr_ray.r_step;
    }

    return 0.0f;
}