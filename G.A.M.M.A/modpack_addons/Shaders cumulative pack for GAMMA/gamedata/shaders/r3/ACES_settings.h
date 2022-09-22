//=================================================================================================
//Defines for and variables for ACES and color grading
//=================================================================================================
#define USE_ACES //Use ACES tonemapping and color space
#define USE_LOG_GRADING //Use log space to prevent clipping
//=================================================================================================

//
//manual settings
//
/*
	Slope = float3(1.000, 1.000, 1.000);
	Offset = float3(0.000, 0.000, 0.000);
	Power = float3(1.000, 1.000, 1.000);
	Saturation = 1.000;
*/
//
//settings for supporting in-game console commands
//
	Slope = shader_param_1.rgb + shader_param_1.w; 	//brightness
	Offset = shader_param_2.rgb + shader_param_2.w; 		//color grading
	Power = shader_param_3.rgb + shader_param_3.w; 		//color grading
	Saturation = pp_img_corrections.z; 	//saturation	