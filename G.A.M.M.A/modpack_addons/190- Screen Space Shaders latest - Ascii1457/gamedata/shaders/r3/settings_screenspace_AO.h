// [ SETTINGS ] [ AMBIENT OCCLUSION ]

#define G_SSDO_RENDER_DIST 				120.0f 	// Max rendering distance.
	
#define G_SSDO_RADIUS 					0.3f	// AO radius, higher values means more occlusion coverage with less details.
#define G_SSDO_INTENSITY 				4.0f 	// General AO intensity.
#define G_SSDO_ATTENUATION 				0.5f 	// Fade out occlusion. Higher values will fade the occlusion faster the farther from the occluder.

#define G_SSDO_MAX_OCCLUSION			0.1f 	// Maximum obscurance for a pixel. 0 = full black
#define G_SSDO_SMOOTH 					1.3f 	// AO softer. Higher occluded pixels will be more affected than less occluded.

#define G_SSDO_WEAPON_LENGTH 			1.5f 	// Maximum distance to apply G_SSDO_WEAPON_RADIUS, G_SSDO_WEAPON_INTENSITY, etc.
#define G_SSDO_WEAPON_RADIUS 			0.01f	// Weapon radius, higher values means more occlusion coverage with less details.
#define G_SSDO_WEAPON_INTENSITY			0.25f	// Weapon intensity. [ 1.0f = 100% ]
#define G_SSDO_WEAPON_ATTENUATION		0.04f	// Weapon fade out occlusion. Higher values will fade the occlusion faster the farther from the occluder.

//#define G_SSDO_COLORBLEEDING					// Enables color bleeding. ( Simulate a basic indirect lighting )
#define G_SSDO_COLORBLEEDING_POWER		0.5f	// Indirect lighting intensity.
#define G_SSDO_COLORBLEEDING_VIBRANCE	5.0f	// Indirect lighting vibrance.

//#define G_SSDO_SECOND_PASS					// Add a second pass. By default more detailed. ( 30% of G_SSDO_RADIUS )
#define G_SSDO_SECOND_PASS_RADIUS		0.3f	// Second pass porcentual radius. [ 1.0f = 100% ]