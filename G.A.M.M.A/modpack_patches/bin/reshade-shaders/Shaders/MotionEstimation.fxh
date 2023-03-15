/*
# ReshadeMotionEstimation
- Dense Realtime Motion Estimation | Based on Block Matching and Pyramids 
- Developed from 2019 to 2022 
- First published 2022 - Copyright, Jakob Wapenhensch
 
# This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) License
- https://creativecommons.org/licenses/by-nc/4.0/
- https://creativecommons.org/licenses/by-nc/4.0/legalcode

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

// todo
/**
 *  add loss of lower levels
 * supress localy long vectors
 */


#include "MotionVectors.fxh"
#include "MotionEstimationUI.fxh"

// Defines

// Preprocessor settings
#ifndef PRE_BLOCK_SIZE_2_TO_7
 #define PRE_BLOCK_SIZE_2_TO_7	4   //[2 - 7]     
#endif


#define BLOCK_SIZE (PRE_BLOCK_SIZE_2_TO_7)

//NEVER change these!!!
#define BLOCK_SIZE_HALF (int(BLOCK_SIZE / 2))
#define BLOCK_AREA (BLOCK_SIZE * BLOCK_SIZE)

#define ME_PYR_DIVISOR (2)
#define ME_PYR_LVL_1_DIV (ME_PYR_DIVISOR)
#define ME_PYR_LVL_2_DIV (ME_PYR_LVL_1_DIV * ME_PYR_DIVISOR)
#define ME_PYR_LVL_3_DIV (ME_PYR_LVL_2_DIV * ME_PYR_DIVISOR)
#define ME_PYR_LVL_4_DIV (ME_PYR_LVL_3_DIV * ME_PYR_DIVISOR)
#define ME_PYR_LVL_5_DIV (ME_PYR_LVL_4_DIV * ME_PYR_DIVISOR)
#define ME_PYR_LVL_6_DIV (ME_PYR_LVL_5_DIV * ME_PYR_DIVISOR)
#define ME_PYR_LVL_7_DIV (ME_PYR_LVL_6_DIV * ME_PYR_DIVISOR)

//Math
#define M_PI 3.1415926535
#define M_F_R2D (180.f / M_PI)
#define M_F_D2R (1.0 / M_F_R2D)

// Textures 
texture texCur0 < pooled = false; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
texture texLast0 < pooled = false; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };

texture texMotionFilterX < pooled = false; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 

texture texGCur0 < pooled = false; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
texture texGLast0 < pooled = false; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
texture texMotionCur0 < pooled = false; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
//texture texMotionLast0 < pooled = false; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 

texture texGCur1 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_1_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_1_DIV; Format = RG16F; };
texture texGLast1 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_1_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_1_DIV; Format = RG16F; };
texture texMotionCur1 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_1_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_1_DIV; Format = RGBA16F; };
//texture texMotionLast1 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_1_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_1_DIV; Format = RGBA16F; };

texture texGCur2 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_2_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_2_DIV; Format = RG16F; };
texture texGLast2 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_2_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_2_DIV; Format = RG16F; };
texture texMotionCur2 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_2_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_2_DIV; Format = RGBA16F; };
//texture texMotionLast2 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_2_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_2_DIV; Format = RGBA16F; };

texture texGCur3 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_3_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_3_DIV; Format = RG16F; };
texture texGLast3 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_3_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_3_DIV; Format = RG16F; };
texture texMotionCur3 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_3_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_3_DIV; Format = RGBA16F; };
//texture texMotionLast3 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_3_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_3_DIV; Format = RGBA16F; };

texture texGCur4 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_4_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_4_DIV; Format = RG16F; };
texture texGLast4 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_4_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_4_DIV; Format = RG16F; };
texture texMotionCur4 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_4_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_4_DIV; Format = RGBA16F; };
//texture texMotionLast4 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_4_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_4_DIV; Format = RGBA16F; };

texture texGCur5 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_5_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_5_DIV; Format = RG16F; };
texture texGLast5 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_5_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_5_DIV; Format = RG16F; };
texture texMotionCur5 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_5_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_5_DIV; Format = RGBA16F; };
//texture texMotionLast5 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_5_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_5_DIV; Format = RGBA16F; };

texture texGCur6 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_6_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_6_DIV; Format = RG16F; };
texture texGLast6 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_6_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_6_DIV; Format = RG16F; };
texture texMotionCur6 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_6_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_6_DIV; Format = RGBA16F; };
//texture texMotionLast6 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_6_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_6_DIV; Format = RGBA16F; };

texture texGCur7 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_7_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_7_DIV; Format = RG16F; };
texture texGLast7 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_7_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_7_DIV; Format = RG16F; };
texture texMotionCur7 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_7_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_7_DIV; Format = RGBA16F; };
//texture texMotionLast7 < pooled = false; > { Width = BUFFER_WIDTH / ME_PYR_LVL_7_DIV; Height = BUFFER_HEIGHT / ME_PYR_LVL_7_DIV; Format = RGBA16F; };

uniform int framecount < source = "framecount"; >;

// Search Block
//Sampling
void getBlock(float2 center, out float2 block[BLOCK_AREA], sampler grayIn)
{
    [unroll]
    for (int x = 0; x < BLOCK_SIZE; x++)
    {
        [unroll]
        for (int y = 0; y < BLOCK_SIZE; y++)
        {
            block[(BLOCK_SIZE * y) + x] = tex2Doffset(grayIn, center, int2(x - BLOCK_SIZE_HALF, y - BLOCK_SIZE_HALF)).rg;
        }
    }
}

float2 sampleBlock(int2 coord, float2 block[BLOCK_AREA])
{
    int2 pos = clamp(coord, int2(0,0), int2(BLOCK_SIZE_HALF - 1, BLOCK_SIZE_HALF - 1));
    return block[(BLOCK_SIZE * coord.y) + coord.x];
}

float2 sampleBlockCenterded(int2 coord, float2 block[BLOCK_AREA])
{
    int2 pos = coord + int2(BLOCK_SIZE_HALF, BLOCK_SIZE_HALF); 
    return sampleBlock(pos, block);
}

//Feature Level
float getBlockFeatureLevel(float2 block[BLOCK_AREA])
{
	float2 average = 0;
	for (int i = 0; i < BLOCK_AREA; i++)
		average += block[i];
	average /= float(BLOCK_AREA);

	float2 diff = 0;
	for (int i = 0; i < BLOCK_AREA; i++)
		diff += abs(block[i] - average);	
    diff /= float(BLOCK_AREA);
	
	/*static const float sobelX[BLOCK_AREA] = {
		2, 3, 4, 3, 2,
		3, 5, 6, 5, 3,
		0, 0, 0, 0, 0,
	   -3,-5,-6,-5,-3,
	   -2,-3,-4,-3,-2
	};

	static const float sobelY[BLOCK_AREA] = {
		2, 3, 0,-3,-2,
		3, 5, 0,-5,-3,
		4, 6, 0,-6,-4,
		3, 5, 0,-5,-3,
		2, 3, 0,-3,-2
	};

	float2 gX = 0; 
	float2 gY = 0;
	for (int i = 0; i < BLOCK_AREA; i++)
	{
		gX += block[i] * sobelX[i];
		gY += block[i] * sobelY[i];
	}
	

	float2 edge = ((gX * gX) + (gY * gY)) * 0.01;
	float weightedEdge = (edge.x * 0.8) + (edge.y * 0.2);

	weightedEdge = clamp((weightedEdge - 0.1) * 0.5, 0.0, 0.5);*/
	float noise = saturate(diff.x * 2);
    return noise;
}


//Loss
float perPixelLoss(float2 grayDepthA, float2 grayDepthB)
{
    float2 loss = (grayDepthA - grayDepthB); 
    float2 finalLoss = float2(0, 0);
    
    finalLoss = abs(loss);

    return lerp(finalLoss.g, finalLoss.r, 0.75);
}

float blockLoss(float2 blockA[BLOCK_AREA], float2 blockB[BLOCK_AREA])
{
    float summedLosses = 0;

    for (int i = 0; i < BLOCK_AREA; i++)
    {
        summedLosses += perPixelLoss(blockA[i], blockB[i]);
    }
    return (summedLosses / float(BLOCK_AREA));
}

// Depth & Nornmals
//Depth

//Normal Vector
float3 GetNormalVector(float2 texcoord)
{
	float3 offset = float3(ReShade::PixelSize.xy, 0.0);
	float2 posCenter = texcoord.xy;
	float2 posNorth  = posCenter - offset.zy;
	float2 posEast   = posCenter + offset.xz;

	float3 vertCenter = float3(posCenter - 0.5, 1) * ReShade::GetLinearizedDepth(posCenter);
	float3 vertNorth  = float3(posNorth - 0.5,  1) * ReShade::GetLinearizedDepth(posNorth);
	float3 vertEast   = float3(posEast - 0.5,   1) * ReShade::GetLinearizedDepth(posEast);

	return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;
}


// Motion Vectors
//Packing
float4 packGbuffer(float2 unpackedMotion, float featureLevel, float loss)
{
    return float4(unpackedMotion.x, unpackedMotion.y, featureLevel, loss);
}

float2 motionFromGBuffer(float4 gbuffer)
{
    return float2(gbuffer.r, gbuffer.g);
}


//Show motion vectors stuff
float3 HUEtoRGB(in float H)
{
	float R = abs(H * 6.f - 3.f) - 1.f;
	float G = 2 - abs(H * 6.f - 2.f);
	float B = 2 - abs(H * 6.f - 4.f);
	return saturate(float3(R,G,B));
}

float3 HSLtoRGB(in float3 HSL)
{
	float3 RGB = HUEtoRGB(HSL.x);
	float C = (1.f - abs(2.f * HSL.z - 1.f)) * HSL.y;
	return (RGB - 0.5f) * C + HSL.z;
}

float4 motionToLgbtq(float2 motion)
{
	float angle = atan2(motion.y, motion.x) * M_F_R2D;
	float dist = length(motion);
	float3 rgb = HSLtoRGB(float3((angle / 360.f) + 0.5, saturate(dist * UI_DEBUG_MULT), 0.5));

	if (UI_DEBUG_MOTION_ZERO == 2)
		rgb = (rgb - 0.5) * 2;
	if (UI_DEBUG_MOTION_ZERO == 0)
		rgb = 1 - ((rgb - 0.5) * 2);
	return float4(rgb.r, rgb.g, rgb.b, 0);
}


// Motion Estimation
//Get Directional Sample

float randFloatSeed2(float2 seed)
{
    return frac(sin(dot(seed, float2(12.9898, 78.233))) * 43758.5453) * M_PI;
}

float2 getCircleSampleOffset(const int samplesOnCircle, const float radiusInPixels, const int sampleId, const float angleOffset)
{
	float angleDelta = 360.f / samplesOnCircle;
	float sampleAngle = angleOffset + ((angleDelta * sampleId) * M_F_D2R);
	float2 delta = float2((cos(sampleAngle) * radiusInPixels), (sin(sampleAngle) * radiusInPixels));
	return delta;
}

//Calculate Motion of a Layer
float4 CalcMotionLayer(float2 coord, float2 searchStart, sampler curBuffer, sampler lastBuffer, const int iterations)
{
	//Local Block from current Frame
	float2 localBlock[BLOCK_AREA];
	getBlock(coord, localBlock, curBuffer);

	//Block from last Frame to compare against
	float2 searchBlock[BLOCK_AREA];
	getBlock(coord + searchStart, searchBlock, lastBuffer);

	//Check if current pixel can/should be tracked
	float localLoss = blockLoss(localBlock, searchBlock);
	float localFeatures = getBlockFeatureLevel(localBlock);

	//Keep Track of stuff while searching
	float lowestLoss = localLoss;
	float featuresAtLowestLoss = getBlockFeatureLevel(searchBlock);
	float2 bestMotion = float2(0, 0);
	float2 searchCenter = searchStart;

	/*[flatten] if (localFeatures < 0.005)
	{
		return packGbuffer(searchCenter, 0, 1); 
	}
	else*/
	{
		float randomValue = randFloatSeed2(coord) * 100;
		randomValue += randFloatSeed2(float2(randomValue, float(framecount % uint(16)))) * 100;
		
		//iterate for better accuracy
		[loop]
		for (int i = 0; i < iterations; i++) 
		{
			randomValue = randFloatSeed2(float2(randomValue, i * 16)) * 100;
			//through Neighborhood and find Offset with lowest blockLoss
			[loop]
			for (int s = 0; s < UI_ME_SAMPLES_PER_ITERATION; s++) 
			{
				float2 pixelOffset = (getCircleSampleOffset(UI_ME_SAMPLES_PER_ITERATION, 1, s, randomValue) / tex2Dsize(lastBuffer)) / pow(2, i);
				float2 samplePos = coord + searchCenter + pixelOffset;
				float2 searchBlockB[BLOCK_AREA];
				getBlock(samplePos, searchBlockB, lastBuffer);
				float loss = blockLoss(localBlock, searchBlockB);

				[flatten]
				if (loss < lowestLoss)
				{
					lowestLoss = loss;
					bestMotion = pixelOffset;
					featuresAtLowestLoss = getBlockFeatureLevel(searchBlockB);
				}
			}
			searchCenter += bestMotion;
			bestMotion = float2(0, 0);
		}
		return packGbuffer(searchCenter, featuresAtLowestLoss, lowestLoss); 
	}
}

//Upscale to next Pyramid layer while supressing wrong / unlikely vectors
float4 UpscaleMotion(float2 texcoord, sampler curLevelGray, sampler lowLevelGray, sampler lowLevelMotion)
{
	float localDepth = tex2D(curLevelGray, texcoord).g;
	float summedWeights = 0.0;
	float2 summedMotion = float2(0, 0);
	float summedFeatures = 0.0;
	float summedLoss = 0.0;

	float randomValue = randFloatSeed2(texcoord) * 100;
	randomValue += randFloatSeed2(float2(randomValue, float(framecount % uint(16)))) * 100;
	const float distPerCircle = UI_ME_PYRAMID_UPSCALE_FILTER_RADIUS / UI_ME_PYRAMID_UPSCALE_FILTER_RINGS;



	//sample and weight neighborhood pixels ond multipe circles around the center
	[loop]
	for (int r = 0; r < UI_ME_PYRAMID_UPSCALE_FILTER_RINGS; r++)	
	{
		int sampleCount = clamp(UI_ME_PYRAMID_UPSCALE_FILTER_SAMPLES_PER_RING / ((r * 0.5) + 1), 1, UI_ME_PYRAMID_UPSCALE_FILTER_SAMPLES_PER_RING);
		float radius = distPerCircle * (r + 1);
		float circleWeight = 1.0 / (r + 1);
		randomValue += randFloatSeed2(float2(randomValue, r * 10)) * 100;
		[loop]
		for (int i = 0; i < sampleCount; i++)
		{
			float2 samplePos = texcoord + (getCircleSampleOffset(sampleCount, radius, i, randomValue) / tex2Dsize(lowLevelGray));
			float nDepth = tex2D(lowLevelGray, samplePos).r;
			float4 llGBuffer = tex2D(lowLevelMotion, samplePos);
			float loss = llGBuffer.a;
			float features = llGBuffer.b;

			float weightDepth = saturate(1.0 - (abs(nDepth - localDepth) * 1));
			float weightLoss = saturate(1.0 - (loss * 1));
			float weightFeatures = saturate((features * 100));
			float weightLength = saturate(1.0 - (length(motionFromGBuffer(llGBuffer) * 1)));
			float weight = saturate(0.000001 + (weightFeatures * weightLoss * weightDepth * weightLength * circleWeight));

			summedWeights += weight;
			summedMotion += motionFromGBuffer(llGBuffer) * weight;
			summedFeatures += features * weight;
			summedLoss += loss * weight;
		}
	}
	return packGbuffer(summedMotion / summedWeights, summedFeatures / summedWeights, summedLoss / summedWeights);
}


//Final Filter
float4 FilterFinal(float2 texcoord, sampler2D motion, sampler2D color, bool y, float radius, float samplesPerPixel)
{
	float4 localColor = tex2D(color, texcoord);
	float localDepth = ReShade::GetLinearizedDepth(texcoord);
	float3 localNormal = GetNormalVector(texcoord);
	float4 localMotionBuffer = tex2D(motion, texcoord);
	float2 localMotion = motionFromGBuffer(localMotionBuffer);
	float localLoss = localMotionBuffer.a;
	
	float4 summedMotion = localMotionBuffer;
	float summedWeights = 1.0;
	const int filterRadius = 10;
	const int samplesPerSide = filterRadius / samplesPerPixel;
	float distPerSample = filterRadius / samplesPerSide;

	for (int i = -samplesPerSide; i < samplesPerSide + 1; i++)
	{

		float2 samplePos = texcoord;
		if (y)
		{
			float pixelOffset = distPerSample * i * ReShade::PixelSize.y;
			samplePos += float2(0, pixelOffset);
		}
		else
		{
			float pixelOffset = distPerSample * i * ReShade::PixelSize.x;
			samplePos += float2(pixelOffset, 0);
		}

		
		float4 sColor = tex2D(color, samplePos);
		float sDepth = ReShade::GetLinearizedDepth(samplePos);
		float3 sNormal = GetNormalVector(samplePos);
		float4 sMotionBuffer = tex2D(motion, samplePos);
		float2 sMotion = motionFromGBuffer(sMotionBuffer);
		float sloss = sMotionBuffer.a;

		float ColorWeight = saturate(1.0 - (length(sColor - localColor)));
		float depthWeight = saturate(1.0 - (abs(sDepth - localDepth) * 10));
		float normalWeight = saturate(1.0 - (length(localNormal - sNormal) * 10));
		float lossWeight = saturate(1.0 - ((sloss - localLoss) * 2));

		float w = 1.0 / (abs(i) + 1);
		float weight = w * ColorWeight * depthWeight * normalWeight * lossWeight;

		summedWeights += weight;
		summedMotion += sMotionBuffer * weight;
	}
	return summedMotion / summedWeights;
}

/*
//Temporal filtering of Motion Vecots with motion aware, shaped neigborhood deviation clamping
float4 FilterMotionTemporal(float2 texcoord, float4 curMotionBuffer,  sampler lastFinalMotionLayer0)
{
	float4 returnValue = float4(0, 0, 0, 0);

	const int sampleCount = 9;
	const float2 samplePattern[sampleCount] = { 	
		float2(-0.7, -0.7), float2(0, -1), 	float2(0.7, -0.7), 
		float2(-1, 0), 	 	float2(0, 0),	float2(1, 0), 
		float2(-0.7, 0.7), 	float2(0, 1), 	float2(0.7, 0.7) 
	};

	float4 curLocalMotionSamples[sampleCount];
	for (int i = 0; i < sampleCount; i++)
	{
		float2 samplePos = texcoord + (samplePattern[i] / tex2Dsize(curGray));
		curLocalMotionSamples[i] = tex2D(curMotion, samplePos);
	}

	float4 average = 0;
	for (int i = 0; i < sampleCount; i++)
		average += curLocalMotionSamples[i];
	average /= float(sampleCount);

	float4 standartDeviation = float4(0, 0, 0, 0);
	for (int i = 0; i < sampleCount; i++)
		standartDeviation += abs(curLocalMotionSamples[i] - average);	
    standartDeviation /= float(sampleCount);

	float4 bufferMin = saturate(average - standartDeviation);
	float4 bufferMax = saturate(average + standartDeviation);

	float4 clampedPrior;

	return returnValue;
}*/


/*
//This is sadly useless as just sampling many times from a texture is faster than to sample an area once and than interpolalte on our own :/ even when you sample some pixels many times
//Search Area
void getSearchArea(float2 center, out float2 searchArea[SEARCH_AREA_AREA], sampler grayIn)
{
    for (int x = 0; x < SEARCH_AREA_SIZE; x++)
    {
        for (int y = 0; y < SEARCH_AREA_SIZE; y++)
        {
            searchArea[(SEARCH_AREA_SIZE * y) + x] = tex2Doffset(grayIn, center, int2(x - SEARCH_AREA_HALF, y - SEARCH_AREA_HALF)).rg;
        }
    }
}

float2 sampleSearchArea(int2 coord, float2 searchArea[SEARCH_AREA_AREA])
{
    int2 pos = clamp((coord), int2(0, 0), int2(SEARCH_AREA_SIZE - 1, SEARCH_AREA_SIZE - 1));
    return searchArea[(SEARCH_AREA_SIZE * pos.y) + pos.x];
}

float2 sampleSearchAreaCendtered(int2 coord, float2 searchArea[SEARCH_AREA_AREA])
{
    int2 pos = coord + int2(SEARCH_AREA_HALF, SEARCH_AREA_HALF);
    return sampleSearchArea(pos, searchArea);
}


float2 sampleSearchAreaBilinear(float2 coord, float2 searchArea[SEARCH_AREA_AREA])
{
    int x1 = clamp(int(coord.x),        0, SEARCH_AREA_SIZE - 1);
    int x2 =  clamp(int(coord.x + 1.0), 0, SEARCH_AREA_SIZE - 1);
    int y1 =  clamp(int(coord.y),       0, SEARCH_AREA_SIZE - 1);
    int y2 =  clamp(int(coord.y + 1.0), 0, SEARCH_AREA_SIZE - 1);

    float dx = coord.x - float(x1);
    float dy = coord.y - float(y1);

    float2 upLeft = sampleSearchArea(int2(x1, y1), searchArea);
    float2 upRight = sampleSearchArea(int2(x2, y1), searchArea);

    float2 downLeft = sampleSearchArea(int2(x1, y2), searchArea);
    float2 downRight = sampleSearchArea(int2(x2, y2), searchArea);

    float2 up = lerp(upLeft, upRight, dx);
    float2 down = lerp(downLeft, downRight, dx);

    return lerp(up, down, dy);
}

float2 sampleSearchAreaBilinearCentered(float2 coord, float2 searchArea[SEARCH_AREA_AREA])
{
    float2 pos = coord + int2(SEARCH_AREA_HALF, SEARCH_AREA_HALF);
    return sampleSearchAreaBilinear(pos, searchArea);
}

void getBlockFromSearchArea(float2 coord, float2 searchArea[SEARCH_AREA_AREA], out float2 block[BLOCK_AREA])
{
    [unroll]
	for (int x = 0; x < BLOCK_SIZE; x++) 
	{
        [unroll]
		for (int y = 0; y < BLOCK_SIZE; y++) 
		{
            float2 grayDepth = sampleSearchAreaBilinearCentered(coord + float2(x, y) - int2(BLOCK_SIZE_HALF, BLOCK_SIZE_HALF), searchArea);
			block[(BLOCK_SIZE * y) + x] = grayDepth;
		}
	}
}

float getSearchAreaFeatureLevel(float2 block[SEARCH_AREA_AREA])
{
	float2 average = 0;
	for (int i = 0; i < SEARCH_AREA_AREA; i++)
		average += block[i];
	average /= float(SEARCH_AREA_AREA);

	float2 featureLevel = 0;
	for (int i = 0; i < SEARCH_AREA_AREA; i++)
		featureLevel += abs(block[i] - average);	
    featureLevel /= float(SEARCH_AREA_AREA);

    float grayWeight = (UI_ME_LOSS_GRAY_DEPTH_RATIO * 0.5) + 0.5;
	return ((featureLevel.r * grayWeight) + (featureLevel.g * (1.0 - grayWeight)));
}
*/
