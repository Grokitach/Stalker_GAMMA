//VolumetricFog
//Written by MJ_Ehsan for Reshade
//Version 1.1a

//license
//CC0 ^_^

///////////////Include/////////////////////

#include "ReShadeUI.fxh"
#include "ReShade.fxh"

#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

#ifndef MAX_MIPSLEVELS_
 #define MAX_MIPSLEVELS_ 2
#endif

#if MAX_MIPSLEVELS_ > 10
 #undef MAX_MIPSLEVELS_
 #define MAX_MIPSLEVELS_ 10
#endif

uniform float Timer < source = "timer"; >;

///////////////Include/////////////////////
///////////////Textures-Samplers///////////

texture2D TexColor : COLOR;
sampler  sTexColor {Texture = TexColor; };

texture2D FogTex { Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA8;};
sampler2D sFogTex { Texture = FogTex;};

texture2D BlurTex 	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA8; MipLevels = MAX_MIPSLEVELS_+1; };
sampler2D sBlurTex	{ Texture = BlurTex;	};

///////////////Textures-Samplers///////////
///////////////UI//////////////////////////

uniform float radius <
	ui_type = "slider";
	ui_max = 200;
	ui_label = "Blur Radius";
	ui_tooltip = "Increase it along with Intensity\n"
				 "if you want a denser fog."; 
	ui_category = "Blurring";
> = 100;

uniform int SampleCount <
	ui_label = "Blur Quality";
	ui_tooltip = "Increase it to reduce noise.\n"
				 "Also look at Temporal Accumulation or Denoiser\n"
				 "Cuz this option is a performance killer";
	ui_max = 8;
	ui_min = 1;
	ui_type = "slider";
	ui_category = "Blurring";
> = 2;

uniform bool TemporalAccum <
	ui_type = "radio";
	ui_label = "Temporal Accumulation";
	ui_tooltip = "If you are using (TFAA) from jak0b,\n"
				 "use this option to improve blur quality for free";
	ui_category = "Blurring";
> = 1;

uniform float Intensity <
	ui_max = 8;
	ui_min = 0;
	ui_type = "slider";
	ui_tooltip = "Overall power of fog.";
	ui_category = "Blending";
> = 1;

uniform float MaxIntensity <
	ui_type = "slider";
	ui_label = "Maximum Intensity";
	ui_max = 1;
	ui_tooltip = "Intensity of fog is relative to depth\n"
				 "Objects further away will be affected more than near ones\n"
				 "You can use this option to avoid fading distant objects completely.";
	ui_category = "Blending";
> = 0.8;

uniform float Exposure <
	ui_type = "slider";
	ui_max = 2;
	ui_category = "Blending";
> = 1;

uniform float Gamma <
	ui_type = "slider";
	ui_max = 2;
	ui_category = "Blending";
> = 1;

//uniform bool Shadow <> = 0;
//static const bool Shadow = 0;


///////////////UI//////////////////////////
///////////////Functions///////////////////

float noise(float2 co)
{
	return frac(sin(dot(co.xy ,float2(1.0,73))) * 43758.5453);
}

float3 noise3dts(float2 co, int s, bool t)
{
	co += sin(Timer/64)*t;
	co += frac(s/3.1415926535);
	return float3( noise(co), noise(co+0.6432168421), noise(co+0.19216811));
}

///////////////Functions///////////////////
///////////////Vertex Shader///////////////
///////////////Vertex Shader///////////////
///////////////Pixel Shader////////////////

float3 Fog( float4 Postion : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float depth = ReShade::GetLinearizedDepth(texcoord);
	float2 p = pix;
	
	float4 color = float4(tex2D(sTexColor, texcoord).rgb,1);
	float4 S = color;
	float Radius = sqrt(depth)*radius;
	uint iteration = Radius*SampleCount/8;
	
	for (int i = 1; i <= iteration; i++)
	{	
		float2 seed = noise3dts( texcoord.xy, i, TemporalAccum).rg;	
		//float distance = (i + seed.x)/iteration;
		float distance = seed.x;
		//float ang = frac(seed.x + i * 0.6180339887498) * 3.1415927 * 2.0;
		float ang = ((i + seed.y) / iteration) * 3.14159265 * 2;
		
		float2 offset; sincos(ang, offset.y, offset.x); 
		offset *= sqrt(distance);
		offset *= p.xy * Radius;
		
		float Jdepth =  ReShade::GetLinearizedDepth(texcoord + offset).r;
		if( Jdepth >= depth -0.01)
		{
			S += float4( tex2Dlod( sTexColor, float4(texcoord + offset,0,0)).rgb, 1);
		}
	}

	S.rgb /= S.a;
	
	float coeff = min( depth*Intensity, MaxIntensity);
	//if(Shadow) S = lerp(S, S * saturate(tex2D(sCommonTex0, texcoord)), min((1-depth)*Intensity, 1));
	
	return S.rgb;
}

float3 Blur( float4 Postion : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float depth = ReShade::GetLinearizedDepth(texcoord);
	float2 p = pix;
	
	float4 color = float4(tex2D(sFogTex, texcoord).rgb,1);
	float4 S = color;

	float Radius = radius/16;
	uint iteration = max(SampleCount, 2); //iteration = 0;
	
	for (int i = 1; i <= iteration; i++)
	{	
		float2 seed = noise3dts( texcoord.xy + 0.33463545721, i, TemporalAccum).rg;
		
		float distance = seed.x;
		float ang = ((i + seed.y) / iteration) * 3.14159265 * 2;
		
		float2 offset; sincos(ang, offset.y, offset.x); 
		offset *= sqrt(distance);
		offset *= p.xy * Radius;
		
		float Jdepth =  ReShade::GetLinearizedDepth(texcoord + offset).r;
		if( Jdepth >= depth -0.01)
		{
			S += float4( tex2Dlod( sFogTex, float4(texcoord + offset,0,0)).rgb, 1);
		}
	}

	S.rgb /= S.a;
	S = pow( abs(S), Gamma)*Exposure;
	return S.rgb;
}

float3 Blend( float4 Postion : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float depth = ReShade::GetLinearizedDepth(texcoord);
	float2 p = pix; p *= pow(2, MAX_MIPSLEVELS_);
	
	float4 fog; fog.a = 1; fog.rgb = tex2Dlod(sBlurTex, float4(texcoord,0,MAX_MIPSLEVELS_)).rgb;
	
	float2 offset[8] =
	{
		float2(  0, p.y), float2( p.x,  0), float2(   0, -p.y), float2(-p.x,    0),
		float2(p.x, p.y), float2(-p.x,p.y), float2(-p.x, -p.y), float2( p.x, -p.y)
	};
	
	
	if( MAX_MIPSLEVELS_ != 0)
	{
		float4 FogSample; FogSample.a = 1;
		float3 DepthSample;
		for(int i; i<8; i++)
		{
			FogSample.rgb = tex2Dlod(sBlurTex, float4(texcoord + offset[i]/2, 0, MAX_MIPSLEVELS_)).rgb;
			DepthSample = ReShade::GetLinearizedDepth(texcoord + offset[i]*1.5);
			if( abs( DepthSample.x - depth.x) < 0.01) fog += FogSample;
		}
		fog /= fog.a;
	}
	
	float3 back= tex2D(sTexColor, texcoord).rgb;
	
	float coeff = min( depth * Intensity, MaxIntensity);
	
	return lerp( back, fog.rgb, coeff);
}

///////////////Pixel Shader////////////////
///////////////Techniques//////////////////

technique VolumetricFog <
	ui_label = "Volumetric Fog";
	ui_tooltip = "Screen  Space  Indirect  Volumetric  Lighting.\n"
				 "              ||By Ehsan2077||                \n"
				 "Recommended to use with TFAA for more quality."; 
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Fog;
		RenderTarget = FogTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Blur;
		RenderTarget = BlurTex;
	}
	pass
	{		
		VertexShader = PostProcessVS;
		PixelShader = Blend;
	}
}

///////////////Techniques//////////////////
