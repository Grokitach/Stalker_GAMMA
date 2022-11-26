//=================================================================================================
//Settings for PBR conversion
//=================================================================================================
#define USE_PBR //Use physically based specular
#define USE_GGX_SPECULAR //use more expensive GGX specular
//=================================================================================================
#define ALBEDO_AMOUNT 1.00

#define ROUGHNESS_LOW 0.01   // 0.4 // 0.45
#define ROUGHNESS_HIGH 1.00 // 1.00
#define ROUGHNESS_POW 0.35  // 0.25 // 0.35

#define SPECULAR_BASE 0.02  // 0.056 // f0 = 2%
#define SPECULAR_RANGE 1.35  // 1 // f0max = 1.25 = "5%"
#define SPECULAR_POW 1.0      // 1
