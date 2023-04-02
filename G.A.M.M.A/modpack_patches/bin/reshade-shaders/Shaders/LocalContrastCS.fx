/*
LocalContrastCS
By: Lord Of Lunacy


A histogram based contrast stretching shader that locally adjusts the contrast of the image
based on the contents of small regions of the image.


Srinivasan, S & Balram, Nikhil. (2006). Adaptive contrast enhancement using local region stretching.
http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.526.5037&rep=rep1&type=pdf
*/


#ifndef LARGE_CONTRAST_LUT
	#define LARGE_CONTRAST_LUT 1
#endif

#ifndef MORE_LOCALITY
	#define MORE_LOCALITY 0
#endif

#define DIVIDE_ROUNDING_UP(numerator, denominator) (int(numerator + denominator - 1) / int(denominator))

#if MORE_LOCALITY != 0
	#define TILES_SAMPLES_PER_THREAD uint2(2, 2)
#else
	#define TILES_SAMPLES_PER_THREAD uint2(3, 3)
#endif

#define COLUMN_SAMPLES_PER_THREAD 4
#define LOCAL_ARRAY_SIZE (TILES_SAMPLES_PER_THREAD.x * TILES_SAMPLES_PER_THREAD.y)
#if LARGE_CONTRAST_LUT != 0
	#define BIN_COUNT 1024
#else
	#define BIN_COUNT 256
#endif
#define GROUP_SIZE uint2(32, 32)
#undef RESOLUTION_MULTIPLIER
#define RESOLUTION_MULTIPLIER 1
#define DISPATCH_SIZE uint2(DIVIDE_ROUNDING_UP(BUFFER_WIDTH, TILES_SAMPLES_PER_THREAD.x * GROUP_SIZE.x * RESOLUTION_MULTIPLIER), \
					  DIVIDE_ROUNDING_UP(BUFFER_HEIGHT, TILES_SAMPLES_PER_THREAD.y * GROUP_SIZE.y * RESOLUTION_MULTIPLIER))

#if (((__RENDERER__ >= 0xb000 && __RENDERER__ < 0x10000) || (__RENDERER__ >= 0x14300)) && __RESHADE__ >=40800)
	#define CONTRAST_COMPUTE 1
#else
	#define CONTRAST_COMPUTE 0
#endif

#if CONTRAST_COMPUTE != 0
namespace LocalContrast 
{
	texture BackBuffer : COLOR;
	texture LocalTiles {Width = BIN_COUNT; Height = DISPATCH_SIZE.x * DISPATCH_SIZE.y; Format = R32f;};
	texture Histogram {Width = BIN_COUNT; Height = 1; Format = R32f;};
	texture HistogramLUT {Width = BIN_COUNT; Height = DISPATCH_SIZE.x * DISPATCH_SIZE.y; Format = R32f;};
	texture RegionVariancesH {Width = DISPATCH_SIZE.x * DISPATCH_SIZE.y; Height = 1; Format = RGBA32f;};
	texture RegionVariances {Width = DISPATCH_SIZE.x * DISPATCH_SIZE.y; Height = 1; Format = RGBA32f;};

	sampler sBackBuffer {Texture = BackBuffer;};
	sampler sLocalTiles {Texture = LocalTiles;};
	sampler sHistogram {Texture = Histogram;};
	sampler sHistogramLUT {Texture = HistogramLUT;};
	sampler sRegionVariancesH {Texture = RegionVariancesH;};
	sampler sRegionVariances {Texture = RegionVariances;};

	storage wLocalTiles {Texture = LocalTiles;};
	storage wHistogram {Texture = Histogram;};
	storage wHistogramLUT {Texture = HistogramLUT;};
	storage wRegionVariancesH {Texture = RegionVariancesH;};
	storage wRegionVariances {Texture = RegionVariances;};
	
	static const float GAUSSIAN[9] = {0.063327,	0.093095,	0.122589,	0.144599,	0.152781,	0.144599,	0.122589,	0.093095,	0.063327};
	//static const float GAUSSIAN[9] = {0.048297,	0.08393,	0.124548,	0.157829,	0.170793,	0.157829,	0.124548,	0.08393,	0.048297};
	//static const float GAUSSIAN[9] = {0.028532,	0.067234,	0.124009,	0.179044,	0.20236,	0.179044,	0.124009,	0.067234,	0.028532};
	//static const float GAUSSIAN[9] = {0.000229,	0.005977,	0.060598,	0.241732,	0.382928,	0.241732,	0.060598,	0.005977,	0.000229};
	//static const float GAUSSIAN[5] = {0.153388,	0.221461,	0.250301,	0.221461,	0.153388};


	uniform float GlobalStrength<
		ui_type = "slider";
		ui_label = "Strength";
		ui_min = 0; ui_max = 1;
	> = 0.75;

	uniform float Minimum<
		ui_type = "slider";
		ui_label = "Minimum";
		ui_category = "Thresholds";
		ui_min = 0; ui_max = 1;
	> = 0;

	uniform float DarkThreshold<
		ui_type = "slider";
		ui_label = "Dark Threshold";
		ui_category = "Thresholds";
		ui_min = 0; ui_max = 1;
	> = 0.333;

	uniform float LightThreshold<
		ui_type = "slider";
		ui_label = "LightThreshold";
		ui_category = "Thresholds";
		ui_min = 0; ui_max = 1;
	> = 0.667;

	uniform float Maximum<
		ui_type = "slider";
		ui_label = "Maximum";
		ui_category = "Thresholds";
		ui_min = 0; ui_max = 1;
	> = 1;

	uniform float DarkPeak<
		ui_type = "slider";
		ui_label = "Dark Blending Curve";
		ui_category = "Dark Settings";
		ui_min = 0; ui_max = 1;
	> = 0.075;
	
	uniform float DarkMax<
		ui_type = "slider";
		ui_label = "Dark Maximum Blending";
		ui_category = "Dark Settings";
		ui_min = 0; ui_max = 1;
	> = 0.15;

	uniform float MidPeak<
		ui_type = "slider";
		ui_label = "Mid Blending Curve";
		ui_category = "Mid Settings";
		ui_min = 0; ui_max = 1;
	> = 0.5;
	
	uniform float MidMax<
		ui_type = "slider";
		ui_label = "Mid Maximum Blending";
		ui_category = "Mid Settings";
		ui_min = 0; ui_max = 1;
	> = 0.4;

	uniform float LightPeak<
		ui_type = "slider";
		ui_label = "Light Blending Curve";
		ui_category = "Light Settings";
		ui_min = 0; ui_max = 1;
	> = 0.7;
	
	uniform float LightMax<
		ui_type = "slider";
		ui_label = "Light Maximum Blending";
		ui_category = "Light Settings";
		ui_min = 0; ui_max = 1;
	> = 0.3;
	

	groupshared uint HistogramBins[BIN_COUNT];
	void HistogramTilesCS(uint3 id : SV_DispatchThreadID, uint3 gid : SV_GroupID, uint3 gtid : SV_GroupThreadID)
	{
		uint threadIndex = gtid.x + gtid.y * GROUP_SIZE.x;
		uint groupIndex = gid.x + gid.y * DISPATCH_SIZE.x;
		
		[unroll]
		while(threadIndex < BIN_COUNT)
		{
			HistogramBins[threadIndex] = 0;
			threadIndex += GROUP_SIZE.x * GROUP_SIZE.y;
		}
		barrier();
		
		uint localValue[LOCAL_ARRAY_SIZE];
		[unroll]
		for(int i = 0; i < TILES_SAMPLES_PER_THREAD.x; i++)
		{
			[unroll]
			for(int j = 0; j < TILES_SAMPLES_PER_THREAD.y; j++)
			{
				float2 coord = (gid.xy * TILES_SAMPLES_PER_THREAD * GROUP_SIZE + (gtid.xy * TILES_SAMPLES_PER_THREAD + float2(i, j)) * 3) * RESOLUTION_MULTIPLIER;
				coord -= float2(GROUP_SIZE * TILES_SAMPLES_PER_THREAD) * 1.5;
				uint arrayIndex = i + TILES_SAMPLES_PER_THREAD.x * j;
				if(any(coord >= uint2(BUFFER_WIDTH, BUFFER_HEIGHT)) || any(coord < 0))
				{
					localValue[arrayIndex] = BIN_COUNT;
				}
				else
				{
					localValue[arrayIndex] = uint(round(dot(tex2Dfetch(sBackBuffer, float2(coord)).rgb, float3(0.299, 0.587, 0.114)) * (BIN_COUNT - 1)));
				}
			}
		}
		
		
		[unroll]
		for(int i = 0; i < LOCAL_ARRAY_SIZE; i++)
		{
			if(localValue[i] < BIN_COUNT)
			{
				atomicAdd(HistogramBins[localValue[i]], 1);
			}
		}
		barrier();
		threadIndex = gtid.x + gtid.y * GROUP_SIZE.x;
		[unroll]
		while(threadIndex < BIN_COUNT)
		{
			tex2Dstore(wLocalTiles, int2(threadIndex, groupIndex), float4(HistogramBins[threadIndex], 1, 1, 1));
			threadIndex += GROUP_SIZE.x * GROUP_SIZE.y;
		}
	}

	groupshared float prefixSums[BIN_COUNT * 2];
	groupshared float valuePrefixSums[BIN_COUNT * 2];
	groupshared float3 regionSums;
	groupshared float3 regionMeans;
	groupshared uint3 regionVariances;

	void ContrastLUTCS(uint3 id : SV_DispatchThreadID)
	{
		float localBin = tex2Dfetch(sLocalTiles, id.xy).r;
		float localPrefixSum = localBin;
		float luma = (float(id.x) / float(BIN_COUNT - 1));
		float localValuePrefixSum = localBin * luma;
		prefixSums[id.x] = localPrefixSum;
		valuePrefixSums[id.x] = localValuePrefixSum;
		barrier();
		
		uint2 prefixSumOffset = uint2(0, BIN_COUNT);
		
		bool enabled = true;
		
		[unroll]
		for(int i = 0; i < log2(BIN_COUNT - 1) + 1; i++)
		{
			int access = id.x - exp2(i);
			if(access >= 0)
			{
				localPrefixSum += prefixSums[access + prefixSumOffset.x];
				localValuePrefixSum += valuePrefixSums[access + prefixSumOffset.x];
				prefixSums[id.x + prefixSumOffset.y] = localPrefixSum;
				valuePrefixSums[id.x + prefixSumOffset.y] = localValuePrefixSum;
			}
			else if (enabled)
			{
				prefixSums[id.x + prefixSumOffset.y] = localPrefixSum;
				valuePrefixSums[id.x + prefixSumOffset.y] = localValuePrefixSum;
				enabled = false;
			}
			
			prefixSumOffset.xy = prefixSumOffset.yx;
			barrier();
		}
		
		float3 localRegionSums;
		float3 localRegionMeans;
		uint darkThresholdUint = DarkThreshold * (BIN_COUNT - 1);
		uint lightThresholdUint = LightThreshold * (BIN_COUNT - 1);
		
		if(id.x == 0)
		{
			localRegionSums.x = prefixSums[darkThresholdUint + prefixSumOffset.x];
			localRegionSums.y = prefixSums[lightThresholdUint + prefixSumOffset.x];
			localRegionSums.z = prefixSums[BIN_COUNT - 1 + prefixSumOffset.x];
			
			localRegionMeans.x = valuePrefixSums[darkThresholdUint + prefixSumOffset.x];
			localRegionMeans.y = valuePrefixSums[lightThresholdUint + prefixSumOffset.x];
			localRegionMeans.z = valuePrefixSums[BIN_COUNT - 1 + prefixSumOffset.x];
			localRegionMeans /= localRegionSums;
			regionMeans = localRegionMeans;
			
			localRegionSums.z -= localRegionSums.y;
			localRegionSums.y -= localRegionSums.x;
			regionSums = localRegionSums;
			regionVariances = 0;
		}
		barrier();
		
		localRegionSums = regionSums;
		localRegionMeans = regionMeans;
		float lutValue;
		
		if(id.x <= darkThresholdUint)
		{
			if(localRegionSums.x == 0)
			{
				lutValue = (float(id.x) / float(BIN_COUNT - 1));
			}
			else
			{
				float offset = Minimum;
				float multiplier = float(DarkThreshold - Minimum);
				lutValue = saturate((localPrefixSum / localRegionSums.x) * multiplier) + offset;
			}
			uint varianceComponent = uint(float(abs(luma - localRegionMeans.x)) * float(localBin * (BIN_COUNT)));
			atomicAdd(regionVariances[0], varianceComponent);
		}
		else if(id.x <= lightThresholdUint)
		{
			if(localRegionSums.y == 0)
			{
				lutValue = (float(id.x) / float(BIN_COUNT - 1));
			}
			else
			{
				float offset = DarkThreshold;
				float multiplier = float(LightThreshold - DarkThreshold);
				localPrefixSum -= localRegionSums.x;
				lutValue = saturate(((localPrefixSum) / localRegionSums.y) * multiplier) + offset;
			}
				uint varianceComponent = uint(float(abs(luma - localRegionMeans.y)) * float(localBin * (BIN_COUNT)));
				atomicAdd(regionVariances[1], varianceComponent);
		}
		else
		{
			if(localRegionSums.z == 0)
			{
				lutValue = (float(id.x) / float(BIN_COUNT - 1));
			}
			else
			{
				float offset = LightThreshold;
				float multiplier = float(LightThreshold - DarkThreshold);
				localPrefixSum -= localRegionSums.x + localRegionSums.y;
				lutValue = saturate(((localPrefixSum) / localRegionSums.z) * multiplier) + offset;
			}
				uint varianceComponent = uint(float(abs(luma - localRegionMeans.z)) * float(localBin * (BIN_COUNT)));
				atomicAdd(regionVariances[2], varianceComponent);
		}
		barrier();
		
		if(id.x == 0)
		{
			float3 localRegionVariances = float3(regionVariances) / ((BIN_COUNT) * float3(max(localRegionSums, 0.001)));
			//localRegionVariances = 0.95 * previousRegionVariances + 0.05 * localRegionVariances;
			tex2Dstore(wRegionVariances, int2(id.y, 0), float4(localRegionVariances.xyz, 1));
		}
			
		tex2Dstore(wHistogramLUT, id.xy, lutValue);
	}

	// Vertex shader generating a triangle covering the entire screen
	void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
	{
		texcoord.x = (id == 2) ? 2.0 : 0.0;
		texcoord.y = (id == 1) ? 2.0 : 0.0;
		position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	}

	float WeightingCurve(float peak, float variance, float maximumBlending)
	{
		float output;
		if(variance <= peak)
		{
			return lerp(0, maximumBlending, abs(variance) / peak);
		}
		else
		{
			return lerp(maximumBlending, 0, abs(variance - peak) / (1 - peak));
		}
	}
	
	void LUTInterpolation(uint2 coord, float yOld, out float yNew, out float3 variances)
	{
		uint2 blockSize = uint2((GROUP_SIZE.x * TILES_SAMPLES_PER_THREAD.x), (GROUP_SIZE.y * TILES_SAMPLES_PER_THREAD.y));
		uint2 groupCoord = coord / blockSize;
		int2 position = (coord % blockSize) - float2(blockSize / 2);
		float2 positionCoord = float2(abs(position)) / float2(blockSize);
		float2 weights = smoothstep(0, 1, positionCoord);
		uint group = groupCoord.x + groupCoord.y * DISPATCH_SIZE.x;
		int2 groupCoordW;
		float samples[4];
		float3 varianceSamples[4];
		samples[0] = tex2Dfetch(sHistogramLUT, float2(yOld * BIN_COUNT, group)).x;
		varianceSamples[0] = tex2Dfetch(sRegionVariances, float2(group, 0)).xyz;
		int2 groupCoordTemp = groupCoord;
		if(position.x < 0)
		{
			groupCoordTemp.x -= 1;
			groupCoordTemp = clamp(groupCoordTemp, 0, DISPATCH_SIZE);
			groupCoordW = groupCoordTemp;
			group = groupCoord.x + groupCoord.y * DISPATCH_SIZE.x;
			samples[1] = tex2Dfetch(sHistogramLUT, float2(yOld * BIN_COUNT, group)).x;
			varianceSamples[1] = tex2Dfetch(sRegionVariances, float2(group, 0)).xyz;
		}
		else
		{
			groupCoordTemp.x += 1;
			groupCoordTemp = clamp(groupCoordTemp, 0, DISPATCH_SIZE);
			groupCoordW = groupCoordTemp;
			group = groupCoordTemp.x + groupCoordTemp.y * DISPATCH_SIZE.x;
			samples[1] = tex2Dfetch(sHistogramLUT, float2(yOld * BIN_COUNT, group)).x;
			varianceSamples[1] = tex2Dfetch(sRegionVariances, float2(group, 0)).xyz;
		}
		
		if(position.y < 0)
		{
			groupCoordTemp.y -= 1;
			groupCoordTemp = clamp(groupCoordTemp, 0, DISPATCH_SIZE);
			groupCoordW.y = groupCoordTemp.y;
			group = groupCoordTemp.x + groupCoordTemp.y * DISPATCH_SIZE.x;
			samples[2] = tex2Dfetch(sHistogramLUT, float2(yOld * BIN_COUNT, group)).x;
			varianceSamples[2] = tex2Dfetch(sRegionVariances, float2(group, 0)).xyz ;
		}
		else
		{
			groupCoordTemp.y += 1;
			groupCoordTemp = clamp(groupCoordTemp, 0, DISPATCH_SIZE);
			groupCoordW.y = groupCoordTemp.y;
			group = groupCoordTemp.x + groupCoordTemp.y * DISPATCH_SIZE.x;
			samples[2] = tex2Dfetch(sHistogramLUT, float2(yOld * BIN_COUNT, group)).x;
			varianceSamples[2] = tex2Dfetch(sRegionVariances, float2(group, 0)).xyz;
		}
		
		group = groupCoordW.x + groupCoordW.y * DISPATCH_SIZE.x;
		samples[3] = tex2Dfetch(sHistogramLUT, float2(yOld * BIN_COUNT, group)).x;
		varianceSamples[3] = tex2Dfetch(sRegionVariances, float2(group, 0)).xyz;
		
		yNew = lerp(lerp(samples[0], samples[1], weights.x), lerp(samples[2], samples[3], weights.x), weights.y);
		variances = lerp(lerp(varianceSamples[0], varianceSamples[1], weights.x), lerp(varianceSamples[2], varianceSamples[3], weights.x), weights.y);
	}
	
	void GaussianVarianceHPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 GaussianVariance : SV_Target0)
	{
		GaussianVariance = 0;
		uint textureHeight = DISPATCH_SIZE.x * DISPATCH_SIZE.y;
		uint2 coord = texcoord * float2(1, textureHeight);
		uint2 group = uint2(coord.x / (GROUP_SIZE.x * TILES_SAMPLES_PER_THREAD.x), (coord.y / (GROUP_SIZE.y * TILES_SAMPLES_PER_THREAD.y)));
		[unroll]
		for(int i = -4; i <= 4; i++)
		{
			int2 sampleCoord = uint2(coord.x, coord.y + i);
			sampleCoord.y = clamp(sampleCoord.y, 0, textureHeight - 1);
			sampleCoord.xy = sampleCoord.yx;
			GaussianVariance.xyz += GAUSSIAN[i + 4] * tex2Dfetch(sRegionVariances, sampleCoord).xyz;
		}
		GaussianVariance.w = 1;
	}
	
	void GaussianVarianceVPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 GaussianVariance : SV_Target0)
	{
		GaussianVariance = 0;
		uint textureHeight = DISPATCH_SIZE.x * DISPATCH_SIZE.y;
		uint2 coord = texcoord * float2(1, textureHeight);
		uint2 group = uint2(coord.x / (GROUP_SIZE.x * TILES_SAMPLES_PER_THREAD.x), (coord.y / (GROUP_SIZE.y * TILES_SAMPLES_PER_THREAD.y)));
		int2 clampingValues;
		clampingValues.x = coord.y % DISPATCH_SIZE.x;
		clampingValues.y = textureHeight - (DISPATCH_SIZE.x - clampingValues.x) - 1;
		[unroll]
		for(int i = -4; i <= 4; i++)
		{
			int2 sampleCoord = uint2(coord.x, coord.y + i * DISPATCH_SIZE.x);
			sampleCoord.y = clamp(sampleCoord.y, clampingValues.x, clampingValues.y);
			sampleCoord.xy = sampleCoord.yx;
			GaussianVariance.xyz += GAUSSIAN[i + 4] * tex2Dfetch(sRegionVariancesH, sampleCoord).xyz;
		}
		GaussianVariance.w = 1;
	}
	

	void OutputPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float3 color : SV_Target0)
	{
		color = tex2D(sBackBuffer, texcoord).rgb;
		uint2 coord = texcoord * float2(BUFFER_WIDTH, BUFFER_HEIGHT);
		float yOld = dot(color, float3(0.299, 0.587, 0.114));
		uint group = coord.x / (GROUP_SIZE.x * TILES_SAMPLES_PER_THREAD.x) + (coord.y / (GROUP_SIZE.y * TILES_SAMPLES_PER_THREAD.y)) * DISPATCH_SIZE.x;
		float3 variances;
		float yNew;
		LUTInterpolation(coord, /*texcoord,*/ yOld, yNew, variances);
		float alpha;
		
		
		if(yOld <= DarkThreshold)
		{
			alpha = WeightingCurve(DarkPeak, variances.x, DarkMax);
			//alpha = variances.x;
		}
		else if(yOld <= LightThreshold)
		{
			alpha = WeightingCurve(MidPeak, variances.y, MidMax);
			//alpha = variances.y;
		}
		else
		{
			alpha = WeightingCurve(LightPeak, variances.z, LightMax);
			//alpha = variances.z;
		}
		float y = lerp(yOld, yNew, (alpha * GlobalStrength));
		
		float cb = -0.168736 * color.r - 0.331264 * color.g + 0.500000 * color.b;
		float cr = +0.500000 * color.r - 0.418688 * color.g - 0.081312 * color.b;
		
		color = float3(
				y + 1.402 * cr,
				y - 0.344136 * cb - 0.714136 * cr,
				y + 1.772 * cb);
			
	}

	technique LocalContrastCS<ui_tooltip = "A histogram based contrast stretching shader that locally adjusts the contrast of the image\n"
										   "based on the contents of small regions of the image.\n\n"
										   "May cause square shaped artifacting \n\n"
										   "Part of the Insane Shaders repository";>
	{
		pass
		{
			ComputeShader = HistogramTilesCS<GROUP_SIZE.x, GROUP_SIZE.y>;
			DispatchSizeX = DISPATCH_SIZE.x;
			DispatchSizeY = DISPATCH_SIZE.y;
		}
		
		pass
		{
			ComputeShader = ContrastLUTCS<(BIN_COUNT), 1>;
			DispatchSizeX = 1;
			DispatchSizeY = DISPATCH_SIZE.x * DISPATCH_SIZE.y;
		}
		
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = GaussianVarianceHPS;
			RenderTarget = RegionVariancesH;
		}
		
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = GaussianVarianceVPS;
			RenderTarget = RegionVariances;
		}
		
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = OutputPS;
		}
	}
}
#endif //CONTRAST_COMPUTE != 0
