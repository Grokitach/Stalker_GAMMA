#ifndef HDR10_H_
#define HDR10_H_

// TODO: contrast adjustment is weird for large values
// TODO: not sure if PQ application/normalization is correct, it's applied to channels, but technically should be applied to luminance (per channel normalized luminance)
// TODO: HDR LUT color grading, done in log space

/* --- General Resources --- */
// Calculators
// https://www.russellcottrell.com/photo/matrixCalculator.htm
// https://www.colour-science.org:8010/apps/rgb_colourspace_transformation_matrix

// Academic Resources
// https://onlinelibrary.wiley.com/doi/book/10.1002/9781118653128
// https://dl.acm.org/doi/book/10.5555/1386684
// https://www.cl.cam.ac.uk/teaching/1920/AdvGraphIP/07_HDR_and_tone_mapping.pdf
// https://www-old.cs.utah.edu/docs/techreports/2002/pdf/UUCS-02-001.pdf

// Specs
// Rec.709   :: https://www.itu.int/dms_pubrec/itu-r/rec/bt/R-REC-BT.709-6-201506-I!!PDF-E.pdf
// Rec.2020  :: https://www.itu.int/dms_pubrec/itu-r/rec/bt/R-REC-BT.2020-2-201510-I!!PDF-E.pdf
// DCI-P3    :: https://www.dcimovies.com/dci-specification
// ST2084 PQ :: https://www.itu.int/dms_pubrec/itu-r/rec/bt/R-REC-BT.2100-2-201807-I!!PDF-E.pdf

// Tonemapping
// http://filmicworlds.com/blog/filmic-tonemapping-with-piecewise-power-curves/
// http://filmicworlds.com/blog/filmic-tonemapping-operators/
// https://gpuopen.com/learn/vdr-follow-up-tonemapping-for-hdr-signals/
// https://bruop.github.io/tonemapping/
// https://64.github.io/tonemapping/

// Colorspaces
// https://en.wikipedia.org/wiki/CIE_1931_color_space
// https://www.colour-science.org/posts/the-importance-of-terminology-and-srgb-uncertainty/
// http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html

// Other
// HDR Analysis Shaders :: https://github.com/EndlesslyFlowering/ReShade_HDR_shaders/tree/master
// SpecialK HDR 		:: https://github.com/SpecialKO/SpecialK/tree/12b1dda5b1b952e0fb77a1e810b9734f3ee30f81/resource/shaders/HDR
// DirectXTK HDR 		:: https://github.com/Microsoft/DirectXTK/wiki/Using-HDR-rendering
// Xbox HDR 			:: https://github.com/microsoft/Xbox-GDK-Samples/blob/main/Kits/ATGTK/HDR/HDRCommon.hlsli#L199
// Rec.709 -> Rec.2020  :: https://www.itu.int/dms_pubrec/itu-r/rec/bt/R-REC-BT.2087-0-201510-I!!PDF-E.pdf

#define HDR10_NAN (0.0 / 0.0)
#define HDR10_INF (1.0 / 0.0)

/* --- Parameters --- */
uniform float4 hdr10_parameters1;
uniform float4 hdr10_parameters2;
uniform float4 hdr10_parameters3;
uniform float4 hdr10_parameters4;
uniform float4 hdr10_parameters5;
uniform float4 hdr10_parameters6;
uniform float4 hdr10_parameters7;
uniform float4 hdr10_parameters8;
uniform float4 hdr10_parameters9;
uniform float4 hdr10_parameters10;

#define HDR10_WHITEPOINT_NITS  (hdr10_parameters1.x)
#define HDR10_UI_NITS_SCALAR   (hdr10_parameters1.y)
#define HDR10_IS_ENABLED       (hdr10_parameters1.z != 0.0)
#define HDR10_IS_RENDERING_PDA (hdr10_parameters1.w != 0.0)

#define HDR10_COLORSPACE    (hdr10_parameters2.x)
#define HDR10_PDA_INTENSITY (hdr10_parameters2.y)
#define HDR10_TONEMAPPER    (hdr10_parameters2.z)
#define HDR10_TONEMAP_MODE  (hdr10_parameters2.w)

#define HDR10_EXPOSURE         	   (hdr10_parameters3.x)
#define HDR10_CONTRAST         	   (hdr10_parameters3.y)
#define HDR10_SATURATION       	   (hdr10_parameters3.z)
#define HDR10_CONTRAST_MIDDLE_GRAY (hdr10_parameters3.w)

#define HDR10_BLOOM_ON		  (hdr10_parameters4.x != 0.0)
#define HDR10_BLOOM_SCALE     (hdr10_parameters4.y)
#define HDR10_BLOOM_INTENSITY (hdr10_parameters4.z)
#define HDR10_SUN_INTENSITY   (hdr10_parameters4.w)

#define HDR10_SUN_DAWN_BEGIN (hdr10_parameters5.x)
#define HDR10_SUN_DAWN_END   (hdr10_parameters5.y)
#define HDR10_SUN_DUSK_BEGIN (hdr10_parameters5.z)
#define HDR10_SUN_DUSK_END   (hdr10_parameters5.w)

#define HDR10_BRIGHTNESS      (hdr10_parameters6.x)
#define HDR10_GAMMA_RCP       (hdr10_parameters6.y)
#define HDR10_FLARE_THRESHOLD (hdr10_parameters6.z)
#define HDR10_FLARE_POWER     (hdr10_parameters6.w)

#define HDR10_FLARE_GHOSTS 			(int(round(hdr10_parameters7.x)))
#define HDR10_FLARE_GHOST_DISPERSAL (hdr10_parameters7.y)
#define HDR10_FLARE_CENTER_FALLOFF  (hdr10_parameters7.z)
#define HDR10_FLARE_HALO_SCALE 		(hdr10_parameters7.w)

#define HDR10_FLARE_HALO_CA    (hdr10_parameters8.x)
#define HDR10_FLARE_GHOST_CA   (hdr10_parameters8.y)
#define HDR10_FLARE_BLUR_SCALE (hdr10_parameters8.z)
#define HDR10_UI_SATURATION    (hdr10_parameters8.w)

#define HDR10_FLARE_GHOST_INTENSITY (hdr10_parameters9.x)
#define HDR10_FLARE_HALO_INTENSITY  (hdr10_parameters9.y)
#define HDR10_SUN_INNER_RADIUS      (hdr10_parameters9.z)
#define HDR10_SUN_OUTER_RADIUS      (hdr10_parameters9.w)

#define HDR10_FLARE_LENS_COLOR (hdr10_parameters10.rgb)
#define HDR10_SUN_ON           (hdr10_parameters10.w)

/* --- Colorspace Options --- */

#define HDR10_USE_COLORSPACE_REC709  (HDR10_COLORSPACE == 0.0)
#define HDR10_USE_COLORSPACE_P3D65   (HDR10_COLORSPACE == 1.0)
#define HDR10_USE_COLORSPACE_REC2020 (HDR10_COLORSPACE == 2.0)

/* --- Tonemapper Options --- */

#define HDR10_USE_TONEMAPPER_ACES_NARKOWICZ (HDR10_TONEMAPPER == 1.0)
#define HDR10_USE_TONEMAPPER_ACES_HILL		(HDR10_TONEMAPPER == 2.0)
#define HDR10_USE_TONEMAPPER_AGX_NORMAL	    (HDR10_TONEMAPPER == 4.0)
#define HDR10_USE_TONEMAPPER_AGX_PUNCHY		(HDR10_TONEMAPPER == 8.0)
#define HDR10_USE_TONEMAPPER_UCHIMURA		(HDR10_TONEMAPPER == 16.0)
#define HDR10_USE_TONEMAPPER_STEVEM			(HDR10_TONEMAPPER == 32.0)
#define HDR10_USE_TONEMAPPER_UNCHARTED2     (HDR10_TONEMAPPER == 64.0)
#define HDR10_USE_TONEMAPPER_REINHARD_W2_0	(HDR10_TONEMAPPER == 128.0)
#define HDR10_USE_TONEMAPPER_REINHARD_W3_0  (HDR10_TONEMAPPER == 256.0)

/* --- Tonemapping Mode Options --- */

#define HDR10_USE_TONEMAP_MODE_LUMINANCE (HDR10_TONEMAP_MODE == 0.0)
#define HDR10_USE_TONEMAP_MODE_COLOR	 (HDR10_TONEMAP_MODE == 1.0)

/* --- Colorspace Transforms --- */

// see https://www.colour-science.org:8010/apps/rgb_colourspace_transformation_matrix?input-colourspace=ITU-R+BT.709&output-colourspace=P3-D65&chromatic-adaptation-transform=Bradford&formatter=str&decimals=8
static const float3x3 HDR10_CSTransform_Rec709_To_P3D65 = {
	{ 0.82246197,  0.17753803, -0.00000000},
 	{ 0.03319420,  0.96680580,  0.00000000},
 	{ 0.01708263,  0.07239744,  0.91051993},
};

// see: https://www.colour-science.org:8010/apps/rgb_colourspace_transformation_matrix?input-colourspace=ITU-R+BT.709&output-colourspace=ITU-R+BT.2020&chromatic-adaptation-transform=Bradford&formatter=str&decimals=8
static const float3x3 HDR10_CSTransform_Rec709_To_Rec2020 = {
	{0.62740390,  0.32928304,  0.04331307},
	{0.06909729,  0.91954040,  0.01136232},
	{0.01639144,  0.08801331,  0.89559525},
};

// see: https://www.colour-science.org:8010/apps/rgb_colourspace_transformation_matrix?input-colourspace=P3-D65&output-colourspace=ITU-R+BT.709&chromatic-adaptation-transform=Bradford&formatter=str&decimals=8
static const float3x3 HDR10_CSTransform_P3D65_To_Rec709 = {
	{ 1.22494018, -0.22494018, -0.00000000},
	{-0.04205695,  1.04205695,  0.00000000},
	{-0.01963755, -0.07863605,  1.09827360},
};

// see: https://www.colour-science.org:8010/apps/rgb_colourspace_transformation_matrix?input-colourspace=P3-D65&output-colourspace=ITU-R+BT.2020&chromatic-adaptation-transform=Bradford&formatter=str&decimals=8
static const float3x3 HDR10_CSTransform_P3D65_To_Rec2020 = {
	{ 0.75383303,  0.19859737,  0.04756960},
 	{ 0.04574385,  0.94177722,  0.01247893},
 	{-0.00121034,  0.01760172,  0.98360862},
};

// see: https://www.colour-science.org:8010/apps/rgb_colourspace_transformation_matrix?input-colourspace=ITU-R+BT.2020&output-colourspace=ITU-R+BT.709&chromatic-adaptation-transform=Bradford&formatter=str&decimals=8
static const float3x3 HDR10_CSTransform_Rec2020_To_Rec709 = {
	{ 1.66049100, -0.58764114, -0.07284986},
	{-0.12455047,  1.13289990, -0.00834942},
	{-0.01815076, -0.10057890,  1.11872966},
};

// see: https://www.colour-science.org:8010/apps/rgb_colourspace_transformation_matrix?input-colourspace=ITU-R+BT.2020&output-colourspace=DCI-P3&chromatic-adaptation-transform=Bradford&formatter=str&decimals=8
static const float3x3 HDR10_CSTransform_Rec2020_To_P3D65 = {
	{ 1.34357825, -0.28217967, -0.06139858},
 	{-0.06529745,  1.07578792, -0.01049046},
 	{ 0.00282179, -0.01959849,  1.01677671},
};

/* --- Utility Functions --- */

float3 HDR10_ApplyColorspaceTransform(float3 color, float3x3 xform)
{
	return mul(xform, color);
}

float3 HDR10_sRGBToLinear(float3 color)
{
	color = pow(color, 2.2);
	return color;
}

float3 HDR10_LinearTosRGB(float3 color)
{
	color = pow(color, 1.0 / 2.2);
	return color;
}

// NOTE: see https://en.wikipedia.org/wiki/Perceptual_quantizer
float3 HDR10_ApplyST2084_PQ(float3 color_norm)
{
    // Apply ST.2084 (PQ curve) for HDR10 standard
    static const float m1 = 2610.0 / 4096.0 / 4;
    static const float m2 = 2523.0 / 4096.0 * 128;
    static const float c1 = 3424.0 / 4096.0;
    static const float c2 = 2413.0 / 4096.0 * 32;
    static const float c3 = 2392.0 / 4096.0 * 32;
    float3             cp = pow(color_norm, m1);

    return pow((c1 + c2 * cp) / (1 + c3 * cp), m2);
}

// NOTE: the luminance weight vector is the y-component (2nd row) of the CIE XYZ matrix for RGB -> CIE XYZ

// calculated with https://www.russellcottrell.com/photo/matrixCalculator.htm
// using primaries and whitepoint from https://en.wikipedia.org/wiki/Rec._709
// with Bradform chromatic adaptation transform
float HDR10_Luminance_Rec709(float3 color)
{
	static const float3 lw = {0.2126390, 0.7151687, 0.0721923};
	return dot(color, lw);
}

// calculated with https://www.russellcottrell.com/photo/matrixCalculator.htm
// using primaries and whitepoint from https://en.wikipedia.org/wiki/DCI-P3
// with Bradform chromatic adaptation transform
float HDR10_Luminance_P3D65(float3 color)
{
	static const float3 lw = {0.2289746, 0.6917385, 0.0792869};
	return dot(color, lw);
}

// calculated with https://www.russellcottrell.com/photo/matrixCalculator.htm
// using primaries and whitepoint from https://en.wikipedia.org/wiki/Rec._2020
// with Bradform chromatic adaptation transform
float HDR10_Luminance_Rec2020(float3 color)
{
	static const float3 lw = {0.2627002, 0.6779981, 0.0593017};
	return dot(color, lw);
}

// Expects input color to be in the target colorspace
// Computes the Luminance for the target colorspace
float HDR10_Luminance(float3 color)
{
	if (HDR10_USE_COLORSPACE_REC709) {
		return HDR10_Luminance_Rec709(color);

	} else if (HDR10_USE_COLORSPACE_P3D65) {
		return HDR10_Luminance_P3D65(color);

	} else if (HDR10_USE_COLORSPACE_REC2020) {
		return HDR10_Luminance_Rec2020(color);
	}

	return HDR10_NAN;
}

// NOTE: see https://64.github.io/tonemapping/#luminance-and-color-theory
float3 HDR10_ChangeLuminance(float3 color, float lum_in, float lum_out)
{
	// TODO: how to solve singularity properly?
	lum_in += 0.00001;
	return color * (lum_out / lum_in);
}

float HDR10_KarisWeight_Rec709(float3 color)
{
	return 1.0 / (1.0 + HDR10_Luminance_Rec709(color));
}

// NOTE: see https://catlikecoding.com/unity/tutorials/custom-srp/color-grading/
// NOTE: see https://www.arri.com/resource/blob/31918/66f56e6abb6e5b6553929edf9aa7483e/2017-03-alexa-logc-curve-in-vfx-data.pdf
static const float LogC_cut = 0.011361;
static const float LogC_a   = 5.555556;
static const float LogC_b   = 0.047996;
static const float LogC_c   = 0.244161;
static const float LogC_d   = 0.386036;
static const float LogC_e   = 5.301883;
static const float LogC_f   = 0.092814;

float3 HDR10_LinearToLogC(float3 x)
{
	return (x > LogC_cut) ? (LogC_c * log10(LogC_a * x + LogC_b) + LogC_d) : (LogC_e * x + LogC_f);
}

float3 HDR10_LogCToLinear(float3 x)
{
	return (x > LogC_e * LogC_cut + LogC_f) ? ((pow(10.0, (x - LogC_d) / LogC_c) - LogC_b) / LogC_a) : ((x - LogC_f) / LogC_e);
}

/* --- Tonemapping Operators --- */

// NOTE: see https://64.github.io/tonemapping/#extended-reinhard
float3 HDR10_Tonemap_ExtendedReinhard(float3 color, float white_point)
{
	float3 numerator   = color * (1.0 + color / (white_point * white_point));
	float3 denominator = 1.0 + color;

	color = numerator / denominator;

	return saturate(color);
}

// NOTE: see https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
float3 HDR10_Tonemap_ACES_Narkowicz(float3 color)
{
	static const float a = 2.51;
	static const float b = 0.03;
	static const float c = 2.43;
	static const float d = 0.59;
	static const float e = 0.14;

	return saturate( (color*(a*color+b))/(color*(c*color+d)+e) );
}

// NOTE: see https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl
float3 HDR10_Tonemap_ACES_Hill(float3 color)
{
	static const float3x3 input_mtx = {
		{0.59719, 0.35458, 0.04823},
		{0.07600, 0.90834, 0.01566},
		{0.02840, 0.13383, 0.83777}
	};

	static const float3x3 output_mtx = {
		{ 1.60475, -0.53108, -0.07367},
		{-0.10208,  1.10813, -0.00605},
		{-0.00327, -0.07276,  1.07602}
	};

	color = mul(input_mtx, color);

	float3 numerator   = color * (color + 0.0245786) - 0.000090537;
	float3 denominator = color * (0.983729 * color + 0.4329510) + 0.238081;

	color = numerator / denominator;

	color = mul(output_mtx, color);

	return saturate(color);
}

// NOTE: see https://www.shadertoy.com/view/WdjSW3
float3 HDR10_Tonemap_Uchimura(float3 x, float P, float a, float m, float l, float c, float b)
{
    // Uchimura 2017, "HDR theory and practice"
    // Math: https://www.desmos.com/calculator/gslcdxvipg
    // Source: https://www.slideshare.net/nikuque/hdr-theory-and-practicce-jp
    float l0 = ((P - m) * l) / a;
    float L0 = m - m / a;
    float L1 = m + (1.0 - m) / a;
    float S0 = m + l0;
    float S1 = m + a * l0;
    float C2 = (a * P) / (P - S1);
    float CP = -C2 / P;

    float3 w0 = 1.0 - smoothstep(0.0, m, x);
    float3 w2 = step(m + l0, x);
    float3 w1 = 1.0 - w0 - w2;

    float3 T = m * pow(x / m, c) + b;
    float3 S = P - (P - S1) * exp(CP * (x - S0));
    float3 L = m + a * (x - m);

    return T * w0 + L * w1 + S * w2;
}

// NOTE: see https://www.shadertoy.com/view/WdjSW3
float3 HDR10_Tonemap_Uchimura(float3 color)
{
    static const float P = 1.0;  // max display brightness
    static const float a = 1.0;  // contrast
    static const float m = 0.22; // linear section start
    static const float l = 0.4;  // linear section length
    static const float c = 1.33; // black
    static const float b = 0.0;  // pedestal

    color = HDR10_Tonemap_Uchimura(color, P, a, m, l, c, b);
	return saturate(color);
}

// NOTE: see https://therealmjp.github.io/posts/a-closer-look-at-tone-mapping/
float3 HDR10_Tonemap_SteveM(float3 color)
{
	static const float a = 10.0;
	static const float b = 0.3;
	static const float c = 0.5;
	static const float d = 1.5;

	return saturate( (color * (a * color + b)) / (color * (a * color + c) + d) );
}

// NOTE: see http://filmicworlds.com/blog/filmic-tonemapping-operators/
float3 HDR10_Tonemap_Uncharted2(float3 x, float a, float b, float c, float d, float e, float f, float w)
{
	return ((x*(a*x+c*b)+d*e)/(x*(a*x+b)+d*f))-e/f;
}

// NOTE: see http://filmicworlds.com/blog/filmic-tonemapping-operators/
float3 HDR10_Tonemap_Uncharted2(float3 color)
{
	static const float a = 0.15;
	static const float b = 0.50;
	static const float c = 0.10;
	static const float d = 0.20;
	static const float e = 0.02;
	static const float f = 0.30;
	static const float w = 11.2;

	static const float exposure_bias = 2.0;
	color *= exposure_bias;
	color = HDR10_Tonemap_Uncharted2(color, a, b, c, d, e, f, w);

	float3 white_scale = 1.0 / HDR10_Tonemap_Uncharted2(w.xxx, a, b, c, d, e, f, w);
	color = color / white_scale;

	return saturate(color);
}

// NOTE: see https://www.shadertoy.com/view/cd3XWr
float3 HDR10_Tonemap_AgX_DefaultContrastApprox(float3 x)
{
	// original polynomial:
	// (15.5 * x^6) + (-40.14 * x^5) + (31.96 * x^4) + (-6.868 * x^3) + (0.4298 * x^2) + (0.1191 * x^1) + (-0.00232 * x^0)

	// improved polynomial:
	// NOTE: see https://www.shadertoy.com/view/mdcSDH comment by FordPerfect
	// (15.122061 * x^6) + (-38.901506 * x^5) + (30.376821 * x^4) + (-5.9293431 * x^3) + (0.2078625 * x^2) + (0.12410293 * x^1)
	// exact endpoints plus the error is better

	// Horner evaluation (fewer multiplies, all FMAs, better numerical stability):
	static const float A =  15.122061;
	static const float B = -38.901506;
	static const float C =  30.376821;
	static const float D = -5.9293431;
	static const float E =  0.2078625;
	static const float F =  0.12410293;
	static const float G =  0.0;

	return G + x * (F + x * (E + x * (D + x * (C + x * (B + x * A)))));
}

// NOTE: see https://www.shadertoy.com/view/cd3XWr
float3 HDR10_Tonemap_AgX_EOTF(float3 color)
{
	static const float3x3 agx_output_xform = {
		{ 1.19687900512017,   -0.0980208811401368, -0.0990297440797205},
		{-0.0528968517574562,  1.15190312990417,   -0.0989611768448433},
		{-0.0529716355144438, -0.0980434501171241,  1.15107367264116},
	};

	// output transform
	color = mul(agx_output_xform, color);

	// to linear sRGB
	color = max(0, color);
	color = pow(color, 2.2);

	return color;
}

// NOTE: see https://www.shadertoy.com/view/cd3XWr
float3 HDR10_Tonemap_AgX_Look(float3 color, float3 slope, float3 power, float saturation)
{
	float luma = HDR10_Luminance(color);

	// ASC CDL
	color = pow(color * slope, power);
	color = lerp(luma, color, saturation);

	return color;
}

// TODO: https://iolite-engine.com/blog_posts/minimal_agx_implementation says that AgX expects input color space
//       to be sRGB/Rec.709. I'm not sure if this is because of the default luminance calculation or the input/output transform matrices
//       I adjusted the luma calculation, no idea if/how to adjust the matrices
// NOTE: see https://www.shadertoy.com/view/cd3XWr
float3 HDR10_Tonemap_AgX_Input(float3 color)
{
	// NOTE: HLSL is row-major, GLSL is column-major
	static const float3x3 agx_input_xform = {
		{0.842479062253094,  0.0784335999999992, 0.0792237451477643},
		{0.0423282422610123, 0.878468636469772,  0.0791661274605434},
		{0.0423756549057051, 0.0784336, 		 0.879142973793104 },
	};

	static const float min_ev = -12.47393;
	static const float max_ev = 4.026069;

	// input transform
	color = mul(agx_input_xform, color);

	// log2 encoding
	// NOTE: see https://github.com/ampas/aces-core/blob/518c27f577e99cdecfddf2ebcfaa53444b1f9343/transforms/ctl/utilities/ACESutil.Lin_to_Log2_param.ctl
	color = (color <= 0.0) ? -HDR10_INF : log2(color);
	color = clamp((color - min_ev) / (max_ev - min_ev), 0, 1);

	// sigmoid contrast
	color = HDR10_Tonemap_AgX_DefaultContrastApprox(color);

	return color;
}

float3 HDR10_Tonemap_AgX_Normal(float3 color)
{
	static const float3 slope      = {1.0, 1.0, 1.0};
	static const float3 power      = {1.0, 1.0, 1.0};
	static const float  saturation = 1.0;

	color = HDR10_Tonemap_AgX_Input(color);
	color = HDR10_Tonemap_AgX_Look(color, slope, power, saturation);
	color = HDR10_Tonemap_AgX_EOTF(color);

	return saturate(color);
}

float3 HDR10_Tonemap_AgX_Punchy(float3 color)
{
	static const float3 slope      = {1.0, 1.0, 1.0};
	static const float3 power      = {1.35, 1.35, 1.35};
	static const float  saturation = 1.4;

	color = HDR10_Tonemap_AgX_Input(color);
	color = HDR10_Tonemap_AgX_Look(color, slope, power, saturation);
	color = HDR10_Tonemap_AgX_EOTF(color);

	return saturate(color);
}

/* --- Dispatch Functions --- */

float3 HDR10_Tonemap_Color(float3 color)
{
	if (HDR10_USE_TONEMAPPER_ACES_NARKOWICZ) {
		return HDR10_Tonemap_ACES_Narkowicz(color);

	} else if (HDR10_USE_TONEMAPPER_ACES_HILL) {
		return HDR10_Tonemap_ACES_Hill(color);

	} else if (HDR10_USE_TONEMAPPER_AGX_NORMAL) {
		return HDR10_Tonemap_AgX_Normal(color);

	} else if (HDR10_USE_TONEMAPPER_AGX_PUNCHY) {
		return HDR10_Tonemap_AgX_Punchy(color);

	} else if (HDR10_USE_TONEMAPPER_UCHIMURA) {
		return HDR10_Tonemap_Uchimura(color);

	} else if (HDR10_USE_TONEMAPPER_STEVEM) {
		return HDR10_Tonemap_SteveM(color);

	} else if (HDR10_USE_TONEMAPPER_UNCHARTED2) {
		return HDR10_Tonemap_Uncharted2(color);

	} else if (HDR10_USE_TONEMAPPER_REINHARD_W2_0) {
		return HDR10_Tonemap_ExtendedReinhard(color, 2.0);

	} else if (HDR10_USE_TONEMAPPER_REINHARD_W3_0) {
		return HDR10_Tonemap_ExtendedReinhard(color, 3.0);
	}

	return saturate(color);
}

float3 HDR10_Tonemap_Luminance(float3 color)
{
	float lum_in  = HDR10_Luminance(color);
	float lum_out = HDR10_Tonemap_Color(lum_in.xxx).x;
	return HDR10_ChangeLuminance(color, lum_in, lum_out);
}

// from Rec.709 to target colorspace
float3 HDR10_TransformColorspace_ToTarget(float3 color)
{
	if (HDR10_USE_COLORSPACE_P3D65) {
		return HDR10_ApplyColorspaceTransform(color, HDR10_CSTransform_Rec709_To_P3D65);

	} else if (HDR10_USE_COLORSPACE_REC2020) {
		return HDR10_ApplyColorspaceTransform(color, HDR10_CSTransform_Rec709_To_Rec2020);
	}

	// no transform since input is already in Rec.709
	return color;
}

// from target colorspace to Rec.2020 (what Windows expects)
float3 HDR10_TransformColorspace_ToDisplay(float3 color)
{
	if (HDR10_USE_COLORSPACE_P3D65) {
		return HDR10_ApplyColorspaceTransform(color, HDR10_CSTransform_P3D65_To_Rec2020);

	} else if (HDR10_USE_COLORSPACE_REC709) {
		return HDR10_ApplyColorspaceTransform(color, HDR10_CSTransform_Rec709_To_Rec2020);
	}

	// no transform for Rec.2020 since output is Rec.2020
	return color;
}

/* --- Processing Functions --- */

// NOTE: see https://catlikecoding.com/unity/tutorials/custom-srp/color-grading/
float3 HDR10_ApplyColorGrading_Rec709(float3 color)
{
	// brightness (lift)
	color += HDR10_BRIGHTNESS;

	// gamma
	color = pow(color, HDR10_GAMMA_RCP);

	// exposure (gain)
	color *= HDR10_EXPOSURE;

	// contrast
	color = HDR10_LinearToLogC(color);
	color = (color - HDR10_CONTRAST_MIDDLE_GRAY) * HDR10_CONTRAST + HDR10_CONTRAST_MIDDLE_GRAY;
	color = HDR10_LogCToLinear(color);

	// saturation
	float luminance = HDR10_Luminance_Rec709(color);
	color = lerp(luminance, color, HDR10_SATURATION);

	return color;
}

// Convert from sRGB to HDR10
// included tonemapping, color grading, colorspace transform, and PQ
float3 HDR10_ToDisplay_World(float3 color)
{
    // just return the color if HDR is disabled
    if (!HDR10_IS_ENABLED) {
        return color;
    }

    // avoid NaNs
    color = max(0, color);

	// color is [0, inf) in 2.2 gamma sRGB (because we disabled all tonemapping in the code and the game seems to render in 2.2 gamma sRGB)
	// we want linear (sRGB/Rec.709 colorspace, but without non-linear OETF applied)
	// NOTE: sRGB/Rec.709 are equivalent color spaces, their OETFs (gamma curves basically) aren't, but when linearized they are equivalent (identical primaries and whitepoint)
	color = HDR10_sRGBToLinear(color);

	// apply color grading in linear HDR sRGB
	color = HDR10_ApplyColorGrading_Rec709(color);

	// apply colorspace transform user selected
	// color is now in target colorspace
	color = HDR10_TransformColorspace_ToTarget(color);

	// color is [0, inf) and linear in target colorspace
	// tonemap since ST2084 PQ expects input values in [0, 1]
	if (HDR10_USE_TONEMAP_MODE_LUMINANCE) {
		color = HDR10_Tonemap_Luminance(color);

	} else if (HDR10_USE_TONEMAP_MODE_COLOR) {
		color = HDR10_Tonemap_Color(color);
	}

	// apply colorspace transfrom from user colorspace to display colorspace
	color = HDR10_TransformColorspace_ToDisplay(color);

	// ST2084 curve operates on normalized luminance (unitless, but 1.0 from tonemapper -> HDR_WHITEPOINT_NITS (cd/m2), normalized by ST2084 peak cd/m2)
	static const float st2084_max_nits = 10000.0;
	color = HDR10_WHITEPOINT_NITS * color / st2084_max_nits;
	color = HDR10_ApplyST2084_PQ(color);

	return color;
}

// Convert from sRGB to HDR10
// only applies the colorspace transform and nits scaling for UI elements (no tonemapping)
float3 HDR10_ToDisplay_UI(float3 color, float nits_scalar, float alpha)
{
    // just return the color if HDR is disabled
    if (!HDR10_IS_ENABLED) {
        return color;
    }

    // avoid NaNs
    color = max(0, color);

	// color is [0, inf) in 2.2 gamma sRGB (because we disabled all tonemapping in the code and the game seems to render in 2.2 gamma sRGB)
	// we want linear (sRGB/Rec.709 colorspace, but without non-linear OETF applied)
	// NOTE: sRGB/Rec.709 are equivalent color spaces, their OETFs (gamma curves basically) aren't, but when linearized they are equivalent
	color = HDR10_sRGBToLinear(color);

	// Apply UI saturation. This is a workaround for UI blending in non-linear PQ colorspace
	// Correct:   output = PQ(alpha * color)
	// Incorrect: output = alpha * PQ(color)
	// at alpha = 1, the color is correct
	// at alpha = 0, the color is the most incorrect
	float saturation = lerp(HDR10_UI_SATURATION, 1.0, alpha);
	float luma = HDR10_Luminance_Rec709(color);
	color = lerp(luma, color, saturation);

	// apply colorspace transform user selected
	color = HDR10_TransformColorspace_ToTarget(color);

	// no tonemapping, assumes input color is in [0, 1]
	color = saturate(color);

	// apply colorspace transform from user colorspace to display colorspace
	color = HDR10_TransformColorspace_ToDisplay(color);

	// ST2084 curve operates on normalized luminance (unitless, but 1.0 from tonemapper -> HDR_WHITEPOINT_NITS (cd/m2), normalized by ST2084 peak cd/m2)
	static const float st2084_max_nits = 10000.0;
	color = HDR10_WHITEPOINT_NITS * nits_scalar * color / st2084_max_nits;
	color = HDR10_ApplyST2084_PQ(color);

	return color;
}

#endif // HDR10_H_
