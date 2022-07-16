// [ SETTINGS ] [ SCREEN SPACE REFLECTIONS ]

#define G_SSR_STEPS						8		// Max ray steps. More steps = better quality / poor performance. ( 8 = low | 16 = medium | 24 = high | 32 = Very High )

#define G_SSR_WATER_SCREENFADE			0.25f	// Screen border fade. ( 0.0f = No border fade )

#define G_SSR_INTENSITY					1.5f	// Reflection intensity ( 1.0f = 100% )
#define G_SSR_SKY_INTENSITY				0.6f	// Sky reflection intensity ( 1.0f = 100% )
#define G_SSR_FLORA_INTENSITY 			0.01f	// Adjust grass and tree branches intensity

#define G_SSR_WEAPON_INTENSITY  		1.0f	// Weapons & arms reflection intensity. ( 1.0f = 100% ~ 0.0f = 0% [ % in relation to G_SSR_INTENSITY ] )
#define G_SSR_WEAPON_MAX_INTENSITY		0.4f	// Weapons & arms max intensity.
#define G_SSR_WEAPON_MAX_LENGTH			1.3f	// Maximum distance to apply G_SSR_WEAPON_INTENSITY.

//#define G_SSR_WEAPON_REFLECT_ONLY_WITH_RAIN	// Uncomment this if you don't want weapon reflections unless is raining
//#define G_SSR_CHEAP_SKYBOX					// Use a faster skybox to improve some performance.