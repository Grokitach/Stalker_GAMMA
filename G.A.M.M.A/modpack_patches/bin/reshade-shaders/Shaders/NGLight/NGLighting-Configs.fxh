#define AspectRatio BUFFER_WIDTH/BUFFER_HEIGHT

#ifndef UI_DIFFICULTY
 #define UI_DIFFICULTY 0
#endif

#ifndef SMOOTH_NORMALS
 #define SMOOTH_NORMALS 1
#endif

#ifndef RESOLUTION_SCALE_
 #define RESOLUTION_SCALE_ 0.67
#endif

//Tonemapping mode : 1 = Timothy Lottes || 0 = Reinhardt
#define TM_Mode 1
#define IT_Intensity 1
//clamps the maximum luma of pixels to avoid unsolvable fireflies
#define LUM_MAX 100

#define HLDIV 4 //multiply history length by this value before evaluating the radius
#define TemporalFilterDisocclusionThreshold 0.004
#define ANTI_LAG_ENABLED 1
//Motion Based Deghosting Threshold is the minimum value to be multiplied to the history length.
//Higher value causes more ghosting but less blur. Too low values might result in strong flickering in motion.
#define MBSDThreshold 0.05 //Default is 0.05
#define MBSDMultiplier 160 //Default is 90

//Temporal stabilizer Intensity
#define TSIntensity 0.99
//Temporal Stabilizer Clamping kernel shape
#define shape 8//4 for cross, 8 for square
#define TEMPORAL_STABILIZER_MINMAX_CLAMPING 1
#define TEMPORAL_STABILIZER_VARIANCE_CLIPPING 1
//Temporal Refine min blend value. lower is more stable but ghosty and too low values may introduce banding
#define TRThreshold 0.001

//Smooth Normals configs. It uses a separable bilateral blur which uses only normals as determinator. 
#define SNThreshold 2.5 //Bilateral Blur Threshold for Smooth normals passes. default is 0.5
#define SNDepthW FAR_PLANE*1*SNThreshold //depth weight as a determinator. default is 100/SNThreshold
#if SMOOTH_NORMALS <= 1 //13*13 8taps
 #define LODD 0.5    //Don't touch this for God's sake
 #define SNWidth 5.5 //Blur pixel offset for Smooth Normals
 #define SNSamples 1 //actually SNSamples*4+4!
#elif SMOOTH_NORMALS == 2 //16*16 16taps
 #define LODD 0.5
 #define SNWidth 2.5
 #define SNSamples 3
#elif SMOOTH_NORMALS > 2 //41*41 84taps
 #warning "SMOOTH_NORMALS 3 is slow and should to be used for photography or old games. Otherwise set to 2 or 1."
 #define LODD 0
 #define SNWidth 1
 #define SNSamples 30
#endif

#define STEPNOISE 1

#if !UI_DIFFICULTY
//simple UI mode preset
#define fov 50
#define UseCatrom false
#define SharpenGI false
#define TemporalRefine 0
#define RAYINC 2
#define RAYDEPTH 5
#define MVErrorTolerance 0.96
#define MAX_Frames 64
#define Sthreshold 0.003
#define AO_Radius_Background 1
#define AO_Radius_Reflection 0.25
#define SkyDepth 0.99
#endif
