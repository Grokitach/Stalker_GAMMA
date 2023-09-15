#include "ReShade.fxh"

/*
	Cheap debanding shader. Finetuned for S.T.A.L.K.E.R. games.

	Author: LVutner
	Contact (Discord): @LVutner#5199

  How to use it? 
  1. Download blue noise textures from: https://momentsingraphics.de/BlueNoise.html
  2. Find LDR_RG01_8.png file in blue noise archive (Data\128_128\LDR_RG01_8)
  3. Put it in yourgamefolder\bin\reshade-shaders\Textures
  4. Enable LV_deband shader in ReShade menu
  5. Enjoy

  You might need to tweak the blur radius to your liking. 
*/

//The only setting. Radius of pseudo-stochastic-meme-blur
uniform float BLUR_RADIUS <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.125;
    ui_label = "Blur radius";
> = 0.045;

//Frame counter
uniform int framecount < source = "framecount"; >;

//Copy of BB
texture2D RT_BACKBUFFER_MIPPED
{
	Width = BUFFER_WIDTH; 
	Height = BUFFER_HEIGHT; 
	Format = RGBA8;
	MipLevels = 4;
};

sampler2D S_BACKBUFFER_MIPPED
{ 
	Texture = RT_BACKBUFFER_MIPPED;

	AddressU = CLAMP;
	AddressV = CLAMP;
	AddressW = CLAMP;
};

//Blue noise texture
texture2D bluenoise_tex < source = "LDR_RG01_13.png"; >
{
	Width = 128;
	Height = 128;
	Format = RG8;
};

sampler2D blue_noise
{
	Texture = bluenoise_tex;
	
	AddressU = Wrap; 
	AddressV = Wrap; 
	AddressW = Wrap;
	
	MipFilter = Point; 
	MinFilter = Point; 
	MagFilter = Point;
	
	SRGBTexture = false;
};

//Save backbuffer and generate mips
float4 PS_SAVE_BACKBUFFER(float4 hpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return float4(tex2Dlod(ReShade::BackBuffer, float4(texcoord, 0, 0)).xyz, 1.0);
}

//Deband
float4 PS_DRAW_BACKBUFFER(float4 hpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 center_color = tex2Dlod(S_BACKBUFFER_MIPPED, float4(texcoord, 0.0, 0.0)).xyz;

	if(ReShade::GetLinearizedDepth(texcoord) < 1.0 || BLUR_RADIUS == 0.0) 
		return float4(center_color, 1.0);

	float2 bluenoise = tex2Dfetch(blue_noise, int2(hpos.xy) % 128).xy;

    float2 texcoord_offset = frac(bluenoise + float(framecount % 64) * float2(0.75487766, 0.56984029)) - 0.5;
    float3 blurred_color = tex2Dlod(S_BACKBUFFER_MIPPED, float4(texcoord + texcoord_offset * BLUR_RADIUS, 0.0, 3.0)).xyz;

    float3 deviation = blurred_color - center_color;
    deviation = max(0.0, sqrt(deviation * deviation));

    center_color = lerp(center_color, blurred_color, float3(deviation < 0.02946));

	return float4(center_color, 1.0);
}

technique LV_deband
< ui_tooltip = "Cheap banding killa"; >
{
	pass PS_SAVE_BACKBUFFER
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_SAVE_BACKBUFFER;
		RenderTarget = RT_BACKBUFFER_MIPPED;
	}

	pass PS_DRAW_BACKBUFFER
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_DRAW_BACKBUFFER;
	}
}