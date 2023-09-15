//VolumetricFog
//Written by MJ_Ehsan for Reshade
//Version 2.0alpha

//license
//CC0 ^_^

///////////////Include/////////////////////

#pragma warning(disable : 3571)

#ifndef SMOOTH_BLUR_EDGES
 #define SMOOTH_BLUR_EDGES 1
#endif

#include "ReShadeUI.fxh"
#include "ReShade.fxh"

#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

#define LDepth ReShade::GetLinearizedDepth
#define AspectRatio (BUFFER_WIDTH/BUFFER_HEIGHT)

///////////////Include/////////////////////
///////////////Textures-Samplers///////////

texture OGColTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler sOGColTex { Texture = OGColTex; };

///////////////Textures-Samplers///////////
///////////////UI//////////////////////////

uniform float radius < 
	ui_label = "Radius";
	ui_type = "slider";
	ui_min = 0.000;
	ui_max = 1.0;
	ui_tooltip = "Blurriness of the fog. \n_SMOOTH_BLUR_EDGES also the affects the blur radius a little.";
> = 0.50;

uniform float power < 
	ui_label = "Power";
	ui_type = "slider";
	ui_min = 0.000;
	ui_max = 1.0;
	ui_tooltip = "Visibility of the fog.";
> = 0.50;

uniform float boost < 
	ui_label = "Boost";
	ui_type = "slider";
	ui_min = 1;
	ui_max = 10;
	ui_tooltip = "Brightness of the fog.";
> = 1;

uniform float3 abscolor <
	ui_label = "Absorption Color";
	ui_type = "color";
> = float3(0.5,0.5,0.5);

uniform int BM <
	ui_label = "Blend Mode";
	ui_type = "combo";
	ui_items = "Hard Light\0Soft Light\0";
> = 0;

uniform bool debug <>;


uniform int Hints<
	ui_text = 
		"\nSMOOTH_BLUR_EDGES can go from 0 to 5. values higher than 5 "
		"behave the same as 5. Higher values smooth the filter and "
		"increase the overall blur quality at the cost of lower performance."; 
		
	ui_category = "PreProcessor Definitions Tooltip";
	ui_category_closed = true;
	ui_label = " ";
	ui_type = "radio";
>;

///////////////UI//////////////////////////
///////////////Functions///////////////////

float4 Atrous(inout float4 color, in float2 texcoord, in float Radius)
{
	float2 t, p; float DG, Depth, Determinator;
	
	Depth = LDepth(texcoord);
	Determinator = Depth-0.1;
	p = pix; p *= Radius*Depth*8;
	
	[unroll]for(int x = -1; x <= 1; x++){
	[unroll]for(int y = -1; y <= 1; y++){
			t = texcoord + float2(x,y)*p;
			DG = LDepth(t);
			if(DG > Determinator)
				color += float4(tex2D(ReShade::BackBuffer, t).rgb, 1);
	}}
	return color;
}

float3 HardLight( inout float3 Blend, in float3 Target)
{
	if(BM == 0)//HardLight
	Blend = (Blend > 0.5) * (1 - (1-Target) * (1-2*(Blend-0.5))) +
	(Blend <= 0.5) * (Target * (2*Blend));
	
	if(BM == 1)//SoftLight
	Blend = (Blend > 0.5) * (1 - (1-Target) * (1-(Blend-0.5))) +
	(Blend <= 0.5) * (Target * (Blend+0.5));;
	
	return Blend;
}

///////////////Functions///////////////////
///////////////Vertex Shader///////////////
///////////////Vertex Shader///////////////
///////////////Pixel Shader////////////////

void OGColTexOut(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float4 OGCol : SV_Target0)
{
	OGCol = tex2D(ReShade::BackBuffer, texcoord).rgba;
}

float3 Filter00(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 color;

	Atrous( color, texcoord, 81*saturate(radius*1)).rgb;
	return color.rgb/color.a;
}

float3 Filter0(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 color;

	Atrous( color, texcoord, 27*saturate(radius*3)).rgb;
	return color.rgb/color.a;
}

float3 Filter1(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 color;

	Atrous( color, texcoord, 9*saturate(radius*9)).rgb;
	return color.rgb/color.a;
}

float3 Filter2(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 color;

	Atrous( color, texcoord, 3*saturate(radius*27)).rgb;
	return color.rgb/color.a;
}

float3 Filter3(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 color;

	Atrous( color, texcoord, 1*saturate(radius*81)).rgb;
	return color.rgb/color.a;
}

float3 OutColor(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 Background = tex2D( sOGColTex, texcoord).rgb;
	float Depth = LDepth(texcoord);
	
	color = color / (( 1 + 1 / boost) - color);
	
	lerp( color, HardLight( color, abscolor), Depth*power);
	
	if(!debug){
	return lerp( Background, color.rgb, pow(saturate(Depth), (1-power)));
	} else{ return color.rgb;}
}

///////////////Pixel Shader////////////////
///////////////Techniques//////////////////

technique VolumetricFogV2 <
	ui_label = "Volumetric Fog V2 - alpha";
	ui_tooltip = "Screen Space Indirect Volumetric Lighting - Version 2.0\n"
				 "                    ||By Ehsan2077||                    \n"
				 "SSIVL V2 uses a different technique so no need for TFAA.\n"; 
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = OGColTexOut;
		RenderTarget0 = OGColTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Filter00;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Filter0;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Filter1;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Filter2;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Filter3;
	}
#if SMOOTH_BLUR_EDGES > 4
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Filter00;
	}
#endif
#if SMOOTH_BLUR_EDGES > 3
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Filter0;
	}
#endif
#if SMOOTH_BLUR_EDGES > 2
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Filter1;
	}
#endif
#if SMOOTH_BLUR_EDGES > 1
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Filter2;
	}
#endif
#if SMOOTH_BLUR_EDGES > 0
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Filter3;
	}
#endif
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = OutColor;
	}
}

///////////////Techniques//////////////////
