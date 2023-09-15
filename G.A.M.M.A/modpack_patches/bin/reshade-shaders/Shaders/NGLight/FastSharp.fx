//FastSharp
//Written by MJ_Ehsan for Reshade
//Version 1.0

//license
//CC0 ^_^

///////////////Include/////////////////////

#include "ReShadeUI.fxh"

///////////////Include/////////////////////
///////////////Textures-Samplers///////////

texture TexColor : COLOR;
sampler sTexColor {Texture = TexColor; SRGBTexture = false;};

///////////////Textures-Samplers///////////
///////////////UI//////////////////////////

uniform float amount <
	ui_type = "slider";
	ui_label = "Sharpness intensity";
> = 0.3;

uniform float mask_amount <
	ui_type = "slider";
	ui_label = "halo removal power";
> = 0.5;

uniform int size <
	ui_type = "combo";
	ui_label = "filter";
	ui_tooltip = "cross only sharpens the most tiny details, while wide catches coarse details too";
	ui_items = "narrow\0wide\0";
> = 1;

///////////////UI//////////////////////////
///////////////Functions///////////////////
///////////////Functions///////////////////
///////////////Vertex Shader///////////////

void VS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

///////////////Vertex Shader///////////////
///////////////Pixel Shader////////////////

float3 PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(sTexColor, texcoord).rgb;
 
	float3 s = color;

	//sample weights:
	// 0  0  2  0  0
	// 0  3  6  3  0
	// 2  6  6  6  2
	// 0  3  6  3  0
	// 0  0  2  0  0
	s += tex2Doffset(sTexColor, (float2(texcoord)), int2( 1,  0)).rgb;
	s += tex2Doffset(sTexColor, (float2(texcoord)), int2(-1,  0)).rgb;
	s += tex2Doffset(sTexColor, (float2(texcoord)), int2( 0, -1)).rgb;
	s += tex2Doffset(sTexColor, (float2(texcoord)), int2( 0,  1)).rgb;
	 
	float3 cross = s;
	float3 wide;
	if ( size == 1 )
	{
		s += (tex2Doffset(sTexColor, (float2(texcoord)), int2( 1,  1)).rgb)/2;
		s += (tex2Doffset(sTexColor, (float2(texcoord)), int2(-1,  1)).rgb)/2;
		s += (tex2Doffset(sTexColor, (float2(texcoord)), int2( 1, -1)).rgb)/2;
		s += (tex2Doffset(sTexColor, (float2(texcoord)), int2(-1, -1)).rgb)/2;
		
		s += (tex2Doffset(sTexColor, (float2(texcoord)), int2( 0, -2)).rgb)/3;
		s += (tex2Doffset(sTexColor, (float2(texcoord)), int2( 0,  2)).rgb)/3;
		s += (tex2Doffset(sTexColor, (float2(texcoord)), int2( 2,  0)).rgb)/3;
		s += (tex2Doffset(sTexColor, (float2(texcoord)), int2(-2,  0)).rgb)/3;
		
		wide = s/8.3333333333333;
	}

	
	float3 sharpness = color-wide;
	
	float3 csharpness = color-(cross/5);

	float3 sharp = color+(amount*5*sharpness);
	
	float3 csharp = color + (amount*5*csharpness);
	
	float3 mask = saturate(abs(csharpness*mask_amount*16));
	
	//return blur; // for cutom debug views. comment the next return funtion to use
	
	if ( size == 1 )
	{return lerp(sharp, color, mask);}
	else
	{return lerp(csharp, color, mask);}
}

///////////////Pixel Shader////////////////
///////////////Techniques//////////////////

technique FastSharp
< ui_label = "Fast Sharp";
  ui_tooltip = "Fast Adaptive Sharpening Filter."
			   "        ||By Ehsan2077||        ";>
{
	pass MJEhsan_FastSharp
	{
		VertexShader = VS;
		PixelShader = PS;
	}
}

///////////////Techniques//////////////////
