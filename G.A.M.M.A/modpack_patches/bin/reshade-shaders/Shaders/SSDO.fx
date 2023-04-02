// ++++++++++++++++++++++++++++++++++++++++++++++++++++++
// *** PPFX SSDO 2.0 for ReShade
// *** SHADER AUTHOR: Pascal Matthäus ( Euda )
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++

//+++++++++++++++++++++++++++++
// DEV_NOTES
//+++++++++++++++++++++++++++++
// Updated for compatibility with ReShade 4 and isolated by Marot Satil.
// Reshade.fxh Preprocessor Definition Support added by JJXB
#include "ReShade.fxh"
//+++++++++++++++++++++++++++++
// CUSTOM PARAMETERS
//+++++++++++++++++++++++++++++

// ** SSDO **

#ifndef pSSDOSamplePrecision
#define		pSSDOSamplePrecision		RGBA16F // SSDO Sample Precision - The texture format of the source texture used to calculate the effect. RGBA8 is generally too low, RGBA16F should be the sweet-spot. RGBA32F is overkill and heavily kills your FPS.
#endif

#ifndef pSSDOLOD
#define		pSSDOLOD					1.0		// SSDO LOD - A scale factor for the resolution which the effect is calculated in - 1.0: Full Resolution, 0.5: Half Resolution, 0.25: Quarter, etc.
#endif

#ifndef pSSDOFilterScale
#define		pSSDOFilterScale			1.0		// SSDO Filter Scale Factor - Resolution control for the filter where noise the technique produces gets removed. Performance-affective. 0.5 means half resolution, 0.25 = quarter res,  1 = full-res. etc. Values above 1.0 yield a downsampled blur which doesn't make sense and is not recommended. | 0.1 - 4.0
#endif

#ifndef qSSDOFilterPrecision
#define		qSSDOFilterPrecision		RGBA16	// SSDO Filter Precision - The texture format used when filtering out the SSDO's noise. Use this to prevent banding artifacts that you may see in combination with very high ssdoIntensity values. RGBA16F, RGBA32F or, standard, RGBA8. Strongly suggest the latter to keep high framerates.
#endif

uniform float pSSDOIntensity <
    ui_label = "SSDO Intensity";
    ui_tooltip = "The intensity curve applied to the effect. High values may produce banding when used along with RGBA8 FilterPrecision.\nAs increasing the precision to RGBA16F will heavily affect performance, rather combine Intensity and Amount if you want high visibility.";
    ui_type = "slider";
    ui_min = 0.001;
    ui_max = 20.0;
    ui_step = 0.001;
> = 1.5;

uniform float pSSDOAmount <
    ui_label = "SSDO Amount";
    ui_tooltip = "A multiplier applied to occlusion/lighting factors when they are calculated. High values increase the effect's visibilty but may expose artifacts and noise.";
    ui_type = "slider";
    ui_min = 0.01;
    ui_max = 10.0;
    ui_step = 0.01;
> = 1.5;

uniform float pSSDOBounceMultiplier <
    ui_label = "SSDO Indirect Bounce Color Multiplier";
    ui_tooltip = "SSDO includes an indirect bounce of light which means that colors of objects may interact with each other. This value controls the effects' visibility.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.8;

uniform float pSSDOBounceSaturation <
    ui_label = "SSDO Indirect Bounce Color Saturation";
    ui_tooltip = "High values may look strange.";
    ui_type = "slider";
    ui_min = 0.1;
    ui_max = 2.0;
    ui_step = 0.01;
> = 1.0;

uniform int pSSDOSampleAmount <
    ui_label = "SSDO Sample Count";
    ui_tooltip = "The amount of samples taken to accumulate SSDO. Affects quality, reduces noise and almost linearly affects performance. Current high-end systems should max out at ~32 samples at Full HD to reach desirable framerates.";
    ui_type = "slider";
    ui_min = 1;
    ui_max = 256;
    ui_step = 1;
> = 10;

uniform float pSSDOSampleRange <
    ui_label = "SSDO Sample Range";
    ui_tooltip = "Maximum distance for occluders to occlude geometry. High values reduce cache coherence, lead to cache misses and thus decrease performance so keep this below ~150.\nYou may prevent this performance drop by increasing Source LOD.";
    ui_type = "slider";
    ui_min = 4.0;
    ui_max = 1000.0;
    ui_step = 0.1;
> = 70.0;

uniform int pSSDOSourceLOD <
    ui_label = "SSDO Source LOD";
    ui_tooltip = "The Mipmap-level of the source texture used to calculate the occlusion/indirect light. 0 = full resolution, 1 = half-axis resolution, 2 = quarter-axis resolution etc.\nCombined with high SampleRange-values, this may improve performance with a slight loss of quality.";
    ui_type = "slider";
    ui_min = 0;
    ui_max = 3;
    ui_step = 1;
> = 2;

uniform int pSSDOBounceLOD <
    ui_label = "SSDO Indirect Bounce LOD";
    ui_tooltip = "The Mipmap-level of the color texture used to calculate the light bounces. 0 = full resolution, 1 = half-axis resolution, 2 = quarter-axis resolution etc.\nCombined with high SampleRange-values, this may improve performance with a slight loss of quality.";
    ui_type = "slider";
    ui_min = 0;
    ui_max = 3;
    ui_step = 1;
> = 3;

uniform float pSSDOFilterRadius <
    ui_label = "Filter Radius";
    ui_tooltip = "The blur radius that is used to filter out the noise the technique produces. Don't push this too high, everything between 8 - 24 is recommended (depending from SampleAmount, SampleRange, Intensity and Amount).";
    ui_type = "slider";
    ui_min = 2.0;
    ui_max = 100.0;
    ui_step = 1.0;
> = 8.0;

uniform float pSSDOAngleThreshold <
    ui_label = "SSDO Angle Threshold";
    ui_tooltip = "Defines the minimum angle for points to contribute when occlusion is computed. This is similar to the depth-bias parameter in other Ambient Occlusion Shaders.";
    ui_type = "slider";
    ui_min = 0.01;
    ui_max = 0.5;
    ui_step = 0.01;
> = 0.125;

uniform float pSSDOFadeStart <
    ui_label = "SSDO Draw Distance: Fade Start";
    ui_tooltip = "The distance from which the effect starts decreasing. Use this slider combined with the Fade-End slider to create a smooth fade-out of the effect.";
    ui_type = "slider";
    ui_min = 0.1;
    ui_max = 0.95;
    ui_step = 0.01;
> = 0.9;

uniform float pSSDOFadeEnd <
    ui_label = "SSDO Draw Distance: Fade End";
    ui_tooltip = "This value defines the distance from which the effect will be cut off. Use this slider combined with the Fade-Start slider to create a smooth fade-out of the effect.";
    ui_type = "slider";
    ui_min = 0.15;
    ui_max = 1.0;
    ui_step = 0.01;
> = 0.95;

uniform int pSSDODebugMode <
    ui_label = "SSDO Debug View";
    ui_type = "combo";
    ui_items = "Debug-mode off\0Outputs the filtered SSDO component\0Shows you the raw, noisy SSDO right after scattering the occlusion/lighting\0";
> = 0;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   TEXTURES   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// *** ESSENTIALS ***
texture texColorLOD { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 4; };
texture texDepth : DEPTH;

// *** FX RTs ***
texture texViewSpace
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = pSSDOSamplePrecision;
	MipLevels = 4;
};
texture texSSDOA
{
	Width = BUFFER_WIDTH*pSSDOLOD;
	Height = BUFFER_HEIGHT*pSSDOLOD;
	Format = qSSDOFilterPrecision;
};
texture texSSDOB
{
	Width = BUFFER_WIDTH*pSSDOFilterScale;
	Height = BUFFER_HEIGHT*pSSDOFilterScale;
	Format = qSSDOFilterPrecision;
};
texture texSSDOC
{
	Width = BUFFER_WIDTH*pSSDOFilterScale;
	Height = BUFFER_HEIGHT*pSSDOFilterScale;
	Format = qSSDOFilterPrecision;
};

// *** EXTERNAL TEXTURES ***
texture texNoise < source = "ssdonoise.png"; >
{
	Width = 4;
	Height = 4;
	Format = R8;
	#define NOISE_SCREENSCALE float2((BUFFER_WIDTH*pSSDOLOD)/4.0,(BUFFER_HEIGHT*pSSDOLOD)/4.0)
};

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   SAMPLERS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// *** ESSENTIALS ***
sampler SamplerColorLOD
{
	Texture = texColorLOD;
	SRGBTexture = true;
};

sampler2D SamplerDepth
{
	Texture = texDepth;
};

// *** FX RTs ***
sampler SamplerViewSpace
{
	Texture = texViewSpace;
};
sampler SamplerSSDOA
{
	Texture = texSSDOA;
};
sampler SamplerSSDOB
{
	Texture = texSSDOB;
};
sampler SamplerSSDOC
{
	Texture = texSSDOC;
};

// *** EXTERNAL TEXTURES ***
sampler SamplerNoise
{
	Texture = texNoise;
	MipFilter = POINT;
	MinFilter = POINT;
	MagFilter = POINT;
};

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   VARIABLES   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

static const float2 pxSize = float2(BUFFER_RCP_WIDTH,BUFFER_RCP_HEIGHT);
static const float3 lumaCoeff = float3(0.2126f,0.7152f,0.0722f);
#define ZNEAR 0.1
#define ZFAR 30.0

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   STRUCTS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

struct VS_OUTPUT_POST
{
	float4 vpos : SV_Position;
	float2 txcoord : TEXCOORD0;
};

struct VS_INPUT_POST
{
	uint id : SV_VertexID;
};

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   HELPERS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float linearDepth(float2 txCoords)
{
	return ReShade::GetLinearizedDepth(txCoords);
}

float4 viewSpace(float2 txCoords)
{
	float2 offsetS = float2(0.0,1.0)*pxSize;
	float2 offsetE = float2(1.0,0.0)*pxSize;
	float depth = linearDepth(txCoords);
	float depthS = linearDepth(txCoords+offsetS);
	float depthE = linearDepth(txCoords+offsetE);
	
	float3 vsNormal = cross(float3((-offsetS)*depth,depth-depthS),float3(offsetE*depth,depth-depthE));
	return float4(normalize(vsNormal),depth);
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   EFFECTS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// *** SSDO ***
	#define SSDO_CONTRIB_RANGE (pSSDOSampleRange*(pxSize.y/pSSDOLOD))
	#define SSDO_BLUR_DEPTH_DISCONTINUITY_THRESH_MULTIPLIER 0.1
	
	// SSDO - Scatter Illumination
	float4 FX_SSDOScatter( float2 txCoords )
	{
		float	sourceAxisDiv = pow(2.0,pSSDOSourceLOD);
		float2	texelSize = pxSize.xy*pow(2.0,pSSDOSourceLOD).xx;
		float4	vsOrig = tex2D(SamplerViewSpace,txCoords);
		float3	ssdo = 0.0;
		
		float	randomDir = tex2D(SamplerNoise,frac(txCoords*NOISE_SCREENSCALE)).x;
		const float2	stepSize = (pSSDOSampleRange/(pSSDOSampleAmount*sourceAxisDiv))*texelSize;

		for (float offs=1.0;offs<=pSSDOSampleAmount;offs++)
		{
			float2 fetchDir = normalize(frac(float2(randomDir*811.139795*offs,randomDir*297.719157*offs))*2.0-1.0);
			fetchDir *= sign(dot(normalize(float3(fetchDir.x,-fetchDir.y,1.0)),vsOrig.xyz)); // flip directions
			float2 fetchCoords = txCoords+fetchDir*stepSize*offs*max(0.75,offs/pSSDOSampleAmount);
			float4 vsFetch = tex2Dlod(SamplerViewSpace,float4(fetchCoords,0,pSSDOSourceLOD));
			
			float3 albedoFetch = tex2Dlod(SamplerColorLOD,float4(fetchCoords,0,pSSDOBounceLOD)).xyz;
			albedoFetch = pow(albedoFetch,pSSDOBounceSaturation);
			albedoFetch = normalize(albedoFetch);
			albedoFetch *= pSSDOBounceMultiplier;
			albedoFetch = 1.0-albedoFetch;
			
			float3 dirVec = float3(fetchCoords.x-txCoords.x,txCoords.y-fetchCoords.y,vsOrig.w-vsFetch.w);
			dirVec.xy *= vsOrig.w;
			float3 dirVecN = normalize(dirVec);
			float visibility = step(pSSDOAngleThreshold,dot(dirVecN,vsOrig.xyz)); // visibility check w/ angle threshold
			visibility *= sign(max(0.0,abs(length(vsOrig.xyz-vsFetch.xyz))-0.01)); // normal bias
			float distFade = max(0.0,SSDO_CONTRIB_RANGE-length(dirVec))/SSDO_CONTRIB_RANGE; // attenuation
			ssdo += albedoFetch * visibility * distFade * distFade * pSSDOAmount;
		}
		ssdo /= pSSDOSampleAmount;
		
		return float4(saturate(1.0-ssdo*smoothstep(pSSDOFadeEnd,pSSDOFadeStart,vsOrig.w)),vsOrig.w);
	}

	// Depth-Bilateral Gaussian Blur - Horizontal
	float4 FX_BlurBilatH( float2 txCoords, float radius )
	{
		float	texelSize = pxSize.x/pSSDOFilterScale;
		float4	pxInput = tex2D(SamplerSSDOB,txCoords);
		pxInput.xyz *= 0.5;
		float	sampleSum = 0.5;
		
		[loop]
		for (float hOffs=1.5; hOffs<radius; hOffs+=2.0)
		{
			float weight = 1.0;
			float2 fetchCoords = txCoords;
			fetchCoords.x += texelSize * hOffs;
			float4 fetch = tex2Dlod(SamplerSSDOB, float4(fetchCoords, 0.0, 0.0));
			float contribFact = max(0.0,sign(SSDO_CONTRIB_RANGE*SSDO_BLUR_DEPTH_DISCONTINUITY_THRESH_MULTIPLIER-abs(pxInput.w-fetch.w))) * weight;
			pxInput.xyz+=fetch.xyz * contribFact;
			sampleSum += contribFact;
			fetchCoords = txCoords;
			fetchCoords.x -= texelSize * hOffs;
			fetch = tex2Dlod(SamplerSSDOB, float4(fetchCoords, 0.0, 0.0));
			contribFact = max(0.0,sign(SSDO_CONTRIB_RANGE*SSDO_BLUR_DEPTH_DISCONTINUITY_THRESH_MULTIPLIER-abs(pxInput.w-fetch.w))) * weight;
			pxInput.xyz+=fetch.xyz * contribFact;
			sampleSum += contribFact;
		}
		pxInput.xyz /= sampleSum;
		
		return pxInput;
	}
	
	// Depth-Bilateral Gaussian Blur - Vertical
	float3 FX_BlurBilatV( float2 txCoords, float radius )
	{
		float	texelSize = pxSize.y/pSSDOFilterScale;
		float4	pxInput = tex2D(SamplerSSDOC,txCoords);
		pxInput.xyz *= 0.5;
		float	sampleSum = 0.5;
		
		[loop]
		for (float vOffs=1.5; vOffs<radius; vOffs+=2.0)
		{
			float weight = 1.0;
			float2 fetchCoords = txCoords;
			fetchCoords.y += texelSize * vOffs;
			float4 fetch = tex2Dlod(SamplerSSDOC, float4(fetchCoords, 0.0, 0.0));
			float contribFact = max(0.0,sign(SSDO_CONTRIB_RANGE*SSDO_BLUR_DEPTH_DISCONTINUITY_THRESH_MULTIPLIER-abs(pxInput.w-fetch.w))) * weight;
			pxInput.xyz+=fetch.xyz * contribFact;
			sampleSum += contribFact;
			fetchCoords = txCoords;
			fetchCoords.y -= texelSize * vOffs;
			fetch = tex2Dlod(SamplerSSDOC, float4(fetchCoords, 0.0, 0.0));
			contribFact = max(0.0,sign(SSDO_CONTRIB_RANGE*SSDO_BLUR_DEPTH_DISCONTINUITY_THRESH_MULTIPLIER-abs(pxInput.w-fetch.w))) * weight;
			pxInput.xyz+=fetch.xyz * contribFact;
			sampleSum += contribFact;
		}
		pxInput /= sampleSum;
		
		return pxInput.xyz;
	}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   VERTEX-SHADERS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

VS_OUTPUT_POST VS_PostProcess(VS_INPUT_POST IN)
{
	VS_OUTPUT_POST OUT;
	OUT.txcoord.x = (IN.id == 2) ? 2.0 : 0.0;
	OUT.txcoord.y = (IN.id == 1) ? 2.0 : 0.0;
	OUT.vpos = float4(OUT.txcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	return OUT;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   PIXEL-SHADERS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// *** Shader Structure ***
float4 PS_SetOriginal(VS_OUTPUT_POST IN) : COLOR
{
    return tex2D(ReShade::BackBuffer,IN.txcoord.xy);
}

// *** SSDO ***
	float4 PS_SSDOViewSpace(VS_OUTPUT_POST IN) : COLOR
	{
		return viewSpace(IN.txcoord.xy);
	}

	float4 PS_SSDOScatter(VS_OUTPUT_POST IN) : COLOR
	{
		return FX_SSDOScatter(IN.txcoord.xy);
	}
	
	float4 PS_SSDOBlurScale(VS_OUTPUT_POST IN) : COLOR
	{
		return tex2D(SamplerSSDOA,IN.txcoord.xy);
	}

	float4 PS_SSDOBlurH(VS_OUTPUT_POST IN) : COLOR
	{
		return FX_BlurBilatH(IN.txcoord.xy,pSSDOFilterRadius/pSSDOFilterScale);
	}

	float4 PS_SSDOBlurV(VS_OUTPUT_POST IN) : COLOR
	{
		return float4(FX_BlurBilatV(IN.txcoord.xy,pSSDOFilterRadius/pSSDOFilterScale).xyz,1.0);
	}
	
	float4 PS_SSDOMix(VS_OUTPUT_POST IN) : COLOR
	{
		float3 ssdo = pow(tex2D(SamplerSSDOB,IN.txcoord.xy).xyz,pSSDOIntensity.xxx);
		
		if (pSSDODebugMode == 1)
			return float4(pow(ssdo,2.2),1.0);
		else if (pSSDODebugMode == 2)
			return float4(pow(tex2D(SamplerSSDOA,IN.txcoord.xy).xyz,2.2),1.0);
		else
      return float4(ssdo * tex2D(SamplerColorLOD,IN.txcoord.xy).xyz,1.0);
	}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   TECHNIQUES   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique PPFXSSDO < ui_label = "PPFX SSDO"; ui_tooltip = "Screen Space Directional Occlusion | Ambient Occlusion simulates diffuse shadows/self-shadowing of geometry.\nIndirect Lighting brightens objects that are exposed to a certain 'light source' you may specify in the parameters below.\nThis approach takes directional information into account and simulates indirect light bounces, approximating global illumination."; >
{
	pass setOriginal
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_SetOriginal;
		RenderTarget0 = texColorLOD;
		
	}
	
	pass ssdoViewSpace
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_SSDOViewSpace;
		RenderTarget0 = texViewSpace;
	}
		
	pass ssdoScatter
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_SSDOScatter;
		RenderTarget0 = texSSDOA;
	}
		
	pass ssdoBlurScale
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_SSDOBlurScale;
		RenderTarget0 = texSSDOB;
	}
		
	pass ssdoBlurH
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_SSDOBlurH;
		RenderTarget0 = texSSDOC;
	}
		
	pass ssdoBlurV
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_SSDOBlurV;
		RenderTarget0 = texSSDOB;
	}
		
	pass ssdoMix
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_SSDOMix;
		SRGBWriteEnable = true;
	}
}