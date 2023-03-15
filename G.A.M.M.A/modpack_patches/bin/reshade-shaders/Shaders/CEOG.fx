////-----------//
///***CEOG***//
//-----------////
// Created by 2b3, ported to ReShade 3 by Insomnia, and lightly optimized by Marot Satil.

//Preprocessor
#define ceog_min 0.00 // [0.00:1.00] //-min value
#define ceog_max 1.00 // [0.00:1.00] //-max value

uniform float ceog_ctr <
	ui_type = "slider";
	ui_min = -100.0; ui_max = 100.0;
	ui_step = 0.01;
	ui_tooltip = "Contrast";
	ui_label = "Contrast";
> = 0.0;
uniform float ceog_e <
	ui_type = "slider";
	ui_min = -20.0; ui_max = 20.0;
	ui_step = 0.01;
	ui_tooltip = "Exposure";
	ui_label = "Exposure";
> = 0.0;
uniform float ceog_o <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_step = 0.005;
	ui_tooltip = "Offset";
	ui_label = "Offset";
> = 0.00;
uniform float ceog_g <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 10.0;
	ui_step = 0.01;
	ui_tooltip = "Gamma";
	ui_label = "Gamma";
> = 1.0;
uniform float Saturation <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "Adjust saturation";
> = 0.0;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 CEOGPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	const float mn=min(color.r, min(color.g, color.b));
	const float mx=max(color.r, max(color.g, color.b));
	
	if(mn >= ceog_min && mx <= ceog_max)
	{
		float ctr=ceog_ctr;
		const float3 color_tmp=color.rgb;

		if (ctr < 0.0)
			ctr = max(ctr/100.0, -100.0);
		else
			ctr = min(ctr, 100.0);
		color.rgb=(color.rgb-0.5)*max(ctr+1.0, 0.0)+0.5;

		color.rgb=pow(saturate(color.rgb*pow(2, ceog_e)+ceog_o), 1/ceog_g);

		const float3 diffcolor = color - dot(color, (1.0 / 3.0));
		color = (color + diffcolor * Saturation) / (1 + (diffcolor * Saturation)); // Saturation

		if(ceog_min > 0 && ceog_max < 1)
		{
			const float dlt=(ceog_max-ceog_min)*0.25;
			if(mn <= (ceog_min+dlt)) color.rgb=lerp(color_tmp, color.rgb, (mn-ceog_min)/dlt);
			else if(mx >= (ceog_max-dlt)) color.rgb=lerp(color_tmp, color.rgb, (ceog_max-mx)/dlt);
		}
	}
	
#if GSHADE_DITHER
	return color + TriDither(color, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return color;
#endif
}


technique CEOG
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CEOGPass;
	}
}