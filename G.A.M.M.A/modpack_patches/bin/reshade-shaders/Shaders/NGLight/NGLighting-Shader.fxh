//Stochastic Screen Space Ray Tracing
//Written by MJ_Ehsan for Reshade
//Version 0.9.1

//Thanks Lord of Lunacy, Leftfarian, and other devs for helping me. <3
//Thanks Alea & MassiHancer for testing. <3

//Credits:
//Thanks Crosire for ReShade.
//https://reshade.me/

//Thanks Jakob for DRME.
//https://github.com/JakobPCoder/ReshadeMotionEstimation

//I learnt a lot from qUINT_SSR. Thanks Pascal Gilcher.
//https://github.com/martymcmodding/qUINT

//Also a lot from DH_RTGI. Thanks Demien Hambert.
//https://github.com/AlucardDH/dh-reshade-shaders

//Thanks Radegast for Unity Sponza Test Scene.
//https://mega.nz/#!qVwGhYwT!rEwOWergoVOCAoCP3jbKKiuWlRLuHo9bf1mInc9dDGE

//Thanks Timothy Lottes and AMD for the Tonemapper and the Inverse Tonemapper.
//https://gpuopen.com/learn/optimized-reversible-tonemapper-for-resolve/

//Thanks Eric Reinhard for the Luminance Tonemapper and  the Inverse.
//https://www.cs.utah.edu/docs/techreports/2002/pdf/UUCS-02-001.pdf

//Thanks sujay for the noise function. Ported from ShaderToy.
//https://www.shadertoy.com/view/lldBRn

//////////////////////////////////////////
//TO DO
//1- [v]Add another spatial filtering pass
//2- [ ]Add Hybrid GI/Reflection
//3- [v]Add Simple Mode UI with setup assist
//4- [ ]Add internal comaptibility with Volumetric Fog V1 and V2
//      By using the background texture provided by VFog to blend the Reflection.
//      Then Blending back the fog to the image. This way fog affects the reflection.
//      But the reflection doesn't break the fog.
//5- [ ]Add ACEScg and or Filmic inverse tonemapping as optional alternatives to Timothy Lottes
//6- [v]Add AO support
//7- [v]Add second temporal pass after second spatial pass.
//8- [o]Add Spatiotemporal upscaling. have to either add jitter to the RayMarching pass or a checkerboard pattern.
//9- [v]Add Smooth Normals.
//10-[v]Use pre-calulated blue noise instead of white. From Nvidia's SpatioTemporal Blue Noise sequence
//11-[v]Add depth awareness to smooth normals. To do so, add depth in the alpha channel of 
//	  NormTex and NormTex1 for optimization.
//12-[v]Make normal based edge awareness of all passes based on angular distance of the 2 normals.
//13-[o]Make sample distance of smooth normals exponential.
//14-[ ]

///////////////Include/////////////////////

#include "ReShadeUI.fxh"
#include "ReShade.fxh"
#include "NGLightingUI.fxh"

uniform float Timer < source = "timer"; >;
uniform float Frame < source = "framecount"; >;

static const float2 pix = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

#define LDepth ReShade::GetLinearizedDepth

#define FAR_PLANE RESHADE_DEPTH_LINEARIZATION_FAR_PLANE 

#define PI 3.1415927
static const float PI2div360 = PI/180;
#define rad(x) x*PI2div360
///////////////Include/////////////////////
///////////////PreProcessor-Definitions////

#include "NGLighting-Configs.fxh"

///////////////PreProcessor-Definitions////
///////////////Textures-Samplers///////////

texture TexColor : COLOR;
sampler sTexColor {Texture = TexColor; SRGBTexture = false;};

texture TexDepth : DEPTH;
sampler sTexDepth {Texture = TexDepth;};

texture texMotionVectors { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
sampler SamplerMotionVectors { Texture = texMotionVectors; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Point; MagFilter = Point; };

texture SSSR_ReflectionTex  { Width = BUFFER_WIDTH*RESOLUTION_SCALE_; Height = BUFFER_HEIGHT*RESOLUTION_SCALE_; Format = RGBA16f; };
sampler sSSSR_ReflectionTex { Texture = SSSR_ReflectionTex; };

texture SSSR_HitDistTex { Width = BUFFER_WIDTH*RESOLUTION_SCALE_; Height = BUFFER_HEIGHT*RESOLUTION_SCALE_; Format = R16f; MipLevels = 7; };
sampler sSSSR_HitDistTex { Texture = SSSR_HitDistTex; };

texture SSSR_POGColTex  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f; };
sampler sSSSR_POGColTex { Texture = SSSR_POGColTex; };

texture SSSR_FilterTex0  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sSSSR_FilterTex0 { Texture = SSSR_FilterTex0; };

texture SSSR_FilterTex1  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sSSSR_FilterTex1 { Texture = SSSR_FilterTex1; };

texture SSSR_FilterTex2  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sSSSR_FilterTex2 { Texture = SSSR_FilterTex2; };

texture SSSR_FilterTex3  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sSSSR_FilterTex3 { Texture = SSSR_FilterTex3; };

texture SSSR_PNormalTex  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sSSSR_PNormalTex { Texture = SSSR_PNormalTex; };

texture SSSR_NormTex  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sSSSR_NormTex { Texture = SSSR_NormTex; };

#if SMOOTH_NORMALS > 0
texture SSSR_NormTex1  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sSSSR_NormTex1 { Texture = SSSR_NormTex1; };
#endif

#if __RENDERER__ >= 0xa000 // If DX10 or higher
#define RES_M 0.5
texture SSSR_LowResDepthTex  { Width = BUFFER_WIDTH*RESOLUTION_SCALE_*RES_M; Height = BUFFER_HEIGHT*RESOLUTION_SCALE_*RES_M; Format = R16f; };
sampler sSSSR_LowResDepthTex { Texture = SSSR_LowResDepthTex; };

texture SSSR_LowResNormTex  { Width = BUFFER_WIDTH*RESOLUTION_SCALE_*RES_M; Height = BUFFER_HEIGHT*RESOLUTION_SCALE_*RES_M; Format = RGBA16f; };
sampler sSSSR_LowResNormTex { Texture = SSSR_LowResNormTex; };
#endif //DX9

texture SSSR_HLTex0 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f; };
sampler sSSSR_HLTex0 { Texture = SSSR_HLTex0; };

texture SSSR_HLTex1 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f; };
sampler sSSSR_HLTex1 { Texture = SSSR_HLTex1; };

texture SSSR_RoughTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; };
sampler sSSSR_RoughTex { Texture = SSSR_RoughTex; };

#if NGL_HYBRID_MODE

texture SSSR_ReflectionTexD  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sSSSR_ReflectionTexD { Texture = SSSR_ReflectionTexD; };

texture SSSR_FilterTex0D  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sSSSR_FilterTex0D { Texture = SSSR_FilterTex0D; };

texture SSSR_FilterTex1D  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sSSSR_FilterTex1D { Texture = SSSR_FilterTex1D; };

texture SSSR_FilterTex2D  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sSSSR_FilterTex2D { Texture = SSSR_FilterTex2D; };

texture SSSR_FilterTex3D  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sSSSR_FilterTex3D { Texture = SSSR_FilterTex3D; };

#endif //NGL_HYBRID_MODE

///////////////Textures-Samplers///////////
///////////////UI//////////////////////////
///////////////UI//////////////////////////
///////////////Vertex Shader///////////////
///////////////Vertex Shader///////////////
///////////////Functions///////////////////

//from: https://www.shadertoy.com/view/XsSfzV
// by Nikos Papadopoulos, 4rknova / 2015
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
float3 toYCC(float3 rgb)
{
	float Y  =  .299 * rgb.x + .587 * rgb.y + .114 * rgb.z; // Luminance
	float Cb = -.169 * rgb.x - .331 * rgb.y + .500 * rgb.z; // Chrominance Blue
	float Cr =  .500 * rgb.x - .419 * rgb.y - .081 * rgb.z; // Chrominance Red
    return float3(Y,Cb + 128./255.,Cr + 128./255.);
}

float3 toRGB(float3 ycc)
{
    float3 c = ycc - float3(0., 128./255., 128./255.);
    
    float R = c.x + 1.400 * c.z;
	float G = c.x - 0.343 * c.y - 0.711 * c.z;
	float B = c.x + 1.765 * c.y;
    return float3(R,G,B);
}

float GetSpecularDominantFactor(float NoV, float roughness)
{
	float a = 0.298475 * log(39.4115 - 39.0029 * roughness);
	float f = pow(saturate(1.0 - NoV), 10.8649)*(1.0 - a) + a;
	
	return saturate(f);
}

float GetHLDivion(in float HL){return HL*HLDIV;}

float2 GetPixelSize()
{
	float2 DepthSize = tex2Dsize(sTexDepth) / BUFFER_SCREEN_SIZE;
	float2 ColorSize = rcp(RESOLUTION_SCALE_);
	
	float2 MinResRcp = max(ColorSize, DepthSize);
	
	return MinResRcp;
}

float2 GetPixelSizeWithMip(in float mip)
{
	float2 DepthSize = tex2Dsize(sTexDepth) / BUFFER_SCREEN_SIZE;
	
	float2 ColorSize = rcp(RESOLUTION_SCALE_);
	ColorSize /= exp2(mip);
	
	float2 MinResRcp = max(ColorSize, DepthSize);
	
	return MinResRcp;
}

float2 sampleMotion(float2 texcoord)
{
    return tex2D(SamplerMotionVectors, texcoord).rg;
}

float checker(float4 vpos)
{
	if(Frame%2)vpos.y++;
	return (vpos.y+vpos.x%2)%2;
}

float checker(float2 uv)
{
	uv *= BUFFER_SCREEN_SIZE;
	return checker(uv.xyxy);
}

float WN(float2 co)
{
  return frac(sin(dot(co.xy ,float2(1.0,73))) * 437580.5453);
}

float3 WN3dts(float2 co, float HL)
{
	co += (Frame%HL)/120.3476687;
	//co += s/16.3542625435332254;
	return float3( WN(co), WN(co+0.6432168421), WN(co+0.19216811));
}

float IGN(float2 n)
{
    float f = 0.06711056 * n.x + 0.00583715 * n.y;
    return frac(52.9829189 * frac(f));
}

float3 IGN3dts(float2 texcoord, float HL)
{
	float3 OutColor;
	float2 seed = texcoord*BUFFER_SCREEN_SIZE+(Frame%HL)*5.588238;
	OutColor.r = IGN(seed);
	OutColor.g = IGN(seed + 91.534651 + 189.6854);
	OutColor.b = IGN(seed + 167.28222 + 281.9874);
	return OutColor;
}

texture SSSR_BlueNoise <source="BlueNoise-64frames128x128.png";> { Width = 1024; Height = 1024; Format = RGBA8;};
sampler sSSSR_BlueNoise { Texture = SSSR_BlueNoise; AddressU = REPEAT; AddressV = REPEAT; MipFilter = Point; MinFilter = Point; MagFilter = Point; };

float3 BN3dts(float2 texcoord, float HL)
{
	texcoord *= BUFFER_SCREEN_SIZE; //convert to pixel index
	
	texcoord = texcoord%128; //limit to texture size
	
	float frame = Frame%HL; //limit frame index to history length
	int2 F;
	F.x = frame%8; //Go from left to right each frame. start over after 8th
	F.y = floor(frame/8)%8; //Go from top to buttom each 8 frame. start over after 8th
	F *= 128; //Each step jumps to the next texture 
	texcoord += F;
	
	texcoord /= 1024; //divide by atlas size
	float3 Tex = tex2D(sSSSR_BlueNoise, texcoord).rgb;
	return Tex;
}

float3 UVtoPos(float2 texcoord)
{
	float3 scrncoord = float3(texcoord.xy*2-1, LDepth(texcoord) * FAR_PLANE);
	scrncoord.xy *= scrncoord.z;
	scrncoord.x *= AspectRatio;
	scrncoord.xy *= rad(fov);
	//scrncoord.xy *= ;
	
	return scrncoord.xyz;
}

float3 UVtoPos(float2 texcoord, float depth)
{
	float3 scrncoord = float3(texcoord.xy*2-1, depth * FAR_PLANE);
	scrncoord.xy *= scrncoord.z;
	scrncoord.x *= AspectRatio;
	scrncoord *= rad(fov);
	//scrncoord.xy *= ;
	
	return scrncoord.xyz;
}

float2 PostoUV(float3 position)
{
	float2 scrnpos = position.xy;
	scrnpos /= rad(fov);
	scrnpos.x /= AspectRatio;
	scrnpos /= position.z;
	
	return scrnpos/2 + 0.5;
}
	
float3 Normal(float2 texcoord)
{
	float2 p = pix;
	float3 u,d,l,r,u2,d2,l2,r2;
	
	u = UVtoPos( texcoord + float2( 0, p.y));
	d = UVtoPos( texcoord - float2( 0, p.y));
	l = UVtoPos( texcoord + float2( p.x, 0));
	r = UVtoPos( texcoord - float2( p.x, 0));
	
	p *= 2;
	
	u2 = UVtoPos( texcoord + float2( 0, p.y));
	d2 = UVtoPos( texcoord - float2( 0, p.y));
	l2 = UVtoPos( texcoord + float2( p.x, 0));
	r2 = UVtoPos( texcoord - float2( p.x, 0));
	
	u2 = u + (u - u2);
	d2 = d + (d - d2);
	l2 = l + (l - l2);
	r2 = r + (r - r2);
	
	float3 c = UVtoPos( texcoord);
	
	float3 v = u-c; float3 h = r-c;
	
	if( abs(d2.z-c.z) < abs(u2.z-c.z) ) v = c-d;
	if( abs(l2.z-c.z) < abs(r2.z-c.z) ) h = c-l;
	
	return normalize(cross( v, h));
}

float lum(in float3 color)
{
	return (color.r+color.g+color.b)/3;
}

float3 ClampLuma(float3 color, float luma)
{
	float L = lum(color);
	color /= L;
	color *= L > luma ? luma : L;
	return color;
}

float3 GetRoughTex(float2 texcoord, float4 normal)
{
	float2 p = pix;
	
	if(!GI)
	{
		//depth threshold to validate samples
		const float Threshold = 0.00003;
		float facing = dot(normal.rgb, normalize(UVtoPos(texcoord, normal.a)));
		facing *= facing;
		//calculating curve and levels
		float roughfac; float2 fromrough, torough;
		roughfac = (1 - roughness);
		fromrough.x = lerp(0, 0.1, saturate(roughness*10));
		fromrough.y = 0.8;
		torough = float2(0, pow(roughness, roughfac));
		
		float3 center = toYCC(tex2D(sTexColor, texcoord).rgb);
		float depth = LDepth(texcoord);

		float Roughness;
		//cross (+)
		float2 offsets[4] = {float2(p.x,0), float2(-p.x,0),float2( 0,-p.y),float2(0,p.y)};
		[unroll]for(int x; x < 4; x++)
		{
			float2 SampleCoord = texcoord + offsets[x];
			float  SampleDepth = LDepth(SampleCoord);
			if(abs(SampleDepth - depth)*facing < Threshold)
			{
				float3 SampleColor = toYCC(tex2D( sTexColor, SampleCoord).rgb);
				SampleColor = min(abs(center.g - SampleColor.g), 0.25);
				Roughness += SampleColor.r;
			}
		}
		
		Roughness = pow( Roughness, roughfac*0.66);
		Roughness = clamp(Roughness, fromrough.x, fromrough.y);
		Roughness = (Roughness - fromrough.x) / ( 1 - fromrough.x );
		Roughness = Roughness / fromrough.y;
		Roughness = clamp(Roughness, torough.x, torough.y);
		
		return saturate(Roughness);
	} 
	return 0;//RoughnessTex
}

#define BT 1000
float3 Bump(float2 texcoord, float height)
{
	float2 p = pix;
	
	float3 s[3];
	s[0] = tex2D(sTexColor, texcoord + float2(p.x, 0)).rgb;
	s[1] = tex2D(sTexColor, texcoord + float2(0, p.y)).rgb;
	s[2] = tex2D(sTexColor, texcoord).rgb;
	float LC = rcp(lum(s[0]+s[1]+s[2])) * height;
	s[0] *= LC; s[1] *= LC; s[2] *= LC;
	float d[3];
	d[0] = LDepth(texcoord + float2(p.x, 0));
	d[1] = LDepth(texcoord + float2(0, p.y));
	d[2] = LDepth(texcoord);
	
	//s[0] *= saturate(1-abs(d[0] - d[2])*1000);
	//s[1] *= saturate(1-abs(d[1] - d[2])*1000);
	
	float3 XB = s[2]-s[0];
	float3 YB = s[2]-s[1];
	
	float3 bump = float3(lum(XB)*saturate(1-abs(d[0] - d[2])*BT), lum(YB)*saturate(1-abs(d[1] - d[2])*BT), 1);
	bump = normalize(bump);
	return bump;
}

float3 blend_normals(float3 n1, float3 n2)
{
    n1 += float3( 0, 0, 1);
    n2 *= float3(-1, -1, 1);
    return n1*dot(n1, n2)/n1.z - n2;
}

static const float LinearGamma = 0.454545;
static const float sRGBGamma = 2.2;

float3 InvTonemapper(float3 color)
{
	if(LinearConvert)color = pow(color, LinearGamma);
	
	float3 L;
	if(TM_Mode)L = max(max(color.r, color.g), color.b); //Lottes
	else L = color; //Reinhardt

	color = color / ((1.0 + max(1-IT_Intensity,0.00001)) - L);
	return color;
}

float3 Tonemapper(float3 color)
{
	float3 L;
	if(TM_Mode)L = max(max(color.r, color.g), color.b); //Lottes
	else L = color; //Reinhardt
	
	color = color / ((1.0 + max(1-IT_Intensity,0.00001)) + L);

	if(LinearConvert)color = pow(color, sRGBGamma);
	
	return (color);
}

float3 FixWhitePoint()
{
	return rcp(Tonemapper(InvTonemapper(float3(1,1,1))));
}

float InvTonemapper(float color)
{//Reinhardt reversible
	return color / (1.001 - color);
}

bool IsSaturated(float2 coord)
{
	float2 a = float2(max(coord.r, coord.g), min(coord.r, coord.g));
	return coord.r > 1 || coord.g < 0;
}

bool IsSaturatedStrict(float2 coord)
{
	float2 a = float2(max(coord.r, coord.g), min(coord.r, coord.g));
	return coord.r >= 1 || coord.g <= 0;
}

// The following code is licensed under the MIT license: https://gist.github.com/TheRealMJP/bc503b0b87b643d3505d41eab8b332ae
// Samples a texture with Catmull-Rom filtering, using 9 texture fetches instead of 16.
// See http://vec3.ca/bicubic-filtering-in-fewer-taps/ for more details
float4 tex2Dcatrom(in sampler tex, in float2 uv, in float2 texsize)
{
	float4 result = 0.0f;
	
	if(UseCatrom){
    float2 samplePos = uv; samplePos *= texsize;
    float2 texPos1 = floor(samplePos - 0.5f) + 0.5f;

    float2 f = samplePos - texPos1;

    float2 w0 = f * (-0.5f + f * (1.0f - 0.5f * f));
    float2 w1 = 1.0f + f * f * (-2.5f + 1.5f * f);
    float2 w2 = f * (0.5f + f * (2.0f - 1.5f * f));
    float2 w3 = f * f * (-0.5f + 0.5f * f);
	
	float2 w12 = w1 + w2;
    float2 offset12 = w2 / (w1 + w2);

    float2 texPos0 = texPos1 - 1;
    float2 texPos3 = texPos1 + 2;
    float2 texPos12 = texPos1 + offset12;

    texPos0 /= texsize;
    texPos3 /= texsize;
    texPos12 /= texsize;

    result += tex2D(tex, float2(texPos0.x, texPos0.y)) * w0.x * w0.y;
    result += tex2D(tex, float2(texPos12.x, texPos0.y)) * w12.x * w0.y;
    result += tex2D(tex, float2(texPos3.x, texPos0.y)) * w3.x * w0.y;
    result += tex2D(tex, float2(texPos0.x, texPos12.y)) * w0.x * w12.y;
    result += tex2D(tex, float2(texPos12.x, texPos12.y)) * w12.x * w12.y;
    result += tex2D(tex, float2(texPos3.x, texPos12.y)) * w3.x * w12.y;
    result += tex2D(tex, float2(texPos0.x, texPos3.y)) * w0.x * w3.y;
    result += tex2D(tex, float2(texPos12.x, texPos3.y)) * w12.x * w3.y;
    result += tex2D(tex, float2(texPos3.x, texPos3.y)) * w3.x * w3.y;
	} //UseCatrom
	else{
	result = tex2D(tex, uv);
	} //UseBilinear
    return max(0, result);
}

float GetRoughness(float2 texcoord)
{ return GI?1:tex2Dlod(sSSSR_RoughTex, float4(texcoord,0,0)).x;}


///////////////Functions///////////////////
///////////////Pixel Shader////////////////

void GBuffer1
(
	float4 vpos : SV_Position,
	float2 texcoord : TexCoord,
	out float4 normal : SV_Target0,
	out float roughness : SV_Target1) //SSSR_NormTex
{
	normal.rgb = Normal(texcoord.xy);
	normal.a   = LDepth(texcoord.xy);
#if SMOOTH_NORMALS <= 0
	normal.rgb = blend_normals( Bump(texcoord, BUMP), normal.rgb);
#endif
	roughness = GetRoughTex(texcoord, normal).r;
}

float4 SNH(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 color = tex2D(sSSSR_NormTex, texcoord);
	float4 s, s1; float sc;
	
	float2 p = pix; p*=SNWidth;
	
		float T = SNThreshold * saturate(2*(1-color.a));
	T = rcp(max(T, 0.0001));
	
	for (int i = -SNSamples; i <= SNSamples; i++)
	{
		s = tex2D(sSSSR_NormTex, float2(texcoord + float2(i*p.x, 0)/*, 0, LODD*/));
		float diff = dot(0.333, abs(s.rgb - color.rgb)) + abs(s.a - color.a)*SNDepthW;
		diff = 1-saturate(diff*T);
		s1 += s*diff;
		sc += diff;
	}
	
	return s1.rgba/sc;
}

#if SMOOTH_NORMALS > 0 //For the sake of compiler error due to removing the sampler for SMOOTH_NORMALS 0
float4 SNV(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 color = tex2Dlod(sSSSR_NormTex1, float4(texcoord, 0, 0));
	float4 s, s1; float sc;

	float2 p = pix; p*=SNWidth;
	float T = SNThreshold * saturate(2*(1-color.a)); T = rcp(max(T, 0.0001));
	for (int i = -SNSamples; i <= SNSamples; i++)
	{
		s = tex2D(sSSSR_NormTex1, float2(texcoord + float2(0, i*p.y)/*, 0, LODD*/));
		float diff = dot(0.333, abs(s.rgb - color.rgb)) + abs(s.a - color.a)*SNDepthW;
		diff = 1-saturate(diff*T*2);
		s1 += s*diff;
		sc += diff;
	}
	
	s1.rgba = s1.rgba/sc;
	s1.rgb = blend_normals( Bump(texcoord, BUMP), s1.rgb);
	return float4(s1.rgb, LDepth(texcoord));
}
#endif

void CopyGBufferLowRes(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float4 Normal : SV_Target0, out float Depth : SV_Target1)
{
	Normal = tex2D(sSSSR_NormTex, texcoord);
	Depth = Normal.a*FAR_PLANE;
}

#define LDepthLoRes(texcoord) tex2Dlod(sSSSR_LowResDepthTex, float4(texcoord.xy, 0, 0)).r
void DoRayMarch(float3 noise, float3 position, float3 raydir, out float3 Reflection, out float HitDistance, out float a) 
{
	float3 raypos; float2 UVraypos; float Check, steplength; bool hit; uint i;
	float bias = -position.z * rcp(FAR_PLANE);
	
	steplength = (1 + noise.x * STEPNOISE) * position.z * 0.01;
	
	raypos = position + raydir * steplength;
	float raydepth = -RAYDEPTH;
	
#if UI_DIFFICULTY == 1
	float RayInc = RAYINC;
	[loop]for(i = 0; i < UI_RAYSTEPS; i++)
#else
	const int RaySteps[5] = {17, 65, 161, 321, 501}; 
	const float RayIncPreset[5] = {2, 1.14, 1.045, 1.02, 1.012};
	float RayInc = RayIncPreset[UI_QUALITY_PRESET];
	[loop]for(i = 0; i < RaySteps[UI_QUALITY_PRESET]; i++)
#endif
	{
		UVraypos = PostoUV(raypos);
#if __RENDERER__ >= 0xa000 // If DX10 or higher
		Check = LDepthLoRes(UVraypos) - raypos.z; //FAR_PLANE is multiplied in the texture
#else
		Check = LDepth(UVraypos)*FAR_PLANE - raypos.z;
#endif //DX9 fallback

		if(Check < bias && Check > raydepth * max(steplength, 1))
		{
			a= 1;
			break;
		}
		else if(TemporalRefine&&Check < bias)break;
		
		raypos += raydir * steplength;
		steplength *= RayInc;
	}
	
	if(IsSaturatedStrict(UVraypos.xy)) Reflection = 0;
	else Reflection = tex2D(sTexColor, UVraypos.xy).rgb*a;
	HitDistance = a ? distance(raypos, position) : FAR_PLANE;
}

void RayMarch(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float4 FinalColor : SV_Target0, out float HitDistance : SV_Target1)
{
	float4 Geometry = tex2D(sSSSR_NormTex, texcoord);

	if(Geometry.w>SkyDepth)
	{ 
		HitDistance = 0;
		FinalColor.rgba = float4(0,0,0,GI?1:0);
	}
	else
	{
		float Roughness = GetRoughness(texcoord);
		float HL = max(1, tex2D(sSSSR_HLTex0, texcoord).r);
		
		float3 BlueNoise  = BN3dts(texcoord, GI?MAX_Frames:max(1,HL));
		float3 IGNoise    = IGN3dts(texcoord, max(MAX_Frames,1)); //Interleaved Gradient Noise
		float3 WhiteNoise = WN3dts(texcoord, HL);
		
		float3 noise = (HL <= 0) ? IGNoise :
					   (HL > 64) ? WhiteNoise :
								   BlueNoise;
								   
		float3 position = UVtoPos (texcoord);
		float3 normal   = Geometry.xyz;
		float3 eyedir   = normalize(position);
		
		float3 raydirG   = reflect(eyedir, normal);
		float3 raydirR   = normalize(noise*2-1);
		if(dot(raydirR, Normal(texcoord))>0) raydirR *= -1;
		
		float raybias    = dot(raydirG, raydirR);
		
		float3 raydir;
		float4 reflection;
		float a;
		if(!GI)raydir = lerp(raydirG, raydirR, pow(1-(0.5*cos(raybias*PI)+0.5), rsqrt(InvTonemapper((GI)?1:Roughness))));
		else raydir = raydirR;
		
		DoRayMarch(IGNoise, position, raydir, reflection.rgb, HitDistance, a);
		
		FinalColor.rgb = max(ClampLuma(InvTonemapper(reflection.rgb), LUM_MAX),0);
		
		float FadeFac = 1-pow(Geometry.w, InvTonemapper(depthfade));
		if(!GI)FinalColor.a = a*FadeFac;
		else
		{
			float AORadius = rcp(max(1, max(AO_Radius_Reflection, AO_Radius_Background)));
			FinalColor.a = saturate((HitDistance)*20*AORadius/FAR_PLANE);
			FinalColor.rgb *= a;
			//depth fade
			FinalColor.rgb *= FadeFac;
			FinalColor.a    = lerp(1, FinalColor.a, FadeFac);
		}
	}//depth check if end
}//ReflectionTex

float2 GetMotionVectorsDeflickered(float2 texcoord)
{
	float2 p = pix;// p /= 1;
	float2 MV = 0;
	if(MVErrorTolerance<1)
	{
		MV = sampleMotion(texcoord);
		if(abs(MV.x) < p.x && abs(MV.y) < p.y) MV = 0;
	}
	return sampleMotion(texcoord);
	//return MV;
}

void TemporalFilter(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float4 FinalColor : SV_Target0, out float HistoryLength : SV_Target1)
{
	float2 MotionVectors = sampleMotion(texcoord);
	float2 PastUV = texcoord + MotionVectors;
	HistoryLength = tex2D(sSSSR_HLTex1, PastUV).r;
	float depth = LDepth(texcoord);
	bool mask;
	if(depth>SkyDepth){mask=0;}else{
		float4 past_normal; float3 normal, ogcolor; float2 outbound; float past_ogcolor, past_depth;
		//Inputs
		normal = tex2D(sSSSR_NormTex, texcoord).rgb;
		past_normal = tex2D(sSSSR_PNormalTex, PastUV);
		past_depth = past_normal.w;
		
		ogcolor = toYCC(tex2D(sTexColor, texcoord).rgb);
		past_ogcolor = tex2D(sSSSR_POGColTex, PastUV).r;
		
		ogcolor.r += ogcolor.g + ogcolor.b;
			 //multiplying by facing fac estimates the expected depth difference, reducing oversensitivity in steep angles.
		mask = abs(depth - past_depth) * dot(normal, normalize(UVtoPos(texcoord)))
			 + abs(ogcolor.r - past_ogcolor)*saturate(1-MVErrorTolerance)
			 <= TemporalFilterDisocclusionThreshold;
	}//sky mask end

	float4 Current, History; float3 Xvirtual, eyedir; float past_depth;
	
	float Roughness = GI?1:GetRoughness(texcoord);

	float2 outbound = PastUV;
	outbound = float2(max(outbound.r, outbound.g), min(outbound.r, outbound.g));
	outbound.rg = (outbound.r > 1 || outbound.g < 0);
	
	mask = min(1-outbound.r, mask);

	Current = tex2Dcatrom(sSSSR_ReflectionTex, texcoord, BUFFER_SCREEN_SIZE*RESOLUTION_SCALE_).rgba;
	History = tex2D(sSSSR_FilterTex1, PastUV);
	
	HistoryLength.r *= mask; //sets the history length to 0 for discarded samples
	HistoryLength.r = min(HistoryLength.r, MAX_Frames); //Limits the linear accumulation to MAX_Frames, The rest will be accumulated exponentialy with the speed = (1-1/Max_Frames)

#if ANTI_LAG_ENABLED		    
	HistoryLength.r *= lerp(
		1-saturate(
			abs((GI?1:1.5)*
				lum(tex2D(sSSSR_FilterTex3, PastUV).rgb) -
				lum(History.rgb)
			)
		),
		1, 
		saturate(1 - length(MotionVectors * MBSDMultiplier / 2))
	);
#endif

	if(!GI)HistoryLength.r = HistoryLength.r
				 * max(saturate(1 - length(MotionVectors) //Weaker history for faster movements
				 * (1 - sqrt(Roughness))                  //More effective on lower roughnesses
				 * MBSDMultiplier), 					  //Motion Based Deghosting Multiplier
				   MBSDThreshold);						//Motion Based Deghosting Max Threshold
	
	HistoryLength.r++;
	FinalColor = lerp(History, Current, 1 / HistoryLength.r);
	FinalColor = max(1e-6, FinalColor);
}

float GetHitDistanceAdaptation(float2 texcoord, float Roughness)
{
	float HD = tex2Dlod(sSSSR_HitDistTex, float4(texcoord, 0, 3)).r;
	HD = lerp(saturate(4 * HD * rcp(FAR_PLANE)), 1, Roughness);
	return HD;
}

void GetNormalAndDepthFromGeometry(in float2 texcoord, out float3 Normal, out float Depth)
{
	float4 Geometry = tex2Dlod(sSSSR_NormTex, float4(texcoord,0,0));
	Normal = Geometry.rgb;
	Depth = Geometry.a;
}

float GetSpecularSpatialDenoiserRadius(float2 texcoord)
{
	float Roughness = GetRoughness(texcoord);
	float HitDistance = GetHitDistanceAdaptation(texcoord, Roughness);
	float radius = saturate(Roughness * 4) * HitDistance;
	
	return (max(0.000025, saturate((radius))));
}

//mode 0 is specular. mode 1 is diffuse
float4 AdaptiveBox(in int size, in sampler Tex, in float2 texcoord, in float checkertex, in float HL)
{
	float2 p = pix;
	float SpecRadius = 1;
	if(!GI)SpecRadius = GetSpecularSpatialDenoiserRadius(texcoord);
	p*=SpecRadius;
	float3 normal; float depth;
	GetNormalAndDepthFromGeometry(texcoord, normal, depth);
	
	//Used to adapt depth thresholding so it considers  the expected depth difference instead of a constant value
	float facing = dot(normal, normalize(UVtoPos(texcoord, depth)));
	facing *= facing;
	//Makes the threshold adaptive to the amount of expected noise
	const float STMulList[3] = {20, 10, 5};
	float ST = lerp(Sthreshold * STMulList[size], Sthreshold, sqrt(saturate(HL/16)));
	float STNormal = 1 - saturate(ST * 100);
	float STDepth = ST/2.5;
	
	const float SizeList[3] = {2,4,8};
	const float SizeListSmall[3] = {0,1,2};
	
	p *= round(lerp(SizeList[size], SizeListSmall[size], min(HL/64, 1)));
	
	p += checkertex * p; //hides atrous artifacts
	float2 pr = p * 0.70710678; //turns the square to circle
	//circle pattern to make the blur appear smoother
	float2 offset[8];
	offset = {
		float2(-pr.x,-pr.y),float2(0, p.y),float2( pr.x,-pr.y),
		float2(-p.x,     0),			   float2( p.x,     0),
		float2(-pr.x, pr.y),float2(0,-p.y),float2( pr.x, pr.y)};
		
	float4 color = tex2Dlod(Tex, float4(texcoord, 0, 0));
	float4 sColor = color;
	int samples = 1;
	float3 snormal; float sdepth; bool determinator;

	[loop]for(int i = 0; i <= 7; i++)
	{
		offset[i] += texcoord;
	
		GetNormalAndDepthFromGeometry(offset[i], snormal, sdepth);
			
		determinator =     
			  (dot(snormal, normal)) > STNormal
			&& abs(sdepth - depth) * facing < STDepth;

			sColor += tex2Dlod(Tex, float4(offset[i],0,0))*determinator;
			samples +=determinator;
	}
	sColor /= samples;
	return sColor;
}

void SpatialFilter0( in float4 vpos : SV_Position, in float2 texcoord : TexCoord, out float4 FinalColor : SV_Target0)
{
	float HLOut = tex2D(sSSSR_HLTex0, texcoord).r;
	float HL = GetHLDivion(HLOut);

	float checkertex = checker(vpos);
	float4 color = AdaptiveBox(0, sSSSR_FilterTex0, texcoord, checkertex, HL);
	color.a = lerp(color.a, tex2D(sSSSR_FilterTex0, texcoord).a, 1);
	FinalColor = max(color, 1e-6);
}
		
void SpatialFilter1( in float4 vpos : SV_Position, in float2 texcoord : TexCoord, out float4 FinalColor : SV_Target0)
{
	float HLOut = tex2D(sSSSR_HLTex0, texcoord).r;
	float HL = GetHLDivion(HLOut);

	float checkertex = checker(vpos);
	float4 color = AdaptiveBox(1, sSSSR_FilterTex1, texcoord, checkertex, HL);
	color.a = lerp(color.a, tex2D(sSSSR_FilterTex1, texcoord).a, 1);
	FinalColor = max(color, 1e-6);
}

void SpatialFilter2(
	in  float4 vpos       : SV_Position,
	in  float2 texcoord   : TexCoord,
	out float4 FinalColor : SV_Target0,//FilterTex1
	out float4 Geometry   : SV_Target1,//PNormalTex
	out float3 Ogcol      : SV_Target2,//POGColTex
	out float  HLOut      : SV_Target3,//HLTex1
	out float4 TSHistory  : SV_Target4)//FilterTex2
{
	HLOut = tex2D(sSSSR_HLTex0, texcoord).r;
	float HL = GetHLDivion(HLOut);

	float checkertex = checker(vpos);
	float4 color = AdaptiveBox(2, sSSSR_FilterTex0, texcoord, checkertex, HL);
	color.a = lerp(color.a, tex2D(sSSSR_FilterTex0, texcoord).a, saturate((HLOut-8)/64));
	FinalColor = max(color, 1e-6);
	
	Geometry   = tex2D(sSSSR_NormTex, texcoord);
	TSHistory  = tex2D(sSSSR_FilterTex3, texcoord).rgba;
	float3 OGC = toYCC(tex2D(sTexColor, texcoord).rgb);
	Ogcol      = OGC.x+OGC.y+OGC.z;
}

void TemporalStabilizer(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float4 FinalColor : SV_Target0)
{
	float HL = tex2D(sSSSR_HLTex0, texcoord).r;
	float2 p = pix;
	
	float Roughness = tex2D(sSSSR_RoughTex, texcoord).x;
	float2 MotionVectors = GetMotionVectorsDeflickered(texcoord);

	float4 current = tex2D(sSSSR_FilterTex1, texcoord);
	float4 history = tex2Dcatrom(sSSSR_FilterTex2, texcoord +  MotionVectors, BUFFER_SCREEN_SIZE);
	//history.rgb = Tonemapper(history.rgb);
	history.rgb = toYCC(history.rgb);
	float4 CurrToYCC = float4(toYCC(current.rgb), current.a);
	
	float4 SharpenMin = 1000000, SharpenMax = 0;
	float4 SharpenMean = current;
	
#if TEMPORAL_STABILIZER_MINMAX_CLAMPING
	float4 Max = CurrToYCC, Min = CurrToYCC;
#endif
	float4 PreSqr = CurrToYCC * CurrToYCC, PostSqr = CurrToYCC;

	float4 SCurrent; int x, y;
	float2 pr = p * 0.707;
	float2 offsets[8] = 
	{
		float2(p.x,  0), float2(-p.x,   0), float2(  0,-p.y), float2(   0,p.y),
		float2(pr.x,pr.y), float2(-pr.x,-pr.y), float2(pr.x,-pr.y), float2(-pr.x,pr.y)
	};
	
	[unroll]for(int x = 0; x < shape; x++)
	{
		SCurrent = tex2D(sSSSR_FilterTex1, texcoord + offsets[x]);
		
		SharpenMin = min(SCurrent, SharpenMin);
		SharpenMax = max(SCurrent, SharpenMax);
		SharpenMean += SCurrent;
		
		SCurrent.rgb = toYCC(SCurrent.rgb);
#if TEMPORAL_STABILIZER_MINMAX_CLAMPING
		Max = max(SCurrent, Max);
		Min = min(SCurrent, Min);
#endif
		PreSqr += SCurrent * SCurrent;
		PostSqr += SCurrent;
	}
	//Min/Max Clamping
#if TEMPORAL_STABILIZER_MINMAX_CLAMPING
	float4 chistory = lerp(history, clamp(history, Min, Max), 1);
#else
	float4 chistory = history;
#endif
	//Variance Clipping
	PostSqr /= shape+1; PreSqr /= shape+1;
	PostSqr *= PostSqr;
	float4 Var = sqrt(abs(PostSqr - PreSqr));
	Var = pow(Var, 0.7);
	Var.xyz *= CurrToYCC.x;
#if TEMPORAL_STABILIZER_VARIANCE_CLIPPING
	chistory = lerp(chistory, clamp(chistory, CurrToYCC - Var, CurrToYCC + Var), 0.15);
#endif

	float4 diff = saturate((abs(chistory - history)));
	diff.r = diff.g + diff.b;
	
	chistory.rgb = toRGB(chistory.rgb);
	
	float2 outbound = texcoord + MotionVectors;
	outbound = float2(max(outbound.r, outbound.g), min(outbound.r, outbound.g));
	outbound.rg = (outbound.r > 1 || outbound.g < 0);
	
	float4 LerpFac = TSIntensity                        //main factor
					*(1 - outbound.r)                   //0 if the pixel is out of boundary
					//*max(0.85, pow(GI ? 1 : Roughness, 1.0)) //decrease if roughness is low
					*max(0.5, saturate(1 - diff.rrra*10))                  //decrease if the difference between original and clamped history is high
					*max(0.7, 1 - 5 * length(MotionVectors))  //decrease if movement is fast
					;
	LerpFac = saturate(LerpFac);
	//current = clamp(current, SharpenMin, SharpenMax);
	FinalColor = lerp(current, chistory, LerpFac);
	
	if(SharpenGI||(RESOLUTION_SCALE_<1&&!UI_DIFFICULTY))
	{
		SharpenMean /= shape+1;
		//will make the sharpness adapt to the noise (less noise => more sharpening)
		float4 weight = 1-saturate(Var * 2 - 1);
		FinalColor = FinalColor + (FinalColor - SharpenMean) * weight * 1;
	}
	FinalColor = clamp(FinalColor, max(0.00000001, SharpenMin), SharpenMax);
}

float3 RITM(in float3 color){return color/max(1 - color, 0.001);}
float3 RTM(in float3 color){return color / (1 + color);}

void Output(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float3 FinalColor : SV_Target0)
{
	FinalColor = 0;
	float2 p = pix;
	float3 Background = tex2D(sTexColor, texcoord).rgb;
	float  Depth      = LDepth(texcoord);
	float  Roughness  = tex2D(sSSSR_RoughTex, texcoord).x;
	float HL = tex2D(sSSSR_HLTex0, texcoord).r;
	
	//Lighting debug
	if(debug==1)Background = 0.5;
	
	//if(Depth>=SkyDepth)FinalColor = Background;
	if(debug == 0 || debug == 1)
	{
		if(GI)
		{
			float4 GI = tex2D(sSSSR_FilterTex3, texcoord).rgba;
			//Changes the InvTonemapper to reinhardt for blending
			GI.rgb = Tonemapper(GI.rgb);
			GI.rgb = RITM(GI.rgb);
			//Invtonemaps the background so we can blend it with GI in HDR space. Gives better results.
			float3 HDR_Background = RITM(Background);
			
			//calculate AO Intensity
			float2 AO;
				//When radiis are higher than 1, the inital radius will increase. This value 
			float Div = max(1, max(AO_Radius_Reflection, AO_Radius_Background));
			AO.g = saturate(GI.a * Div / AO_Radius_Reflection);
			AO.r = saturate(GI.a * Div / AO_Radius_Background);
			AO   = saturate(pow(AO, AO_Intensity));
			
			//modify saturation and exposure
			GI.rgb *= SatExp.g;
			GI.rgb = lerp(lum(GI.rgb), GI.rgb, SatExp.r);
			
			//apply AO
			float3 Img_AO = HDR_Background * AO.r;
			float3  GI_AO = GI.rgb * AO.g;
			//apply GI
			float3 Img_GI = Img_AO + GI_AO * Background;
			Img_GI = RTM(Img_GI);
			//fix highlights by reducing the GI intensity
			FinalColor = Img_GI;
		}
		else 
		{
			float4 Reflection = tex2D(sSSSR_FilterTex3, texcoord);
			Reflection.rgb = Tonemapper(Reflection.rgb);
			Reflection.rgb = RITM(Reflection.rgb);
			
			//calculate Fresnel
			float3 Normal  = tex2D(sSSSR_NormTex, texcoord).rgb;
			float3 Eyedir  = normalize(UVtoPos(texcoord));
			float  Coeff   = pow(abs(1 - dot(Normal, Eyedir)), lerp(EXP, 0, Roughness));
			float  Fresnel = lerp(0.05, 1, Coeff)*Reflection.a;
			
			//modify saturation and exposure
			Reflection.rgb *= SatExp.g;
			Reflection.rgb  = lerp(lum(Reflection.rgb), Reflection.rgb, SatExp.r);
			
			//apply Reflection
			float3 Img_Reflection = lerp(RITM(Background), Reflection.rgb, Fresnel);
			Img_Reflection = RTM(Img_Reflection);
			//fix highlights by reducing the Reflection intensity
			FinalColor = Img_Reflection;
		}
		//Fixes White Point dimming after Inverse/Re-Tonemapping
		FinalColor *= FixWhitePoint();
	}
	
	//debug views: depth, normal, history length, roughness
	else if(debug == 2) FinalColor = sqrt(Depth);
	else if(debug == 3) FinalColor = tex2D(sSSSR_NormTex, texcoord).rgb * 0.5 + 0.5;
	else if(debug == 4) FinalColor = tex2D(sSSSR_HLTex1, texcoord).r/MAX_Frames;
	else if(debug == 5) FinalColor = Roughness;
	
	//Avoids covering menues in black
	if(Depth <= 0.0001) FinalColor = Background;
	//	FinalColor = Tonemapper(tex2D(sSSSR_FilterTex3, texcoord).rgb*2);
}
			
			
	

///////////////Pixel Shader////////////////
///////////////Techniques//////////////////
///////////////Techniques//////////////////
