//night_vision.h - to define functions and variables for all 3 generations
#include "common.h"

///////////////////////////////////////////////////////
//      BEEF'S SHADER BASED NIGHT VISION EFFECT      //
///////////////////////////////////////////////////////
// Huge credit TO LVutner from Anomaly Discord, who  //
// literally taught me everything I know, to Sky4Ace //
// who's simple_blur function I've adapted for this  //
// shader, and to Meltac, who provided some advice   //
// and inspiration for developing this shader.       //
///////////////////////////////////////////////////////
// Note: You are free to distribute and adapt this   //
// Shader and any components, just please provide    //
// credit to myself and/or the above individuals. I  //
// have provided credit for individual functions and //
// their original authors where applicable.	- BEEF   //
///////////////////////////////////////////////////////

///////////////////////////////////////////////////////
// STEP 0 - GLOBAL DEFINITIONS AND INCLUDES
///////////////////////////////////////////////////////

//////// GLOBAL SETTINGS(ALL GENERATIONS)//////// 

// NVG POSITIONING OPTIONS: in (X, Y) format. If X is 0, it's L edge of screen, if 1, it's right edge of screen. Note that it's not linear across the screen.
		#define nvg_gen_1_centered float2(0.5f,0.5f)		// Gen 1 monocular without offset
		#define nvg_gen_2_offset_1 float2(0.25f,0.5f)		// Offset for Gen 2 left eye
		#define nvg_gen_2_offset_2 float2(0.75f,0.5f)		// Offset for Gen 2 right eye
		#define nvg_gen_3_offset_1 float2(0.05f,0.5f)		// Offset for Gen 3 outer left tube
		#define nvg_gen_3_offset_2 float2(0.3f,0.5f)		// Offset for Gen 3 inner left tube
		#define nvg_gen_3_offset_3 float2(0.7f,0.5f)		// Offset for Gen 3 inner right tube
		#define nvg_gen_3_offset_4 float2(0.95f,0.5f)		// Offset for Gen 3 outer right tube
		#define nvg_gen_1_offset float2(0.75f,0.5f)			// Offset for Gen 1 monocular
		#define nvg_gen_1_offset_flipped float2 (1-nvg_gen_1_offset.x, 1-nvg_gen_1_offset.y) // inverse of nvg_gen_1_offset (To allow switching L/R side of screen)
		#define circle_radius float (0.5f)
// NVG BLUR OPTIONS: (DEPTH INFLUENCED, CLOSE OBJECTS ARE AT MAX BLUR, FAR OBJECTS ARE AT MIN BLUR)
		#define gen_1_min_blur_factor float (0.25) 			// Gen 1 - minimum blur applied to image (at far distance), 1 is no blur, higher is more
		#define gen_1_max_blur_factor float (0.95) 					// maximum blur applied to image (at camera)
		#define gen_2_min_blur_factor float (0.2) 			// Gen 1 - minimum blur applied to image (at far distance), 1 is no blur, higher is more
		#define gen_2_max_blur_factor float (0.8) 					// maximum blur applied to image (at camera)
		#define gen_3_min_blur_factor float (0.1) 			// Gen 1 - minimum blur applied to image (at far distance), 1 is no blur, higher is more
		#define gen_3_max_blur_factor float (0.6) 					// maximum blur applied to image (at camera)

// NVG VISION DISTANCE (LIGHT ATTENTUATION - FEWER PHOTONS FROM FAR OBJECTS HIT THE INTENSIFIER TUBE AND THEREFORE APPEAR DARKER)
		#define gen_1_max_vision_distance float (250)			// How far away do objects appear completely dark for Gen 1 NVG
		#define gen_1_min_vision_distance float(30.0)				// How close does light attenutation begin to take effect (default 0.0)
		#define gen_1_dim_threshold float (0.7)					// Pixels brighter than this aren't dimmed, since they're likely light sources
		#define gen_2_max_vision_distance float (400)			// How far away do objects appear completely dark for Gen 1 NVG
		#define gen_2_min_vision_distance float(30.0)				// How close does light attenutation begin to take effect (default 0.0)
		#define gen_2_dim_threshold float (0.7)					// Pixels brighter than this aren't dimmed, since they're likely light sources
		#define gen_3_max_vision_distance float (600)			// How far away do objects appear completely dark for Gen 1 NVG
		#define gen_3_min_vision_distance float(30.0)				// How close does light attenutation begin to take effect (default 0.0)
		#define gen_3_dim_threshold float (0.7)					// Pixels brighter than this aren't dimmed, since they're likely light sources

// LIGHT AMPLIFICATION VALUES
	//	#define nvg_light_amplificiation float (8)			// How much brigher does the image get before NVG processing 

// LUMA SHARPEN VALUES
	
// NVG BLOOM OPTIONS (AKA WASHOUT EFFECT):
		#define gen_1_bloom_threshold (0.11)						// Threshold from 0 to 1 of how bright the pixel should be for bloom (0 is black, 0.5 is middle gray, 1.0 is bright white - default about 0.9 looks good)
		#define gen_1_bloom_multiplier float (2.5)				// How much transparency to apply to bloom effect (0.0 = full bloom, 0.5 = 50%, 1.0 = no bloom)
		#define gen_2_bloom_threshold (0.18)						// Threshold from 0 to 1 of how bright the pixel should be for bloom (0 is black, 0.5 is middle gray, 1.0 is bright white - default about 0.9 looks good)
		#define gen_2_bloom_multiplier float (2)				// How much transparency to apply to bloom effect (0.0 = full bloom, 0.5 = 50%, 1.0 = no bloom)
		#define gen_3_bloom_threshold (0.29)						// Threshold from 0 to 1 of how bright the pixel should be for bloom (0 is black, 0.5 is middle gray, 1.0 is bright white - default about 0.9 looks good)
		#define gen_3_bloom_multiplier float (2)				// How much transparency to apply to bloom effect (0.0 = full bloom, 0.5 = 50%, 1.0 = no bloom)
// NVG CRT / NOISE VALUES
		
		#define gen_1_crt_effect_factor float(0.05)				// How much CRT effect to add to NVG image (0 = none, 1 = max) (CRT effect makes it look like an old school Cathode Ray Tube television)
		#define gen_1_nvg_noise_factor float (0.15)				// How much noise to add to NVG image (0.04 is default, anything greater than 0.15 is insane)
		#define gen_1_scintillation_constant float (0.999f) 		// The closer the number is to 1.00000, the less scintillation effect. 0.9995f is a good default value. 0.9990 is stronger.
		
		#define gen_2_crt_effect_factor float(0.2)				// How much CRT effect to add to NVG image (0 = none, 1 = max) (CRT effect makes it look like an old school Cathode Ray Tube television)
		#define gen_2_nvg_noise_factor float (0.15)				// How much noise to add to NVG image (0.04 is default, anything greater than 0.15 is insane)
		#define gen_2_scintillation_constant float (0.9993f) 		// The closer the number is to 1.00000, the less scintillation effect. 0.9995f is a good default value. 0.9990 is stronger.
	
		#define gen_3_crt_effect_factor float(0.4)				// How much CRT effect to add to NVG image (0 = none, 1 = max) (CRT effect makes it look like an old school Cathode Ray Tube television)
		#define gen_3_nvg_noise_factor float (0.15)				// How much noise to add to NVG image (0.04 is default, anything greater than 0.15 is insane)
		#define gen_3_scintillation_constant float (0.9995f) 		// The closer the number is to 1.00000, the less scintillation effect. 0.9995f is a good default value. 0.9990 is stronger.
		
// NVG COLOR OPTIONS:
		#define gen_1_saturation_color float3 (0.4,1,0.1)	// Gen1 NVG color - it defines the max amount of color from 0 to 1 using (Red,Green,Blue)
		#define gen_2_saturation_color float3 (0.3,1,0.3)	// Gen1 NVG color - it defines the max amount of color from 0 to 1 using (Red,Green,Blue)
		#define gen_3_saturation_color float3 (0.1,1,0.8)	// Gen1 NVG color - it defines the max amount of color from 0 to 1 using (Red,Green,Blue)

// LUMA Sharpen

// NVG VIGNETTE AMOUNT
		#define gen_1_vignette_amount float (0.1f)
		#define gen_2_vignette_amount float (0.08f)
		#define gen_3_vignette_amount float	(0.05f)
		
///////////////////////////////////////////////////////
// DEFINE NVG MASK (Credit to LVutner for huge assistance in designing the functions)
///////////////////////////////////////////////////////
float compute_lens_mask(float2 masktc, float nvg_gen)
{
	if (nvg_gen == 1) // for Gen 1 NVG
		{
			return step(distance(masktc,nvg_gen_1_offset), circle_radius);
		}
	else if (nvg_gen == 10) // for Gen 1 NVG, but flipped (Left side vs right side) aka Gen 10 NVG
		{
			return step(distance(masktc,nvg_gen_1_offset_flipped), circle_radius);
		}
	else if (nvg_gen == 11) // for Gen 1 NVG, but centered
		{
			return step(distance(masktc,nvg_gen_1_centered), circle_radius);
		}
	else if (nvg_gen == 2) // for Gen 2 NVGs
		{
			if ( (step(distance(masktc,nvg_gen_2_offset_1), circle_radius) == 1) || (step(distance(masktc,nvg_gen_2_offset_2), circle_radius) == 1))
				{
				return 1;
				}
			else
				{
				return 0;
				}
		}
	else if (nvg_gen == 3) // for Gen 3 NVGs
		{
		if  (((step(distance(masktc,nvg_gen_3_offset_1), circle_radius) == 1) || (step(distance(masktc,nvg_gen_3_offset_2), circle_radius) == 1)) || ((step(distance(masktc,nvg_gen_3_offset_3), circle_radius) == 1) || (step(distance(masktc,nvg_gen_3_offset_4), circle_radius) == 1)))
				{
				return 1;
				}
			else
				{
				return 0;
				}
		}
	else
	{
		return 0;
	}
}

///////////////////////////////////////////////////////
// ASPECT RATIO CORRECTION (Credit LVutner)
///////////////////////////////////////////////////////
float2 aspect_ratio_correction (float2 tc)
	{
	tc.x -= 0.5f;
    tc.x *= (screen_res.x / screen_res.y);
    tc.x += 0.5f;
	return tc;
	}

///////////////////////////////////////////////////////
// CURVED TEXTURE COORDINATES FOR CRT EFFECT (adapted from "MattiasCRT" on ShaderToy, credit Mattias)
///////////////////////////////////////////////////////
float2 curve_texturecoords(float2 curved_tc)
{
	curved_tc = (curved_tc - 0.5) * 2.0;
	curved_tc *= 1.1;	
	curved_tc.x *= 1.0 + pow((abs(curved_tc.y) / 5.0), 2.0);
	curved_tc.y *= 1.0 + pow((abs(curved_tc.x) / 4.0), 2.0);
	curved_tc  = (curved_tc / 2.0) + 0.5;
	curved_tc =  curved_tc *0.92 + 0.04;
	return curved_tc;
}


///////////////////////////////////////////////////////
// Exposure Increaser
///////////////////////////////////////////////////////
float3 exposer_increaser( float3 image, float gray, float exposure)
{
     float b=4*(exposure-1);
	 float a=1-b;
	 float f= gray*(a*gray+b);
	 return f*image;
}

///////////////////////////////////////////////////////
// CRT EFFECT (adapted from MattiasCRT on ShaderToy, credit Mattias)
///////////////////////////////////////////////////////
float3 make_crt_ified(float3 fragColor, float2 tc )
{
	//float2 screen_res = screen_res.xy; // define screen res variable
    float2 uv = curve_texturecoords(tc);
    float3 col;
	float x =  sin(0.3*timers.x+uv.y*21.0)*sin(0.7*timers.x+uv.y*29.0)*sin(0.3+0.33*timers.x+uv.y*31.0)*0.0017;

	col.r = fragColor.r;
	col.g = fragColor.g;
	col.b = fragColor.b;
	
	col.r += 0.08f * fragColor.r;
	col.g += 0.05f * fragColor.g;
   	col.b += 0.08f * fragColor.b;

    col = clamp(col*0.6+0.4*col*col*1.0,0.0,1.0);

    float vig = (0.0 + 1.0*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y));
	col *= float(pow(abs(vig),0.3));

    col *= float3(0.95,1.05,0.95);
	col *= 2.8;
	
	float scans = clamp( 0.35+0.35*sin(uv.y*screen_res.y*2.0), 0.0, 1.0);
	
	float s = pow(scans,1.7);
	col = col*float( 0.4+0.7*s) ;

    col *= 1.0+0.01*sin(110.0*timers.x);
	if (uv.x < 0.0 || uv.x > 1.0)
		col *= 0.0;
	if (uv.y < 0.0 || uv.y > 1.0)
		col *= 0.0;
	
	col*=1.0-0.65*float(clamp(((tc.x % 2.0)-1.0)*2.0,0.0f,1.0f));
	
    float comp = smoothstep( 0.1, 0.9, sin(timers.x) );
 
    fragColor = col;
	return fragColor;
}

///////////////////////////////////////////////////////
// LUMA SHARPEN	(adapted from  Simple Luma Sharpen on ShaderToy, credit xwize)
///////////////////////////////////////////////////////

float3 YUVFromRGB( float3 color)
{
	return float3 (color.r * 0.299 + color.g * 0.587 + color.b * 0.114,
					color.r * -0.147 + color.g * -0.289 + color.b * 0.436,
					color.r * 0.615 + color.g * -0.515 + color.b * -0.100);
}

float3 RGBFromYUV ( float3 color)
{
	return float3 (color.r * 1.0 + color.b * 1.140,
					color.r * 1.0 + color.g * -0.395 + color.b * 0.581 ,
					color.r * 1.0 + color.g * 2.032);
}

float extractLuma(float3 c)
{
    return (c.r * 0.299 + c.g * 0.587 + c.b * 0.114);
}

float3 luma_sharpen(float3 image, float2 uv)
{
    float3 yuv = YUVFromRGB(image);
    
    float2 imgSize = screen_res.xy;
    
    float accumY = 0.0; 
    for(int i = -1; i <= 1; ++i) {
        for(int j = -1; j <= 1; ++j) {
            float2 offset = float2(i,j) / imgSize;
            
            float s = extractLuma(s_image.SampleLevel(smp_rtlinear,uv + offset,0).rgb);
            float notCentre = min(float(i*i + j*j),1.0);
            accumY += s * (9.0 - notCentre*10.0);
        }
    }
    
    accumY /= 9.0;
    
    float gain = 0.9;
    accumY = (accumY + yuv.x)*gain;
    
		image = RGBFromYUV (float3(accumY,yuv.y,yuv.z)); // sharpened
		return image;   
}

///////////////////////////////////////////////////////
// VIGNETTE CALCULATOR (USED IN NVG AS WELL AS BLOOM PHASES TO DARKEN EDGES OF SHIT)
///////////////////////////////////////////////////////
float calc_vignette (float night_vision_generation, float2 tc)
{
	float vignette;
	float2 corrected_texturecoords = aspect_ratio_correction(tc);
	
	if (night_vision_generation == 1)
	{
		float gen1_vignette_right = pow(smoothstep(circle_radius,circle_radius-gen_1_vignette_amount, distance(corrected_texturecoords,nvg_gen_1_offset)),3);
		vignette = 1.0 - (1.0 - gen1_vignette_right); // apply vignette
	}
	else if (night_vision_generation == 10)
	{
		float gen1_vignette_left = pow(smoothstep(circle_radius,circle_radius-gen_1_vignette_amount, distance(corrected_texturecoords,nvg_gen_1_offset_flipped)),3);
		vignette = 1.0 - (1.0 - gen1_vignette_left); // apply vignette
	}
	else if (night_vision_generation == 11)
	{
		float gen1_vignette_center = pow(smoothstep(circle_radius,circle_radius-gen_1_vignette_amount, distance(corrected_texturecoords,nvg_gen_1_centered)),3);
		vignette = 1.0 - (1.0 - gen1_vignette_center); // apply vignette
	}
	else if (night_vision_generation == 2)
	{
		float gen2_vignette_1 = pow(smoothstep(circle_radius,circle_radius-gen_2_vignette_amount, distance(corrected_texturecoords,nvg_gen_2_offset_1)),3);
		float gen2_vignette_2 = pow(smoothstep(circle_radius,circle_radius-gen_2_vignette_amount, distance(corrected_texturecoords,nvg_gen_2_offset_2)),3);
		vignette = 1.0 - ((1.0 - gen2_vignette_1) * (1.0 - gen2_vignette_2)); // apply vignette
	}
	else if (night_vision_generation == 3)
	{
		float gen3_vignette_1 = pow(smoothstep(circle_radius,circle_radius-gen_3_vignette_amount, distance(corrected_texturecoords,nvg_gen_3_offset_1)),3);
		float gen3_vignette_2 = pow(smoothstep(circle_radius,circle_radius-gen_3_vignette_amount, distance(corrected_texturecoords,nvg_gen_3_offset_2)),3);
		float gen3_vignette_3 = pow(smoothstep(circle_radius,circle_radius-gen_3_vignette_amount, distance(corrected_texturecoords,nvg_gen_3_offset_3)),3);
		float gen3_vignette_4 = pow(smoothstep(circle_radius,circle_radius-gen_3_vignette_amount, distance(corrected_texturecoords,nvg_gen_3_offset_4)),3);
		vignette = 1.0 - ((1.0 - gen3_vignette_1) * (1.0 - gen3_vignette_2) * (1.0 - gen3_vignette_3) * (1.0 - gen3_vignette_4)); // apply vignette
	}
	return vignette;
}			

///////////////////////////////////////////////////////
// DEPTH BLUR - LITERALLY BLURS THE DEPTH VALUE IN S_POSITION
///////////////////////////////////////////////////////
float blurred_depth (float2 tc, float fp_start, float fp_end)
{
    float Pi = 6.28318530718; // Pi*2
    
    float Directions = 12.0; // BLUR DIRECTIONS (Default 16.0 - More is better but slower)
    float Quality = 4.0; // BLUR QUALITY (Default 4.0 - More is better but slower)
	float Size = 4;
	float2 Radius = Size/screen_res.xy;

	// how far away is the center of our COC
   	float center_depth = s_position.Load( int3( (tc)*screen_res.xy, 0 ), 0 ).z;
		if (center_depth == 0) { center_depth = 10000; }
	// set our average depth to be center depth
	float depth_average = 0;
	// where we store the depth_sample
	float depth_sample;
	// where we store the weighted value from sample
	float depth_tap;
	// where we store our weighted
	float weight = 0.0;
	// where we store the total weighted
	float total_weight = 0.0;
	
	// Blur calculations
	for(float i=1.0; i<=Quality; i++) // how far away are we
    {
		for( float d=0.0; d<Pi; d+=Pi/Directions) // where are we around the circle
		{
			// pull depth at our sample point
			depth_sample = s_position.Load( int3( ((tc+float2(cos(d),sin(d))*Radius*i) * screen_res.xy), 0 ), 0 ).z;
			
			// if we hit the sky, give it a depth of 10k
			if (depth_sample == 0) {depth_sample = 10000.0f; }
			
			// if the point we hit is closer than our (center? average), then that point should add blurring to our centerpoint
			if (depth_sample < center_depth) 
			{
				weight = Quality - pow((i - 1),0.5);
				depth_average += depth_sample * weight;
				total_weight += weight;
			}
			// but if the point we hit is farther than our (center? average?) then that point should not be adding blur to our centerpoint

        }
    }
	depth_average /= total_weight;
    return depth_average;
}