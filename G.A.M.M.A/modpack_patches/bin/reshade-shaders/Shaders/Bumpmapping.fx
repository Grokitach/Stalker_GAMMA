/*
   Bumpmapping Shader
   
   Copyright (C) 2019 guest(r) - guest.r@gmail.com

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform float SMOOTHING <
	ui_min = 0.0; ui_max = 1.0;
    ui_type = "slider";
	ui_label = "Effect Smoothing";
	ui_tooltip = "Effect Smoothing";
    ui_step = 0.001;
> = 0.5;

uniform float RANGE <
	ui_min = 0.5; ui_max = 2.0;
    ui_type = "slider";
	ui_label = "Effect Width";
	ui_tooltip = "Effect Width";
    ui_step = 0.001;
> = 1.0;

uniform float EMBOSS <
	ui_min = 0.0; ui_max = 2.0;
    ui_type = "slider";
    ui_label = "BumpMapping Strength";
    ui_tooltip = "BumpMapping Strength";
    ui_step = 0.001;
> = 1.0;

uniform float CONTRAST <
	ui_min = 0.0; ui_max = 0.40;
	ui_type = "slider";
	ui_label = "Contrast";
	ui_tooltip = "Ammount of haloing etc.";
    ui_step = 0.001;
> = 0.20; 

uniform float SMART <
	ui_min = 0.0; ui_max = 1.0;
	ui_type = "slider";
	ui_label = "Smart Bumpmapping";
	ui_tooltip = "Smart Bumpmapping";
    ui_step = 0.001;
> = 0.75; 


texture SmoothTexture01 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler Texture01S { Texture = SmoothTexture01; };


static const float2 g10 = float2( 0.333,-1.0)*BUFFER_PIXEL_SIZE;
static const float2 g01 = float2(-1.0,-0.333)*BUFFER_PIXEL_SIZE;
static const float2 g12 = float2(-0.333, 1.0)*BUFFER_PIXEL_SIZE;
static const float2 g21 = float2( 1.0, 0.333)*BUFFER_PIXEL_SIZE;

float3 SMOOTH (float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{		
	const float3 c10 = tex2D(ReShade::BackBuffer, uv + g10).rgb;
	const float3 c01 = tex2D(ReShade::BackBuffer, uv + g01).rgb;
	const float3 c11 = tex2D(ReShade::BackBuffer, uv      ).rgb;
	const float3 c21 = tex2D(ReShade::BackBuffer, uv + g21).rgb;
	const float3 c12 = tex2D(ReShade::BackBuffer, uv + g12).rgb;

	const float3 b11 = (c10+c01+c12+c21+c11)*0.2;
	
	return lerp(c11,b11,SMOOTHING);
} 
 

float3 GetWeight(float3 dif1)
{
	return lerp(float3(1.0,1.0,1.0), 0.7*dif1 + 0.3, SMART);
}

float3 BUMP(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	const float3 dt = float3(1.0,1.0,1.0);

	// Calculating texel coordinates
	const float2 inv_size = RANGE * BUFFER_PIXEL_SIZE;	

	const float2 dx = float2(inv_size.x,0.0);
	const float2 dy = float2(0.0, inv_size.y);
	const float2 g1 = float2(inv_size.x,inv_size.y);
	
	const float2 pC4 = uv;	
	
	// Reading the texels
	const float3 c00 = tex2D(Texture01S,uv - g1).rgb; 
	const float3 c10 = tex2D(Texture01S,uv - dy).rgb;
	const float3 c01 = tex2D(Texture01S,uv - dx).rgb;
	const float3 c11 = 0.5*(tex2D(ReShade::BackBuffer,uv).rgb + tex2D(Texture01S,uv).rgb);
	const float3 c21 = tex2D(Texture01S,uv + dx).rgb;
	const float3 c12 = tex2D(Texture01S,uv + dy).rgb;
	const float3 c22 = tex2D(Texture01S,uv + g1).rgb;

	const float3 w00 = GetWeight(saturate(2.25*abs(c00-c22)/(c00+c22+0.25)));
	const float3 w01 = GetWeight(saturate(2.25*abs(c01-c21)/(c01+c21+0.25)));
	const float3 w10 = GetWeight(saturate(2.25*abs(c10-c12)/(c10+c12+0.25)));
	
	const float3 b11 = (w00*(c00-c22) + w01*(c01-c21) + w10*(c10-c12)) + c11;

#if GSHADE_DITHER
	const float3 outcolor = clamp(lerp(c11,b11,-EMBOSS), c11*(1.0-CONTRAST),c11*(1.0+CONTRAST));
	return outcolor + TriDither(outcolor, uv, BUFFER_COLOR_BIT_DEPTH);
#else
	return clamp(lerp(c11,b11,-EMBOSS), c11*(1.0-CONTRAST),c11*(1.0+CONTRAST));
#endif
}

technique BUMPMAPPING
{
	pass bump1
	{
		VertexShader = PostProcessVS;
		PixelShader = SMOOTH;
		RenderTarget = SmoothTexture01; 		
	}
	pass bump2
	{
		VertexShader = PostProcessVS;
		PixelShader = BUMP;
	}
}
