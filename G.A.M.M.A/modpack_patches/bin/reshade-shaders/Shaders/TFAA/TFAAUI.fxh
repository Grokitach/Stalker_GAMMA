/** 
 * - Temporal Filter Anti Aliasing | TFAA
 * - First published 2022 - Copyright, Jakob Wapenhensch
 * - https://creativecommons.org/licenses/by-nc/4.0/
 * - https://creativecommons.org/licenses/by-nc/4.0/legalcode
 */

/*
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

// UI
//User UI

uniform float  UI_TEMPORAL_FILTER_STRENGTH <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
	ui_label = "Temporal Filter Strength";
	ui_category = "Temporal Filter";
	ui_tooltip = "";
> = 0.5;

uniform float  UI_CLAMP_STRENGTH <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.1;
	ui_label = "Clamping Strength";
	ui_category = "Temporal Filter";
	ui_tooltip = "";
> = 0.5;

// uniform float  UI_CLIP_STRESH <
// 	ui_type = "slider";
// 	ui_min = 0.0; ui_max = 1.0; ui_step = 0.1;
// 	ui_label = "Clipping Threshold";
// 	ui_category = "Temporal Filter";
// 	ui_tooltip = "";
// > = 0.5;

uniform float  UI_PRESHARP <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.1;
	ui_label = "Pre Filter Sharpening";
	ui_category = "Sharpening";
	ui_tooltip = "";
> = 0.5;

// uniform float  UI_POSTSHARP <
// 	ui_type = "slider";
// 	ui_min = 0.0; ui_max = 1.0; ui_step = 0.1;
// 	ui_label = "Post Filter Sharpening";
// 	ui_category = "Sharpening";
// 	ui_tooltip = "";
// > = 0.5;

uniform bool UI_USE_CUBIC_HISTORY <
	ui_label = "Cubic History Sampling";
	ui_category = "Sharpening";
	ui_tooltip = "Default (ON) \nIf activated Bicubic Interpolation is used to resample Data from the past instead of basic Bilinear Interpolation. \nThis makes the image much sharper in motion";
> = true;


uniform int UI_COLOR_FORMAT <
	ui_type = "combo";
	ui_items = "RGB\0YCgCo\0YCbCr\0";
	ui_label = "Clamping Color Space ";
	ui_category = "Clamping Method";
	ui_tooltip = "Default (YCbCr) \nThis selects what color space is used to clamp data from past Frames. \nThe YCgCo and YCbCr color spaces, in contrast to RGB, dedicate one of their 3 channels to brightness, \nthis makes them much sharper on high Filter Strength settings\n ";
> = 2;

uniform int UI_CLAMP_PATTERN <
	ui_type = "combo";
	ui_items = "Cross (4 Samples)\0Rounded Box (8 Samples)\0";
	ui_label = "Clamp Pattern";
	ui_category = "Clamping Method";
	ui_tooltip = "Default (Rounded Box (8 Samples)) \nThis selects how many neighbouring pixels are sampled to calculate clamping and sharpening weights";
> = 1;

uniform int UI_CLAMP_TYPE <
	ui_type = "combo";
	ui_items = "Min/Max Clamping\0Variance Clamping\0None (Debug)\0";
	ui_label = "Camping Type";
	ui_category = "Clamping Method";
	ui_tooltip = "Default (Min/Max Clamping) \nThis selects what formula is used to clamp data from past frames into a reasonable range. \nOne is not better than the other and they don't have the same clamping strength by default.";
> = 0;

