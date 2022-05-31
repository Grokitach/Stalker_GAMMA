// [ SETTINGS ] [ WATER ]

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
#define G_SSR_WATER_SHADOWS				0.55f	// Shadows intensity

#define G_SSR_WATER_CHEAPFRESNEL				// Uncomment/comment this if you want to use a faster/accurate fresnel calc