//Scatter
//Written by MJ_Ehsan for Reshade
//Version 1.2

//credits:
//the noise2d function is converted from shadertoy to work with reshade
//original code: https://www.shadertoy.com/view/lldBRn
//created by "sujay" with the name "Noise Functions"
//Thanks leftfarian for your great repository "Reshaders" and for your helps
//Thanks Lord OF Lunacy for your helps
//Thanks Pascal Gilcher for your helps
//Thanks Radegast, Ceejay.dk, kingeric1992, and every other shader dev in the reshade discord server who helped me
//Also Thanks alot Google!
//And thank you Nvidia for your "RayTracing Gems" book - section "ReBlur : A Hierarchical Recurrent Denoiser"
//And Thanks again Pascal Gilcher, because This shader sandwiches your qUINT_SSR shader
//And finally, thanks jakobPCoder for DMRE

//license
//CC0 ^_^	

//TO DO
//1-  [v]fix reflection blending in bright areas and when the reflection is darker than the surface color
//2-  [v]adaptive spatial blur depending on the number of blended frames using deghosting mask
//3-  [v]add blending options such as exposure, gamma, and saturation
//4-  [v]inverse tonemapping for reflections to make fireflies more effective in the spatially
//       denoised image(Yes! they're needed)
//5-  [v]mip generation for history rejection fixing after Temporal Accumulator
//6-  [v]reprojection using DRME
//7-  [v]rewriting ui
//8-  [x]fixing gi mode - Removed feature, May add again in the future
//9-  [v]fixing Temporal Accumulator clmaping (It's now using the same clmaping factor as the Temporal Stabilizer)
//10- [v]changing the determinator of blur passes from OGColor to DepthNormals (- and maybe adding the OGColor to it as well)
//11- [v]adding roughness estimation
//12- [v]making midblur pass relative to the estimated roughness
//13- [v]optimizing blur passes by dividing the sampling area to the number of iterations
//14- [o]any possible optimization is welcome 
//15- [v]finding a good looking default setting for the ui
//16- [v]adding temporal infinite bounces to the SSR
//		[ ]1- fix sea wave effect when infinite bounce is enabled!
//17- [x]add sky masking after denoiser
//18- [v]add debug view for :
//		[v]1- reflection //needs rewrite
//		[v]2- roughness
//19- [x]add the option to disable denoiser passes individually
//20- [v]fix deghosting threshold. It gives a value higher than 0 even with a completely still image!
//21- [v]moving blur quality from uniform variables to preprocessor defenitions or making it conditional depending on API
//	   Blur quality is used as a condition state in loops. But uniform variables are not good for DX9 and older
//22- [v]fixing temporal accumulator only accumulating 2 frames! (fixed. know it can accumulate infinite amount of frames)
//23- [ ]Changing the median filter (PreBlur) to something that conserves the energy

///////////////Include/////////////////////

#include "ReShadeUI.fxh"
#include "ReShade.fxh"
#if exists("MotionVectors.fxh")
 #include "MotionVectors.fxh"
#endif

uniform float Timer < source = "timer"; >;

#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

#ifndef BLUR_QUALITY
 #define BLUR_QUALITY 8
#endif

#ifndef MaxAccumulatedFrameNum
 #define MaxAccumulatedFrameNum 15
#endif

///////////////Include/////////////////////
///////////////Textures-Samplers///////////

texture TexColor : COLOR;
sampler sTexColor {Texture = TexColor; SRGBTexture = false;};

texture TexDepth : DEPTH;
sampler sTexDepth {Texture = TexDepth;};

texture2D NormalTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler sNormalTex {Texture = NormalTex; };

texture2D RoughnessTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8;};
sampler sRoughnessTex {Texture = RoughnessTex;};
	
texture2D NoiseTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sNoiseTex {Texture = NoiseTex;};

texture2D OGColorTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler sOGColorTex {Texture = OGColorTex;};

texture2D TASSRTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sTASSRTex {Texture = TASSRTex; };

texture2D TAColorTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sTAColorTex {Texture = TAColorTex; };

texture2D TSTex1 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sTSTex1 {Texture = TSTex1; };

texture2D TATex2 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; MipLevels = 4; };
sampler sTATex2 {Texture = TATex2; };

///////////////Textures-Samplers///////////
///////////////UI//////////////////////////

uniform int Hints<
	ui_text = 
		"Strongly recommended to use with DRME(MotionEstimation.fx)\n"
		"This shader is supposed to be used with qUINT_SSR and or DH_RTGI\n"
		"If you want to use both SSR and DH_RTGI at the same time, put SSR\n"
		"on top of DH_RTGI to avoid artifacts. Even tho otherwise is more physical.\n\n"
		
		"Download SSR : https://github.com/martymcmodding/qUINT\n"
		"Thanks Marty\n"
		"Recommended settigns for qUINT_SSR:\n"
		"Filtering and Details >\n"
		"Filter Kernel Size : 0.5\n"
		"Surface Relief Height : 1.00\n"
		"Surface Relief Scale : 0.35\n\n"
		
		"Download DH_RTGI : https://github.com/mj-ehsan/dh-reshade-shaders\n"
		"Thanks Alucard\n"
		"Recommended settings for DH_RTGI\n"
		"Settings > Temporal accumulation : 0\n"
		"AO > Distance : 32 - 128\n"
		"Smoothing > Radius : 1\n"
		"Smoothing > Pass : 2.5\n"
		
		"Download DRME : https://github.com/JakobPCoder/ReshadeMotionEstimation\n"
		"Thanks JakobPCoder\n"
		"Recommended settings for DRME\n"
		"Motion Estimation Detail : Quarter\n";
		
	ui_category = "Hints - Please Read for good results";
	ui_category_closed = true;
	ui_label = " ";
	ui_type = "radio";
>;

uniform float roughfac1 <
	ui_type = "slider";
	ui_category = "Roughness";
	ui_label = "Variation Frequency";
	ui_tooltip = "How wide it should search for variation in roughness?\n"
				 "Low = Detailed\nHigh = Soft";
	ui_max = 3;
> = 1;

uniform float roughfac2 <
	ui_type = "slider";
	ui_category = "Roughness";
	ui_label = "Roughness Curve";
	ui_tooltip = "Overall roughness bias\n"
				 "Final Roughness is also affected by (Surface Relief Height - Recommended : 1)\n"
				 "and (Surface Relief Scale - Recommended : 0.35) Values in SSR.";
	ui_min = 0.1;
	ui_max = 2;
> = 0.45;

uniform float2 fromrough <
	ui_type = "slider";
	ui_category = "Roughness";
	ui_label = "Levels - input";
	ui_tooltip = "1st one: Any color below this will become black.\n"
				 "2nd one: Any color above this will become white.";
> = float2( 0.1, 1);

uniform float2 torough <
	ui_type = "slider";
	ui_category = "Roughness";
	ui_label = "Levels - output";
	ui_tooltip = "1st one: Brightens the dark pixels.\n"
				 "2nd one: Darkens the bright pixels.";
> = float2( 0.1, 1);

/*uniform float BlendFactor <
	ui_type = "slider";
	ui_category = "Temporal Stabilizer";
	ui_category_closed = true;
	ui_label = "Power";
	ui_max = 0.99;
	ui_tooltip = "More = More stable image and potentially more ghosting artifact\n0 by default";
> = 0.0;*/
static const float BlendFactor = 0;

/*uniform float Deghost <
	ui_type = "slider";
	ui_category = "Temporal Stabilizer";
	ui_category_closed = true;
	ui_label = "Deghosting Power";
	ui_max = 5;
	ui_tooltip = "Reduces Temporal Stabilizer artifacts";
> = 2.5;*/

static const float Deghost = 0;

uniform float color_threshold1 <
	ui_label = "Color Threshold";
	ui_tooltip = "Color Based Deghosting for Temporal Accumulator";
	ui_type = "slider";
	ui_category = "Temporal Accumulator";
	ui_category_closed = true;
	ui_min = 0;
	ui_max = 1;
> = 0.4;

uniform float normal_threshold1 <
	ui_label = "Normal Threshold";
	ui_tooltip = "Normal (Surface Angle) Based Deghosting for Temporal Accumulator\nReduce only if the game is using TAA";
	ui_type = "slider";
	ui_category = "Temporal Accumulator";
	ui_category_closed = true;
	ui_min = 0;
	ui_max = 4;
> = 2.5;

uniform float color_threshold <
	ui_label = "Color Threshold";
	ui_tooltip = "Color Based Edge Detection Threshold\nLower = More detail\nHigher = Less noise";
	ui_type = "slider";
	ui_category = "Spatial Denoiser";
	ui_category_closed = true;
	ui_min = 0;
	ui_max = 0.2;
> = 0.005;

uniform float normal_threshold <
	ui_label = "Normal Threshold";
	ui_tooltip = "Normal (Surface Angle) Based Edge Detection Threshold\nLower = More detail\nHigher = Less noise";
	ui_type = "slider";
	ui_category = "Spatial Denoiser";
	ui_category_closed = true;
	ui_min = 0;
	ui_max = 0.2;
> = 0.005;

uniform float radius <
	ui_label = "Blur Radius";
	ui_category = "Spatial Denoiser";
	ui_tooltip = "A multiplier for the Blur Radius";
	ui_type = "slider";
	ui_category_closed = true;
	ui_max = 30;
> = 40;

uniform int debug <
	ui_label = "Debug Mode";
	ui_type = "combo";
	ui_tooltip = "Shows different layers of the shader to let you adjust the settings easier";
	ui_items = "None\0Roughness map\0";
	ui_category = "Extra";
> = 0;

uniform bool MedianDebug <
	ui_label = "PreBlur";
	ui_category = "Extra";
> = 1;

uniform float Exposure <
	ui_category = "Extra";
	ui_tooltip = "Reflection exposure";
	ui_type = "slider";
	ui_max = 2;
> = 1;

uniform bool infinitebounce <
	ui_category = "Extra";
	ui_type = "radio";
	ui_label = "(EXPERIMENTAL!)infinite bounce";
> = 0;

uniform bool GI <
	ui_label = "GI mode";
	ui_category = "Extra";
	ui_type = "radio";
	ui_tooltip = "Turn on if you want to use Scatter only with DH_RTGI";
> = 0;

///////////////UI//////////////////////////
///////////////Functions///////////////////

//Normal From Depth - From DisplayDepth.fx
float3 GetNormal(float2 texcoord)
{
	float3 offset = float3(BUFFER_PIXEL_SIZE, 0.0);
	float2 posCenter = texcoord.xy;
	float2 posNorth  = posCenter - offset.zy;
	float2 posEast   = posCenter + offset.xz;

	float3 vertCenter = float3(posCenter - 0.5, 1) * ReShade::GetLinearizedDepth(posCenter);
	float3 vertNorth  = float3(posNorth - 0.5,  1) * ReShade::GetLinearizedDepth(posNorth);
	float3 vertEast   = float3(posEast - 0.5,   1) * ReShade::GetLinearizedDepth(posEast);

	return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;
}

//////noise function//////
//from "https://www.shadertoy.com/view/lldBRn" - noise functions
float noise2d(float2 co)
{
  return frac(sin(dot(co.xy ,float2(1.0,73))) * 43758.5453);
}

float3 noise3dts(float2 co, int s, bool t)
{
	co += sin(Timer/64)*t;
	co += frac(s/3.1415926535);
	return float3( noise2d(co), noise2d(co+0.6432168421), noise2d(co+0.19216811));
}

//////median filter functions/////
//from cMedian

float4 Max3(float4 a, float4 b, float4 c)
{
    return max(max(a, b), c);
}

float4 Min3(float4 a, float4 b, float4 c)
{
    return min(min(a, b), c);
}

float4 Med3(float4 a, float4 b, float4 c)
{
    return clamp(a, min(b, c), max(b, c));
}

float4 Med9(float4 x0, float4 x1, float4 x2,
            float4 x3, float4 x4, float4 x5,
            float4 x6, float4 x7, float4 x8)
{
    float4 A = Max3(Min3(x0, x1, x2), Min3(x3, x4, x5), Min3(x6, x7, x8));
    float4 B = Min3(Max3(x0, x1, x2), Max3(x3, x4, x5), Max3(x6, x7, x8));
    float4 C = Med3(Med3(x0, x1, x2), Med3(x3, x4, x5), Med3(x6, x7, x8));
    return Med3(A, B, C);
}

void MedianOffsets(in float2 TexCoord, in float2 PixelSize, out float4 SampleOffsets[3])
{
    // Sample locations:
    // [0].xy [1].xy [2].xy
    // [0].xz [1].xz [2].xz
    // [0].xw [1].xw [2].xw
    SampleOffsets[0] = TexCoord.xyyy + (float4(-1.0, 1.0, 0.0, -1.0) * PixelSize.xyyy);
    SampleOffsets[1] = TexCoord.xyyy + (float4( 0.0, 1.0, 0.0, -1.0) * PixelSize.xyyy);
    SampleOffsets[2] = TexCoord.xyyy + (float4( 1.0, 1.0, 0.0, -1.0) * PixelSize.xyyy);
}

///////////////Functions///////////////////
///////////////Vertex Shader///////////////

//////for median pass//////
//from cMedian
void MedianVS(in uint ID : SV_VertexID, out float4 Position : SV_Position, out float4 Offsets[3] : TEXCOORD0)
{
    float2 TexCoord0;
    PostProcessVS(ID, Position, TexCoord0);
    MedianOffsets(TexCoord0, 1.0 / (float2(BUFFER_WIDTH, BUFFER_HEIGHT)), Offsets);
}

///////////////Vertex Shader///////////////
///////////////Pixel Shader////////////////

//saves a copy of backbuffer before adding grain and further effects
float3 ogcolor( float4 Position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float3 color   = tex2D(sTexColor, texcoord).rgb;
	
	if(infinitebounce == 1)
	{
		float3 pastSSR = tex2D(sTSTex1, texcoord).rgb;
			   //pastSSR   = pastSSR / ( 1 - pastSSR); //tonemap
		float3 X = color - (pastSSR -0.5);
			   color = X - pastSSR;
		return color + pastSSR; //OGColorTex
	}
	else
	{
		return color;
	}
}

void TA_Color(in float4 Position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 OutputColor : SV_Target0)
{
	//OutputColor = float4(tex2D(sOGColorTex, texcoord).rgb, BlendFactor);
	OutputColor = float4( GetNormal( texcoord ).xyz, BlendFactor);
}

float3 FrameDiff( float4 Position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float3 TA = tex2D(sTAColorTex, texcoord).rgb;
	
	//float3 Current = tex2D(sOGColorTex, texcoord).rgb;
	float3 Current = GetNormal( texcoord ).xyz;
	float3 History = (TA*2) - Current;
	
	return abs(Current - History); //FrameDiffTex
} 	

//produces a fake roughness map
float3 roughness( float4 Position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float2 p = pix;
	
	if(!GI)
	{
		//roughness estimation based on color variation
		//to do: looped high iteration sampling for wider filter
		float3 center = tex2D( sOGColorTex, texcoord).rgb;
		float3 r = tex2D( sOGColorTex, texcoord + float2(  roughfac1*p.x, 0)).rgb;
		float3 l = tex2D( sOGColorTex, texcoord + float2( -roughfac1*p.x, 0)).rgb;
		float3 d = tex2D( sOGColorTex, texcoord + float2( 0, -roughfac1*p.y)).rgb;
		float3 u = tex2D( sOGColorTex, texcoord + float2( 0,  roughfac1*p.y)).rgb;
		
		//using depth as bilateral blur's determinator
		float depth = ReShade::GetLinearizedDepth(texcoord);
		float ld = ReShade::GetLinearizedDepth(texcoord + float2(  roughfac1*p.x, 0));
		float rd = ReShade::GetLinearizedDepth(texcoord + float2( -roughfac1*p.x, 0));
		float dd = ReShade::GetLinearizedDepth(texcoord + float2( 0, -roughfac1*p.y));
		float ud = ReShade::GetLinearizedDepth(texcoord + float2( 0,  roughfac1*p.y));
		
		//a formula based on trial and error!
		l = clamp(abs(center - l), 0, 0.25);
		r = clamp(abs(center - r), 0, 0.25);
		u = clamp(abs(center - u), 0, 0.25);
		d = clamp(abs(center - d), 0, 0.25);
		
		float a = 0.02;
		
		float3 sharp = 0;
		if ( abs(ld - depth) <= a ) { sharp += l; }
		if ( abs(rd - depth) <= a ) { sharp += r; }
		if ( abs(ud - depth) <= a ) { sharp += u; }
		if ( abs(dd - depth) <= a ) { sharp += d; }
		//sharp = sharp + l+r+u+d;
		
		sharp = pow( sharp, roughfac2);
		sharp = clamp(sharp, fromrough.x, fromrough.y);
		sharp = (sharp - fromrough.x) / ( 1 - fromrough.x );
		sharp = sharp / fromrough.y;
		sharp = clamp(sharp, torough.x, torough.y);
		//sharp = normalize(sharp);
	
		
		return sharp/2;
	} 
	return 0;//RoughnessTex
}
	
//produces a noise texture
float3 noise( float4 Position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float3 color = tex2D(sOGColorTex, texcoord).rgb;
	if(!GI)
	{
		float t = Timer;
		float2 uv = texcoord;
		uv *= sin(t/30)+0.01;
	
		float3 noise = noise2d(noise2d(noise2d(uv)));
	
	    float roughness;
	    roughness = tex2D( sRoughnessTex, texcoord).r;
	    return lerp(color, noise, roughness); //NoiseTex
	} else
	{return color;}
}

//blends the noise into the image
void noiseblend(float4 Position : SV_Position, float2 texcoord : TEXCOORD, out float3 noisy : SV_Target0) //noisy image
{
	float3 color = tex2D(sOGColorTex, texcoord).rgb;
	if(!GI)
	{
		float3 noise1 = tex2D(sNoiseTex, texcoord).rgb;	
		noisy = (color + noise1) / 2; //TexColor
	} else
	{noisy = color;}
}

float3 noiseremove(float4 Position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 color = tex2D(sTexColor, texcoord).rgb;
	if(!GI)
	{
		float3 noise = tex2D(sNoiseTex, texcoord).rgb;
		return (color*2)-noise; //TexColor
	} else 
	{return color;}
}

//extracts the SSR itself before it's getting blended to the backbuffer
float3 SSRdebug(float4 Position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 color = tex2D(sTexColor, texcoord).rgb;
	float3 ogcolor = tex2D(sOGColorTex, texcoord).rgb;
	
	float3 ssr = (1 + ogcolor - color)/2;
	
	//Reinhard inverse tonemapping. Will be tonemapped again in the final (Blend) pass.
	//ssr = ssr / (1+ssr);
	
	return ssr; //NoiseTex
}




////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////DENOISER STARTS FROM HERE/////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
//Heavily inspired by ReBlur from NRD ( Nvidia Raytracing Denoiser ) library.
//Check "https://link.springer.com/chapter/10.1007%2F978-1-4842-7185-8_49" for more information.
//Check "https://github.com/NVIDIAGameWorks/NRDSample" for the original ReBlur code.

float4 MedianPS(in float4 Position : SV_Position, in float4 Offsets[3] : TEXCOORD0) : SV_Target0
{
	// "PRE-BLUR" is the first pass of the denoiser
	// Median filter from "cMedian" used to spread the energy of outliers to a 3*3 block
	// while maintaining the details
    float4 OutputColor = 0.0;
    // Sample locations:
    // [0].xy [1].xy [2].xy
    // [0].xz [1].xz [2].xz
    // [0].xw [1].xw [2].xw
    if(GI == 0 && MedianDebug == 1){

    float4 Sample[9];
    
    Sample[0] = tex2D(sNoiseTex, Offsets[0].xy);
    Sample[1] = tex2D(sNoiseTex, Offsets[1].xy);
    Sample[2] = tex2D(sNoiseTex, Offsets[2].xy);
    Sample[3] = tex2D(sNoiseTex, Offsets[0].xz);
    Sample[4] = tex2D(sNoiseTex, Offsets[1].xz);
    Sample[5] = tex2D(sNoiseTex, Offsets[2].xz);
    Sample[6] = tex2D(sNoiseTex, Offsets[0].xw);
    Sample[7] = tex2D(sNoiseTex, Offsets[1].xw);
    Sample[8] = tex2D(sNoiseTex, Offsets[2].xw);
    
    OutputColor = Med9(Sample[0], Sample[1], Sample[2], //TASSRTex
                 	  Sample[3], Sample[4], Sample[5],
         	          Sample[6], Sample[7], Sample[8]);
    } else
    {OutputColor = tex2D(sNoiseTex, Offsets[1].xz);}
    return OutputColor;
}

float4 TA( float4 Position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float2 velocity = 0;
#if exists("MotionVectors.fxh")
	velocity = sampleMotion(texcoord).xy;
#endif
	float roughness = tex2D(sRoughnessTex, texcoord).r;
	
	float4 current = tex2D( sTASSRTex, texcoord ).rgba;
	float4 history = tex2D( sTSTex1, texcoord + velocity).rgba;
	
	float3 diff = abs(current.rgb - history.rgb);
	float diffmax = max(max(diff.r, diff.g), diff.b) * color_threshold1 * (1-roughness);	
	
	float3 PastNorm = tex2D( sNormalTex, texcoord + velocity ).rgb;
	float3 CurrNorm = GetNormal( texcoord );
	
	float3 ndiff = abs(CurrNorm.xyz - PastNorm.xyz);
	float ndiffmax = max(max(ndiff.r, ndiff.g), ndiff.b) * normal_threshold1;
	
	ndiffmax += diffmax;
	//ndiffmax *= 10;
	
	float coeff = saturate( 1 / ( history.a + 1 ) + ndiffmax);

	return float4(lerp( history.rgb, current.rgb, coeff), min(MaxAccumulatedFrameNum, 1/(coeff))); //TATex2
} //TATex2

float4 Blur(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	// "BLUR" is the 3rd pass of the denosier
	float2 p = pix; //pixel size in x and y axis
	float2 Alpha = float2(tex2D(sTATex2, texcoord).a, 1);
	float NormalG = dot(0.333, GetNormal(texcoord));
	
	float alphaR;// = clamp( 64 - Alpha.r, 0, 64);
	alphaR = min(3, max(0, 3-Alpha.r));
	float Roughness = 1;
	if(!GI) Roughness = tex2D( sRoughnessTex, texcoord).r;
	
	// "HISTORY FIX" pass is combined with the "BLUR" pass for performance reasons
	float4 Color = float4( tex2Dlod( sTATex2, float4(texcoord, 0, alphaR)).rgb, 1); //The output of the Temporal Accumulator
	
	//noise2d result is not random enough so I had to do it 3 times!
	int iteration = BLUR_QUALITY;
	for (int i = 1; i <= iteration; i++)
	{
		float2 seed = noise3dts(texcoord.xy, i, 0).rg;
		float distance = (seed.x + i) / iteration;
		float ang = seed.y * 3.14159265 * 2;
		
		float2 offset; sincos(ang, offset.y, offset.x); 
		offset *= sqrt(distance);
		offset *= p.xy * radius * Roughness;
		//Thanks Pascal Gilcher/Marty mcFly
		
		//jittered SSR Color
		float4 JCol = float4( tex2Dlod( sTATex2, float4(texcoord + offset, 0, alphaR)).rgb, 1);	
		float2 JAlpha = float2(tex2Dlod(sTATex2, float4(texcoord + offset, 0, alphaR)).a, 1);
		//jittered original Color. To be used as a determinator

		float JNormalG = dot(0.333, GetNormal(texcoord + offset ).xyz);
		float Ndiff = abs(JNormalG - NormalG);
		float Cdiff = abs(dot(0.333, JCol) - dot(0.333, Color));
		if(Ndiff < normal_threshold && Cdiff < color_threshold)
		//if(Ndiff < normal_threshold)
		{
			Color += JCol;
			//Alpha += JAlpha;
		}
	}
	
	float3 Blurred = Color.rgb/Color.a;
	return float4( Blurred.rgb, Alpha.r/Alpha.g ); //NoiseTex
}

void PostBlur(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float4 FinalColor : SV_Target0, out float3 Normal : SV_Target1)
{
	float2 p = pix;
	
	float4 Color = float4( tex2Dlod(sTATex2, float4(texcoord, 0, 0)).rgb, 1); //The output of the Temporal Accumulator
	float4 Color2 = tex2D(sNoiseTex, texcoord).rgba; //Blur pass output
	float2 Alpha = float2(Color2.a, 1);
	Color2.a = 1;
	
	float NormalG = dot(0.333, GetNormal(texcoord));
	float Radius = dot(0.333, 8 * radius * abs(Color2-Color));
	
	int iteration = BLUR_QUALITY;
	for (int i = 1; i <= iteration; i++)
	{
		float2 seed = noise3dts(texcoord.xy, i, 0).rg;
		float distance = (seed.x + i) / iteration;
		float ang = seed.y * 3.14159265 * 2;

		float2 offset; sincos(ang, offset.y, offset.x); 
		offset *= sqrt(distance);
		offset *= p.xy * Radius;
		
		float4 JCol   = float4( tex2D( sNoiseTex, texcoord + offset ).rgb, 1);
		float2 JAlpha = float2( tex2D( sNoiseTex, texcoord + offset ).a  , 1);	

		float JNormalG = dot(0.333, GetNormal(texcoord + offset ).xyz);
		float Ndiff = abs(JNormalG - NormalG);
		float Cdiff = abs(dot(0.333, JCol) - dot(0.333, Color));
		if(Ndiff < normal_threshold && Cdiff < color_threshold)
		{
			Color2 += JCol;
			//Alpha += JAlpha;
		}
	}
	
	float3 Blurred = Color2.rgb/Color2.a;	
	FinalColor = float4( Blurred.rgb, Alpha.r/Alpha.g ); //TSTex1
	Normal = GetNormal(texcoord); //NormalTex
}	

//float4 TemporalStabilizer(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
//{// Copy backbuffer to a that continuously blends with its previous result
//	float2 velocity = sampleMotion(texcoord).xy;
//	float3 FrameDiff =  abs(tex2D(sFrameDiffTex, texcoord).rgb);
//	
//	float FD_Gray = max(max(FrameDiff.r, FrameDiff.g), FrameDiff.b);
//	FD_Gray = saturate(1 - FD_Gray * Deghost * 50);
//	//FD_Gray = (FD_Gray > 1 - Deghost) ? 0 : 1;
//	
//    return float4(tex2D(sTSTex1, texcoord).rgb, saturate(BlendFactor*(FD_Gray))); //TSTex
//}




////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////DENOISER ENDS HERE/////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////




//Blends the denoised SSR with the image again
float3 Blend(float4 Position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 color = tex2D(sTSTex1, texcoord).rgb; //reflection only
	//color = color / ( 1 - color); //tonemapped. inverse tonemapping was done in SSRDebug pass
	float3 ogcolor = tex2D(sOGColorTex, texcoord).rgb;
	float3 col = ogcolor-((color)-0.5);
	
	color = col - ogcolor;
	
	float Roughness = tex2D( sRoughnessTex, texcoord).r;
	
	//removes grayness of the grain mixed to reflection
	color = lerp( dot( 0.333, color), color, Roughness+1);
	
	if ( debug == 0 ) //none
	{
		col = ogcolor + color * Exposure;
	}
	else if ( debug == 3 ) //reflection only
	{	
		col = abs(color)*16;
	}
	else if ( debug == 1 ) //roughness map
	{
		col = Roughness;
	}
	return col;
}

///////////////Pixel Shader////////////////
///////////////Techniques//////////////////

technique Scatter1
< ui_label = "Scatter Top";
  ui_tooltip = "                             Scatter FX                             \n"
  			 "                          ||By Ehsan2077||                          \n"
			   "||This shader is intended to be used with qUINT_SSR and or DH_RTGI||\n"
			   "|It adds roughness to SSR and an advanced denoiser to both         |\n"
			   "|Use the shader like this:                                         |\n"
			   "|1- SSR Companion Top                                              |\n"
			   "|2- SSR and or DH_RTGI                                             |\n"
			   "|4- SSR Companion Buttom                                           |\n"
			   "|(optional-Extremely recommended) Put DRME(MotionVectors.fx) on top|";>
{
	pass OGColor
	{
		VertexShader = PostProcessVS;
		PixelShader = ogcolor;
		RenderTarget = OGColorTex;
	}
    //pass FrameDiff
    //{
    //	VertexShader = PostProcessVS;
    //	PixelShader = FrameDiff;
    //	RenderTarget = FrameDiffTex;
    //}
    pass TA_Color
    {
        VertexShader = PostProcessVS;
        PixelShader = TA_Color;
        RenderTarget0 = TAColorTex;
    }
    pass Roughness
    {
    	VertexShader = PostProcessVS;
    	PixelShader = roughness;
    	RenderTarget = RoughnessTex;
    }
	pass Noise
	{
		VertexShader = PostProcessVS;
		PixelShader = noise;
		RenderTarget = NoiseTex;
	}
	pass NosieBlend
	{
		VertexShader = PostProcessVS;
		PixelShader = noiseblend;
		RenderTarget1 = NoiseTex;
	}
}

technique Scatter
< ui_label = "Scatter Buttom";
  ui_tooltip = "                             Scatter FX                             \n"
  			 "                          ||By Ehsan2077||                          \n"
			   "||This shader is intended to be used with qUINT_SSR and or DH_RTGI||\n"
			   "|It adds roughness to SSR and an advanced denoiser to both         |\n"
			   "|Use the shader like this:                                         |\n"
			   "|1- SSR Companion Top                                              |\n"
			   "|2- SSR and or DH_RTGI                                             |\n"
			   "|4- SSR Companion Buttom                                           |\n"
			   "|(optional-Extremely recommended) Put DRME(MotionVectors.fx) on top|";>
{
	pass NoiseRemove
	{
		VertexShader = PostProcessVS;
		PixelShader = noiseremove;
	}
	pass SSRDebug
	{
		VertexShader = PostProcessVS;
		PixelShader = SSRdebug;
		RenderTarget = NoiseTex;
	}
	//Denoiser Passes
	pass PreBlur
    {
        VertexShader = MedianVS;
        PixelShader = MedianPS;
        RenderTarget = TASSRTex;
    }
    /*pass PreBlur
    {
    	VertexShader = PostProcessVS;
    	PixelShader = PreBlur;
    	RenderTarget = TASSRTex;
    }*/
    pass TemporalAccum
	{
		VertexShader = PostProcessVS;
		PixelShader = TA;
		RenderTarget = TATex2;
	}
	pass Blur
	{
		VertexShader = PostProcessVS;
		PixelShader = Blur;
		RenderTarget = NoiseTex;
	}
	pass PostBlur
	{
		VertexShader = PostProcessVS;
		PixelShader = PostBlur;
		RenderTarget0 = TSTex1;
		RenderTarget1 = NormalTex;
	}
	//pass TemporalStab
    //{
    //    VertexShader = PostProcessVS;
    //    PixelShader = TemporalStabilizer;
    //    RenderTarget0 = TSTex;
    //    BlendEnable = TRUE;
    //    BlendOp = ADD;
    //    SrcBlend = INVSRCALPHA;
    //    DestBlend = SRCALPHA;
    //}
    //Denoiser Passes end
    pass Blend
    {
    	VertexShader = PostProcessVS;
        PixelShader = Blend;
	}
}

///////////////Techniques//////////////////
