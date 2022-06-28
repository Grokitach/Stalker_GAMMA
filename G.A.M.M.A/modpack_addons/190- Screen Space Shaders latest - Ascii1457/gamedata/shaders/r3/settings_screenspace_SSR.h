// [ SETTINGS ] [ SCREEN SPACE REFLECTIONS ]

#define G_SSR_MAX_DISTANCE       		15.0f	// Max Ray distance. The reflection will reach far pixels. 
												// Lower numbers will improve the reflection coherency, but will eliminate some nice reflections

#define G_SSR_STEPS           			8		// Max ray steps. More steps = "better" quality / poor performance. ( 8 = low | 16 = medium | 32 = high )

#define G_SSR_INTENSITY         		0.8f 	// Reflection intensity
#define G_SSR_FLORA_INTENSITY 			0.04f	// Adjust grass and tree branches intensity

#define G_SSR_WEAPON_INTENSITY  		0.3f 	// Weapon & arms reflection intensity. 1.0f = 100% ~ 0.0f = 0% ( % in relation to G_SSR_INTENSITY )
#define G_SSR_WEAPON_MAX_LENGTH			1.1f	// Maximum distance to apply G_SSR_WEAPON_INTENSITY.

#define G_SSR_GLOSS_THRESHOLD			0.15f	// Omit surfaces with less gloss than... 0 = Opaque ~ 1 = Full gloss?