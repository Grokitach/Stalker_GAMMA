


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

#include "ReShadeUI.fxh"
#include "ReShade.fxh"
#include "TFAAUI.fxh"


uniform float frametime < source = "frametime"; >;
uniform int framecount < source = "framecount"; >;


// Shader
//Textures
texture texInCur : COLOR;
texture texInCurBackup < pooled = false; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };

texture texExpColor < pooled = false; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
texture texExpColorBackup < pooled = false; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };

texture texDepthBackup < pooled = false; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f; };

//Samplers
sampler smpInCur { Texture = texInCur; AddressU = Clamp; AddressV = Clamp; MipFilter = Linear; MinFilter = Linear; MagFilter = Linear; };
sampler smpInCurBackup { Texture = texInCurBackup; AddressU = Clamp; AddressV = Clamp; MipFilter = Linear; MinFilter = Linear; MagFilter = Linear; };

sampler smpExpColor { Texture = texExpColor; AddressU = Clamp; AddressV = Clamp; MipFilter = Linear; MinFilter = Linear; MagFilter = Linear; };
sampler smpExpColorBackup { Texture = texExpColorBackup; AddressU = Clamp; AddressV = Clamp; MipFilter = Linear; MinFilter = Linear; MagFilter = Linear; };

sampler smpDepthBackup { Texture = texDepthBackup; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Point; MagFilter = Point; };


//Motion Vectors
texture texMotionVectors < pooled = false; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
sampler SamplerMotionVectors { Texture = texMotionVectors; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Point; MagFilter = Point; };

//Easy way to sample the velocity buffer
float2 sampleMotion(float2 texcoord)
{
    return tex2D(SamplerMotionVectors, texcoord).rg;
}


//  Helper Functions
// Color Converstions
//YCgCo
float3 cvtRgb2YCgCo(float3 rgb)
{
	float3 RGB2Y =  float3(0.25, 0.5, -0.25);
	float3 RGB2Cg = float3(0.5,  0.0,  0.5);
	float3 RGB2Co = float3(0.25,-0.5, -0.25);
	return float3(dot(rgb, RGB2Y), dot(rgb, RGB2Cg), dot(rgb, RGB2Co));
}

float3 cvtYCgCo2Rgb(float3 ycc)
{
	float3 YCgCo2R = float3( 1.0, 1.0, 1.0);
	float3 YCgCo2G = float3(1.0, 0.0, -1.0);
	float3 YCgCo2B = float3(-1.0, 1.0, -1.0);
	return float3(dot(ycc, YCgCo2R), dot(ycc, YCgCo2G), dot(ycc, YCgCo2B));
}

//YCbCr
//with permissions from https://github.com/BlueSkyDefender/AstrayFX
float3 cvtRgb2YCbCr(float3 rgb)
{
 	float y = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b;
    float cb = (rgb.b - y) * 0.565;
    float cr = (rgb.r - y) * 0.713;

    return float3(y, cb, cr);
}

float3 cvtYCbCr2Rgb(float3 YCbCr)
{
    return float3(
        YCbCr.x + 1.403 * YCbCr.z,
        YCbCr.x - 0.344 * YCbCr.y - 0.714 * YCbCr.z,
        YCbCr.x + 1.770 * YCbCr.y
    );
}

//Color Conversion Wrapper
float3 cvtRgb2whatever(float3 rgb)
{
	switch(UI_COLOR_FORMAT)
	{
		case 1:
			return cvtRgb2YCgCo(rgb);
		case 2:
			return cvtRgb2YCbCr(rgb);
		default:
			return rgb;
	}
}

float3 cvtWhatever2Rgb(float3 whatever)
{
	switch(UI_COLOR_FORMAT)
	{
		case 1:
			return cvtYCgCo2Rgb(whatever);
		case 2:
			return cvtYCbCr2Rgb(whatever);
		default:
			return whatever;
	}
}

// History resampling, could not track down who wrote this code comes from, but thanks to who ever did it first
float4 sampleBicubic(sampler2D source, float2 texcoord)
{
	float2 texSize = tex2Dsize(source);
    float2 samplePos = texcoord * texSize;
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

    texPos0 /= texSize;
    texPos3 /= texSize;
    texPos12 /= texSize;

    float4 result = 0.0f;
    result += tex2D(source, float2(texPos0.x, texPos0.y)) * w0.x * w0.y;
    result += tex2D(source, float2(texPos12.x, texPos0.y)) * w12.x * w0.y;
    result += tex2D(source, float2(texPos3.x, texPos0.y)) * w3.x * w0.y;

    result += tex2D(source, float2(texPos0.x, texPos12.y)) * w0.x * w12.y;
    result += tex2D(source, float2(texPos12.x, texPos12.y)) * w12.x * w12.y;
    result += tex2D(source, float2(texPos3.x, texPos12.y)) * w3.x * w12.y;

    result += tex2D(source, float2(texPos0.x, texPos3.y)) * w0.x * w3.y;
    result += tex2D(source, float2(texPos12.x, texPos3.y)) * w12.x * w3.y;
    result += tex2D(source, float2(texPos3.x, texPos3.y)) * w3.x * w3.y;

	return result;
}

//Sample Wrapper
float4 sampleHistory(sampler2D historySampler, float2 texcoord)
{
	[branch] if (UI_USE_CUBIC_HISTORY)
		return sampleBicubic(historySampler, texcoord);
	else
		return tex2D(historySampler, texcoord);
}


//Passes

float4 SaveCurPS(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target0
{	
	//write current color and depth into one texture for easy use later;
	float depthOnly = ReShade::GetLinearizedDepth(texcoord);
	return float4(tex2D(smpInCur, texcoord).rgb, depthOnly);
}


float4 TaaPass(float4 position : SV_Position, float2 texcoord : TEXCOORD ) : SV_Target
{
	//sample local pixel color and depth
	float4 sampleCur = tex2D(smpInCurBackup, texcoord);
	float3 colorCur = sampleCur.rgb;
	float depthCur = sampleCur.a;

	//get size of neighborhood
	float2 sampleDist =  1.0 * ReShade::PixelSize; //lerp(0.33, 1.0, lerp(1.0, 0.0, UI_CLAMP_STRENGTH)) * ReShade::PixelSize; old method. clamping is not done another way

	//local pixel from rgb to clamping format		
	float4 cvtColorCur = float4(cvtRgb2whatever(colorCur), depthCur);
	
	//we asume no motion as default
	float2 sampledMotion = float2(0, 0);

	//variables for storing min max values for clamping and for calulating sharpening weights
	float4 nCrossMin = cvtColorCur;
	float4 nCrossMax = cvtColorCur;
	float4 boxMin = 1.0;
	float4 boxMax = 0.0; 
	float4 finalMin = 1.0;
	float4 finalMax = 0.0;

	//variables for variance clamping
	float4 summedRGB = sampleCur;
	float4 mean = 0;
	float4 varMin;
	float4 varMax;

	//neigborhood sample offsets
	static const float2 nOffsets[8] = { float2(0,1), float2(0,-1), float2(1,0), float2(-1,0),
										float2(-1,-1), float2(1,-1), float2(1,1), float2(-1,1) };
	
	//variables for storing neigborhood and closest depth for dilated motion vectors
	float4 neigborhood[8];
	int closestDepthIndex = -1;
	float closestDepth = 1.0;

	//splittinge the cross and corner pixels because we might not need both
	[unroll] for (int i = 0; i < 4; i++)
	{
		float4 nSample = tex2D(smpInCurBackup, texcoord + (nOffsets[i] * sampleDist));
		neigborhood[i] = nSample;
		summedRGB += nSample;

		//find pixel for dilated motion vectors
		if (nSample.a < closestDepth)
		{
			closestDepth = nSample.a;
			closestDepthIndex = i;
		}

		//get min and max of neighborhood for clamping
		float4 cvt = float4(cvtRgb2whatever(nSample.rgb), nSample.a);
		nCrossMin = min(cvt, nCrossMin);
		nCrossMax = max(cvt, nCrossMax);
	}

	[branch] if (UI_CLAMP_PATTERN != 0)	
	{
		float4 nCornersMin = cvtColorCur;
		float4 nCornersMax = cvtColorCur;
		[unroll] for (int i = 4; i < 8; i++)
		{
			float4 nSample = tex2D(smpInCurBackup, texcoord + (nOffsets[i] * sampleDist));
			neigborhood[i] = nSample;
			summedRGB += nSample;

			//find pixel for dilated motion vectors
			if (nSample.a < closestDepth)
			{
				closestDepth = nSample.a;
				closestDepthIndex = i;
			}

			//get min and max of neighborhood for clamping
			float4 cvt = float4(cvtRgb2whatever(nSample.rgb), nSample.a);
			nCornersMin = min(cvt, nCornersMin);
			nCornersMax = max(cvt, nCornersMax);
		}

		//box min max from cross and corner min max
		boxMin = min(nCrossMin, nCornersMin);
		boxMax = max(nCrossMax, nCornersMax);

		//Rounded Box -> average of Box and Cross min max values -> close to properly weighted samples
		finalMin = (nCrossMin + boxMin) * 0.5;
		finalMax = (nCrossMax + boxMax) * 0.5;

		mean = summedRGB / 9.0;

	}
	//Cross
	else 
	{
		//only cross min max
		finalMin = nCrossMin;
		finalMax = nCrossMax;
		mean = summedRGB / 5.0;
	}

	//sample Motion with closest Depth
	if(closestDepthIndex != -1)
		sampledMotion = sampleMotion(texcoord + (neigborhood[closestDepthIndex] * sampleDist));

	//get fps factor
	static const float fpsConst = (1000.0 / 48.0);
	float fpsFix = frametime / fpsConst;

	//reprojection -> sample where local pixel was last
	float2 lastSamplePos = texcoord + sampledMotion;
	float4 sampleLast = sampleHistory(smpExpColorBackup, lastSamplePos);
	float3 colorLast = sampleLast.rgb;
	float  depthLast = tex2D(smpDepthBackup, lastSamplePos).r;

	//sharp current pixel before blending with past and before clamping so artifacts are supressed
	float sharpAmount = saturate((UI_PRESHARP + 0.1) * 5);

	//convert min and max back to rgb
	float3 rgbMin = cvtWhatever2Rgb(nCrossMin.rgb);
	float3 rgbMax = cvtWhatever2Rgb(nCrossMax.rgb);

	//calulate sharpening weights for current frame pixel, similar to sharpening weights calulation from AMD CAS
	float3 crossWeight = -rcp(rsqrt(saturate(min(rgbMin, 2.0 - rgbMax) * rcp(rgbMax))) * (-3.0 * sharpAmount + 8.0));

	//get reciprocal of crossWeight scaled by the amount of pixels used for sharpening
	float3 rcpWeight = rcp(4.0 * crossWeight + 1.0);

	//get the summ of the neighbouring pixels
	float3 crossSumm = ((neigborhood[0].rgb + neigborhood[1].rgb) + (neigborhood[2].rgb + neigborhood[3].rgb));

	//combine local pixel with neighbouring pixels according to their weights
	float3 sharpened = lerp(colorCur, saturate((crossSumm * crossWeight + colorCur) * rcpWeight), sharpAmount);

	//get how much we clamped last frame at this point;
	float previousClamping = sampleLast.a;

	//reduce history impact when we clamped a lot last time
    float reduceBlendClamp = saturate(previousClamping * UI_CLAMP_STRENGTH * UI_TEMPORAL_FILTER_STRENGTH);

	//weight from menu
	float maxWeight = 0.5;
	float weight = lerp(maxWeight, 0.01, sqrt(UI_TEMPORAL_FILTER_STRENGTH));

	//weight normalized to 48 hz test scenario 
	weight = weight * fpsFix;

	//weigt clamped in a reasonable range	//less old info when old info was wrong last time
	weight = saturate(lerp(weight, maxWeight, reduceBlendClamp));

	//blending
	float3 blendedColor = lerp(colorLast, sharpened, weight);
	// if ui clamp type debug
	[branch] if (UI_CLAMP_TYPE == 2)
		return float4(blendedColor, 0);


	//clamp
	float3 clamped = 0;
	switch (UI_CLAMP_TYPE)	
	{

		case 0:	//clamp min/max
			clamped = clamp(cvtRgb2whatever(blendedColor.rgb), finalMin.rgb, finalMax.rgb);
			break;
		case 1:	//clamp var/sd
			float3 center = cvtRgb2whatever(blendedColor.rgb);
			float3 M1 = center;
			float3 M2 = center * center;
			float3 s;
			int sampleCount = UI_CLAMP_PATTERN ? 8 : 4;
			[unroll] for (int i = 0; i < sampleCount; i++)
			{
				s = cvtRgb2whatever(neigborhood[i].rgb);
				M1 += s;
				M2 += s*s;
			}
			sampleCount++;
			M1 /= sampleCount; M2 /= sampleCount;
			M1 *= M1;
			float3 sd = sqrt(abs(M1 - M2));
			varMin = cvtColorCur.rgb - sd;
			varMax = cvtColorCur.rgb + sd;
			clamped = clamp(cvtRgb2whatever(blendedColor.rgb), varMin.rgb, varMax.rgb);
			break;
		default:
			clamped = blendedColor;
			break;
	}

	//convert back to rgb
	float3 rgb = cvtWhatever2Rgb(clamped);

	//check how much the blended color got clamped
	float clampDelta = length(clamped - colorLast);

	//smooth it
	float smoothedDelta = (clampDelta + previousClamping) * 0.5;

	//return color and clamp amount
	return float4(rgb, smoothedDelta);
}


void SaveThisPS(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float4 lastExpOut : SV_Target0, out float depthOnly : SV_Target1)
{
	//save current depth and state of the exponential history for use in the next frame frame
	lastExpOut = tex2D(smpExpColor, texcoord);
	depthOnly = ReShade::GetLinearizedDepth(texcoord);
}

float4 OutPS(float4 position : SV_Position, float2 texcoord : TEXCOORD ) : SV_Target
{
	//show filtered image to screen
	return tex2D(smpExpColor, texcoord);
}

//Technique
technique TFAA
{
	pass SaveLastColorPass
	{
		VertexShader = PostProcessVS;
		PixelShader = SaveCurPS;
		RenderTarget0 = texInCurBackup;
	}
	pass TaaPass
	{
		VertexShader = PostProcessVS;
		PixelShader = TaaPass;
		RenderTarget = texExpColor;
	}
	pass SaveThisPass
	{
		VertexShader = PostProcessVS;
		PixelShader = SaveThisPS;
		RenderTarget0 = texExpColorBackup;
		RenderTarget1 = texDepthBackup;
	}
	pass OutPass
	{
		VertexShader = PostProcessVS;
		PixelShader = OutPS;
	}
}