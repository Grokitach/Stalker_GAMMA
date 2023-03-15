/*
# ReshadeMotionEstimation
- Dense Realtime Motion Estimation | Based on Block Matching and Pyramids 
- Developed from 2019 to 2022 
- First published 2022 - Copyright, Jakob Wapenhensch
 
# This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) License
- https://creativecommons.org/licenses/by-nc/4.0/
- https://creativecommons.org/licenses/by-nc/4.0/legalcode

# Human-readable summary of the License and not a substitute for https://creativecommons.org/licenses/by-nc/4.0/legalcode:
You are free to:
- Share — copy and redistribute the material in any medium or format
- Adapt — remix, transform, and build upon the material
- The licensor cannot revoke these freedoms as long as you follow the license terms.

Under the following terms:
- Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
- NonCommercial — You may not use the material for commercial purposes.
- No additional restrictions — You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.

Notices:
- You do not have to comply with the license for elements of the material in the public domain or where your use is permitted by an applicable exception or limitation.
- No warranties are given. The license may not give you all of the permissions necessary for your intended use. For example, other rights such as publicity, privacy, or moral rights may limit how you use the material.
*/

#include "ReShadeUI.fxh"

// UI
//Block Matching
uniform int UI_ME_LAYER_MAX <
	ui_type = "combo";
    ui_label = "Motion Estimation Detail";
	ui_items = "Full\0Half\0Qarter\0";
	ui_tooltip = "The highest Layer / Resolution Motion Estimation is performed on.\n\
Motion Vectors Are than upscaled To Full Resolution. It's per Axis,\n\
so Half Resolution means Quarter Pixels.\n\
VERY HIGH PERFORMANCE IMPACT";
    ui_category = "Motion Estimation Block Matching";
> = 0;

uniform int UI_ME_LAYER_MIN < __UNIFORM_SLIDER_INT1
	ui_min = 3; ui_max = 6; ui_step = 1;
	ui_label = "Motion Estimation Range";
	ui_tooltip = "The lowest Layer / Resolution Motion Estimation is performed on. Actual range is (2^Range).\n\
Motion Estimation will break down and will produce inacurate Motion Vectors if a Pixel moves close to or more than (2^Range)\n\
LOW PERFORMANCE IMPACT";
	ui_category = "Motion Estimation Block Matching";
> = 6;

uniform int  UI_ME_MAX_ITERATIONS_PER_LEVEL < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 3; ui_step = 1;
	ui_tooltip = "Select how many Search Iterations are done per Layer. Each Iteration is 2x more precise than the last one.\n\
HIGH PERFORMANCE IMPACT";
	ui_label = "Search Iterations per Layer";
	ui_category = "Motion Estimation Block Matching";
> = 2;

uniform int  UI_ME_SAMPLES_PER_ITERATION < __UNIFORM_SLIDER_INT1
	ui_min = 3; ui_max = 9; ui_step = 1;
	ui_tooltip = "Select how many differnt Direction are sampled per Iteration.\n\
HIGH PERFORMANCE IMPACT";
	ui_label = "Samples per Iteration";
	ui_category = "Motion Estimation Block Matching";
> = 5;

//Pyramid
uniform float  UI_ME_PYRAMID_UPSCALE_FILTER_RADIUS < __UNIFORM_SLIDER_FLOAT1
	ui_min = 3.0; ui_max = 5.0; ui_step = 0.25;
	ui_tooltip = "Select how large the Filter Radius is when Upscaling Vectors from one Layer to the Next.\n\
NO PERFORMANCE IMPACT";
	ui_label = "Filer Radius";
	ui_category = "Pyramid Upscaling";
> = 4.0;

uniform int  UI_ME_PYRAMID_UPSCALE_FILTER_RINGS < __UNIFORM_SLIDER_INT1
	ui_min = 3; ui_max = 5; ui_step = 1;
	ui_tooltip = "Select how many Rings of Samples are taken when Upscaling Vectors from one Layer to the Next.\n\
MEDIUM PERFORMANCE IMPACT";
	ui_label = "Filer Rings";
	ui_category = "Pyramid Upscaling";
> = 3;

uniform int  UI_ME_PYRAMID_UPSCALE_FILTER_SAMPLES_PER_RING < __UNIFORM_SLIDER_INT1
	ui_min = 3; ui_max = 9; ui_step = 1;
	ui_tooltip = "Select how many Samples are taken on the inner most Ring when Upscaling Vectors from one Layer to the Next.\n\
HIGH PERFORMANCE IMPACT";
	ui_label = "Samples on inner Ring";
	ui_category = "Pyramid Upscaling";
> = 5;



//Debug_________________________
uniform bool UI_DEBUG_ENABLE <
    ui_label = "Debug View";
    ui_tooltip = "Activates Debug View";
    ui_category = "Debug";
> = false;

uniform int UI_DEBUG_LAYER < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 6; ui_step = 1;
    ui_label = "Pyramid Layer";
	ui_tooltip = "Different Layers of the Pyramid";
    ui_category = "Debug";
> = 0;

uniform int UI_DEBUG_MODE <
	ui_type = "combo";
    ui_label = "Pyramid Data";
	ui_items = "Gray\0Depth\0Frame Difference\0Feature Level\0Motion\0Final Motion\0Velocity Buffer\0Velocity Buffer 3D\0";
	ui_tooltip = "What kind of stuff you wanna see";
    ui_category = "Debug";
> = 5;

uniform int UI_DEBUG_MOTION_ZERO <
	ui_type = "combo";
    ui_label = "Motion Debug Background Color";
	ui_items = "White\0Gray\0Black\0";
	ui_tooltip = "";
	ui_category = "Debug";
> = 1;

uniform float UI_DEBUG_MULT < __UNIFORM_SLIDER_FLOAT1
	ui_min = 1.0; ui_max = 100.0; ui_step = 1;
	ui_tooltip = "Use this is the Debug Output is hard to see";
	ui_label = "Debug Multiplier";
	ui_category = "Debug";
> = 15.0;


/*uniform bool UI_DEBUG_PYRAMID_MERGE <
    ui_label = "Pyramid Merging";
    ui_tooltip = "If disabled, it limits the Search Results of each Layer to its own Range. No Upscaling of lower Level Features";
    ui_category = "Debug";
> = true;


uniform bool UI_DEBUG_PYRAMID_UPSCALE_SPATIAL_FILTER <
    ui_label = "Spacial Pyramid Filtlering";
    ui_tooltip = "spacialy filtering of each Layer. Layer Merging must not be disabled for this to take Effect";
    ui_category = "Debug";
> = true;*/


/*uniform bool UI_DEBUG_PYRAMID_UPSCALE_TEMPORAL_FILTER <
    ui_label = "Temporal Pyramid Filtlering";
    ui_tooltip = "Temporal filtering of each Layer";
    ui_category = "Debug Pyramid Merging";
> = true;*/


/*uniform bool UI_ME_PYRAMID_UPSCALE_TEMPORAL_FILTER <
    ui_label = "Pyramid Upscaling Use Temporal Filtering";
    ui_tooltip = "Uses Different Search and Upscale Samples each Frame and Recontructs their position for more stable Motion Vectors. Good for Motion blur, bad for Taa.";
    ui_category = "Motion Estimation Pyramid";
> = false;

uniform float  UI_ME_PYRAMID_UPSCALE_FILTER_TEMPORAL_STRENGTH < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.25; ui_max = 1.0; ui_step = 0.05;
	ui_tooltip = "Higher Values lead to smoother but more delayed Motion Vectors. Good for Motion blur, bad for Taa.";
	ui_label = "Pyramid Upscaling Temporal Filter Strength";
	ui_category = "Motion Estimation Pyramid";
> = 0.25;*/


