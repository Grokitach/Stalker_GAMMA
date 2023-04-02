/*=============================================================================

   Copyright (c) Pascal Gilcher. All rights reserved.

	ReShade effect file
    github.com/martymcmodding

	Support me:
   		patreon.com/mcflypg

    Optical Flow 
	
	changelog:

    0.1:    - initial release

	Big credits to Jakob Wapenhensch (Jak0bW) for concept and lots of help!
	Without his Dense Realtime Motion Estimation, this project wouldn't have
	been possible.
	
	see https://github.com/JakobPCoder/ReshadeMotionEstimation	

=============================================================================*/

/*
	TODO: experiment with block size 2
		switch to gather() and reimplement tiled
*/

/*=============================================================================
	Preprocessor settings
=============================================================================*/

#ifndef ENABLE_GREY_ONLY
 #define ENABLE_GREY_ONLY 0
#endif

#ifndef RESOLUTION_SCALE
 #define RESOLUTION_SCALE 2		//[0-2] 0=fullres, 1=halfres, 2=quarter res
#endif

/*=============================================================================
	UI Uniforms
=============================================================================*/

uniform float FILTER_RADIUS <
	ui_type = "drag";
	ui_label = "Filter Smoothness";
	ui_min = 0.0;
	ui_max = 6.0;	
> = 4.0;

/*
uniform float4 tempF1 <
    ui_type = "drag";
    ui_min = -100.0;
    ui_max = 100.0;
> = float4(1,1,1,1);

uniform float4 tempF2 <
    ui_type = "drag";
    ui_min = -100.0;
    ui_max = 100.0;
> = float4(1,1,1,1);

uniform float4 tempF3 <
    ui_type = "drag";
    ui_min = -100.0;
    ui_max = 100.0;
> = float4(1,1,1,1);
*/
/*=============================================================================
	Textures, Samplers, Globals, Structs
=============================================================================*/

//do NOT change anything here. "hurr durr I changed this and now it works"
//you ARE breaking things down the line, if the shader does not work without changes
//here, it's by design.

texture ColorInputTex : COLOR;
texture DepthInputTex : DEPTH;
sampler ColorInput 	{ Texture = ColorInputTex; };
sampler DepthInput  { Texture = DepthInputTex; };

#include "qUINT\Global.fxh"
#include "qUINT\Depth.fxh"

//integer divide, rounding up
#define PI 3.14159265

#define INTERP 			LINEAR
#define FILTER_WIDE	 	true 
#define FILTER_NARROW 	false
#define BLOCK_SIZE 					3
#define SEARCH_OCTAVES              2
#define OCTAVE_SAMPLES             4	

#define MAX_MIP  	6 //do not change, tied to textures
#define MIN_MIP 	RESOLUTION_SCALE

texture texMotionVectors          { Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RG16F; };
sampler sMotionVectorTex         { Texture = texMotionVectors;  };

texture MotionTexIntermediate6               { Width = BUFFER_WIDTH >> 6;   Height = BUFFER_HEIGHT >> 6;   Format = RGBA16F; };
sampler sMotionTexIntermediate6              { Texture = MotionTexIntermediate6; };
texture MotionTexIntermediate5               { Width = BUFFER_WIDTH >> 5;   Height = BUFFER_HEIGHT >> 5;   Format = RGBA16F;  };
sampler sMotionTexIntermediate5              { Texture = MotionTexIntermediate5; };
texture MotionTexIntermediate4               { Width = BUFFER_WIDTH >> 4;   Height = BUFFER_HEIGHT >> 4;   Format = RGBA16F;  };
sampler sMotionTexIntermediate4              { Texture = MotionTexIntermediate4; };
texture MotionTexIntermediate3               { Width = BUFFER_WIDTH >> 3;   Height = BUFFER_HEIGHT >> 3;   Format = RGBA16F;  };
sampler sMotionTexIntermediate3              { Texture = MotionTexIntermediate3; };
texture MotionTexIntermediate2               { Width = BUFFER_WIDTH >> 2;   Height = BUFFER_HEIGHT >> 2;   Format = RGBA16F;  };
sampler sMotionTexIntermediate2              { Texture = MotionTexIntermediate2; };
texture MotionTexIntermediate1               { Width = BUFFER_WIDTH >> 1;   Height = BUFFER_HEIGHT >> 1;   Format = RGBA16F;  };
sampler sMotionTexIntermediate1              { Texture = MotionTexIntermediate1; };

#define MotionTexIntermediate0 				texMotionVectors
#define sMotionTexIntermediate0 			sMotionVectorTex


#if ENABLE_GREY_ONLY != 0
 #define FEATURE_FORMAT 	R8 
 #define FEATURE_TYPE 		float
 #define FEATURE_COMPS 		x
#else 
 #define FEATURE_FORMAT 	RG16F
 #define FEATURE_TYPE		float2
 #define FEATURE_COMPS 		xy
#endif

texture FeaturePyramid          { Width = BUFFER_WIDTH>>MIN_MIP;   Height = BUFFER_HEIGHT>>MIN_MIP;   Format = FEATURE_FORMAT; MipLevels = 1 + MAX_MIP - MIN_MIP; };
sampler sFeaturePyramid         { Texture = FeaturePyramid; MipFilter=INTERP; MagFilter=INTERP; MinFilter=INTERP; AddressU = MIRROR; AddressV = MIRROR; }; //MIRROR helps with out of frame disocclusions
texture FeaturePyramidPrev          { Width = BUFFER_WIDTH>>MIN_MIP;   Height = BUFFER_HEIGHT>>MIN_MIP;   Format = FEATURE_FORMAT; MipLevels = 1 + MAX_MIP - MIN_MIP; };
sampler sFeaturePyramidPrev         { Texture = FeaturePyramidPrev;MipFilter=INTERP; MagFilter=INTERP; MinFilter=INTERP; AddressU = MIRROR; AddressV = MIRROR; };


struct VSOUT
{
    float4 vpos : SV_Position;
    float2 uv   : TEXCOORD0;
};

struct CSIN 
{
    uint3 groupthreadid     : SV_GroupThreadID;         //XYZ idx of thread inside group
    uint3 groupid           : SV_GroupID;               //XYZ idx of group inside dispatch
    uint3 dispatchthreadid  : SV_DispatchThreadID;      //XYZ idx of thread inside dispatch
    uint threadid           : SV_GroupIndex;            //flattened idx of thread inside group
};

/*=============================================================================
	Functions
=============================================================================*/

FEATURE_TYPE get_curr_feature(float2 uv, int mip)
{
	mip = max(0, mip - MIN_MIP);
	return tex2Dlod(sFeaturePyramid, saturate(uv), mip).FEATURE_COMPS;
}

FEATURE_TYPE get_prev_feature(float2 uv, int mip)
{
	mip = max(0, mip - MIN_MIP);
	return tex2Dlod(sFeaturePyramidPrev, saturate(uv), mip).FEATURE_COMPS;
}

float4 find_best_residual_motion(VSOUT i, int level, float4 coarse_layer)
{	
	float2 texelsize = rcp(BUFFER_SCREEN_SIZE / exp2(level));
	FEATURE_TYPE local_block[BLOCK_SIZE * BLOCK_SIZE];

	float2 total_motion = coarse_layer.xy;
	float coarse_sim = coarse_layer.w;

	//use float4 for everything, then it's just doubling the components
	float4 moments_local = 0;
	float4 moments_search = 0;
	float2 moments_cov = 0;

	i.uv -= texelsize * (BLOCK_SIZE / 2); //since we only use to sample the blocks now, offset by half a block so we can do it easier inline

	[unroll] //array index not natively addressable bla...
	for(uint k = 0; k < BLOCK_SIZE * BLOCK_SIZE; k++)
	{
		float2 tuv = i.uv + float2(k / BLOCK_SIZE, k % BLOCK_SIZE) * texelsize;
		float2 t_local = get_curr_feature(tuv, level); 	
		float2 t_search = get_prev_feature(tuv + total_motion, level);		

		local_block[k] = t_local.FEATURE_COMPS;

		moments_local += float4(t_local, t_local * t_local);			
		moments_search += float4(t_search, t_search * t_search);
		moments_cov += t_local * t_search;
	}

	float2 cossim = moments_cov * rsqrt(moments_local.zw * moments_search.zw);
	float best_sim = saturate(min(cossim.x, cossim.y));
	float2 best_moments = moments_search.xz;

	float randseed = (((dot(uint2(i.vpos.xy) % 5, float2(1, 5)) * 17) % 25) + 0.5) / 25.0; //prime shuffled, similar spectral properties to bayer but faster to compute and unique values within 5x5
	randseed = frac(randseed + SEARCH_OCTAVES * 0.6180339887498);
	float2 randdir; sincos(randseed * 6.283, randdir.x, randdir.y); //yo dawg, I heard you like golden ratios

	int _octaves = SEARCH_OCTAVES;
	while(_octaves-- > 0)
	{
		_octaves = best_sim < 0.999999 ? _octaves : 0;
		float2 local_motion = 0;

		int _samples = OCTAVE_SAMPLES;
		while(_samples-- > 0)		
		{
			_samples = best_sim < 0.999999 ? _samples : 0;
			randdir = mul(randdir, float2x2(-0.7373688, 0.6754903, -0.6754903, -0.7373688));//rotate by larger golden angle			
			float2 search_offset = randdir * texelsize;
			float2 search_center = i.uv + total_motion + search_offset;			 

			moments_search = 0;			
			moments_cov = 0;

			[loop]
			for(uint k = 0; k < BLOCK_SIZE * BLOCK_SIZE; k++)
			{
				float2 t = get_prev_feature(search_center + float2(k / BLOCK_SIZE, k % BLOCK_SIZE) * texelsize, level);
				moments_search += float4(t, t * t);
				moments_cov += t * local_block[k];
			}

			cossim = moments_cov * rsqrt(moments_local.zw * moments_search.zw); 
			float sim = saturate(min(cossim.x, cossim.y));

			[branch] //1 less register vs branch
			if(sim > best_sim)				
			{
				best_sim = sim;
				local_motion = search_offset;
				best_moments = moments_search.xz;			
			}		
		}
		total_motion += local_motion;
		randdir *= 0.5;
	}
	best_moments /= BLOCK_SIZE * BLOCK_SIZE;		
	float4 curr_layer = float4(total_motion, sqrt(abs(best_moments.x * best_moments.x - best_moments.y)), saturate(1 - acos(best_sim) / (PI * 0.5)));  //delayed sqrt for variance -> stddev
	float blendfact = linearstep(curr_layer.w, 1.0, coarse_layer.w) * (level < MAX_MIP); //do not blend with prev frame as we don't have data
	return lerp(curr_layer, coarse_layer, sqrt(blendfact));
}

float4 atrous_upscale(VSOUT i, int level, sampler sMotionLow, bool filter_size)
{	
    float2 texelsize = rcp(tex2Dsize(sMotionLow));
	float2x2 rot90 = float2x2(0, -FILTER_RADIUS, FILTER_RADIUS, 0);

	float4 gbuffer_sum = 0;
	float wsum = 1e-6;
	int rad = filter_size ? 2 : 1;

	[loop]for(int x = -rad; x <= rad; x++)
	[loop]for(int y = -rad; y <= rad; y++)
	{
		float2 offs = mul(float2(x, y), rot90) * texelsize;
		float2 sample_uv = i.uv + offs;

		float4 sample_gbuf = tex2Dlod(sMotionLow, sample_uv, 0);
		float ws = saturate(10 - sample_gbuf.w * 10);
		float wf = saturate(1 - sample_gbuf.b * 128.0);
		float wm = dot(sample_gbuf.xy, sample_gbuf.xy);

		float weight = exp2(-(ws + wm + wf) * 8);
		weight *= all(saturate(sample_uv - sample_uv * sample_uv));
		gbuffer_sum += sample_gbuf * weight;
		wsum += weight;		
	}

	return gbuffer_sum / wsum;	
}

float4 motion_pass(in VSOUT i, sampler sMotionLow, int level, bool filter_size)
{
	float4 prior_motion = tex2Dlod(sMotionLow, i.uv, 0)*0.95;
    if(level < MAX_MIP)
    	prior_motion = atrous_upscale(i, level, sMotionLow, filter_size);	

	if(level < MIN_MIP)
		return prior_motion;

	return find_best_residual_motion(i, level, prior_motion);	
}

float3 showmotion(float2 motion)
{
	float angle = atan2(motion.y, motion.x);
	float dist = length(motion);
	float3 rgb = saturate(3 * abs(2 * frac(angle / 6.283 + float3(0, -1.0/3.0, 1.0/3.0)) - 1) - 1);
	return lerp(0.5, rgb, saturate(dist * 100));
}

/*=============================================================================
	Shader Entry Points
=============================================================================*/

VSOUT VS_Main(in uint id : SV_VertexID)
{
    VSOUT o;
    VS_FullscreenTriangle(id, o.vpos, o.uv); 
    return o;
}

void PSWriteFeature(in VSOUT i, out float2 o : SV_Target0)
{	
#if MIN_MIP > 0	
	const float4 radius = float4(0.7577, -0.7577, 2.907, 0);
	const float2 weight = float2(0.37487566, -0.12487566);
	o.x  =  dot(weight.x *float3(0.299, 0.587, 0.114), tex2D(ColorInput, i.uv + radius.xx * BUFFER_PIXEL_SIZE).xyz);
	o.x += dot(weight.x * float3(0.299, 0.587, 0.114), tex2D(ColorInput, i.uv + radius.xy * BUFFER_PIXEL_SIZE).xyz);
	o.x += dot(weight.x * float3(0.299, 0.587, 0.114), tex2D(ColorInput, i.uv + radius.yx * BUFFER_PIXEL_SIZE).xyz);
	o.x += dot(weight.x * float3(0.299, 0.587, 0.114), tex2D(ColorInput, i.uv + radius.yy * BUFFER_PIXEL_SIZE).xyz);
	o.x += dot(weight.y * float3(0.299, 0.587, 0.114), tex2D(ColorInput, i.uv + radius.zw * BUFFER_PIXEL_SIZE).xyz);
	o.x += dot(weight.y * float3(0.299, 0.587, 0.114), tex2D(ColorInput, i.uv - radius.zw * BUFFER_PIXEL_SIZE).xyz);
	o.x += dot(weight.y * float3(0.299, 0.587, 0.114), tex2D(ColorInput, i.uv + radius.wz * BUFFER_PIXEL_SIZE).xyz);
	o.x += dot(weight.y * float3(0.299, 0.587, 0.114), tex2D(ColorInput, i.uv - radius.wz * BUFFER_PIXEL_SIZE).xyz);	
#else	
	o.x = dot(tex2D(ColorInput, i.uv).rgb, float3(0.299, 0.587, 0.114));
#endif	
	o.y = Depth::get_linear_depth(i.uv);	
}

void PSMotion6(in VSOUT i, out float4 o : SV_Target0){o = motion_pass(i, sMotionTexIntermediate0, 6, FILTER_WIDE);}
void PSMotion5(in VSOUT i, out float4 o : SV_Target0){o = motion_pass(i, sMotionTexIntermediate6, 5, FILTER_WIDE);}
void PSMotion4(in VSOUT i, out float4 o : SV_Target0){o = motion_pass(i, sMotionTexIntermediate5, 4, FILTER_WIDE);}
void PSMotion3(in VSOUT i, out float4 o : SV_Target0){o = motion_pass(i, sMotionTexIntermediate4, 3, FILTER_WIDE);}
void PSMotion2(in VSOUT i, out float4 o : SV_Target0){o = motion_pass(i, sMotionTexIntermediate3, 2, FILTER_WIDE);}
void PSMotion1(in VSOUT i, out float4 o : SV_Target0){o = motion_pass(i, sMotionTexIntermediate2, 1, FILTER_NARROW);}
void PSMotion0(in VSOUT i, out float4 o : SV_Target0){o = motion_pass(i, sMotionTexIntermediate1, 0, FILTER_NARROW);}

void PSOut(in VSOUT i, out float3 o : SV_Target0)
{	
	o = showmotion(-tex2D(sMotionTexIntermediate0, i.uv).xy);
}

/*=============================================================================
	Techniques
=============================================================================*/

technique qUINT_opticalflow
{
    pass {VertexShader = VS_Main;PixelShader  = PSWriteFeature; RenderTarget = FeaturePyramid; } 

	pass {VertexShader = VS_Main;PixelShader = PSMotion6;RenderTarget = MotionTexIntermediate6;}
    pass {VertexShader = VS_Main;PixelShader = PSMotion5;RenderTarget = MotionTexIntermediate5;}
    pass {VertexShader = VS_Main;PixelShader = PSMotion4;RenderTarget = MotionTexIntermediate4;}
    pass {VertexShader = VS_Main;PixelShader = PSMotion3;RenderTarget = MotionTexIntermediate3;}
    pass {VertexShader = VS_Main;PixelShader = PSMotion2;RenderTarget = MotionTexIntermediate2;}
    pass {VertexShader = VS_Main;PixelShader = PSMotion1;RenderTarget = MotionTexIntermediate1;}
    pass {VertexShader = VS_Main;PixelShader = PSMotion0;RenderTarget = MotionTexIntermediate0;}

	pass {VertexShader = VS_Main;PixelShader  = PSWriteFeature; RenderTarget = FeaturePyramidPrev; }
	//pass {VertexShader = VS_Main;PixelShader  = PSOut;  }  
}