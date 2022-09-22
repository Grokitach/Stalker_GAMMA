// [ SETTINGS ] [ SCREEN SPACE REFLECTIONS ]

#define G_SSR_QUALITY					2		// Quality of the SSR. ( 0 = Very low | 1 = Low | 2 = Medium | 3 = High | 4 = Very High | 5 = Ultra )

#define G_SSR_SCREENFADE				0.15f	// Screen border fade. ( 0.0f = No border fade )

#define G_SSR_INTENSITY					0.6f	// Global reflection intensity ( 1.0f = 100% ~ 0.0f = 0% )
#define G_SSR_MAX_INTENSITY				0.4f	// Global reflection MAX intensity.
#define G_SSR_SKY_INTENSITY				0.5f	// Sky reflection intensity ( 1.0f = 100% ~ 0.0f = 0% )
#define G_SSR_FLORA_INTENSITY 			0.5f	// Adjust grass and tree branches intensity
#define G_SSR_TERRAIN_BUMP_INTENSITY	0.4f	// Terrain bump intensity ( Lower values will generate cleaner reflections )

#define G_SSR_WEAPON_INTENSITY  		0.37f	// Weapons & arms reflection intensity. ( 1.0f = 100% ~ 0.0f = 0% )
#define G_SSR_WEAPON_MAX_INTENSITY		0.016f	// Weapons & arms MAX intensity.
#define G_SSR_WEAPON_MAX_LENGTH			2.0f	// Maximum distance to apply G_SSR_WEAPON_INTENSITY.
#define G_SSR_WEAPON_RAIN_FACTOR		0.2f	// Weapons reflections boost when raining ( 0 to disable ) ( Affected by rain intensity )

//#define G_SSR_WEAPON_REFLECT_ONLY_WITH_RAIN	// Uncomment this if you don't want weapon reflections unless is raining
#define G_SSR_CHEAP_SKYBOX					// Use a faster skybox to improve some performance.