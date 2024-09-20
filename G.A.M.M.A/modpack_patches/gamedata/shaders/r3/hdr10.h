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

// Other
// HDR Analysis Shaders :: https://github.com/EndlesslyFlowering/ReShade_HDR_shaders/tree/master
// SpecialK HDR 		:: https://github.com/SpecialKO/SpecialK/tree/12b1dda5b1b952e0fb77a1e810b9734f3ee30f81/resource/shaders/HDR
// DirectXTK HDR 		:: https://github.com/Microsoft/DirectXTK/wiki/Using-HDR-rendering
// Xbox HDR 			:: https://github.com/microsoft/Xbox-GDK-Samples/blob/main/Kits/ATGTK/HDR/HDRCommon.hlsli#L199
// Rec.709 -> Rec.2020  :: https://www.itu.int/dms_pubrec/itu-r/rec/bt/R-REC-BT.2087-0-201510-I!!PDF-E.pdf

/* --- Parameters --- */
uniform float4 hdr10_parameters1;
uniform float4 hdr10_parameters2;
uniform float4 hdr10_parameters3;

#define HDR10_WHITEPOINT_NITS  (hdr10_parameters1.x)
#define HDR10_UI_NITS_SCALAR   (hdr10_parameters1.y)
#define HDR10_IS_ENABLED       (hdr10_parameters1.z != 0.0)
#define HDR10_IS_RENDERING_PDA (hdr10_parameters1.w != 0.0)

#define HDR10_COLORSPACE       (hdr10_parameters2.x)
#define HDR10_PDA_INTENSITY    (hdr10_parameters2.y)
#define HDR10_TONEMAPPER       (hdr10_parameters2.z)
#define HDR10_TONEMAP_MODE     (hdr10_parameters2.w)

#define HDR10_EXPOSURE         	   (hdr10_parameters3.x)
#define HDR10_CONTRAST         	   (hdr10_parameters3.y + 1.0f)
#define HDR10_SATURATION       	   (hdr10_parameters3.z + 1.0f)
#define HDR10_CONTRAST_MIDDLE_GRAY (hdr10_parameters3.w)

/* --- Colorspace Options --- */

#define HDR10_USE_COLORSPACE_REC709  (HDR10_COLORSPACE == 0.0)
#define HDR10_USE_COLORSPACE_P3D65   (HDR10_COLORSPACE == 1.0)
#define HDR10_USE_COLORSPACE_REC2020 (HDR10_COLORSPACE == 2.0)

/* --- Tonemapper Options --- */

// NOTE: must be checked in this order
#define HDR10_USE_TONEMAPPER_ACES_NARKOWICZ (HDR10_TONEMAPPER < 1.0f - 0.01f)
#define HDR10_USE_TONEMAPPER_ACES_HILL		(HDR10_TONEMAPPER < 2.0f - 0.01f)
#define HDR10_USE_TONEMAPPER_UCHIMURA		(HDR10_TONEMAPPER < 3.0f - 0.01f)
#define HDR10_USE_TONEMAPPER_LOTTES			(HDR10_TONEMAPPER < 4.0f - 0.01f)
#define HDR10_USE_TONEMAPPER_STEVEM			(HDR10_TONEMAPPER < 5.0f - 0.01f)
#define HDR10_USE_TONEMAPPER_UNCHARTED2     (HDR10_TONEMAPPER < 6.0f - 0.01f)
#define HDR10_USE_TONEMAPPER_REINHARD_W1_7	(HDR10_TONEMAPPER < 7.0f - 0.01f)
#define HDR10_USE_TONEMAPPER_REINHARD_W3_8	(HDR10_TONEMAPPER < 8.0f - 0.01f)
#define HDR10_USE_TONEMAPPER_REINHARD_W8_4  (HDR10_TONEMAPPER < 9.0f - 0.01f)

/* --- Tonemapping Mode Options --- */

#define HDR10_USE_TONEMAP_MODE_LUMINANCE	(HDR10_TONEMAP_MODE == 0.0f)
#define HDR10_USE_TONEMAP_MODE_COLOR		(HDR10_TONEMAP_MODE == 1.0f)

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

// NOTE: see https://64.github.io/tonemapping/#luminance-and-color-theory
// NOTE: this is the y-component of the CIE XYZ matrix for sRGB -> CIE XYZ
float HDR10_Luminance_sRGB(float3 color)
{
	static const float3 luminance_vector = {0.2126f, 0.7152f, 0.0722f};

	return dot(color, luminance_vector);
}

// NOTE: see https://64.github.io/tonemapping/#luminance-and-color-theory
float3 HDR10_ChangeLuminance(float3 color, float lum_in, float lum_out)
{
	// TODO: how to solve singularity properly?
	lum_in += 0.00001f;
	return color * (lum_out / lum_in);
}

// NOTE: see https://catlikecoding.com/unity/tutorials/custom-srp/color-grading/
// NOTE: see https://www.arri.com/resource/blob/31918/66f56e6abb6e5b6553929edf9aa7483e/2017-03-alexa-logc-curve-in-vfx-data.pdf
static const float LogC_cut = 0.011361f;
static const float LogC_a   = 5.555556f;
static const float LogC_b   = 0.047996f;
static const float LogC_c   = 0.244161f;
static const float LogC_d   = 0.386036f;
static const float LogC_e   = 5.301883f;
static const float LogC_f   = 0.092814f;

float3 HDR10_LinearToLogC(float3 x)
{
	return (x > LogC_cut) ? (LogC_c * log10(LogC_a * x + LogC_b) + LogC_d) : (LogC_e * x + LogC_f);
}

float3 HDR10_LogCToLinear(float3 x)
{
	return (x > LogC_e * LogC_cut + LogC_f) ? ((pow(10.0f, (x - LogC_d) / LogC_c) - LogC_b) / LogC_a) : ((x - LogC_f) / LogC_e);
}

/* --- Tonemapping Operators --- */

// NOTE: see https://64.github.io/tonemapping/#extended-reinhard
float3 HDR10_Tonemap_ExtendedReinhard(float3 color, float white_point)
{
	float lum_in = HDR10_Luminance_sRGB(color);

	float numerator   = lum_in * (1.0f + lum_in / (white_point * white_point));
	float denominator = 1.0f + lum_in;

	float lum_out = numerator / denominator;

	color = HDR10_ChangeLuminance(color, lum_in, lum_out);

	return saturate(color);
}

// NOTE: see https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
float3 HDR10_Tonemap_ACES_Narkowicz(float3 color)
{
	static const float a = 2.51f;
	static const float b = 0.03f;
	static const float c = 2.43f;
	static const float d = 0.59f;
	static const float e = 0.14f;

	return saturate( (color*(a*color+b))/(color*(c*color+d)+e) );
}

// NOTE: see https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl
float3 HDR10_Tonemap_ACES_Hill(float3 color)
{
	static const float3x3 input_mtx = {
		{0.59719f, 0.35458f, 0.04823f},
		{0.07600f, 0.90834f, 0.01566f},
		{0.02840f, 0.13383f, 0.83777f}
	};

	static const float3x3 output_mtx = {
		{ 1.60475f, -0.53108f, -0.07367f},
		{-0.10208f,  1.10813f, -0.00605f},
		{-0.00327f, -0.07276f,  1.07602f}
	};

	color = mul(input_mtx, color);

	float3 numerator   = color * (color + 0.0245786f) - 0.000090537f;
	float3 denominator = color * (0.983729f * color + 0.4329510f) + 0.238081f;

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

// NOTE: see https://www.shadertoy.com/view/WdjSW3
float3 HDR10_Tonemap_Lottes(float3 x)
{
    // Lottes 2016, "Advanced Techniques and Optimization of HDR Color Pipelines"
    static const float a = 1.6;
    static const float d = 0.977;
    static const float hdrMax = 8.0;
    static const float midIn = 0.18;
    static const float midOut = 0.267;

    // Can be precomputed
    const float b =
        (-pow(midIn, a) + pow(hdrMax, a) * midOut) /
        ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);
    const float c =
        (pow(hdrMax, a * d) * pow(midIn, a) - pow(hdrMax, a) * pow(midIn, a * d) * midOut) /
        ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);

    return saturate( pow(x, a) / (pow(x, a * d) * b + c) );
}

// NOTE: see https://therealmjp.github.io/posts/a-closer-look-at-tone-mapping/
float3 HDR10_Tonemap_SteveM(float3 color)
{
	static const float a = 10.0f;
	static const float b = 0.3f;
	static const float c = 0.5f;
	static const float d = 1.5f;

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
	static const float a = 0.15f;
	static const float b = 0.50f;
	static const float c = 0.10f;
	static const float d = 0.20f;
	static const float e = 0.02f;
	static const float f = 0.30f;
	static const float w = 11.2f;

	static const float exposure_bias = 2.0f;
	color *= exposure_bias;
	color = HDR10_Tonemap_Uncharted2(color, a, b, c, d, e, f, w);

	float3 white_scale = 1.0f / HDR10_Tonemap_Uncharted2(w.xxx, a, b, c, d, e, f, w);
	color = color / white_scale;

	return saturate(color);
}

/* --- Dispatch Functions --- */

float3 HDR10_Tonemap_sRGB_Color(float3 color)
{
	if (HDR10_USE_TONEMAPPER_ACES_NARKOWICZ) {
		return HDR10_Tonemap_ACES_Narkowicz(color);

	} else if (HDR10_USE_TONEMAPPER_ACES_HILL) {
		return HDR10_Tonemap_ACES_Hill(color);

	} else if (HDR10_USE_TONEMAPPER_UCHIMURA) {
		return HDR10_Tonemap_Uchimura(color);

	} else if (HDR10_USE_TONEMAPPER_LOTTES) {
		return HDR10_Tonemap_Lottes(color);

	} else if (HDR10_USE_TONEMAPPER_STEVEM) {
		return HDR10_Tonemap_SteveM(color);

	} else if (HDR10_USE_TONEMAPPER_UNCHARTED2) {
		return HDR10_Tonemap_Uncharted2(color);

	} else if (HDR10_USE_TONEMAPPER_REINHARD_W1_7) {
		return HDR10_Tonemap_ExtendedReinhard(color, 1.7f);

	} else if (HDR10_USE_TONEMAPPER_REINHARD_W3_8) {
		return HDR10_Tonemap_ExtendedReinhard(color, 3.8f);

	} else if (HDR10_USE_TONEMAPPER_REINHARD_W8_4) {
		return HDR10_Tonemap_ExtendedReinhard(color, 8.4f);

	} else {
		return saturate(color);
	}
}

float HDR10_Tonemap_sRGB_Luminance(float luminance)
{
	float3 lum3 = luminance.xxx;

	if (HDR10_USE_TONEMAPPER_ACES_NARKOWICZ) {
		return HDR10_Tonemap_ACES_Narkowicz(lum3);

	} else if (HDR10_USE_TONEMAPPER_ACES_HILL) {
		return HDR10_Tonemap_ACES_Hill(lum3);

	} else if (HDR10_USE_TONEMAPPER_UCHIMURA) {
		return HDR10_Tonemap_Uchimura(lum3);

	} else if (HDR10_USE_TONEMAPPER_LOTTES) {
		return HDR10_Tonemap_Lottes(lum3);

	} else if (HDR10_USE_TONEMAPPER_STEVEM) {
		return HDR10_Tonemap_SteveM(lum3);

	} else if (HDR10_USE_TONEMAPPER_UNCHARTED2) {
		return HDR10_Tonemap_Uncharted2(lum3);

	} else if (HDR10_USE_TONEMAPPER_REINHARD_W1_7) {
		return HDR10_Tonemap_ExtendedReinhard(lum3, 1.7f);

	} else if (HDR10_USE_TONEMAPPER_REINHARD_W3_8) {
		return HDR10_Tonemap_ExtendedReinhard(lum3, 3.8f);

	} else if (HDR10_USE_TONEMAPPER_REINHARD_W8_4) {
		return HDR10_Tonemap_ExtendedReinhard(lum3, 8.4f);

	} else {
		return saturate(luminance);
	}
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
float3 HDR10_ApplyColorGrading(float3 color)
{
	// post-exposure
	color *= HDR10_EXPOSURE;

	// contrast
	color = HDR10_LinearToLogC(color);
	color = (color - HDR10_CONTRAST_MIDDLE_GRAY) * HDR10_CONTRAST + HDR10_CONTRAST_MIDDLE_GRAY;
	color = HDR10_LogCToLinear(color);

	// saturation
	float luminance = HDR10_Luminance_sRGB(color);
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
	// NOTE: sRGB/Rec.709 are equivalent color spaces, their OETFs (gamma curves basically) aren't, but when linearized they are equivalent
	color = HDR10_sRGBToLinear(color);

	// apply color grading in linear HDR sRGB
	color = HDR10_ApplyColorGrading(color);

	// compute luminance in sRGB (easier, should be invariant)
	float lum_in = HDR10_Luminance_sRGB(color);

	// apply colorspace transform user selected
	color = HDR10_TransformColorspace_ToTarget(color);

	// now color is [0, inf) and linear in sRGB/Rec.709
	// first tonemap since everything else expects input values in [0, 1]
	if (HDR10_USE_TONEMAP_MODE_LUMINANCE) {
		float lum_out = HDR10_Tonemap_sRGB_Luminance(lum_in);
		color = HDR10_ChangeLuminance(color, lum_in, lum_out);

	} else if (HDR10_USE_TONEMAP_MODE_COLOR) {
		color = HDR10_Tonemap_sRGB_Color(color);
	}

	// apply colorspace transfrom from user colorspace to display colorspace
	color = HDR10_TransformColorspace_ToDisplay(color);

	// ST2084 curve operates on normalized luminance (unitless, but 1.0 from tonemapper -> HDR_WHITEPOINT_NITS (cd/m2), normalized by ST2084 peak cd/m2)
	static const float st2084_max_nits = 10000.0f;
	color = HDR10_WHITEPOINT_NITS * color / st2084_max_nits;
	color = HDR10_ApplyST2084_PQ(color);

	return color;
}

// Convert from sRGB to HDR10
// only applies the colorspace transform and nits scaling for UI elements
float3 HDR10_ToDisplay_UI(float3 color, float nits_scalar)
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

	// apply colorspace transform user selected
	color = HDR10_TransformColorspace_ToTarget(color);

	// no tonemapping, assumes input color is in [0, 1]
	color = saturate(color);

	// apply colorspace transform from user colorspace to display colorspace
	color = HDR10_TransformColorspace_ToDisplay(color);

	// ST2084 curve operates on normalized luminance (unitless, but 1.0 from tonemapper -> HDR_WHITEPOINT_NITS (cd/m2), normalized by ST2084 peak cd/m2)
	static const float st2084_max_nits = 10000.0f;
	color = HDR10_WHITEPOINT_NITS * nits_scalar * color / st2084_max_nits;
	color = HDR10_ApplyST2084_PQ(color);

	return color;
}

#endif
