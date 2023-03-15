/*=============================================================================

	ReShade effect file
    github.com/martymcmodding

    Copyright (c) Pascal Gilcher. All rights reserved.

	Support me:
   		paypal.me/mcflypg
   		patreon.com/mcflypg

    REGRADE

    changelog:

    0.1:    - initial release
    0.2:    - ported to refactored qUINT structure
            - removed RGB split from tone curve and lift gamma gain, replaced with
              with RGB selector
            - fixed bug with color remapper red affecting pure white
            - add more grading controls
            - remade lift gamma gain to fit convention
            - replaced histogram with McFly's '21 bomb ass histogram (TM)
            - added split toning
            - switched to internal LUT processing
    0.3:    - switched to LUT atlas for free arrangement of CC operations
            - added clipping mask
            - fixed bug with levels
            - closed UI sections by default
            - added vignette
            - improved color remap - still allows all hues, but now allows raising saturation
    0.4:    - changed LUT sampling to tetrahedral
            - flattened LUTs, improves performance greatly
    0.5:    - added color balance node
            - added dark wash feature
            - extended levels to in/out
            - added gamma to adjustments
    0.6:    - remade histogram UI
            - added dithering
    0.7:    - added compute histogram
            - integration with SOLARIS
            - remade hue controls entirely
            - added waveform mode for compute enabled platforms
            - fixed colorspace linear conversion in xyz, lab and oklab
            - remade split toning
            - moved waveform to Insight
    0.8:    - remade color balance 
            - added special transforms 
            - remade tone curve 
    0.9:    - update LUTs only when GUI is active or LUTs are empty
            - change LUT size for least perceptual error at a given quality
            - optimize tetrahedral sampling
    0.10:   - added filmic gamma
            - vast optimizations for SOLARIS
            - better depth mask for SOLARIS
            - different blend modes for SOLARIS
    0.11:   - added HSV lut indexing to improve greyscale gradients
            - added dequantize
            - remade split tone for better blending and saturation based toning
            - modified color remapper to use smoothstepped ranges instead
            - extended lift gamma gain with Resolve's formula
            - improved saturation and vibrance in adjustments layer
            - added Lab based white balance
    0.12:   - modify HSL tools to protect greys, change L to gamma
            - add trilinear sampling
            - add native color processing option
            - rename white balance to calibration and add primary adjustments
            - major cleanup
    0.12.1  - fix for ReShade 5.6

    * Unauthorized copying of this file, via any medium is strictly prohibited
 	* Proprietary and confidential

=============================================================================*/

/*=============================================================================
	Preprocessor settings
=============================================================================*/

#ifndef ENABLE_SOLARIS_REGRADE_PARITY
 #define ENABLE_SOLARIS_REGRADE_PARITY                 0   //[0 or 1]      If enabled, ReGrade takes HDR input from SOLARIS as color buffer instead. This allows HDR exposure, bloom and color grading to work nondestructively
#endif

#ifndef ENABLE_NATIVE_COLOR_PROCESSING
 #define ENABLE_NATIVE_COLOR_PROCESSING                0   //[0 or 1]      If enabled, ReGrade will natively process every pixel and not generate+apply a LUT    
#endif

/*=============================================================================
	UI Uniforms
=============================================================================*/

uniform int UIHELP <
	ui_type = "radio";
	ui_label = " ";	
	ui_text = "How to use ReGrade:\n\n"
    "ReGrade is a modular color grading platform.\n"
    "Pick any color grading operation in the slots below,\n"
    "then adjust its parameters in the respective section.\n\n"
    "CAUTION: You *can* pick operations multiple times, but they do NOT\n"
    "have separate controls, so it is advised to not use them twice.\n\n"
    "To use the histogram/waveforms, enable the respective\n"
    "technique in the technique window above."
   ;
	ui_category = ">>>> OVERVIEW / HELP (click me) <<<<";
	ui_category_closed = false;
>;

#define LABEL_NONE              "None"
#define LABEL_LEVELS            "Levels"
#define LABEL_ADJ               "Adjustments"
#define LABEL_LGG               "Lift Gamma Gain"
#define LABEL_CALIB             "Calibration"
#define LABEL_REMAP             "Color Remapping"
#define LABEL_TONECURVE         "Tone Curve"
#define LABEL_SPLIT             "Split Toning"
#define LABEL_CB                "Color Balance"
#define LABEL_SPECIAL           "Special Transforms"

#define COMBINE(a, b) a ## b
#define CONCAT(a,b) COMBINE(a, b)
#define SECTION_PREFIX          "Parameters for "

#define SECTION_LEVELS          CONCAT(SECTION_PREFIX, LABEL_LEVELS) 
#define SECTION_ADJ             CONCAT(SECTION_PREFIX, LABEL_ADJ) 
#define SECTION_LGG             CONCAT(SECTION_PREFIX, LABEL_LGG) 
#define SECTION_CALIB           CONCAT(SECTION_PREFIX, LABEL_CALIB) 
#define SECTION_REMAP           CONCAT(SECTION_PREFIX, LABEL_REMAP) 
#define SECTION_TONECURVE       CONCAT(SECTION_PREFIX, LABEL_TONECURVE) 
#define SECTION_SPLIT           CONCAT(SECTION_PREFIX, LABEL_SPLIT) 
#define SECTION_CB              CONCAT(SECTION_PREFIX, LABEL_CB) 
#define SECTION_SPECIAL         CONCAT(SECTION_PREFIX, LABEL_SPECIAL) 

#define GRADE_ID_NONE           0
#define GRADE_ID_LEVELS         1
#define GRADE_ID_ADJ            2
#define GRADE_ID_LGG            3
#define GRADE_ID_CALIB          4
#define GRADE_ID_REMAP          5
#define GRADE_ID_TONECURVE      6
#define GRADE_ID_SPLIT          7
#define GRADE_ID_CB             8
#define GRADE_ID_SPECIAL        9

#define NUM_SECTIONS 9 //cannot use this to generate the nodes below! Increment and extend concat, add node

#define concat_all(a,b,c,d,e,f,g,h,i,j) a ## "\0" ## b ## "\0" ##c ## "\0" ##d ## "\0" ##e ## "\0" ##f ## "\0" ##g ## "\0" ##h ## "\0" ##i ## "\0" ##j ## "\0"  
#define CURR_ITEMS concat_all(LABEL_NONE, LABEL_LEVELS, LABEL_ADJ, LABEL_LGG, LABEL_CALIB, LABEL_REMAP, LABEL_TONECURVE, LABEL_SPLIT, LABEL_CB, LABEL_SPECIAL)

uniform int NODE1 <
	ui_type = "combo";
    ui_label = "Slot 1";
	ui_items = CURR_ITEMS;
    ui_category = "ORDER OF COLOR OPERATIONS";
> = 0;

uniform int NODE2 <
	ui_type = "combo";
    ui_label = "Slot 2";
	ui_items = CURR_ITEMS;
    ui_category = "ORDER OF COLOR OPERATIONS";
> = 0;

uniform int NODE3 <
	ui_type = "combo";
    ui_label = "Slot 3";
	ui_items = CURR_ITEMS;
    ui_category = "ORDER OF COLOR OPERATIONS";
> = 0;

uniform int NODE4 <
	ui_type = "combo";
    ui_label = "Slot 4";
	ui_items = CURR_ITEMS;
    ui_category = "ORDER OF COLOR OPERATIONS";
> = 0;

uniform int NODE5 <
	ui_type = "combo";
    ui_label = "Slot 5";
	ui_items = CURR_ITEMS;
    ui_category = "ORDER OF COLOR OPERATIONS";
> = 0;

uniform int NODE6 <
	ui_type = "combo";
    ui_label = "Slot 6";
	ui_items = CURR_ITEMS;
    ui_category = "ORDER OF COLOR OPERATIONS";
> = 0;

uniform int NODE7 <
	ui_type = "combo";
    ui_label = "Slot 7";
	ui_items = CURR_ITEMS;
    ui_category = "ORDER OF COLOR OPERATIONS";
> = 0;

uniform int NODE8 <
	ui_type = "combo";
    ui_label = "Slot 8";
	ui_items = CURR_ITEMS;
    ui_category = "ORDER OF COLOR OPERATIONS";
> = 0;

uniform int NODE9 <
	ui_type = "combo";
    ui_label = "Slot 9";
	ui_items = CURR_ITEMS;
    ui_category = "ORDER OF COLOR OPERATIONS";
> = 0;

uniform bool BYPASS_LEVELS <
    ui_label = CONCAT("Bypass ", LABEL_LEVELS);
    ui_category = SECTION_LEVELS;
    ui_category_closed = true;
> = false;

uniform float INPUT_BLACK_LVL <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 255.0;
	ui_step = 1.0;
	ui_label = "Black Level In";
    ui_category = SECTION_LEVELS;
    ui_category_closed = true;
> = 0.0;

uniform float INPUT_WHITE_LVL <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 255.0;
	ui_step = 1.0;
	ui_label = "White Level In";
    ui_category = SECTION_LEVELS;
    ui_category_closed = true;
> = 255.0;

uniform float OUTPUT_BLACK_LVL <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 255.0;
	ui_step = 1.0;
	ui_label = "Black Level Out";
    ui_category = SECTION_LEVELS;
    ui_category_closed = true;
> = 0.0;

uniform float OUTPUT_WHITE_LVL <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 255.0;
	ui_step = 1.0;
	ui_label = "White Level Out";
    ui_category = SECTION_LEVELS;
    ui_category_closed = true;
> = 255.0;

uniform bool BYPASS_ADJ <
    ui_label = CONCAT("Bypass ", LABEL_ADJ);
    ui_category = SECTION_ADJ;
    ui_category_closed = true;
> = false;

uniform float GRADE_CONTRAST <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Contrast";
    ui_category = SECTION_ADJ;
    ui_category_closed = true;
> = 0.0;

uniform float GRADE_EXPOSURE <
	ui_type = "drag";
	ui_min = -4.0; ui_max = 4.0;
	ui_label = "Exposure";
    ui_category = SECTION_ADJ;
    ui_category_closed = true;
> = 0.0;

uniform float GRADE_GAMMA <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Gamma";
    ui_category = SECTION_ADJ;
    ui_category_closed = true;
> = 0.0;

uniform float GRADE_FILMIC_GAMMA <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Filmic Gamma";
    ui_category = SECTION_ADJ;
    ui_category_closed = true;
> = 0.0;

uniform float GRADE_SATURATION <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Saturation";
    ui_category = SECTION_ADJ;
    ui_category_closed = true;
> = 0.0;

uniform float GRADE_VIBRANCE <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Vibrance";
    ui_category = SECTION_ADJ;
    ui_category_closed = true;
> = 0.0;

uniform bool BYPASS_LGG <
    ui_label = CONCAT("Bypass ", LABEL_LGG);
    ui_category = SECTION_LGG;
    ui_category_closed = true;
> = false;

uniform int INPUT_LGG_MODE <
	ui_type = "combo";
    ui_label = "Lift Gamma Gain Mode";
	ui_items = " American Society of Cinematographers\0 DaVinci Resolve\0";
    ui_category = SECTION_LGG;
    ui_category_closed = true;  
> = 0;

uniform float3 INPUT_LIFT_COLOR <
  	ui_type = "color";
  	ui_label="Lift";
  	ui_category = SECTION_LGG;
    ui_category_closed = true;    
> = float3(0.5, 0.5, 0.5);

uniform float3 INPUT_GAMMA_COLOR <
  	ui_type = "color";
  	ui_label="Gamma";
  	ui_category = SECTION_LGG;
      ui_category_closed = true;    
> = float3(0.5, 0.5, 0.5);

uniform float3 INPUT_GAIN_COLOR <
  	ui_type = "color";
  	ui_label="Gain";
  	ui_category = SECTION_LGG;
      ui_category_closed = true;    
> = float3(0.5, 0.5, 0.5);

uniform bool BYPASS_CALIB <
    ui_label = CONCAT("Bypass ", LABEL_CALIB);
    ui_category = SECTION_CALIB;
    ui_category_closed = true;
> = false;

uniform float INPUT_COLOR_TEMPERATURE <
	ui_type = "drag";
	ui_min = 1700.0; ui_max = 40000.0;
    ui_step = 10.0;
	ui_label = "Color Temperature";
    ui_category = SECTION_CALIB;
    ui_category_closed = true;
> = 6500.0;

uniform float INPUT_COLOR_LAB_A <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.01;
	ui_label = "Lab A Offset (Green - Magenta)";
    ui_category = SECTION_CALIB;
    ui_category_closed = true;
> = 0.0;

uniform float INPUT_COLOR_LAB_B <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.01;
	ui_label = "Lab B Offset (Blue - Orange)";
    ui_category = SECTION_CALIB;
    ui_category_closed = true;
> = 0.0;

uniform int INPUT_COLOR_PRIMARY_MODE <
	ui_type = "combo";
    ui_label = "R|G|B Primary Mode";
	ui_items = " ReGrade Legacy\0 Barycentric\0 Hue Based\0";
    ui_category = SECTION_CALIB;
    ui_category_closed = true;  
> = 0;

uniform float3 INPUT_COLOR_PRIMARY_HUE <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.01;
	ui_label = "R|G|B Primary Hue";
    ui_category = SECTION_CALIB;
    ui_category_closed = true;
> = float3(0.0, 0.0, 0.0);

uniform float3 INPUT_COLOR_PRIMARY_SAT <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.01;
	ui_label = "R|G|B Primary Saturation";
    ui_category = SECTION_CALIB;
    ui_category_closed = true;
> = float3(0.0, 0.0, 0.0);

uniform bool BYPASS_REMAP <
    ui_label = CONCAT("Bypass ", LABEL_REMAP);
    ui_category = SECTION_REMAP;
    ui_category_closed = true;
> = false;

uniform float3 COLOR_REMAP_RED <
  	ui_type = "drag";
    ui_min = -1.0;
    ui_max = 1.0;
  	ui_label="Hue|Sat|Value Red";
  	ui_category = SECTION_REMAP;
      ui_category_closed = true;   
> = float3(0.0, 0.0, 0.0);

uniform float3 COLOR_REMAP_ORANGE <
  	ui_type = "drag";
    ui_min = -1.0;
    ui_max = 1.0;
  	ui_label="Hue|Sat|Value Orange";
  	ui_category = SECTION_REMAP;
      ui_category_closed = true;    
> = float3(0.0, 0.0, 0.0);

uniform float3 COLOR_REMAP_YELLOW <
  	ui_type = "drag";
    ui_min = -1.0;
    ui_max = 1.0;
  	ui_label="Hue|Sat|Value Yellow";
  	ui_category = SECTION_REMAP;
      ui_category_closed = true;     
> = float3(0.0, 0.0, 0.0);

uniform float3 COLOR_REMAP_GREEN <
  	ui_type = "drag";
    ui_min = -1.0;
    ui_max = 1.0;
  	ui_label="Hue|Sat|Value Green";
  	ui_category = SECTION_REMAP;
      ui_category_closed = true;   
> = float3(0.0, 0.0, 0.0);

uniform float3 COLOR_REMAP_AQUA <
  	ui_type = "drag";
    ui_min = -1.0;
    ui_max = 1.0;
  	ui_label="Hue|Sat|Value Aqua";
	ui_category = SECTION_REMAP;
    ui_category_closed = true;
> = float3(0.0, 0.0, 0.0);

uniform float3 COLOR_REMAP_BLUE <
  	ui_type = "drag";
    ui_min = -1.0;
    ui_max = 1.0;
  	ui_label="Hue|Sat|Value Blue";
  	ui_category = SECTION_REMAP;
      ui_category_closed = true;    
> = float3(0.0, 0.0, 0.0);

uniform float3 COLOR_REMAP_MAGENTA <
  	ui_type = "drag";
    ui_min = -1.0;
    ui_max = 1.0;
  	ui_label="Hue|Sat|Value Magenta";
  	ui_category = SECTION_REMAP;
      ui_category_closed = true;     
> = float3(0.0, 0.0, 0.0);

uniform bool BYPASS_TONECURVE <
    ui_label = CONCAT("Bypass ", LABEL_TONECURVE);
    ui_category = SECTION_TONECURVE;
    ui_category_closed = true;
> = false;

uniform float TONECURVE_SHADOWS <
	ui_type = "drag";
	ui_min = -1.00; ui_max = 1.00;
	ui_label = "Shadows";
    ui_category = SECTION_TONECURVE;
    ui_category_closed = true;
> = 0.00;

uniform float TONECURVE_DARKS <
	ui_type = "drag";
	ui_min = -1.00; ui_max = 1.00;
	ui_label = "Darks";
    ui_category = SECTION_TONECURVE;
    ui_category_closed = true;
> = 0.00;

uniform float TONECURVE_LIGHTS <
	ui_type = "drag";
	ui_min = -1.00; ui_max = 1.00;
	ui_label = "Lights";
    ui_category = SECTION_TONECURVE;
    ui_category_closed = true;
> = 0.00;

uniform float TONECURVE_HIGHLIGHTS <
	ui_type = "drag";
	ui_min = -1.00; ui_max = 1.00;
	ui_label = "Highlights";
    ui_category = SECTION_TONECURVE;
    ui_category_closed = true;
> = 0.00;

uniform float TONECURVE_DARKWASH_RANGE <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Dark Wash Range";
    ui_category = SECTION_TONECURVE;
    ui_category_closed = true;
> = 0.2;
uniform float TONECURVE_DARKWASH_INT <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Dark Wash Intensity";
    ui_category = SECTION_TONECURVE;
    ui_category_closed = true;
> = 0.0;

uniform bool BYPASS_SPLIT <
    ui_label = CONCAT("Bypass ", LABEL_SPLIT);
    ui_category = SECTION_SPLIT;
    ui_category_closed = true;
> = false;

uniform int SPLITTONE_MODE <
	ui_type = "combo";
    ui_label = "Split Mode";
	ui_items = " Shadows/Highlights\0 Greys/Saturated Colors\0";
    ui_category = SECTION_SPLIT;
    ui_category_closed = true;
> = 0;

uniform float3 SPLITTONE_SHADOWS <
  	ui_type = "color";
  	ui_label="Tint A";
  	ui_category = SECTION_SPLIT;
    ui_category_closed = true;    
> = float3(0.5, 0.5, 0.5);

uniform float3 SPLITTONE_HIGHLIGHTS <
  	ui_type = "color";
  	ui_label="Tint B";
  	ui_category = SECTION_SPLIT;
    ui_category_closed = true;    
> = float3(0.5, 0.5, 0.5);

uniform float SPLITTONE_BALANCE <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Balance";
    ui_category = SECTION_SPLIT;
    ui_category_closed = true;
> = 0.0;

uniform int SPLITTONE_BLEND <
	ui_type = "combo";
    ui_label = "Blend Mode";
	ui_items = " Soft Light\0 Overlay\0";
    ui_category = SECTION_SPLIT;
    ui_category_closed = true;
> = 0;

uniform bool BYPASS_CB <
    ui_label = CONCAT("Bypass ", LABEL_CB);
    ui_category = SECTION_CB;
    ui_category_closed = true;
> = false;

uniform float2 CB_SHAD <
  	ui_type = "drag";
  	ui_label="Hue / Saturation: Shadows";
    ui_min = 0.00; ui_max = 1.00;  
  	ui_category = SECTION_CB;
    ui_category_closed = true;    
> = float2(0.0, 0.0);

uniform float2 CB_MID <
  	ui_type = "drag";
  	ui_label="Hue / Saturation: Midtones";
    ui_min = 0.00; ui_max = 1.00;  
  	ui_category = SECTION_CB;
    ui_category_closed = true;    
> = float2(0.0, 0.0);

uniform float2 CB_HI <
  	ui_type = "drag";
  	ui_label="Hue / Saturation: Highlights";
    ui_min = 0.00; ui_max = 1.00;  
  	ui_category = SECTION_CB;
    ui_category_closed = true;    
> = float2(0.0, 0.0);

uniform bool BYPASS_SPECIAL <
    ui_label = CONCAT("Bypass ", LABEL_SPECIAL);
    ui_category = SECTION_SPECIAL;
    ui_category_closed = true;
> = false;

uniform float SPECIAL_BLEACHBP <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Bleach Bypass (Gamma Corrected)";
    ui_category = SECTION_SPECIAL;
    ui_category_closed = true;
> = 0.0;

uniform float2 SPECIAL_GAMMA_LUM_CHROM <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Gamma on Luma | Chroma";
    ui_category = SECTION_SPECIAL;
    ui_category_closed = true;
> = float2(0.0, 0.0);

uniform bool ENABLE_VIGNETTE <
	ui_label = "Enable Vignette Effect";
    ui_tooltip = "Allows two kinds of vignette effects:\n\n" 
    "Mechanical Vignette:   The insides of a camera lens occlude light at the corners of the field of view.\n\n"
    "Sensor Vignette:       Projection of light onto sensor plane causes a secondary vignette effect.\n"
    "                       Incident angle of light hitting the sensor and its travel distance affect light intensity.";
    ui_category = "Vignette";
    ui_category_closed = true;
> = false;

uniform float VIGNETTE_RADIUS_MECH <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Mechanical Vignette: Radius";
    ui_category = "Vignette";
    ui_category_closed = true;
> = 0.525;

uniform float VIGNETTE_BLURRYNESS_MECH <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Mechanical Vignette: Blurryness";
    ui_category = "Vignette";
    ui_category_closed = true;
> = 0.8;

uniform float VIGNETTE_RATIO <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Mechanical Vignette: Shape";
    ui_category = "Vignette";
    ui_category_closed = true;
> = 0.0;

uniform float VIGNETTE_RADIUS_SENSOR <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "Sensor Vignette:     Scale";
    ui_category = "Vignette";
    ui_category_closed = true;
> = 1.0;

uniform int VIGNETTE_BLEND_MODE <
	ui_type = "combo";
    ui_label = "Vignette Blending Mode";
	ui_items = "Standard\0HDR simulation\0HDR simulation (protect tones)\0";
    ui_category = "Vignette";
    ui_category_closed = true;
> = 1;

uniform int DITHER_BIT_DEPTH <
	ui_type = "combo";
    ui_label = "Dithering";
	ui_items = " Off\0 6 Bit\0 8 Bit\0 10 Bit\0 12 Bit\0";
    ui_category = "Utility";
    ui_category_closed = true;
> = 2;

/*
uniform bool DITHER_ADD_DEQUANTIZE <
	ui_label = "Dequantize Input";
    ui_tooltip = "Strong color transformations can make quantization artifacts in the input image visible.\n" 
                 "This includes burned colors or blocky, banded color gradients in e.g. bloom, skycolor or car paint.\n"
    "Enabling the dequantizer analyzes the colors within a small area and tries to estimate the source data.\n\n"
    "!! This only works if the source data is already dithered, either from the game or a (prior) deband shader !!";
    ui_category = "Utility";
    ui_category_closed = true;
> = false;
*/
/*
uniform float4 tempF1 <
    ui_type = "drag";
    ui_min = -100.0;
    ui_max = 100.0;
> = float4(1,1,1,1);

uniform float4 tempF2 <
    ui_type = "drag";
    ui_min = -100.0;
    ui_max = 100.0;
> = float4(1,1,1,1);

uniform float4 tempF3 <
    ui_type = "drag";
    ui_min = -100.0;
    ui_max = 100.0;
> = float4(1,1,1,1);
*/
/*=============================================================================
	Textures, Samplers, Globals, Structs
=============================================================================*/

#pragma warning(disable : 3571) //pow(f, e) will not work etc etc

uniform float FRAMETIME < source = "frametime";  >;
uniform uint FRAMECOUNT  < source = "framecount"; >;
uniform bool OVERLAY_ACTIVE < source = "overlay_open"; >;

#define LUT_INDEXING            0 //0 = RGB | 1 = HSV
#define LUT_INTERP              1 //0 = trilinear | 1 = tetrahedral

//An analysis covering all possible colors yielded these magic numbers
//as viable minima for single channel and compounded error to neutral LUT
//Results vary a bit for analysis using colors weighted by natural occurence
//and average weighting entire RGB cube. 
//Values were picked that score well in both and R*B < 4096 (DX9 limit)

#if LUT_INDEXING != 0
//HSV indexing - allows for the grey line to be parallel to a lattice axis
//improving quality on greys but maximum error for selected colors increases
//and it doesn't allow for C1+ continuous sampling.
 #define LUT_DIM_R    43
 #define LUT_DIM_G    64
 #define LUT_DIM_B    94
#else 
//Values picked after perceptual luma so that G > R > B in precision. 
 #define LUT_DIM_R    51 
 #define LUT_DIM_G    84
 #define LUT_DIM_B    34
#endif

#define LUT_DIM_X (LUT_DIM_R * LUT_DIM_B)
#define LUT_DIM_Y (LUT_DIM_G)

#if ENABLE_NATIVE_COLOR_PROCESSING == 0
texture2D LUTAtlas	                    { Width = LUT_DIM_X;   Height = LUT_DIM_Y * NUM_SECTIONS;     Format = RGBA32F;  	};
texture2D LUTFlattened	                { Width = LUT_DIM_X;   Height = LUT_DIM_Y;                    Format = RGBA32F;  	};
sampler2D sLUTAtlas		                { Texture = LUTAtlas;       };
sampler2D sLUTFlattened		            { Texture = LUTFlattened;   };
#endif

#if ENABLE_SOLARIS_REGRADE_PARITY != 0
texture2D ColorInputHDRTex			    { Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;                Format = RGBA16F; };
sampler ColorInput 	{ Texture = ColorInputHDRTex; MinFilter=POINT; MipFilter=POINT; MagFilter=POINT; };
#else 
texture ColorInputTex : COLOR;
sampler ColorInput 	{ Texture = ColorInputTex; MinFilter=POINT; MipFilter=POINT; MagFilter=POINT; };
#endif

struct VSOUT
{
	float4 vpos : SV_Position;
    float4 uv : TEXCOORD0;
};

#include "qUINT\Global.fxh"
#include "qUINT\Colorspaces.fxh"
#include "qUINT\ColorOps.fxh"

/*=============================================================================
	Functions
=============================================================================*/

float3 apply_color_op(float3 col, int op)
{
    switch(op)
    {
        case GRADE_ID_LEVELS:       if(BYPASS_LEVELS) break;        col = ColorOps::input_remap(col, INPUT_BLACK_LVL / 255.0, INPUT_WHITE_LVL / 255.0, OUTPUT_BLACK_LVL / 255.0, OUTPUT_WHITE_LVL / 255.0); break;
        case GRADE_ID_ADJ:          if(BYPASS_ADJ) break;           col = ColorOps::adjustments(col, GRADE_EXPOSURE, GRADE_CONTRAST, GRADE_GAMMA, GRADE_VIBRANCE, GRADE_SATURATION, GRADE_FILMIC_GAMMA); break;
        case GRADE_ID_LGG:          if(BYPASS_LGG) break;           col = ColorOps::lgg(col, INPUT_LGG_MODE, INPUT_LIFT_COLOR, INPUT_GAMMA_COLOR, INPUT_GAIN_COLOR); break;
        case GRADE_ID_CALIB:        if(BYPASS_CALIB) break;         col = ColorOps::calibration(col, INPUT_COLOR_TEMPERATURE, INPUT_COLOR_LAB_A, INPUT_COLOR_LAB_B, INPUT_COLOR_PRIMARY_HUE, INPUT_COLOR_PRIMARY_SAT, INPUT_COLOR_PRIMARY_MODE); break;
        case GRADE_ID_REMAP:        if(BYPASS_REMAP) break;         col = ColorOps::color_remapper(col, COLOR_REMAP_RED, COLOR_REMAP_ORANGE, COLOR_REMAP_YELLOW, COLOR_REMAP_GREEN, COLOR_REMAP_AQUA, COLOR_REMAP_BLUE, COLOR_REMAP_MAGENTA); break;
        case GRADE_ID_TONECURVE:    if(BYPASS_TONECURVE) break;     col = ColorOps::tonecurve(col, TONECURVE_SHADOWS, TONECURVE_DARKS, TONECURVE_LIGHTS, TONECURVE_HIGHLIGHTS, TONECURVE_DARKWASH_INT, TONECURVE_DARKWASH_RANGE); break;
        case GRADE_ID_SPLIT:        if(BYPASS_SPLIT) break;         col = ColorOps::splittone(col, SPLITTONE_MODE, SPLITTONE_BLEND, SPLITTONE_BALANCE, SPLITTONE_SHADOWS, SPLITTONE_HIGHLIGHTS); break;
        case GRADE_ID_CB:           if(BYPASS_CB) break;            col = ColorOps::color_balance(col, CB_SHAD, CB_MID, CB_HI); break;      
        case GRADE_ID_SPECIAL:      if(BYPASS_SPECIAL) break;       col = ColorOps::specialfx(col, SPECIAL_BLEACHBP, SPECIAL_GAMMA_LUM_CHROM); break;   
    };

    return col;
}

float3 dither(in int2 pos, int bit_depth)
{    
    const float lsb = exp2(bit_depth) - 1;
    const float2 magicdot = float2(0.75487766624669276, 0.569840290998); 
    const float3 magicadd = float3(0, 0.025, 0.0125) * dot(magicdot, 1);

    float3 dither = frac(dot(pos, magicdot) + magicadd);       
    dither = dither - 0.5;
    dither *= 0.99; //so if added to source color, it just does not spill over to next bucket
    dither /= lsb;
    return dither;
}

float3 draw_lut(float2 coord, int3 volumesize) //need float2 due to DX9 being a jackass
{
    coord.y %= volumesize.y;
    float3 col = float3(coord.x % volumesize.x, coord.y, floor(coord.x / volumesize.x));
    col = saturate(col / (volumesize - 1.0));    

#if LUT_INDEXING != 0
    col = Colorspace::hsv_to_rgb(col);
#endif
    return saturate(col);
}

//I'm really proud of this solution, it's orders of magnitude simpler than the ACES reference
float4 tetrahedral_volume_sampling(sampler s_volume, float3 uvw, int3 volume_size, int atlas_idx)
{    
    float3 p = saturate(uvw) * (volume_size - 1);   //p += float3(1.0/4096.0, 0, 1.0/2048.0); 
    float3 corner000 = floor(p); float3 corner111 = ceil(p);
    float3 delta = p - corner000;
    
    //work out the axes with most/least delta (min axis goes backwards from 111)
    float3 comp = delta.xyz > delta.yzx; 
    float3 minaxis = comp.zxy * (1.0 - comp);
    float3 maxaxis = comp * (1.0 - comp.zxy);	
                
    //3D coords of the 2 dynamic interpolants in the lattice    
    int3 cornermin = lerp(corner111, corner000, minaxis);
    int3 cornermax = lerp(corner000, corner111, maxaxis);
    
    float maxv = dot(maxaxis, delta);
    float minv = dot(minaxis, delta);
    float medv = dot(1 - maxaxis - minaxis, delta);

    //3D barycentric
    float4 lattice_weights = float4(1, maxv, medv, minv);
    lattice_weights.xyz -= lattice_weights.yzw;

    return  tex2Dfetch(s_volume, int2(corner000.x + corner000.z * volume_size.x, corner000.y + volume_size.y * atlas_idx)) * lattice_weights.x     //000       
          + tex2Dfetch(s_volume, int2(cornermax.x + cornermax.z * volume_size.x, cornermax.y + volume_size.y * atlas_idx)) * lattice_weights.y     //max
          + tex2Dfetch(s_volume, int2(cornermin.x + cornermin.z * volume_size.x, cornermin.y + volume_size.y * atlas_idx)) * lattice_weights.z     //min
          + tex2Dfetch(s_volume, int2(corner111.x + corner111.z * volume_size.x, corner111.y + volume_size.y * atlas_idx)) * lattice_weights.w;    //111
}

float4 tex3D(sampler s, float3 uvw, int3 size, int atlas_idx)
{
    uvw = saturate(uvw);
    uvw = uvw * size - uvw;
    uvw.xy = (uvw.xy + 0.5) / size.xy;
    
    float zlerp = frac(uvw.z);
    uvw.x = (uvw.x + uvw.z - zlerp) / size.z;

    float2 uv_a = uvw.xy;
    float2 uv_b = uvw.xy + float2(1.0/size.z, 0);
    
    int atlas_size = tex2Dsize(s).y / size.y;
    uv_a.y = (uv_a.y + atlas_idx) / atlas_size;
    uv_b.y = (uv_b.y + atlas_idx) / atlas_size;

    return lerp(tex2Dlod(s, uv_a, 0), 
                tex2Dlod(s, uv_b, 0),
                zlerp); 
}

float4 tex3D(sampler s, float3 uvw, int3 size)
{
    return tex3D(s, uvw, size, 0);
}

float3 sample_lut(sampler s, float3 col, int atlas_idx)
{
#if LUT_INDEXING != 0
    col = Colorspace::rgb_to_hsv(col);
#endif
    col = saturate(col);

    const int3 size = int3(LUT_DIM_R, LUT_DIM_G, LUT_DIM_B);

#if LUT_INTERP == 0
    return tex3D(s, col, size, atlas_idx).rgb;
#elif LUT_INTERP == 1 
    return tetrahedral_volume_sampling(s, col, size, atlas_idx).rgb;   
#else 
    return tex3D(s, col, size, atlas_idx).rgb;
#endif
}

float3 apply_vignette(float2 uv, float3 color)
{
    float2 viguv = uv * 2.0 - 1.0;
    viguv   -= viguv * saturate(float2(VIGNETTE_RATIO, -VIGNETTE_RATIO));
    viguv.x *= BUFFER_ASPECT_RATIO.y;

    float r = sqrt(dot(viguv, viguv) / dot(BUFFER_ASPECT_RATIO, BUFFER_ASPECT_RATIO));

    float vig = 1.0;
            
    float rf = r * VIGNETTE_RADIUS_SENSOR;
    float vigsensor = 1.0 + rf * rf; //cos is 1/sqrt(1+r*r) here, so 1/(1+r*r)^2 is cos^4
    vig *= rcp(vigsensor * vigsensor);
  
    float2 radii = VIGNETTE_RADIUS_MECH + float2(-VIGNETTE_BLURRYNESS_MECH * VIGNETTE_RADIUS_MECH * 0.2, 0);          

    float2 vsdf = r - radii;
    vig *= saturate(1 - vsdf.x / abs(vsdf.y - vsdf.x));

    switch(VIGNETTE_BLEND_MODE)
    {
        case 0:
            color *= vig; 
            break;
        case 1:
            color = color * rcp(1.03 - color);
            color *= vig;
            color = 1.03 * color * rcp(color + 1.0);
            break;
        case 2:
            float3 oldcolor = color;
            color = color * rcp(1.03 - color);
            color *= vig;
            color = 1.03 * color * rcp(color + 1.0);
            color = normalize(oldcolor + 1e-5) * length(color);
            break;
    }
    return color;
}

/*=============================================================================
	Shader Entry Points
=============================================================================*/

VSOUT VSBasic(in uint id : SV_VertexID)
{
    VSOUT o;
    VS_FullscreenTriangle(id, o.vpos, o.uv.xy); o.uv.zw = 0;
    return o;
}

#if ENABLE_NATIVE_COLOR_PROCESSING == 0
VSOUT VSLUTAtlas(in uint id : SV_VertexID)
{ 
    int op_sequence[NUM_SECTIONS] = {NODE1,NODE2,NODE3,NODE4,NODE5,NODE6,NODE7,NODE8,NODE9};
    int op_slot = id / 3u;
    int op = op_sequence[op_slot];
    uint write_slot = op_slot;    
    for(uint j = 0; j < op_slot; j++)
        if(op_sequence[j] == GRADE_ID_NONE) 
            write_slot--;

    VSOUT o; 
    o.uv.x = (id % 3u == 2) ? 2.0 : 0.0;
    o.uv.y = (id % 3u == 1) ? 2.0 : 0.0;

    float2 target_uv = o.uv.xy;
    target_uv.y = (target_uv.y + write_slot) / NUM_SECTIONS;   
    o.vpos = float4(target_uv * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);  

    o.uv.zw = op; 
    o.vpos = op == GRADE_ID_NONE ? 0 : o.vpos;
    return o;
}

void PSLUTAtlas(in VSOUT i, out float4 o : SV_Target0)
{
    if(any(saturate(i.uv.xy - 1.0))) discard;
    int op = round(i.uv.z);
    float3 col = draw_lut(floor(i.vpos.xy), int3(LUT_DIM_R, LUT_DIM_G, LUT_DIM_B));
    col = apply_color_op(col, op);
    col = saturate(col);
    o.rgb = col;
    o.w = 1; 
}

VSOUT VSLUTFlatten(in uint id : SV_VertexID)
{
    VSOUT o;
    VS_FullscreenTriangle(id, o.vpos, o.uv.xy);

    int op_sequence[NUM_SECTIONS] = {NODE1,NODE2,NODE3,NODE4,NODE5,NODE6,NODE7,NODE8,NODE9};
    int op_count = 0;
    for(int j = 0; j < NUM_SECTIONS; j++) 
        op_count += op_sequence[j] != GRADE_ID_NONE ? 1 : 0;
    o.uv.zw = op_count;
    return o;    
}

void PSLUTFlatten(in VSOUT i, out float4 o : SV_Target0)
{
    float3 col = draw_lut(floor(i.vpos.xy), int3(LUT_DIM_R, LUT_DIM_G, LUT_DIM_B));
    int op_count = round(i.uv.z);
    for(int op = 0; op < op_count; op++)
        col = sample_lut(sLUTAtlas, col, op);     
    o.rgb = col;
    o.w = 1;
}

void PSLUTApplyFlattened(in VSOUT i, out float3 o : SV_Target0)
{    
    float3 col = tex2D(ColorInput, i.uv.xy).rgb;  

    if(ENABLE_VIGNETTE)
        col = apply_vignette(i.uv.xy, col);

    //col = i.uv.x > 0.5 ? Colorspace::hsl_to_rgb(float3(frac(i.uv.x * 2), i.uv.y*1.3333, 0.5)) : Colorspace::hsl_to_rgb(float3(frac(i.uv.x * 2), 1, i.uv.y*1.3333));
    //col = i.uv.y > 0.6666 ? i.uv.x : col;

    col = sample_lut(sLUTFlattened, col, 0);
  
    if(DITHER_BIT_DEPTH > 0) 
        col += dither(i.vpos.xy, DITHER_BIT_DEPTH * 2 + 4);
  
    o = col;
}

#endif

void PSReGradeNative(in VSOUT i, out float3 o : SV_Target0)
{ 
    float3 col = tex2D(ColorInput, i.uv.xy).rgb;  

    if(ENABLE_VIGNETTE)
        col = apply_vignette(i.uv.xy, col);

    int op_sequence[NUM_SECTIONS] = {NODE1,NODE2,NODE3,NODE4,NODE5,NODE6,NODE7,NODE8,NODE9};

    [loop]
    for(int op_slot = 0; op_slot < NUM_SECTIONS; op_slot++)
    {
        int op = op_sequence[op_slot];
        if(op == GRADE_ID_NONE) continue;
        col = apply_color_op(col, op);
        col = saturate(col);
    }

     if(DITHER_BIT_DEPTH > 0) 
        col += dither(i.vpos.xy, DITHER_BIT_DEPTH * 2 + 4);
  
    o = col;
}

/*=============================================================================
	Techniques
=============================================================================*/

technique qUINT_ReGrade
< ui_tooltip =
"                         >> qUINT::ReGrade <<"
"\n"
"\n"
"ReGrade is a comprehensive framework for color grading and -correction.\n"
"\n"
"It features many tools commonly used by photographers and video editors,\n"
"in a modular, intuitive and highly optimized framework.\n"
"Additionally, it is designed to work in tandem with SOLARIS, a novel approach\n"
"to bloom and HDR exposure adjustment.\n"
"\n"
"If using this feature, make sure to place this effect right after SOLARIS,\n"
"with no other effects in between, as they will be ignored.\n";
>
{
#if ENABLE_NATIVE_COLOR_PROCESSING == 0    
    pass
	{
		VertexShader = VSLUTAtlas;
		PixelShader = PSLUTAtlas;
        RenderTarget = LUTAtlas;
        PrimitiveTopology = TRIANGLELIST;
		VertexCount = 3 * NUM_SECTIONS;
	}
    pass
	{
		VertexShader = VSLUTFlatten;
		PixelShader = PSLUTFlatten;
        RenderTarget = LUTFlattened;
	}
    pass    
	{
		VertexShader = VSBasic;
		PixelShader = PSLUTApplyFlattened;
	}
#else 
    pass    
	{
		VertexShader = VSBasic;
		PixelShader = PSReGradeNative;
	}
#endif
}