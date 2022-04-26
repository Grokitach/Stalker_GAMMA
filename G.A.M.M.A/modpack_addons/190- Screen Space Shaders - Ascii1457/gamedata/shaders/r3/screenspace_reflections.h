#include "screenspace_common.h"

// [ SETTINGS ]
#define G_SSR_MAX_DISTANCE       		15.0f	// Max Ray distance. The reflection will reach far pixels. 
												// Lower numbers will improve the reflection coherency, but will eliminate some nice reflections

#define G_SSR_STEPS           			8		// Max ray steps. More steps = "better" quality / poor performance. ( 8 = low | 16 = medium | 32 = high )

#define G_SSR_INTENSITY         		0.8f 	// Reflection intensity
#define G_SSR_FLORA_INTENSITY 			0.04f	// Adjust grass and tree branches intensity

#define G_SSR_WEAPON_INTENSITY  		0.3f 	// Weapon & arms reflection intensity. 1.0f = 100% ~ 0.0f = 0% ( % in relation to G_SSR_INTENSITY )
#define G_SSR_WEAPON_MAX_LENGTH			1.1f	// Maximum distance to apply G_SSR_WEAPON_INTENSITY.

#define G_SSR_GLOSS_THRESHOLD			0.15f	// Omit surfaces with less gloss than... 0 = Opaque ~ 1 = Full gloss?


float4 SSFX_ssr_fast_ray(float3 ray_start_vs, float3 ray_dir_vs, uint iSample : SV_SAMPLEINDEX)
{
	// Initialize Ray
	RayTrace ssr_ray = SSFX_ray_init(ray_start_vs, ray_dir_vs, G_SSR_MAX_DISTANCE, G_SSR_STEPS, 1.0f);

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
		
		// Reflect this UV coor if... Ray intersect and is in front of the ray start position.
		bool Reflect = (ray_check.x >= 0 && (ray_depthstart - 1.0f) < ray_check.y);
		bool isSky = is_sky(ray_check.y);
		
		// Sky is safe
		if (Reflect || isSky)
			return float4(ssr_ray.r_pos, (float)isSky, abs(ray_depthstart - ray_check.y));
        
        // Step the ray
        ssr_ray.r_pos += ssr_ray.r_step;
    }

    return 0.0f;
}

void SSFX_ScreenSpaceReflections(float2 tc, float4 P, float3 N, float gloss, inout float3 color, uint iSample : SV_SAMPLEINDEX )
{
	// Don't want to waste time in low/non reflective pixels... Let's calc some things before trace a ray
	// Screen border fade
	float edgeFade = 1.0f - pow(length( tc.xy - 0.5f ) * 2.0f, 2.0f);
	
	// Tweak the gloss based on rain... ( Just a minor adjustment with ES ) 
#ifndef SSFX_ENHANCED_SHADERS 
	if (rain_params.x > 0)
		gloss *= clamp(P.z, 3.0f, 100.0f) * (1 - smoothstep(-100, 100, P.z)); // This is totally nonsense, just forcing the wet surfaces to look like what i want
	else
		gloss *= 2.0f;
#else
	gloss *= 2.0f;
#endif

	// Reflect intensity. Some limits to the gloss buffer and apply the edge fade
	float refl_power = clamp(gloss, 0, 2.0) * edgeFade;

	// Weapon Attenuation
	refl_power *= saturate(G_SSR_WEAPON_INTENSITY + smoothstep(G_SSR_WEAPON_MAX_LENGTH - 0.1f, G_SSR_WEAPON_MAX_LENGTH, length(P.xyz)));
	
	// Adjust the intensity of MAT_FLORA
	if (abs(P.w - MAT_FLORA) <= 0.05f)
		refl_power *= G_SSR_FLORA_INTENSITY;
		
	// Compute reflection bounce
	float3 inVec 	= normalize(P.xyz); // Incident
	float3 reVec	= normalize(reflect(inVec , N)); // Reflected
	
	// Fade out rays facing the camera
	refl_power *= 1 - smoothstep(-0.6f, 0.0f, dot(-inVec, reVec));
		
	// Discard low reflective pixels created in the border fade and intensity adjustments
	if (refl_power < G_SSR_GLOSS_THRESHOLD)
		return;
	
	// Calc SSR ray
	float3 hit_uv = SSFX_ssr_fast_ray(P.xyz, reVec, iSample);

	// Valid UV coor? SSFX_trace_ssr_ray return 0.0f if uv is out of bounds
	if (!all(hit_uv.xy))
		return;
	
	// Get the hit_uv coor from the scene+light
	float3 RayColor = SSFX_get_scenelighting(hit_uv.xy, iSample);
	
	// Adjust sky intensity, this is to deal with some extreme bright reflections ( hit_uv.z returns 1 if reflection comes from the sky )
	float sky_intensity = saturate( 1.5f - hit_uv.z );
	
	// Let's fade the reflection based on ray Y coor to avoid abrupt changes and glitches ( Reflections coming from below mid screen are full opacity )
	float ray_fade = hit_uv.y * 2;
	
	// Final reflection intencity
	refl_power = saturate(refl_power * sky_intensity * ray_fade * G_SSR_INTENSITY);
	
	// Add the color to the scene
	color = lerp(color, RayColor, refl_power ); 
}