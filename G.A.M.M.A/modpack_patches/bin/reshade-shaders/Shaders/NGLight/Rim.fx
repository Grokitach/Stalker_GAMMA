//Rim
//Written by MJ_Ehsan for Reshade
//Version 1.0a

//license
//CC0 ^_^

///////////////Include/////////////////////

#include "ReShadeUI.fxh"
#include "ReShade.fxh"

#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

#if __RENDERER__ < 0xA000
 #define D3D9 0 //yes it's weird to set true value as 0 and false as 1?
#else
 #define D3D9 1
#endif

///////////////Include/////////////////////
///////////////Textures-Samplers///////////

texture TexColor : COLOR;
sampler sTexColor {Texture = TexColor; SRGBTexture = false;};	

texture TexDepth : DEPTH;
sampler sTexDepth {Texture = TexDepth; SRGBTexture = false;};

texture TexRim { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sTexRim {Texture = TexRim; SRGBTexture = false;};	

texture TexHBlur { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sTexHBlur {Texture = TexHBlur; SRGBTexture = false;};

///////////////Textures-Samplers///////////
///////////////UI//////////////////////////

uniform int Blend <
	ui_label = "Blend Mode";
	ui_type = "combo";
	ui_items = "Add\0Color Dodge\0";
> = 0;

uniform float smooth <
	ui_label = "Rim Width";
	ui_type = "slider";
	ui_tooltip = "Higher values limits the rim to a tighter area";
	ui_category = "Rim";
	ui_min = 1;
	ui_max = 10;
> = 5;

uniform float Rim <
	ui_label = "Rim Intensity";
	ui_type = "slider";
	ui_category = "Rim";
	ui_tooltip = "Exposure of the rim";
	ui_min = 0;
	ui_max = 100;
> = 1;

uniform float3 light <
	ui_label = "Rim Light Color";
	ui_category = "Rim";
	ui_type = "color";
> = 1;

#if D3D9
uniform int BLUR_ITERATION_ <
	ui_label = "Bloom Width";
	ui_type = "slider";
	ui_category = "Bloom";
	ui_min = 1;
	ui_max = 16;
> = 4;
#else
#ifndef BLUR_ITERATION_
 #define BLUR_ITERATION_ 4
#endif
#endif
uniform float bloom <
	ui_label = "Bloom Intensity";
	ui_type = "slider";
	ui_category = "Bloom";
	ui_min = 0;
	ui_max = 10;
> = 1;

uniform float MaxDepth <
	ui_label = "Max Depth";
	ui_tooltip = "Depth Masking End Clipping";
	ui_category = "Masking";
	ui_type = "slider";
> = 1;

uniform float MinDepth <
	ui_label = "Min Depth";
	ui_category = "Masking";
	ui_tooltip = "Depth Masking Start Clipping";
	ui_type = "slider";
> = 0;

//static const bool Quality = 0;

///////////////UI//////////////////////////
///////////////Functions///////////////////

float3 Depth(float2 texcoord)
{
	return ReShade::GetLinearizedDepth(texcoord);
}

float3 GetNormal(float2 texcoord)
{
	float3 offset = float3(BUFFER_PIXEL_SIZE, 0.0);
	float2 posCenter = texcoord.xy;
	float2 posNorth  = posCenter - offset.zy;
	float2 posEast   = posCenter + offset.xz;

	float3 vertCenter = float3(posCenter - 0.5, 1) * Depth(posCenter);
	float3 vertNorth  = float3(posNorth  - 0.5, 1) * Depth(posNorth);
	float3 vertEast   = float3(posEast   - 0.5, 1) * Depth(posEast);

	return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;
}

float3 GetNormalHQ(float2 texcoord)
{
	float3 p = float3(BUFFER_PIXEL_SIZE, 0.0);
	float3 h;
	float3 v;
	//-|1|-
	//2|5|3
	//-|4|-
	float3 Sample[6];
	Sample[1] = Depth(texcoord + p.zy);// * float3( texcoord + p.zy - 0.5, 1);
	Sample[2] = Depth(texcoord - p.xz);// * float3( texcoord - p.xz - 0.5, 1);
	Sample[3] = Depth(texcoord - p.zy);// * float3( texcoord - p.zy - 0.5, 1);
	Sample[4] = Depth(texcoord + p.xz);// * float3( texcoord + p.xz - 0.5, 1);
	Sample[5] = Depth(texcoord       );// * float3( texcoord        - 0.5, 1);
	
	h = Sample[5] - Sample[3];
	if( dot( 0.333, abs(Sample[5] - Sample[2])) < dot( 0.333, abs(Sample[5] - Sample[3])))
	h = Sample[2] - Sample[5];
		
	v = Sample[5] - Sample[4];
	if( dot( 0.333, abs(Sample[5] - Sample[1])) < dot( 0.333, abs(Sample[5] - Sample[4])))
	v = Sample[1] - Sample[5];
		
	//return normalize(cross(h, v)) * 0.5 + 0.5;
	return float3(h.x,v.x,10) * 0.5 + 0.5;
}
///////////////Functions///////////////////
///////////////Vertex Shader///////////////
///////////////Vertex Shader///////////////
///////////////Pixel Shader////////////////

float3 rim(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float2 p = pix;
	float3 normal; normal = GetNormal( texcoord ).z;
	//if(Quality == 0) {normal = GetNormal( texcoord ).z;}
	//else             {normal = GetNormalHQ(texcoord).z;}
	
	float3 color = tex2D(sTexColor, texcoord).rgb;
	
	normal = 1-normal;
	normal = pow(abs(normal), smooth);
	normal *= Rim;
	
	color = normal * color * (light);
	color = color/(color+1);
	return color;
}

float3 HBlur(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float2 p = pix;
	float3 Color = 0;
	
	for (int i = -BLUR_ITERATION_; i <= BLUR_ITERATION_; i++)
	{
		int x = abs(i);
		Color += (BLUR_ITERATION_ - x)*tex2D( sTexRim, texcoord + float2(( p.r * ( ( 2 * i ) + 0.5 )), 0)).rgb;	
	}
	return Color/((BLUR_ITERATION_*BLUR_ITERATION_));	
}

float3 VBlur(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float2 p = pix;
	float3 Color;
	float3 Bloom;
	float3 Background = tex2D(sTexColor, texcoord).rgb;
	float Depth = ReShade::GetLinearizedDepth(texcoord);
	
	for (int i = -BLUR_ITERATION_; i <= BLUR_ITERATION_; i++)
	{
		int x = abs(i);
		Color += (BLUR_ITERATION_ - x)*tex2D( sTexHBlur, texcoord + float2(0,( p.g * ( ( 2 * i ) + 0.5 )))).rgb;	
	}
	Bloom = Color/((BLUR_ITERATION_*BLUR_ITERATION_));
	
	Bloom *= bloom;
	Bloom += tex2D( sTexRim, texcoord).rgb;
	Bloom = saturate(Bloom);
	float3 Mixed;
	if(Blend == 0) Mixed = Bloom + Background;
	if(Blend == 1) Mixed = Background / ( 1 - Bloom );
	
	Mixed = lerp(Background, Mixed, bool ( Depth < MaxDepth && Depth > MinDepth ));
	return Mixed;
	//return GetNormalHQ(texcoord);
}
///////////////Pixel Shader////////////////
///////////////Techniques//////////////////

technique Rim <
	ui_tooltip = "               Rim Light Effect               \n"
				 "               ||By Ehsan2077||               \n"
				 "Add an AO shader after this for a better look.";

>
{
	pass Rim
	{
		VertexShader = PostProcessVS;
		PixelShader = rim;
		RenderTarget = TexRim;
	}
	pass HBlur
	{
		VertexShader = PostProcessVS;
		PixelShader = HBlur;
		RenderTarget = TexHBlur;
	}
	pass VBlur	
	{
		VertexShader = PostProcessVS;
		PixelShader = VBlur;
		//RenderTarget = TexVBlur;
	}
}


///////////////Techniques//////////////////
