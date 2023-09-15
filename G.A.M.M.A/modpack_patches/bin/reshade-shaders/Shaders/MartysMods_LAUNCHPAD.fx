/*=============================================================================
                                                           
 d8b 888b     d888 888b     d888 8888888888 8888888b.   .d8888b.  8888888888 
 Y8P 8888b   d8888 8888b   d8888 888        888   Y88b d88P  Y88b 888        
     88888b.d88888 88888b.d88888 888        888    888 Y88b.      888        
 888 888Y88888P888 888Y88888P888 8888888    888   d88P  "Y888b.   8888888    
 888 888 Y888P 888 888 Y888P 888 888        8888888P"      "Y88b. 888        
 888 888  Y8P  888 888  Y8P  888 888        888 T88b         "888 888        
 888 888   "   888 888   "   888 888        888  T88b  Y88b  d88P 888        
 888 888       888 888       888 8888888888 888   T88b  "Y8888P"  8888888888                                                                 
                                                                            
    Copyright (c) Pascal Gilcher. All rights reserved.
    
    * Unauthorized copying of this file, via any medium is strictly prohibited
 	* Proprietary and confidential

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.

===============================================================================

    Launchpad is a prepass effect that prepares various data to use 
	in later shaders.

    Author:         Pascal Gilcher

    More info:      https://martysmods.com
                    https://patreon.com/mcflypg
                    https://github.com/martymcmodding  	

=============================================================================*/

/*=============================================================================
	Preprocessor settings
=============================================================================*/

#ifndef OPTICAL_FLOW_MATCHING_LAYERS 
 #define OPTICAL_FLOW_MATCHING_LAYERS 	1		//[0-2] 0=luma, 1=luma + depth, 2 = rgb + depth
#endif

#ifndef OPTICAL_FLOW_RESOLUTION
 #define OPTICAL_FLOW_RESOLUTION 		1		//[0-2] 0=fullres, 1=halfres, 2=quarter res
#endif

#ifndef LAUNCHPAD_DEBUG_OUTPUT
 #define LAUNCHPAD_DEBUG_OUTPUT 	  	0		//[0 or 1] 1: enables debug output of the motion vectors
#endif

/*=============================================================================
	UI Uniforms
=============================================================================*/

uniform float FILTER_RADIUS <
	ui_type = "drag";
	ui_label = "Optical Flow Filter Smoothness";
	ui_min = 0.0;
	ui_max = 6.0;	
> = 4.0;

uniform bool ENABLE_SMOOTH_NORMALS <	
	ui_label = "Enable Smooth Normals";
	ui_tooltip = "Filters the normal buffer to reduce low-poly look in MXAO and RTGI."
	"\n\n"
	"Lighting algorithms depend on normal vectors, which describe the orientation\n"
	"of the geometry in the scene. As ReShade does not access the game's own normals,\n"
	"they are generated from the depth buffer instead. However, this process is lossy\n"
	"and does not contain normal maps and smoothing groups.\n"
	"As a result, they represent the true (blocky) object shapes and lighting calculated\n"
	"using them can make the low-poly appearance of geometry apparent.\n";
> = false;

#if LAUNCHPAD_DEBUG_OUTPUT != 0
uniform int DEBUG_MODE < 
    ui_type = "combo";
	ui_items = "All\0Optical Flow\0Normals\0Depth\0";
	ui_label = "Debug Output";
> = 0;
#endif

uniform int UIHELP <
	ui_type = "radio";
	ui_label = " ";	
	ui_text ="\nDescription for preprocessor definitions:\n"
	"\n"
	"OPTICAL_FLOW_MATCHING_LAYERS\n"
	"\n"
	"Determines which data to use for optical flow\n"
	"0: luma (fastest)\n"
	"1: luma + depth (more accurate, slower, recommended)\n"
	"2: circular harmonics (by far most accurate, slowest)\n"
	"\n"
	"OPTICAL_FLOW_RESOLUTION\n"
	"\n"
	"Resolution factor for optical flow\n"
	"0: full resolution (slowest)\n"
	"1: half resolution (faster, recommended)\n"
	"2: quarter resolution (fastest)\n"
	"\n"
	"LAUNCHPAD_DEBUG_OUTPUT\n"
	"\n"
	"Various debug outputs\n"
	"0: off\n"
	"1: on\n";
	ui_category_closed = false;
>;

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

#include ".\MartysMods\mmx_global.fxh"
#include ".\MartysMods\mmx_depth.fxh"
#include ".\MartysMods\mmx_math.fxh"
#include ".\MartysMods\mmx_qmc.fxh"
#include ".\MartysMods\mmx_camera.fxh"
#include ".\MartysMods\mmx_deferred.fxh"

#if __RENDERER__ < RENDERER_D3D10 //too many textures because DX9 is a jackass
 #if OPTICAL_FLOW_MATCHING_LAYERS == 2
 #undef OPTICAL_FLOW_MATCHING_LAYERS 
 #define OPTICAL_FLOW_MATCHING_LAYERS 1
 #endif	
#endif

#define INTERP 			LINEAR
#define FILTER_WIDE	 	true 
#define FILTER_NARROW 	false

#define SEARCH_OCTAVES              2
#define OCTAVE_SAMPLES             	4

uniform uint FRAMECOUNT < source = "framecount"; >;

#define MAX_MIP  	6 //do not change, tied to textures
#define MIN_MIP 	OPTICAL_FLOW_RESOLUTION

texture MotionTexIntermediate6               { Width = BUFFER_WIDTH >> 6;   Height = BUFFER_HEIGHT >> 6;   Format = RGBA16F;  };
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

#define MotionTexIntermediate0 				Deferred::MotionVectorsTex
#define sMotionTexIntermediate0 			Deferred::sMotionVectorsTex

#if OPTICAL_FLOW_MATCHING_LAYERS == 0
 #define FEATURE_FORMAT 	R8 
 #define FEATURE_TYPE 		float
 #define FEATURE_COMPS 		x
#else
 #define FEATURE_FORMAT 	RG16F
 #define FEATURE_TYPE		float2
 #define FEATURE_COMPS 		xy
#endif

texture FeatureLayerPyramid          { Width = BUFFER_WIDTH>>MIN_MIP;   Height = BUFFER_HEIGHT>>MIN_MIP;   Format = FEATURE_FORMAT; MipLevels = 1 + MAX_MIP - MIN_MIP; };
sampler sFeatureLayerPyramid         { Texture = FeatureLayerPyramid; MipFilter=INTERP; MagFilter=INTERP; MinFilter=INTERP; AddressU = MIRROR; AddressV = MIRROR; }; 
texture FeatureLayerPyramidPrev          { Width = BUFFER_WIDTH>>MIN_MIP;   Height = BUFFER_HEIGHT>>MIN_MIP;   Format = FEATURE_FORMAT; MipLevels = 1 + MAX_MIP - MIN_MIP; };
sampler sFeatureLayerPyramidPrev         { Texture = FeatureLayerPyramidPrev;MipFilter=INTERP; MagFilter=INTERP; MinFilter=INTERP; AddressU = MIRROR; AddressV = MIRROR; };

#if OPTICAL_FLOW_MATCHING_LAYERS == 2
texture CircularHarmonicsPyramidCurr0          { Width = BUFFER_WIDTH>>MIN_MIP;   Height = BUFFER_HEIGHT>>MIN_MIP;   Format = RGBA16F; MipLevels = 4 - MIN_MIP; };
sampler sCircularHarmonicsPyramidCurr0         { Texture = CircularHarmonicsPyramidCurr0; MipFilter=INTERP; MagFilter=INTERP; MinFilter=INTERP; AddressU = MIRROR; AddressV = MIRROR; }; 
texture CircularHarmonicsPyramidCurr1          { Width = BUFFER_WIDTH>>MIN_MIP;   Height = BUFFER_HEIGHT>>MIN_MIP;   Format = RGBA16F; MipLevels = 4 - MIN_MIP; };
sampler sCircularHarmonicsPyramidCurr1         { Texture = CircularHarmonicsPyramidCurr1; MipFilter=INTERP; MagFilter=INTERP; MinFilter=INTERP; AddressU = MIRROR; AddressV = MIRROR; }; 
texture CircularHarmonicsPyramidPrev0          { Width = BUFFER_WIDTH>>MIN_MIP;   Height = BUFFER_HEIGHT>>MIN_MIP;   Format = RGBA16F; MipLevels = 4 - MIN_MIP; };
sampler sCircularHarmonicsPyramidPrev0         { Texture = CircularHarmonicsPyramidPrev0; MipFilter=INTERP; MagFilter=INTERP; MinFilter=INTERP; AddressU = MIRROR; AddressV = MIRROR; }; 
texture CircularHarmonicsPyramidPrev1          { Width = BUFFER_WIDTH>>MIN_MIP;   Height = BUFFER_HEIGHT>>MIN_MIP;   Format = RGBA16F; MipLevels = 4 - MIN_MIP; };
sampler sCircularHarmonicsPyramidPrev1         { Texture = CircularHarmonicsPyramidPrev1; MipFilter=INTERP; MagFilter=INTERP; MinFilter=INTERP; AddressU = MIRROR; AddressV = MIRROR; }; 
#else 
 #define CircularHarmonicsPyramidCurr0 ColorInputTex
 #define CircularHarmonicsPyramidCurr1 ColorInputTex
 #define CircularHarmonicsPyramidPrev0 ColorInputTex
 #define CircularHarmonicsPyramidPrev1 ColorInputTex
 #define sCircularHarmonicsPyramidCurr0 ColorInput
 #define sCircularHarmonicsPyramidCurr1 ColorInput
 #define sCircularHarmonicsPyramidPrev0 ColorInput
 #define sCircularHarmonicsPyramidPrev1 ColorInput
#endif

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

float4 get_curr_feature(float2 uv, int mip)
{
	mip = max(0, mip - MIN_MIP);
	return tex2Dlod(sFeatureLayerPyramid, saturate(uv), mip);
}

float4 get_prev_feature(float2 uv, int mip)
{
	mip = max(0, mip - MIN_MIP);
	return tex2Dlod(sFeatureLayerPyramidPrev, saturate(uv), mip);
}

float get_similarity(FEATURE_TYPE m_xx, FEATURE_TYPE m_yy, FEATURE_TYPE m_xy)
{	
#if OPTICAL_FLOW_MATCHING_LAYERS == 0
	return m_xy * rsqrt(m_xx * m_yy);
#else
	return dot(0.5, m_xy) * rsqrt(dot(0.5, m_xx) * dot(0.5, m_yy));
#endif
}

float3 jitter(in int2 pos)
{    
    const float2 magicdot = float2(0.75487766624669276, 0.569840290998); 
    const float3 magicadd = float3(0, 0.025, 0.0125) * dot(magicdot, 1);
    return frac(dot(pos, magicdot) + magicadd);  
}

float4 block_matching(VSOUT i, int level, float4 coarse_layer, const int blocksize)
{	
	level = max(level - 1, 0); //sample one higher res for better quality
	float2 texelsize = rcp(tex2Dsize(sFeatureLayerPyramid, max(0, level - MIN_MIP)));
	
	FEATURE_TYPE local_block[16];

	float2 total_motion = coarse_layer.xy;
	float coarse_sim = coarse_layer.w;

	FEATURE_TYPE m_x = 0;
	FEATURE_TYPE m_xx = 0;
	FEATURE_TYPE m_yy = 0;
	FEATURE_TYPE m_xy = 0;

	float search_scale = 3;
	i.uv -= texelsize * (blocksize / 2) * search_scale; //since we only use to sample the blocks now, offset by half a block so we can do it easier inline

	[unroll] //array index not natively addressable bla...
	for(uint k = 0; k < blocksize * blocksize; k++)
	{
		float2 offs = float2(k % blocksize, k / blocksize);
		float2 tuv = i.uv + offs * texelsize * search_scale;
		FEATURE_TYPE t_local = get_curr_feature(tuv, level).FEATURE_COMPS; 	
		FEATURE_TYPE t_search = get_prev_feature(tuv + total_motion, level).FEATURE_COMPS;		

		local_block[k] = t_local;

		m_x += t_local;
		m_xx += t_local * t_local;
		m_yy += t_search * t_search;
		m_xy += t_local * t_search;
	}	

	float variance = abs(m_xx.x / (blocksize * blocksize) - m_x.x * m_x.x / ((blocksize * blocksize)*(blocksize * blocksize)));
	float best_sim = minc(m_xy * rsqrt(m_xx * m_yy));

	//this fixes completely white areas from polluting the buffer with false offsets
	if(variance < exp(-32.0) || best_sim > 0.999999) 
		return float4(coarse_layer.xy, 0, 0);

	float phi = radians(360.0 / OCTAVE_SAMPLES);
	float4 rotator = Math::get_rotator(phi);	
	float randseed = jitter(i.vpos.xy).x;
	randseed = QMC::roberts1(level, randseed);

	float2 randdir; sincos(randseed * phi, randdir.x, randdir.y);
	int _octaves = SEARCH_OCTAVES + (level >= 1 ? 4 : 0);

	while(_octaves-- > 0)
	{
		_octaves = best_sim < 0.999999 ? _octaves : 0;
		float2 local_motion = 0;

		int _samples = OCTAVE_SAMPLES;
		while(_samples-- > 0)		
		{
			_samples = best_sim < 0.999999 ? _samples : 0;
			randdir = Math::rotate_2D(randdir, rotator);
			float2 search_offset = randdir * texelsize;
			float2 search_center = i.uv + total_motion + search_offset;			 

			m_yy = 0;
			m_xy = 0;

			[loop]
			for(uint k = 0; k < blocksize * blocksize; k++)
			{
				FEATURE_TYPE t = get_prev_feature(search_center + float2(k % blocksize, k / blocksize) * texelsize * search_scale, level).FEATURE_COMPS;
				m_yy += t * t;
				m_xy += local_block[k] * t;
			}	

			float sim = minc(m_xy * rsqrt(m_xx * m_yy));	
			if(sim < best_sim) continue;
			
			best_sim = sim;
			local_motion = search_offset;	
							
		}
		total_motion += local_motion;
		randdir *= 0.5;
	}

	
	float4 curr_layer = float4(total_motion, variance, saturate(-acos(best_sim) * PI + 1.0));
	return curr_layer;
}

float4 harmonics_matching(VSOUT i, int level, float4 coarse_layer, const int blocksize)
{	
	level = max(level - 1, 0); //sample one higher res for better quality
	float2 texelsize = rcp(tex2Dsize(sFeatureLayerPyramid, max(0, level - MIN_MIP)));

	float2 total_motion = coarse_layer.xy;
	float coarse_sim = coarse_layer.w;

	float4 local_harmonics[2];
	local_harmonics[0] = tex2Dlod(sCircularHarmonicsPyramidCurr0, saturate(i.uv), max(0, level - MIN_MIP));
	local_harmonics[1] = tex2Dlod(sCircularHarmonicsPyramidCurr1, saturate(i.uv), max(0, level - MIN_MIP));

	float4 search_harmonics[2];
	search_harmonics[0] = tex2Dlod(sCircularHarmonicsPyramidPrev0, saturate(i.uv + total_motion), max(0, level - MIN_MIP));
	search_harmonics[1] = tex2Dlod(sCircularHarmonicsPyramidPrev1, saturate(i.uv + total_motion), max(0, level - MIN_MIP));

	float m_xx = dot(1, local_harmonics[0]*local_harmonics[0] + local_harmonics[1]*local_harmonics[1]);
	float m_yy = dot(1, search_harmonics[0]*search_harmonics[0] + search_harmonics[1]*search_harmonics[1]);
	float m_xy = dot(1, search_harmonics[0]*local_harmonics[0] + search_harmonics[1]*local_harmonics[1]);

	float best_sim = m_xy * rsqrt(m_xx * m_yy);

	//this fixes completely white areas from polluting the buffer with false offsets
	if(best_sim > 0.999999) 
		return float4(coarse_layer.xy, 0, 0);

	float phi = radians(360.0 / OCTAVE_SAMPLES);
	float4 rotator = Math::get_rotator(phi);	
	float randseed = jitter(i.vpos.xy).x;
	randseed = QMC::roberts1(level, randseed);

	float2 randdir; sincos(randseed * phi, randdir.x, randdir.y);
	int _octaves = SEARCH_OCTAVES + (level >= 1 ? 2 : 0);

	while(_octaves-- > 0)
	{
		_octaves = best_sim < 0.999999 ? _octaves : 0;
		float2 local_motion = 0;

		int _samples = OCTAVE_SAMPLES;
		while(_samples-- > 0)		
		{
			_samples = best_sim < 0.999999 ? _samples : 0;
			randdir = Math::rotate_2D(randdir, rotator);
			float2 search_offset = randdir * texelsize;
			float2 search_center = i.uv + total_motion + search_offset;

			search_harmonics[0] = tex2Dlod(sCircularHarmonicsPyramidPrev0, saturate(search_center), max(0, level - MIN_MIP));
			search_harmonics[1] = tex2Dlod(sCircularHarmonicsPyramidPrev1, saturate(search_center), max(0, level - MIN_MIP));

			float m_yy = dot(1, search_harmonics[0]*search_harmonics[0] + search_harmonics[1]*search_harmonics[1]);
			float m_xy = dot(1, search_harmonics[0]*local_harmonics[0] + search_harmonics[1]*local_harmonics[1]);

			float sim = m_xy * rsqrt(m_xx * m_yy);
	
			if(sim < best_sim) continue;
			
			best_sim = sim;
			local_motion = search_offset;
							
		}
		total_motion += local_motion;
		randdir *= 0.5;
	}
	
	float4 curr_layer = float4(total_motion, 1.0, saturate(-acos(best_sim) * PI + 1.0));
	return curr_layer;
}

float4 atrous_upscale(VSOUT i, int level, sampler sMotionLow, int rad)
{	
    float2 texelsize = rcp(tex2Dsize(sMotionLow));
	float phi = QMC::roberts1(level * 0.2144, FRAMECOUNT % 16) * HALF_PI;
	float4 kernelmat = Math::get_rotator(phi) * FILTER_RADIUS;

	float4 sum = 0;
	float wsum = 1e-6;

	[loop]for(int x = -rad; x <= rad; x++)
	[loop]for(int y = -rad; y <= rad; y++)
	{
		float2 offs = float2(x, y);
		offs *= abs(offs);	
		float2 sample_uv = i.uv + Math::rotate_2D(offs, kernelmat) * texelsize; 

		float4 sample_gbuf = tex2Dlod(sMotionLow, sample_uv, 0);
		float2 sample_mv = sample_gbuf.xy;
		float sample_var = sample_gbuf.z;
		float sample_sim = sample_gbuf.w;

		float vv = dot(sample_mv, sample_mv);
		float ws = saturate(1.0 - sample_sim); ws *= ws;
		float wf = saturate(1 - sample_var * 128.0) * 3;
		float wm = dot(sample_gbuf.xy, sample_gbuf.xy) * 4;
		float weight = exp2(-(ws + wm + wf) * 4);

		weight *= all(saturate(sample_uv - sample_uv * sample_uv));
		sum += sample_gbuf * weight;
		wsum += weight;		
	}

	sum /= wsum;
	return sum;	
}

float4 atrous_upscale_temporal(VSOUT i, int level, sampler sMotionLow, int rad)
{	
   	float2 texelsize = rcp(tex2Dsize(sMotionLow));
	float phi = QMC::roberts1(level * 0.2144, FRAMECOUNT % 16) * HALF_PI;
	float4 kernelmat = Math::get_rotator(phi) * FILTER_RADIUS;

	float4 sum = 0;
	float wsum = 1e-6;

	float center_z = get_curr_feature(i.uv, max(0, level - 2)).y;

	[loop]for(int x = -rad; x <= rad; x++)
	[loop]for(int y = -rad; y <= rad; y++)
	{
		float2 offs = float2(x, y);
		offs *= abs(offs);	
		float2 sample_uv = i.uv + Math::rotate_2D(offs, kernelmat) * texelsize; 

		float4 sample_gbuf = tex2Dlod(sMotionLow, sample_uv, 0);
		float2 sample_mv = sample_gbuf.xy;
		float sample_var = sample_gbuf.z;
		float sample_sim = sample_gbuf.w;

		float vv = dot(sample_mv, sample_mv);

		float2 prev_mv = tex2Dlod(sMotionTexIntermediate0, sample_uv + sample_gbuf.xy, 0).xy;
		float2 mvdelta = prev_mv - sample_mv;
		float diff = dot(mvdelta, mvdelta) * rcp(1e-8 + max(vv, dot(prev_mv, prev_mv)));

		float wd = 3.0 * diff;		
		float ws = saturate(1.0 - sample_sim); ws *= ws;
		float wf = saturate(1 - sample_var * 128.0) * 3;
		float wm = dot(sample_gbuf.xy, sample_gbuf.xy) * 4;

		float weight = exp2(-(ws + wm + wf + wd) * 4);		

		float sample_z = get_curr_feature(sample_uv, max(0, level - 2)).y;
		float wz = abs(center_z - sample_z) / max3(0.00001, center_z, sample_z);
		weight *= exp2(-wz * 4);

		weight *= all(saturate(sample_uv - sample_uv * sample_uv));
		sum += sample_gbuf * weight;
		wsum += weight;
	}

	sum /= wsum;
	return sum;	
}

float4 motion_pass(in VSOUT i, sampler sMotionLow, int level, int filter_size, int block_size)
{
	float4 prior_motion = 0;
    if(level < MAX_MIP)
    	prior_motion = atrous_upscale(i, level, sMotionLow, filter_size);	

	if(level < MIN_MIP)
		return prior_motion;
	
	return block_matching(i, level, prior_motion, block_size);	
}

float4 motion_pass_with_temporal_filter(in VSOUT i, sampler sMotionLow, int level, int filter_size, int block_size)
{
	float4 prior_motion = 0;
    if(level < MAX_MIP)
    	prior_motion = atrous_upscale_temporal(i, level, sMotionLow, filter_size);	

	if(level < MIN_MIP)
		return prior_motion;

	return block_matching(i, level, prior_motion, block_size);	
}

float4 motion_pass_with_temporal_filter_harmonics(in VSOUT i, sampler sMotionLow, int level, int filter_size, int block_size)
{
	float4 prior_motion = 0;
    if(level < MAX_MIP)
    	prior_motion = atrous_upscale_temporal(i, level, sMotionLow, filter_size);	

	if(level < MIN_MIP)
		return prior_motion;

	return harmonics_matching(i, level, prior_motion, block_size);
}

float4 motion_pass_harmonics(in VSOUT i, sampler sMotionLow, int level, int filter_size, int block_size)
{
	float4 prior_motion = 0;
    if(level < MAX_MIP)
    	prior_motion = atrous_upscale(i, level, sMotionLow, filter_size);	

	if(level < MIN_MIP)
		return prior_motion;

	return harmonics_matching(i, level, prior_motion, block_size);
}

float3 showmotion(float2 motion)
{
	float angle = atan2(motion.y, motion.x);
	float dist = length(motion);
	float3 rgb = saturate(3 * abs(2 * frac(angle / 6.283 + float3(0, -1.0/3.0, 1.0/3.0)) - 1) - 1);
	return lerp(0.5, rgb, saturate(dist * 100));
}

//turbo colormap fit, turned into MADD form
float3 gradient(float t)
{	
	t = saturate(t);
	float3 res = float3(59.2864, 2.82957, 27.3482);
	res = mad(res, t.xxx, float3(-152.94239396, 4.2773, -89.9031));	
	res = mad(res, t.xxx, float3(132.13108234, -14.185, 110.36276771));
	res = mad(res, t.xxx, float3(-42.6603, 4.84297, -60.582));
	res = mad(res, t.xxx, float3(4.61539, 2.19419, 12.6419));
	res = mad(res, t.xxx, float3(0.135721, 0.0914026, 0.106673));
	return saturate(res);
}

float2 centroid_dir(float2 uv)
{
	const float2 offs[16] = {float2(-1, -3),float2(0, -3),float2(1, -3),float2(2, -2),float2(3, -1),float2(3, 0),float2(3, 1),float2(2,2),float2(1,3),float2(0,3),float2(-1,3),float2(-2,2),float2(-3,1),float2(-3,0),float2(-3,-1),float2(-2,-2)};
	float4 moments = 0;
	[unroll]
	for(int j = 0; j < 16; j++)
	{
		float v = dot(float3(0.299, 0.587, 0.114), tex2D(ColorInput, uv + BUFFER_PIXEL_SIZE * offs[j]).rgb);
		moments += float4(1, offs[j].x, offs[j].y, offs[j].x*offs[j].y) * v;
	}
	moments /= 16.0;
	return moments.yz / moments.x;
}

/*=============================================================================
	Shader Entry Points
=============================================================================*/

VSOUT MainVS(in uint id : SV_VertexID)
{
    VSOUT o;
    FullscreenTriangleVS(id, o.vpos, o.uv); 
    return o;
}

void WriteFeaturePS(in VSOUT i, out FEATURE_TYPE o : SV_Target0)
{	
	float4 feature_data = 0;
#if MIN_MIP > 0	
	const float4 radius = float4(0.7577, -0.7577, 2.907, 0);
	const float2 weight = float2(0.37487566, -0.12487566);
	feature_data.rgb =  weight.x * tex2D(ColorInput, i.uv + radius.xx * BUFFER_PIXEL_SIZE).xyz;
	feature_data.rgb += weight.x * tex2D(ColorInput, i.uv + radius.xy * BUFFER_PIXEL_SIZE).xyz;
	feature_data.rgb += weight.x * tex2D(ColorInput, i.uv + radius.yx * BUFFER_PIXEL_SIZE).xyz;
	feature_data.rgb += weight.x * tex2D(ColorInput, i.uv + radius.yy * BUFFER_PIXEL_SIZE).xyz;
	feature_data.rgb += weight.y * tex2D(ColorInput, i.uv + radius.zw * BUFFER_PIXEL_SIZE).xyz;
	feature_data.rgb += weight.y * tex2D(ColorInput, i.uv - radius.zw * BUFFER_PIXEL_SIZE).xyz;
	feature_data.rgb += weight.y * tex2D(ColorInput, i.uv + radius.wz * BUFFER_PIXEL_SIZE).xyz;
	feature_data.rgb += weight.y * tex2D(ColorInput, i.uv - radius.wz * BUFFER_PIXEL_SIZE).xyz;	
#else	
	feature_data.rgb = tex2D(ColorInput, i.uv).rgb;
#endif	
	feature_data.w = Depth::get_linear_depth(i.uv);	

#if OPTICAL_FLOW_MATCHING_LAYERS == 0
	o = dot(float3(0.299, 0.587, 0.114), feature_data.rgb);
#else
	o.x = dot(float3(0.299, 0.587, 0.114), feature_data.rgb);
	o.y = feature_data.w;
#endif
}

void generate_circular_harmonics(in VSOUT i, sampler s_features, out float4 coeffs0, out float4 coeffs1)
{
	float2 Y1 = 0;
	float2 Y2 = 0;
	float2 Y3 = 0;
	float2 Y4 = 0;

	//take 5 minutes writing down all the coefficients? no
	//take 15 minutes generating them procedurally? hell yes
	float2 gather_offsets[4] = {float2(-0.5, 0.5), float2(0.5, 0.5), float2(0.5, -0.5), float2(-0.5, -0.5)};
	float4 rotator = Math::get_rotator(radians(90.0));
	float2 offsets[3] = {float2(1.5, 0.5), float2(1.5, 2.5), float2(0.0, 3.5)};

	[unroll]
	for(int j = 0; j < 4; j++)
	{
		[unroll]
		for(int k = 0; k < 3; k++)
		{
			float2 p = offsets[k];
			float4 v = tex2DgatherR(s_features, i.uv + p * BUFFER_PIXEL_SIZE * exp2(MIN_MIP));

			[unroll]
			for(int ch = 0; ch < 4; ch++)
			{
				float x = p.x + gather_offsets[ch].x;
				float y = p.y + gather_offsets[ch].y;
				float r = sqrt(x*x+y*y+1e-6);

				Y1 += v[ch].xx * float2(y, x) / r;
				Y2 += v[ch].xx * float2(x * y, x*x - y*y) / (r * r);
				Y3 += v[ch].xx * float2(y*(3*x*x-y*y), x*(x*x-3*y*y)) / (r*r*r);
				Y4 += v[ch].xx * float2(x*y*(x*x-y*y),x*x*(x*x-3*y*y)-y*y*(3*x*x-y*y)) / (r*r*r*r);
			}

			offsets[k] = Math::rotate_2D(offsets[k], rotator);
		}
	}

	coeffs0 = float4(Y1, Y2);
	coeffs1 = float4(Y3, Y4);
}

void CircularHarmonicsPS(in VSOUT i, out PSOUT2 o)
{	
	generate_circular_harmonics(i, sFeatureLayerPyramid, o.t0, o.t1);
}

void CircularHarmonicsPrevPS(in VSOUT i, out PSOUT2 o)
{	
	generate_circular_harmonics(i, sFeatureLayerPyramidPrev, o.t0, o.t1);
}

void MotionPS6(in VSOUT i, out float4 o : SV_Target0){o = motion_pass_with_temporal_filter(i, sMotionTexIntermediate2, 6, 2, 4);}
void MotionPS5(in VSOUT i, out float4 o : SV_Target0){o = motion_pass_with_temporal_filter(i, sMotionTexIntermediate6, 5, 2, 4);}
void MotionPS4(in VSOUT i, out float4 o : SV_Target0){o = motion_pass_with_temporal_filter(i, sMotionTexIntermediate5, 4, 2, 4);}
void MotionPS3(in VSOUT i, out float4 o : SV_Target0){o = motion_pass_with_temporal_filter(i, sMotionTexIntermediate4, 3, 2, 4);}
#if OPTICAL_FLOW_MATCHING_LAYERS == 2
void MotionPS2(in VSOUT i, out float4 o : SV_Target0){o = motion_pass_with_temporal_filter_harmonics(i, sMotionTexIntermediate3, 2, 2, 4);}
void MotionPS1(in VSOUT i, out float4 o : SV_Target0){o = motion_pass_harmonics(i, sMotionTexIntermediate2, 1, 1, 3);}
void MotionPS0(in VSOUT i, out float4 o : SV_Target0){o = motion_pass_harmonics(i, sMotionTexIntermediate1, 0, 1, 2);}
#else 
void MotionPS2(in VSOUT i, out float4 o : SV_Target0){o = motion_pass_with_temporal_filter(i, sMotionTexIntermediate3, 2, 2, 4);}
void MotionPS1(in VSOUT i, out float4 o : SV_Target0){o = motion_pass(i, sMotionTexIntermediate2, 1, 1, 3);}
void MotionPS0(in VSOUT i, out float4 o : SV_Target0){o = motion_pass(i, sMotionTexIntermediate1, 0, 1, 2);}
#endif

/*=============================================================================
	Shader Entry Points - Normals
=============================================================================*/

void NormalsPS(in VSOUT i, out float2 o : SV_Target0)
{
	//TODO optimize with tex2Dgather? Compute? What about scaled depth buffers? oh man
	const float2 dirs[9] = 
	{
		BUFFER_PIXEL_SIZE * float2(-1,-1),//TL
		BUFFER_PIXEL_SIZE * float2(0,-1),//T
		BUFFER_PIXEL_SIZE * float2(1,-1),//TR
		BUFFER_PIXEL_SIZE * float2(1,0),//R
		BUFFER_PIXEL_SIZE * float2(1,1),//BR
		BUFFER_PIXEL_SIZE * float2(0,1),//B
		BUFFER_PIXEL_SIZE * float2(-1,1),//BL
		BUFFER_PIXEL_SIZE * float2(-1,0),//L
		BUFFER_PIXEL_SIZE * float2(-1,-1)//TL first duplicated at end cuz it might be best pair	
	};

	float z_center = Depth::get_linear_depth(i.uv);
	float3 center_pos = Camera::uv_to_proj(i.uv, Camera::depth_to_z(z_center));

	//z close/far
	float2 z_prev;
	z_prev.x = Depth::get_linear_depth(i.uv + dirs[0]);
	z_prev.y = Depth::get_linear_depth(i.uv + dirs[0] * 2);

	float4 best_normal = float4(0,0,0,100000);
	float4 weighted_normal = 0;

	[loop]
	for(int j = 1; j < 9; j++)
	{
		float2 z_curr;
		z_curr.x = Depth::get_linear_depth(i.uv + dirs[j]);
		z_curr.y = Depth::get_linear_depth(i.uv + dirs[j] * 2);

		float2 z_guessed = 2 * float2(z_prev.x, z_curr.x) - float2(z_prev.y, z_curr.y);
		float score = dot(1, abs(z_guessed - z_center));
	
		float3 dd_0 = Camera::uv_to_proj(i.uv + dirs[j],     Camera::depth_to_z(z_curr.x)) - center_pos;
		float3 dd_1 = Camera::uv_to_proj(i.uv + dirs[j - 1], Camera::depth_to_z(z_prev.x)) - center_pos;
		float3 temp_normal = cross(dd_0, dd_1);
		float w = rcp(dot(temp_normal, temp_normal));
		w *= rcp(score * score + exp2(-32.0));
		weighted_normal += float4(temp_normal, 1) * w;	

		best_normal = score < best_normal.w ? float4(temp_normal, score) : best_normal;
		z_prev = z_curr;
	}

	float3 normal = weighted_normal.w < 1.0 ? best_normal.xyz : weighted_normal.xyz;
	//normal = best_normal.xyz;
	normal *= rsqrt(dot(normal, normal) + 1e-8);	
	o = Math::octahedral_enc(-normal);//fixes bugs in RTGI, normal.z positive gives smaller error :)
}

//gbuffer halfres for fast filtering
texture SmoothNormalsTempTex0  { Width = BUFFER_WIDTH/2;   Height = BUFFER_HEIGHT/2;   Format = RGBA16F;  };
sampler sSmoothNormalsTempTex0 { Texture = SmoothNormalsTempTex0; };
//gbuffer halfres for fast filtering
texture SmoothNormalsTempTex1  { Width = BUFFER_WIDTH/2;   Height = BUFFER_HEIGHT/2;   Format = RGBA16F;  };
sampler sSmoothNormalsTempTex1 { Texture = SmoothNormalsTempTex1; };
//high res copy back so we can fetch center tap at full res always
texture SmoothNormalsTempTex2  < pooled = true; > { Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RG8;  };
sampler sSmoothNormalsTempTex2 { Texture = SmoothNormalsTempTex2; };

void CopyNormalsPS(in VSOUT i, out float2 o : SV_Target0)
{
	o = tex2D(sSmoothNormalsTempTex2, i.uv).xy;
}

void SmoothNormalsMakeGbufPS(in VSOUT i, out float4 o : SV_Target0)
{
	o.xyz = Deferred::get_normals(i.uv);
	o.w = Camera::depth_to_z(Depth::get_linear_depth(i.uv));
}

void get_gbuffer(in sampler s, in float2 uv, out float3 p, out float3 n)
{
	float4 t = tex2Dlod(s, uv, 0);
	n = t.xyz;
	p = Camera::uv_to_proj(uv, t.w);
}

void get_gbuffer_hi(in float2 uv, out float3 p, out float3 n)
{
	n = Deferred::get_normals(uv);
	p = Camera::uv_to_proj(uv);
}

float sample_distribution(float x, int iteration)
{
	if(!iteration) return x * sqrt(x);
	return x;
	//return x * x;
	//return exp2(2 * x - 2);
}

float sample_pdf(float x, int iteration)
{
	if(!iteration) return 1.5 * sqrt(x);
	return 1;
	//return 2 * x;
	//return 2 * log(2.0) * exp2(2 * x - 2);
}

float2x3 to_tangent(float3 n)
{
    bool bestside = n.z < n.y;
    float3 n2 = bestside ? n.xzy : n;
    float3 k = (-n2.xxy * n2.xyy) * rcp(1.0 + n2.z) + float3(1, 0, 1);
    float3 u = float3(k.xy, -n2.x);
    float3 v = float3(k.yz, -n2.y);
    u = bestside ? u.xzy : u;
    v = bestside ? v.xzy : v;
    return float2x3(u, v);
}

float4 smooth_normals_mkii(in VSOUT i, int iteration, sampler sGbuffer)
{
	int num_dirs = iteration ? 6 : 4;
	int num_steps = iteration ? 3 : 6;	
	float radius_mult = iteration ? 0.2 : 1.0;	

	float2 angle_tolerance = float2(45.0, 30.0); //min/max

	radius_mult *= 0.2 * 0.2;

	float4 rotator = Math::get_rotator(TAU / num_dirs);
	float2 kernel_dir; sincos(TAU / num_dirs + TAU / 12.0, kernel_dir.x, kernel_dir.y); 
	
	float3 p, n;
	get_gbuffer_hi(i.uv, p, n);
	float2x3 kernel_matrix = to_tangent(n);

	float4 bin_front = float4(n, 1) * 0.15;
	float4 bin_back = float4(n, 1) * 0.15;

	float2 sigma_n = cos(radians(angle_tolerance));

	[loop]
	for(int dir = 0; dir < num_dirs; dir++)
	{
		[loop]
		for(int stp = 0; stp < num_steps; stp++)
		{
			float fi = float(stp + 1.0) / num_steps;

			float r = sample_distribution(fi, iteration);
			float ipdf = sample_pdf(fi, iteration);

			float2 sample_dir = normalize(Camera::proj_to_uv(p + 0.1 * mul(kernel_dir, kernel_matrix)) - i.uv);
			//sample_dir = 0.8 * BUFFER_ASPECT_RATIO * kernel_dir;//

			float2 sample_uv = i.uv + sample_dir * r * radius_mult;
			if(!Math::inside_screen(sample_uv)) break;

			float3 sp, sn;
			get_gbuffer(sGbuffer, sample_uv, sp, sn);

			float ndotn = dot(sn, n);
			float plane_distance = abs(dot(sp - p, n)) + abs(dot(p - sp, sn));

			float wn = smoothstep(sigma_n.x, sigma_n.y, ndotn);
			float wz = exp2(-plane_distance*plane_distance * 10.0);
			float wd = exp2(-dot(p - sp, p - sp));

			float w = wn * wz * wd;

			//focal point detection, find closest point to both 3D lines
			/*
			//find connecting axis
			float3 A = cross(n, sn);

			//find segment lengths for both line equations p + lambda * n
			float d2 = dot(p - sp, cross(n, A)) / dot(sn, cross(n, A));
			float d1 = dot(sp - p, cross(sn, A)) / dot(n, cross(sn, A));
			*/

			//heavily simplified math of the above using Lagrange identity and dot(n,n)==dot(sn,sn)==1
			float d2 = (ndotn * dot(p - sp,  n) - dot(p - sp, sn)) / (ndotn*ndotn - 1);
			float d1 = (ndotn * dot(p - sp, sn) - dot(p - sp,  n)) / (1 - ndotn*ndotn);

			//calculate points where each line is closest to the other line
			float3 hit1 = p + n * d1;
			float3 hit2 = sp + sn * d2;

			//mutual focal point is the mid point between those 2
			float3 middle = (hit1 + hit2) * 0.5;
			float side = dot(middle - p, n);

			//a hard sign split causes flickering, so do a smooth classifier as front or back
			float front_weight = saturate(side * 3.0 + 0.5);
			float back_weight = 1 - front_weight;

			if(ndotn > 0.9999) //fix edge case with parallel lines
			{
				front_weight = 1;
				back_weight = 1;
			}

			bin_front += float4(sn, 1) * ipdf * w * front_weight;
			bin_back += float4(sn, 1) * ipdf * w * back_weight;

			if(w < 0.01) break;
		}

		kernel_dir = Math::rotate_2D(kernel_dir, rotator);
	}

	bin_back.xyz = normalize(bin_back.xyz);
	bin_front.xyz = normalize(bin_front.xyz);

	//smooth binary select
	float bal = bin_back.w / (bin_front.w + bin_back.w);
	bal = smoothstep(0, 1, bal);
	bal = smoothstep(0, 1, bal);

	float3 best_bin = lerp(bin_front.xyz, bin_back.xyz, bal);
	return float4(safenormalize(best_bin), p.z);
}

VSOUT SmoothNormalsVS(in uint id : SV_VertexID)
{
    VSOUT o;
    FullscreenTriangleVS(id, o.vpos, o.uv); 
	if(!ENABLE_SMOOTH_NORMALS) o.vpos = -100000; //forcing NaN here kills this in geometry stage, faster than discard()
    return o;
}

void SmoothNormalsPass0PS(in VSOUT i, out float4 o : SV_Target0)
{
	o = smooth_normals_mkii(i, 0, sSmoothNormalsTempTex0);	
}

void SmoothNormalsPass1PS(in VSOUT i, out float2 o : SV_Target0)
{	
	o = Math::octahedral_enc(-smooth_normals_mkii(i, 1, sSmoothNormalsTempTex1).xyz);
}

#if LAUNCHPAD_DEBUG_OUTPUT != 0
void DebugPS(in VSOUT i, out float3 o : SV_Target0)
{	
	o = 0;
	switch(DEBUG_MODE)
	{
		case 0: //all 
		{
			float2 tuv = i.uv * 2.0;
			int2 q = tuv < 1.0.xx ? int2(0,0) : int2(1,1);
			tuv = frac(tuv);
			int qq = q.x * 2 + q.y;
			if(qq == 0) o = Deferred::get_normals(tuv) * 0.5 + 0.5;
			if(qq == 1) o = gradient(Depth::get_linear_depth(tuv));
			if(qq == 2) o = showmotion(Deferred::get_motion(tuv));	
			if(qq == 3) o = tex2Dlod(ColorInput, tuv, 0).rgb;	
			break;			
		}
		case 1: o = showmotion(Deferred::get_motion(i.uv)); break;
		case 2: o = Deferred::get_normals(i.uv) * 0.5 + 0.5; break;
		case 3: o = gradient(Depth::get_linear_depth(i.uv)); break;
	}

	//o = linearstep(tempF2.x, 1, tex2D(sMotionTexIntermediate2, i.uv).w);
}
#endif

/*=============================================================================
	Techniques
=============================================================================*/

technique MartysMods_Launchpad
<
    ui_label = "iMMERSE Launchpad (enable and move to the top!)";
    ui_tooltip =        
        "                           MartysMods - Launchpad                             \n"
        "                   MartysMods Epic ReShade Effects (iMMERSE)                  \n"
        "______________________________________________________________________________\n"
        "\n"

        "Launchpad is a catch-all setup shader that prepares various data for the other\n"
        "effects. Enable this effect and move it to the top of the effect list.        \n"
        "\n"
        "\n"
        "Visit https://martysmods.com for more information.                            \n"
        "\n"       
        "______________________________________________________________________________";
>
{
	pass {VertexShader = MainVS;PixelShader = NormalsPS; RenderTarget = Deferred::NormalsTex; }		
	pass {VertexShader = SmoothNormalsVS;PixelShader = SmoothNormalsMakeGbufPS;  RenderTarget = SmoothNormalsTempTex0;}
	pass {VertexShader = SmoothNormalsVS;PixelShader = SmoothNormalsPass0PS;  RenderTarget = SmoothNormalsTempTex1;}
	pass {VertexShader = SmoothNormalsVS;PixelShader = SmoothNormalsPass1PS;  RenderTarget = SmoothNormalsTempTex2;}
	pass {VertexShader = SmoothNormalsVS;PixelShader = CopyNormalsPS; RenderTarget = Deferred::NormalsTex; }
#if OPTICAL_FLOW_MATCHING_LAYERS == 2
	pass {VertexShader = MainVS;PixelShader  = CircularHarmonicsPrevPS;  RenderTarget0 = CircularHarmonicsPyramidPrev0; RenderTarget1 = CircularHarmonicsPyramidPrev1; }	
#endif
    pass {VertexShader = MainVS;PixelShader = WriteFeaturePS; RenderTarget = FeatureLayerPyramid; } 
#if OPTICAL_FLOW_MATCHING_LAYERS == 2
	pass {VertexShader = MainVS;PixelShader  = CircularHarmonicsPS;  RenderTarget0 = CircularHarmonicsPyramidCurr0; RenderTarget1 = CircularHarmonicsPyramidCurr1; }
#endif
	pass {VertexShader = MainVS;PixelShader = MotionPS6;RenderTarget = MotionTexIntermediate6;}
    pass {VertexShader = MainVS;PixelShader = MotionPS5;RenderTarget = MotionTexIntermediate5;}
    pass {VertexShader = MainVS;PixelShader = MotionPS4;RenderTarget = MotionTexIntermediate4;}
    pass {VertexShader = MainVS;PixelShader = MotionPS3;RenderTarget = MotionTexIntermediate3;}
    pass {VertexShader = MainVS;PixelShader = MotionPS2;RenderTarget = MotionTexIntermediate2;}
    pass {VertexShader = MainVS;PixelShader = MotionPS1;RenderTarget = MotionTexIntermediate1;}
    pass {VertexShader = MainVS;PixelShader = MotionPS0;RenderTarget = MotionTexIntermediate0;}
	pass {VertexShader = MainVS;PixelShader = WriteFeaturePS; RenderTarget = FeatureLayerPyramidPrev; }
#if LAUNCHPAD_DEBUG_OUTPUT != 0 //why waste perf for this pass in normal mode
	pass {VertexShader = MainVS;PixelShader  = DebugPS;  }		
#endif 

}