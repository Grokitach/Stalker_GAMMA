// -------------------------------------------------------------------------- //

// FGFX::LSPOIrr - Large Scale Perceptual Obscurance and Irradiance
// Author  : Alex Tuduran | alex.tuduran@gmail.com | github.com/AlexTuduran
// Version : 0.7 [ReShade 3.0]

// -------------------------------------------------------------------------- //
// preprocessor definitions
// -------------------------------------------------------------------------- //

// enables / disables the auto-gain feature
// disable for a slight performance boost if auto-gain is not needed
// 0 = auto-gain disabled
// 1 = auto-gain enabled
// def = 1
#ifndef LSPOIRR_AUTO_GAIN_ENABLED
    #define LSPOIRR_AUTO_GAIN_ENABLED 1
#endif

#if LSPOIRR_AUTO_GAIN_ENABLED

// defines how fast the auto-gain adapts to the scenery
// greater than 0
// less than 0.25
// def = 0.04
#ifndef LSPOIRR_AUTO_GAIN_SPEED 
    #define LSPOIRR_AUTO_GAIN_SPEED 0.04
#endif

// defines the breaking point between the two piecewise functions that make up
// the compute blur gain function
// greater than 0
// less than 0.5
// def = 0.05
#ifndef LSPOIRR_BLUR_MAX_RECIPROCAL_THRESHOLD
    #define LSPOIRR_BLUR_MAX_RECIPROCAL_THRESHOLD 0.05
#endif

#endif // LSPOIRR_AUTO_GAIN_ENABLED

// required for resolutions > 4K
// 0 = cascade 3 disabled
// 1 = cascade 3 enabled
// def = 0
#ifndef LSPOIRR_CASCADE_3_ON
    #define LSPOIRR_CASCADE_3_ON 0
#endif

// enables / disables working in sRGB color space
// 0 = sRGB disabled
// 1 = sRGB 3 enabled
// def = 0
#ifndef LSPOIRR_SRGB
    #define LSPOIRR_SRGB 0
#endif

// -------------------------------------------------------------------------- //
// internal preprocessor definitions
// -------------------------------------------------------------------------- //

// at the core of effect there's the overlay blending operation which is a
// piecewise function computed as a multiplication blending operation if the
// overlay layer is less than 0.5 and as a screen blending operation otherwise
// therefore, the standard overlay blending operation breaks by default at 0.5
// however, the overlay blending operation can be further extended by introducing
// a custom breaking point that can range from 0.0 to 1.0
// this preprocessor definition enables the usage of a custom
// occlusion - irradiance breaking point that can be controled from UI
// see 'Occlusion-Irradiance Neutral Point' ui parameter
//
// warning:
// however, this feature is ***work in progress***, as the screen blending
// operation used in the overlay blending opration  doesn't play well with
// custom breaking point and a different custom blending operation is required
// to be developed
#define ___CUSTOM_OCCLUSSION_IRRADIANCE_NEUTRAL_POINT 0

// -------------------------------------------------------------------------- //

#include "ReShadeUI.fxh"

// -------------------------------------------------------------------------- //

#define IDENT_TO_STR(ident) #ident

// -------------------------------------------------------------------------- //
// "About" category
// -------------------------------------------------------------------------- //

uniform int ___ABOUT <
    ui_type = "radio";
    ui_label = " ";
    ui_category = "About";
    ui_text =
        "-=[ FGFX::LSPOIrr - Large Scale Perceptual Obscurance and Irradiance ]=-\n"
        "\n"

        "The Large Scale Perceptual Obscurance and Irradiance is a post-processing "
        "effect that attempts to inject obscurance and irradiance in the scene at a "
        "large scale (low frequency).\n"
        "\n"

        "Due to the fact that the effect operates on the low frequencies of the "
        "input image, the effect often plays just on a perceptual level rather "
        "than being an actual physically correct rendition of scene obscurrance and "
        "irradiance.\n"
        "\n"

        "* How does it work? *\n"
        "\n"

        "The concept sitting at the core of the effect is really simple and relies "
        "on some assumptions that more than often are correct. If we take an "
        "arbitrary image, blur it with a large gaussian and then overlay (as in "
        "standard overlay blending operation) the blurred image onto the original "
        "image, we get the illusion that some statistically-correct occlusion and "
        "irradiance shows up in the image.\n"
        "\n"

        "* Why does it work? *\n"
        "\n"

        "The effect relies on the statistical fact that if there's a part in the "
        "input image that is predominantly dark, chances are that the entire part "
        "contains objects that obscure each other, reducing the amount of light "
        "radiated in that particular area.\n"
        "\n"

        "Admittedly, the opposite is also true: If a part of the input image is "
        "predominantly bright, chances are that the objects in that part of the "
        "image have an increased amount of light inter-radiation, as a result of "
        "objects in that part of the image bouncing light to each other.\n"
        "\n"

        "* What about performance? *\n"
        "\n"

        "The implementation uses the Fast Cascaded Separable Blur technique, "
        "which is blazing-fast. The entire effect executes in less than 0.35 ms "
        "on a machine with a i7-8700K running at 4.2Ghz CPU and a GTX 1080Ti "
        "running at 2000Mhz GPU in 2560x1440 resolution.\n"
        "\n"

        "And if you think you don't need the auto-gain feature (by disabling it "
        "in preprocessor definitions), you can cut 0.05 ms and get the total "
        "execution time down to 0.3 ms.\n"
        "\n"

        "* Where is this effect best placed? *\n"
        "\n"

        "Since the effect addresses the lighting in the scene, it's best put "
        "after any Global Illumination technique like Ambient Occlusion, "
        "Obscurance, RTGI and before tone-mapping, film grain, color grading "
        "of any sort, bloom, CA or any lens & sensor effects.\n";
>;

// -------------------------------------------------------------------------- //
// "Obscurance / Irradiance Settings" category
// -------------------------------------------------------------------------- //

#define ___CATEGORY_EFFECT_SETTINGS___ "Effect Settings"

uniform bool LSPOIrrEffectEnabled <
    ui_category = ___CATEGORY_EFFECT_SETTINGS___;
    ui_label = "Effect Enabled";
    ui_tooltip = "Enables / disables the effect entirely.";
> = true;

uniform float LSPOIrrEffectIntensity < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.0;
    ui_max = 1.0;
    ui_category = ___CATEGORY_EFFECT_SETTINGS___;
    ui_label = "Effect Intensity";
    ui_tooltip = "Adjusts the overall intensity of the effect.";
> = 0.9;

uniform float LSPOIrrOcclusionIntensity < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.0;
    ui_max = 1.0;
    ui_category = ___CATEGORY_EFFECT_SETTINGS___;
    ui_label = "Occlusion Intensity";
    ui_tooltip = "Adjusts the occlusion intensity of the effect.";
> = 1.0;

uniform float LSPOIrrIrradianceIntensity < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.0;
    ui_max = 1.0;
    ui_category = ___CATEGORY_EFFECT_SETTINGS___;
    ui_label = "Irradiance Intensity";
    ui_tooltip = "Adjusts the irradiance intensity of the effect.";
> = 1.0;

#if ___CUSTOM_OCCLUSSION_IRRADIANCE_NEUTRAL_POINT

uniform float LSPOIrrOcclusionIrradianceNeutralPoint < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.0;
    ui_max = 1.0;
    ui_category = ___CATEGORY_EFFECT_SETTINGS___;
    ui_label = "Occlusion-Irradiance Neutral Point";
    ui_tooltip = "Adjusts the point where occlusion and irradiance meet at 0 intensity.";
> = 0.5;

#endif // ___CUSTOM_OCCLUSSION_IRRADIANCE_NEUTRAL_POINT

uniform float LSPOIrrEffectRadius < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.25;
    ui_max = 1.00;
    ui_category = ___CATEGORY_EFFECT_SETTINGS___;
    ui_label = "Effect Radius";
    ui_tooltip = "Adjusts the radius of the effect.";
> = 0.65;

uniform float LSPOIrrEffectSaturation < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.0;
    ui_max = 1.0;
    ui_category = ___CATEGORY_EFFECT_SETTINGS___;
    ui_label = "Effect Saturation";
    ui_tooltip =
        "Adjusts the saturation of the resulting occlusion and irradiance.\n"
        "\n"
        "Notice this is NOT the final output saturation, but the saturation applied to occlusion and irradiance prior to blending over the color buffer.\n"
        "For the final output saturation see 'Saturation' in the 'Toning Settings' category.";
> = 0.0;

uniform float LSPOIrrOcclusionIrradianceRecovery < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.0;
    ui_max = 1.0;
    ui_category = ___CATEGORY_EFFECT_SETTINGS___;
    ui_label = "Occlusion-Irradiance Recovery";
    ui_tooltip =
        "Adjusts the recovery applied to occlusion and radiance.\n"
        "\n"
        "Set it to 0 for a dramatic effect overall, set to 1 for maximum recovery of dark and bright areas.";
> = 0.75;

// -------------------------------------------------------------------------- //
// "Toning Settings" category
// -------------------------------------------------------------------------- //

#define ___CATEGORY_TONING_SETTINGS___ "Toning Settings"

#if LSPOIRR_AUTO_GAIN_ENABLED

uniform float LSPOIrrAutoGain < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.0;
    ui_max = 1.0;
    ui_category = ___CATEGORY_TONING_SETTINGS___;
    ui_label = "Auto-Gain";
    ui_tooltip = "Adjusts the influence of auto-gain.";
> = 0.5;

#endif // LSPOIRR_AUTO_GAIN_ENABLED

uniform float LSPOIrrGamma < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.10;
    ui_max = 4.00;
    ui_category = ___CATEGORY_TONING_SETTINGS___;
    ui_label = "Gamma";
    ui_tooltip = "Adjusts the gamma of the final result.";
> = 1.0;

uniform float LSPOIrrGain < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.0;
    ui_max = 4.0;
    ui_category = ___CATEGORY_TONING_SETTINGS___;
    ui_label = "Gain";
    ui_tooltip = "Adjusts the gain of the final result.";
> = 1.0;

uniform float LSPOIrrContrast < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.0;
    ui_max = 1.0;
    ui_category = ___CATEGORY_TONING_SETTINGS___;
    ui_label = "Contrast";
    ui_tooltip = "Adjusts the contrast of the final result.";
> = 1.0;

uniform float LSPOIrrSaturation < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.0;
    ui_max = 2.0;
    ui_category = ___CATEGORY_TONING_SETTINGS___;
    ui_label = "Saturation";
    ui_tooltip = "Adjusts the saturation of the final result.";
> = 1.0;

// -------------------------------------------------------------------------- //
// "Debug" category
// -------------------------------------------------------------------------- //

uniform int LSPOIrrDebugType <
    ui_type = "combo";
    ui_category = "Debug";

    ui_items =
        "None\0"
        "No Intensity\0"
        "No Toning\0"
        "Raw Blur\0"
        "Saturated Blur\0"

#if LSPOIRR_AUTO_GAIN_ENABLED
        "Gained Blur\0"
#endif // LSPOIRR_AUTO_GAIN_ENABLED

        "Scaled Blur\0"
        "Occlusion - Irradiance Map\0"

#if LSPOIRR_AUTO_GAIN_ENABLED
        "Blur Max Samples Positions\0"
        "Blur Max\0"
        "Blur Gain\0"
#endif // LSPOIRR_AUTO_GAIN_ENABLED

        "Recovery Blur\0"
        "Scaled Recovery Blur\0"
        "Recovery Occlusion - Irradiance Map\0";

    ui_label = "Debug Type";
    ui_tooltip = "Different debug outputs";
> = 0;

// -------------------------------------------------------------------------- //

#if 1

    #define ___LSPOIRR_DEBUG_NONE___                                (0x00)
    #define ___LSPOIRR_DEBUG_NO_INTENSITY___                        (0x01)
    #define ___LSPOIRR_DEBUG_NO_TONING___                           (0x02)
    #define ___LSPOIRR_DEBUG_RAW_BLUR___                            (0x03)
    #define ___LSPOIRR_DEBUG_SATURATED_BLUR___                      (0x04)

#endif

#if LSPOIRR_AUTO_GAIN_ENABLED

    #define ___LSPOIRR_DEBUG_GAINED_BLUR___                         (0x05)

    #define ___LSPOIRR_DEBUG_SCALED_BLUR___                         (0x06)
    #define ___LSPOIRR_DEBUG_OCCLUSION_IRRADIANCE_MAP___            (0x07)

#else // LSPOIRR_AUTO_GAIN_ENABLED

    #define ___LSPOIRR_DEBUG_SCALED_BLUR___                         (0x05)
    #define ___LSPOIRR_DEBUG_OCCLUSION_IRRADIANCE_MAP___            (0x06)

#endif // LSPOIRR_AUTO_GAIN_ENABLED

#if LSPOIRR_AUTO_GAIN_ENABLED

    #define ___LSPOIRR_DEBUG_BLUR_MAX_SAMPLES_POSITIONS___          (0x08)
    #define ___LSPOIRR_DEBUG_BLUR_MAX___                            (0x09)
    #define ___LSPOIRR_DEBUG_BLUR_GAIN___                           (0x0A)

    #define ___LSPOIRR_DEBUG_RECOVERY_BLUR___                       (0x0B)
    #define ___LSPOIRR_DEBUG_SCALED_RECOVERY_BLUR___                (0x0C)
    #define ___LSPOIRR_DEBUG_RECOVERY_OCCLUSION_IRRADIANCE_MAP___   (0x0D)

#else // LSPOIRR_AUTO_GAIN_ENABLED

    #define ___LSPOIRR_DEBUG_RECOVERY_BLUR___                       (0x08)
    #define ___LSPOIRR_DEBUG_SCALED_RECOVERY_BLUR___                (0x09)
    #define ___LSPOIRR_DEBUG_RECOVERY_OCCLUSION_IRRADIANCE_MAP___   (0x0A)

#endif // LSPOIRR_AUTO_GAIN_ENABLED

// -------------------------------------------------------------------------- //
// "Preprocessor definitions descriptions" category
// -------------------------------------------------------------------------- //

#define ___CATEGORY_PREPROCESSOR_DEFINITIONS_DESCRIPTIONS___ "Preprocessor definitions descriptions"

#define MAKE_DESCRIPTION_VAR(ident) ident##_DESC

uniform int MAKE_DESCRIPTION_VAR(___LSPOIRR_AUTO_GAIN_ENABLED) <
    ui_type = "radio";
    ui_label = " ";
    ui_category = ___CATEGORY_PREPROCESSOR_DEFINITIONS_DESCRIPTIONS___;
    ui_text =
        IDENT_TO_STR(LSPOIRR_AUTO_GAIN_ENABLED)
        ":\n- Enables / disables the auto-gain feature. "
        "Disable for a slight performance boost if auto-gain is not needed.\n"
        "- 0 means disabled, 1 means enabled, default is 1.\n";
>;

uniform int MAKE_DESCRIPTION_VAR(___LSPOIRR_AUTO_GAIN_SPEED) <
    ui_type = "radio";
    ui_label = " ";
    ui_category = ___CATEGORY_PREPROCESSOR_DEFINITIONS_DESCRIPTIONS___;
    ui_text =
        IDENT_TO_STR(LSPOIRR_AUTO_GAIN_SPEED)
        ":\n- Defines how fast the auto-gain adapts to the scenery. "
        "Disable for a slight performance boost if auto-gain is not needed.\n"
        "- Must be greater than 0, less than 0.25, default is 0.04.\n";
>;

uniform int MAKE_DESCRIPTION_VAR(___LSPOIRR_BLUR_MAX_RECIPROCAL_THRESHOLD) <
    ui_type = "radio";
    ui_label = " ";
    ui_category = ___CATEGORY_PREPROCESSOR_DEFINITIONS_DESCRIPTIONS___;
    ui_text =
        IDENT_TO_STR(LSPOIRR_BLUR_MAX_RECIPROCAL_THRESHOLD)
        ":\n- Defines the breaking point between the two piecewise functions that make up the compute blur gain function.\n"
        "- Must be greater than 0, less than 0.5, default is 0.05.\n";
>;

uniform int MAKE_DESCRIPTION_VAR(___LSPOIRR_CASCADE_3_ON) <
    ui_type = "radio";
    ui_label = " ";
    ui_category = ___CATEGORY_PREPROCESSOR_DEFINITIONS_DESCRIPTIONS___;
    ui_text =
        IDENT_TO_STR(LSPOIRR_CASCADE_3_ON)
        ":\n- Enables / disables cascade 3 in the Fast Cascaded Separable Blur implementation in order to achieve a much wider blur radius. "
        "Only required for resolutions bigger than 4K.\n"
        "- 0 means disabled, 1 means enabled, default is 0.\n";
>;

uniform int MAKE_DESCRIPTION_VAR(___LSPOIRR_SRGB) <
    ui_type = "radio";
    ui_label = " ";
    ui_category = ___CATEGORY_PREPROCESSOR_DEFINITIONS_DESCRIPTIONS___;
    ui_text =
        IDENT_TO_STR(LSPOIRR_SRGB)
        ":\n- Enables / disables working in sRGB color space. "
        "Blending the effect in sRGB yields slightly different results and it should be toggled as needed by the specific game you're running.\n"
        "- However, beware that when enabled, in most cases the final output is lightly darker in the shadows areas than when disabled.\n"
        "- 0 means disabled, 1 means enabled, default is 0.\n";
>;

// -------------------------------------------------------------------------- //

#include "ReShade.fxh"

// -------------------------------------------------------------------------- //

// this value is tightly related to the architecture of this implementation (16X)
// of FCSB (Fast Cascaded Separable Blur), therefore should not be changed
#define ___BUFFER_SIZE_MAX_BIT_SHIFT___ (4)

// -------------------------------------------------------------------------- //

uniform float FrameTime <source = "frametime";>;

// -------------------------------------------------------------------------- //
// sRGB back-buffer sampler
// -------------------------------------------------------------------------- //

sampler2D ReShadeBackBufferSRGBSampler {
    Texture = ReShade::BackBufferTex;
#if LSPOIRR_SRGB
    SRGBTexture = true;
#endif // LSPOIRR_SRGB
};

// -------------------------------------------------------------------------- //
// down-samplers and their textures
// -------------------------------------------------------------------------- //

texture HalfBlurTex {
    Width = BUFFER_WIDTH >> 1;
    Height = BUFFER_HEIGHT >> 1;
    Format = RGBA16F;
};

sampler HalfBlurSampler {
    Texture = HalfBlurTex;
};

texture QuadBlurTex {
    Width = BUFFER_WIDTH >> 2;
    Height = BUFFER_HEIGHT >> 2;
    Format = RGBA16F;
};

sampler QuadBlurSampler {
    Texture = QuadBlurTex;
};

texture OctoBlurTex {
    Width = BUFFER_WIDTH >> 3;
    Height = BUFFER_HEIGHT >> 3;
    Format = RGBA16F;
};

sampler OctoBlurSampler {
    Texture = OctoBlurTex;
};

texture HexaBlurTex {
    Width = BUFFER_WIDTH >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Height = BUFFER_HEIGHT >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Format = RGBA16F;
};

sampler HexaBlurSampler {
    Texture = HexaBlurTex;
};

// -------------------------------------------------------------------------- //
// cascades ping-pong textures & samplers
// -------------------------------------------------------------------------- //

texture HBlurTex {
    Width = BUFFER_WIDTH >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Height = BUFFER_HEIGHT >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Format = RGBA16F;
};

sampler HBlurSampler {
    Texture = HBlurTex;
};

texture VBlurTex {
    Width = BUFFER_WIDTH >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Height = BUFFER_HEIGHT >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Format = RGBA16F;
};

sampler VBlurSampler {
    Texture = VBlurTex;
};

texture ShortBlurTex {
    Width = BUFFER_WIDTH >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Height = BUFFER_HEIGHT >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Format = RGBA16F;
};

sampler ShortBlurSampler {
    Texture = ShortBlurTex;
};

#if LSPOIRR_AUTO_GAIN_ENABLED

// -------------------------------------------------------------------------- //
// auto-gain txtures & samplers
// -------------------------------------------------------------------------- //

texture BlurMaxTex {
    Width = BUFFER_WIDTH >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Height = BUFFER_HEIGHT >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Format = R16F;
};

sampler BlurMaxSampler {
    Texture = BlurMaxTex;
};

texture BlurMaxHistoryTex {
    Width = BUFFER_WIDTH >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Height = BUFFER_HEIGHT >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Format = R16F;
};

sampler BlurMaxHistorySampler {
    Texture = BlurMaxHistoryTex;
};

texture BlurMaxHistoryTempTex {
    Width = BUFFER_WIDTH >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Height = BUFFER_HEIGHT >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Format = R16F;
};

sampler BlurMaxHistoryTempSampler {
    Texture = BlurMaxHistoryTempTex;
};

#endif // LSPOIRR_AUTO_GAIN_ENABLED

// -------------------------------------------------------------------------- //

#define ___BLUR_SAMPLE_OFFSET_CASCADE_0___         (  1.0) // 3 ^ 0
#define ___BLUR_SAMPLE_OFFSET_CASCADE_1___         (  3.0) // 3 ^ 1
#define ___BLUR_SAMPLE_OFFSET_CASCADE_2___         (  9.0) // 3 ^ 2
#define ___BLUR_SAMPLE_OFFSET_CASCADE_3___         ( 27.0) // 3 ^ 3
#define ___BLUR_SAMPLE_OFFSET_CASCADE_4___         ( 81.0) // 3 ^ 4
#define ___BLUR_SAMPLE_OFFSET_CASCADE_5___         (243.0) // 3 ^ 5

// -------------------------------------------------------------------------- //

#define ___MAX_CHANNEL_COMPENSATION___             (1.5)
#define ___HASH_TIME_STEP___                       (0.79531)
#define ___HALF_SQRT_TWO___                        (0.707106781)

// -------------------------------------------------------------------------- //

#define ___MAX_BLUR_NUM_SAMPLES___                 (7)
#define ___MAX_BLUR_POS_SAMPLE_START___            (0.35)
#define ___MAX_BLUR_POS_SAMPLE_STEP___             (0.05)

// -------------------------------------------------------------------------- //

#define SATURATE_COLOR(color, saturation)          (lerp((((color).r) + ((color).g) + ((color).b)) * ___ONE_THIRD___, (color), (saturation)))
#define COMPUTE_COLOR_MAX_CHANNEL(color)           (max(((color).r), max(((color).g), ((color).b))))
#define SMOOTHSTEP_QUINTIC_INTERPOLANT(x)          ((x) * (x) * (3.0 - (x) * 2.0))

// -------------------------------------------------------------------------- //

static const float  ___BUFFER_ASPECT_RATIO___            = BUFFER_WIDTH / BUFFER_HEIGHT;
static const int    ___MAX_BLUR_NUM_TOTAL_SAMPLES___     = ___MAX_BLUR_NUM_SAMPLES___ * ___MAX_BLUR_NUM_SAMPLES___;
static const float  ___MAX_BLUR_NUM_TOTAL_SAMPLES_RCP___ = 1.0 / ___MAX_BLUR_NUM_TOTAL_SAMPLES___;
static const int    ___BUFFER_SIZE_DIVIDER___            = 1 << ___BUFFER_SIZE_MAX_BIT_SHIFT___;
static const float  ___ONE_THIRD___                      = 1.0 / 3.0;

// we use a step of 1.5 for sampling 2 pixels at the same time with just one
// tex2D call and directly get their average:
// lerp(a, b, 0.5) =
//   = a + (b - a) * 0.5
//   = a + b * 0.5 - a * 0.5
//   = a + b / 2 - a / 2
//   = (2 * a + b - a) / 2
//   = (a + a + b - a) / 2
//   = (a + b + a - a) / 2
//   = (a + b) / 2
//
// therefore, when we sample a texture with an offset of half texel (linear
// sampler required), we in fact fetch directly the average of left and right
// texel
//
// better yet, if we sample the texture at half texel on x and y as well, we in fact fetch directly the average of the neighbour 4 texels TL, TR, BL, BR:
// tex2D(sampler, (intUV + 0.5) * BUFFER_PIXEL_SIZE) =
//   = lerp(lerp(TL, TR, 0.5), lerp(BL, BR, 0.5), 0.5)
//   = (lerp(TL, TR, 0.5) + lerp(BL, BR, 0.5)) / 2
//   = ((TL + TR) / 2 + (BL + BR) / 2) / 2
//   = ((TL + TR + BL + BR) / 2) / 2
//   = (TL + TR + BL + BR) / 4
// where:
//   TL = tex2D(sampler, BUFFER_PIXEL_SIZE * (intUV + float2(0, 0)))
//   TR = tex2D(sampler, BUFFER_PIXEL_SIZE * (intUV + float2(0, 1)))
//   BL = tex2D(sampler, BUFFER_PIXEL_SIZE * (invUV + float2(1, 0)))
//   BR = tex2D(sampler, BUFFER_PIXEL_SIZE * (intUV + float2(1, 1)))
//
// so we get a 2x2 convolution basically for free
static const float  ___STEP_MULTIPLIER___                                        = 1.5;
static const float  ___BUFFER_SIZE_DIVIDER_COMPENSATION_OFFSET___                = ___BUFFER_SIZE_DIVIDER___ * ___STEP_MULTIPLIER___;
static const float2 ___SCALED_BUFFER_SIZE_DIVIDER_DIVIDER_COMPENSATION_OFFSET___ = ___BUFFER_SIZE_DIVIDER_COMPENSATION_OFFSET___ * BUFFER_PIXEL_SIZE;

// -------------------------------------------------------------------------- //
// * down-sampling routines *
//
// we don't down-sample to the smallest texture directly in order to avoid aliasing
// by down-sampling in steps, we get an energy-conservative down-sampling that
// accounts for all pixels in the back-buffer, hence free of any aliasing
// -------------------------------------------------------------------------- //

float3 CopyBBPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // if writing to a half-sized texture, this returns the average of 4 neighbour texels
    return tex2D(ReShadeBackBufferSRGBSampler, texcoord.xy).rgb;
}

float3 CopyHalfPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // if writing to a half-sized texture, this returns the average of 4 neighbour texels
    return tex2D(HalfBlurSampler, texcoord.xy).rgb;
}

float3 CopyQuadPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // if writing to a half-sized texture, this returns the average of 4 neighbour texels
    return tex2D(QuadBlurSampler, texcoord.xy).rgb;
}

float3 CopyOctoPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // if writing to a half-sized texture, this returns the average of 4 neighbour texels
    return tex2D(OctoBlurSampler, texcoord.xy).rgb;
}

float3 CopyHexaPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // if writing to a half-sized texture, this returns the average of 4 neighbour texels
    return tex2D(HexaBlurSampler, texcoord.xy).rgb;
}

// -------------------------------------------------------------------------- //
// * separable cascades routines *
//
// we call these many times in a "cascade" fashion with exponentially increasing
// blurSampleOffset in order to achieve a large radius blur
//
// since we're sampling 3 texels at a time, the next cascade should use a
// blurSampleOffset that is 3 times wider
//
// because now the 3 times wider apart samples contain the average of the
// previous 3 close samples in previous cascade, their average effectivelly
// equals to the average of 9 close samples
//
// to harness the power behind this principle, we use multiple cascades:
// cascade 0 will yield a 1 * 3 = 3 (3 ^ 1) texel wide blur
// cascade 1 will yield a 3 * 3 = 9 (3 ^ 2) texels wide blur
// cascade 2 will yield a 9 * 3 = 27 (3 ^ 3) texels wide blur
// cascade 3 will yield a 27 * 3 = 81 (3 ^ 4) texels wide blur
// cascade 4 will yield a 81 * 3 = 243 (3 ^ 5) texels wide blur
// cascade 5 will yield a 243 * 3 = 729 (3 ^ 6) texels wide blur
//
// if we also factor in the 1.5 step multiplier, the radius of the achieved blur
// is actually even wider
//
// futher more, to achieve smooth blur instead of box blur, we apply some
// cascades 2 or more times - this not only turns the rectangular convolution
// into smooth convolution, but also widens the effective radius of
// the convolution
//
// * why applying a rectangular convolution multiple times yields smoothness?
//
// mathematically speaking, convolution shares a lot in common with sumation
// or multiplication: it is *commutative* and *associative*
//
// if we denote * as the convolution operation, the following statements are
// both true:
// a * b = b * a
// a * (b * c) = (a * b) * c
//
// what that means is that if we're convolving N signals, the convolution
// order doesn't matter at all
// a * b * c * d * e * f = f * c * b * e * d * a
//
// more than that, convolving any subsets from the N signals and then taking the
// resulted convolutions of those subsets and convolve them afterwards is the
// same of convolving all the N signals one after another in any order
// (a * b * c) * (d * e * f) = a * b * c * d * e * f
//
// for us, it means that if we have a signal s and a rectangular kernel r, the
// following is true:
// s * r * r * r = (r * r * r) * s
//
// in other words, convolving the signal with consecutive rectangulars is the
// same as convolving the rectangulars first and convolving the resulting kernel
// with our signal
//
// but what happens when you convolve a rectangular with itself?
// -> a trapezoid kernel emerges
//
// and what if we convolve the trapezoid kernel with another rectangular?
// -> an *almost* gaussian kernel emerges
//
// and if we keep on convolving with a rectangular?
// -> the resulting kernel starts to approximate a gaussian kernel with each
// rectangular convolution
//
// it will never reach a perfect gaussian shape, but for our application is
// good enough
//
// in practice, convolving with 3 rectangulars produces a very smooth result
// and that's all we need to approximate the convolution with a gaussian kernel
// -------------------------------------------------------------------------- //

float3 HBlur(in float2 texcoord : TEXCOORD, float blurSampleOffset, sampler srcSampler) {
    float offset = ___SCALED_BUFFER_SIZE_DIVIDER_DIVIDER_COMPENSATION_OFFSET___.x * blurSampleOffset * LSPOIrrEffectRadius;

    float3 color = tex2D(srcSampler, texcoord).rgb; // center
    color += tex2D(srcSampler, float2(texcoord.x - offset, texcoord.y)).rgb; // left-center
    color += tex2D(srcSampler, float2(texcoord.x + offset, texcoord.y)).rgb; // right-center
    color *= ___ONE_THIRD___;

    return color;
}

float3 VBlur(in float2 texcoord : TEXCOORD, float blurSampleOffset, sampler srcSampler) {
    float offset = ___SCALED_BUFFER_SIZE_DIVIDER_DIVIDER_COMPENSATION_OFFSET___.y * blurSampleOffset * LSPOIrrEffectRadius;

    float3 color = tex2D(srcSampler, texcoord).rgb; // center
    color += tex2D(srcSampler, float2(texcoord.x, texcoord.y - offset)).rgb; // center-bottom
    color += tex2D(srcSampler, float2(texcoord.x, texcoord.y + offset)).rgb; // center-top
    color *= ___ONE_THIRD___;

    return color;
}

// -------------------------------------------------------------------------- //
// cascade 0
// -------------------------------------------------------------------------- //

float3 HBlurC0BBPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from backbuffer, writes to HBlurTex
    return HBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_0___, ReShadeBackBufferSRGBSampler);
}

float3 HBlurC0PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from VBlurTex, writes to HBlurTex
    return HBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_0___, VBlurSampler);
}

float3 VBlurC0PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from HBlurTex, writes to VBlurTex
    return VBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_0___, HBlurSampler);
}

// -------------------------------------------------------------------------- //
// cascade 1
// -------------------------------------------------------------------------- //

float3 HBlurC1PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from VBlurTex, writes to HBlurTex
    return HBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_1___, VBlurSampler);
}

float3 VBlurC1PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from HBlurTex, writes to VBlurTex
    return VBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_1___, HBlurSampler);
}

// -------------------------------------------------------------------------- //
// cascade 2
// -------------------------------------------------------------------------- //

float3 HBlurC2PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from VBlurTex, writes to HBlurTex
    return HBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_2___, VBlurSampler);
}

float3 VBlurC2PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from HBlurTex, writes to VBlurTex
    return VBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_2___, HBlurSampler);
}

// -------------------------------------------------------------------------- //
// cascade 3
// -------------------------------------------------------------------------- //

float3 HBlurC3PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from VBlurTex, writes to HBlurTex
    return HBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_3___, VBlurSampler);
}

float3 VBlurC3PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from HBlurTex, writes to VBlurTex
    return VBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_3___, HBlurSampler);
}

// -------------------------------------------------------------------------- //
// cascade 4
// -------------------------------------------------------------------------- //

float3 HBlurC4PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from VBlurTex, writes to HBlurTex
    return HBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_4___, VBlurSampler);
}

float3 VBlurC4PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from HBlurTex, writes to VBlurTex
    return VBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_4___, HBlurSampler);
}

// -------------------------------------------------------------------------- //
// cascade 5
// -------------------------------------------------------------------------- //

float3 HBlurC5PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from VBlurTex, writes to HBlurTex
    return HBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_5___, VBlurSampler);
}

float3 VBlurC5PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from HBlurTex, writes to VBlurTex
    return VBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_5___, HBlurSampler);
}

// -------------------------------------------------------------------------- //
// blur copying routines
// -------------------------------------------------------------------------- //

float3 CopyVBlurPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    return tex2D(VBlurSampler, texcoord.xy).rgb;
}

#if LSPOIRR_AUTO_GAIN_ENABLED

// -------------------------------------------------------------------------- //
// hashing routines
// -------------------------------------------------------------------------- //

float3 Hash31(in float p) {
   float3 p3 = frac(p * float3(0.1031, 0.1030, 0.0973));
   p3 += dot(p3, p3.yzx + 33.33);
   return frac((p3.xxy + p3.yzz) * p3.zyx); 
}

float3 Hash32(in float2 p) {
    float3 p3 = frac(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return frac((p3.xxy + p3.yzz) * p3.zyx);
}

float3 Hash33(in float3 p3) {
    p3 = frac(p3 * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return frac((p3.xxy + p3.yxx) * p3.zyx);
}

float3 Hash32UV(in float2 uv, in float step) {
    return Hash33(float3(uv * 14353.45646, (FrameTime % 100.0) * step));
}

#endif // LSPOIRR_AUTO_GAIN_ENABLED
    
// -------------------------------------------------------------------------- //
// blending routines
// -------------------------------------------------------------------------- //

#if ___CUSTOM_OCCLUSSION_IRRADIANCE_NEUTRAL_POINT

float MultiplyBlend(in float a, in float b) {
    return a * b;
}

float3 MultiplyBlend(in float3 a, in float3 b) {
    return float3(
        MultiplyBlend(a.r, b.r),
        MultiplyBlend(a.g, b.g),
        MultiplyBlend(a.b, b.b)
    );
}

float ScreenBlend(in float a, in float b) {
    return 1.0 - (1.0 - a) * (1.0 - b);
}

float3 ScreenBlend(in float3 a, in float3 b) {
    return float3(
        ScreenBlend(a.r, b.r),
        ScreenBlend(a.g, b.g),
        ScreenBlend(a.b, b.b)
    );
}

float DodgeBlend(in float a, in float b) {
    return a / (1.0 - b);
}

float3 DodgeBlend(in float3 a, in float3 b) {
    return float3(
        DodgeBlend(a.r, b.r),
        DodgeBlend(a.g, b.g),
        DodgeBlend(a.b, b.b)
    );
}

float DodgeScreenBlend(in float a, in float b, in float pieceWiseBreakPoint) {
    float t = (b - pieceWiseBreakPoint) / (1.0 - pieceWiseBreakPoint);

    t *= 2.0;
    t = saturate(t);
    t = smoothstep(0.0, 1.0, t);

#if 0 // debug interpolant
    return t;
#else
    return lerp(DodgeBlend(a, b), ScreenBlend(a, b), t);
#endif
}

#endif // ___CUSTOM_OCCLUSSION_IRRADIANCE_NEUTRAL_POINT

float OverlayBlend(in float a, in float b) {
    [branch]
    if (a < 0.5) {
        return a * b * 2.0;
    } else {
        return 1.0 - (1.0 - a) * (1.0 - b) * 2.0;
    }
}

float3 OverlayBlend(in float3 a, in float3 b) {
    return float3(
        OverlayBlend(a.r, b.r),
        OverlayBlend(a.g, b.g),
        OverlayBlend(a.b, b.b)
    );
}

float ScaleOcclusionAndIrradiance(in float occlusionIrradianceOverlay, in float occlusionIntensity, in float irradianceIntensity) {
    // lerp(0.5, occlusionIrradianceOverlay, xxxxIntensity)
    return 0.5 + (occlusionIrradianceOverlay - 0.5) * (occlusionIrradianceOverlay < 0.5 ? occlusionIntensity : irradianceIntensity);
}

float3 ScaleOcclusionAndIrradiance(in float3 occlusionIrradianceOverlay, in float occlusionIntensity, in float irradianceIntensity) {
    return float3(
        ScaleOcclusionAndIrradiance(occlusionIrradianceOverlay.r, occlusionIntensity, irradianceIntensity),
        ScaleOcclusionAndIrradiance(occlusionIrradianceOverlay.g, occlusionIntensity, irradianceIntensity),
        ScaleOcclusionAndIrradiance(occlusionIrradianceOverlay.b, occlusionIntensity, irradianceIntensity)
    );
}

#if ___CUSTOM_OCCLUSSION_IRRADIANCE_NEUTRAL_POINT

float OverlayExtendedBlend(in float a, in float b, in float pieceWiseBreakPoint) {
    [branch]
    if (b < pieceWiseBreakPoint) {
        float normalizer = 1.0 / pieceWiseBreakPoint;
        return MultiplyBlend(a, b * normalizer);

#if 0
        return 0;
#endif
    } else {
        float offset = 1.0 - pieceWiseBreakPoint;
        float normalizer = 1.0 / offset;
#if 1
        return ScreenBlend(a, (b - pieceWiseBreakPoint) * normalizer);
#endif

#if 0
        return DodgeBlend(a, (b - pieceWiseBreakPoint) * normalizer);
#endif

#if 0
        return DodgeScreenBlend(a, (b - pieceWiseBreakPoint) * normalizer, pieceWiseBreakPoint);
#endif

#if 0
        return 1;
#endif
    }
}

float3 OverlayExtendedBlend(in float3 a, in float3 b, in float pieceWiseBreakPoint) {
    return float3(
        OverlayExtendedBlend(a.r, b.r, pieceWiseBreakPoint),
        OverlayExtendedBlend(a.g, b.g, pieceWiseBreakPoint),
        OverlayExtendedBlend(a.b, b.b, pieceWiseBreakPoint)
    );
}

#endif // ___CUSTOM_OCCLUSSION_IRRADIANCE_NEUTRAL_POINT

#if LSPOIRR_AUTO_GAIN_ENABLED

// -------------------------------------------------------------------------- //
// auto-gain routines
// -------------------------------------------------------------------------- //

float ComputeBlurMaxChannel(in float2 texcoord) {
#if 0
    // debug
    if (1) {
        return tex2D(ReShadeBackBufferSRGBSampler, texcoord).r;
    }
#endif

    float maxChannel = 0;
    float2 uv = float2(___MAX_BLUR_POS_SAMPLE_START___, ___MAX_BLUR_POS_SAMPLE_START___);

    [unroll]
    for (int i = 0; i < ___MAX_BLUR_NUM_SAMPLES___; i++) {
        uv.x = ___MAX_BLUR_POS_SAMPLE_START___;

        [unroll]
        for (int j = 0; j < ___MAX_BLUR_NUM_SAMPLES___; j++) {
            maxChannel = max(maxChannel, COMPUTE_COLOR_MAX_CHANNEL(tex2D(VBlurSampler, uv).rgb));
            uv.x += ___MAX_BLUR_POS_SAMPLE_STEP___;
        }

        uv.y += ___MAX_BLUR_POS_SAMPLE_STEP___;
    }

#if 0 // debug history persistence
    maxChannel = Hash32UV(texcoord, ___HASH_TIME_STEP___).r;
#endif

    maxChannel *= ___MAX_CHANNEL_COMPENSATION___; // compensate for the sampling error that emerges from using just the center of the image

    return maxChannel;
}

float3 DrawBlurMaxSamplesPositions(in float2 texcoord) {
    float3 color = 0;
    float2 uv = float2(___MAX_BLUR_POS_SAMPLE_START___, ___MAX_BLUR_POS_SAMPLE_START___);

    [unroll]
    for (int i = 0; i < ___MAX_BLUR_NUM_SAMPLES___; i++) {
        uv.x = ___MAX_BLUR_POS_SAMPLE_START___;

        [unroll]
        for (int j = 0; j < ___MAX_BLUR_NUM_SAMPLES___; j++) {
            float xDist = uv.x - texcoord.x;
            xDist *= ReShade::AspectRatio;
            float yDist = uv.y - texcoord.y;
            float dist = xDist * xDist + yDist * yDist;
            dist = sqrt(dist);

            dist = 1.0 - dist;
            dist = saturate(dist);
            dist = pow(dist, 100.0);

            dist = dist > 0.5 ? 0.5 : 0;
            color += float3(dist, 0, 0);
            uv.x += ___MAX_BLUR_POS_SAMPLE_STEP___;
        }

        uv.y += ___MAX_BLUR_POS_SAMPLE_STEP___;
    }

    return color;
}

float ComputeBlurGain(in float blurMax, in float reciptocalThreshold) {
    [branch]
    if (blurMax <= reciptocalThreshold) {
        return blurMax / (reciptocalThreshold * reciptocalThreshold);
    } else {
        return 1.0 / blurMax;
    }
}

float ComputeBlurMaxPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR {
    return ComputeBlurMaxChannel(texcoord);
}

#endif // LSPOIRR_AUTO_GAIN_ENABLED

// -------------------------------------------------------------------------- //

float3 LSPOIrrPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR {
    // sample scene color
    float2 screenUV = texcoord.xy;
    float3 color = tex2D(ReShadeBackBufferSRGBSampler, screenUV).rgb;

    // early exit
    [branch]
    if (!LSPOIrrEffectEnabled) {
        return color;
    }

    // we need the original color later
    float3 finalColor = color;

    // sample blur as overlay color
    float3 overlayColor = tex2D(VBlurSampler, screenUV).rgb;

    // debug
    [branch]
    if (LSPOIrrDebugType == ___LSPOIRR_DEBUG_RAW_BLUR___) {
        return overlayColor;
    }

    // saturate the overlay color
    overlayColor = SATURATE_COLOR(overlayColor, LSPOIrrEffectSaturation);

    // debug
    [branch]
    if (LSPOIrrDebugType == ___LSPOIRR_DEBUG_SATURATED_BLUR___) {
        return overlayColor;
    }

    // debug
    [branch]
    if (LSPOIrrDebugType == ___LSPOIRR_DEBUG_OCCLUSION_IRRADIANCE_MAP___) {
        return lerp(color, 1.0 - step(overlayColor, 0.5), 0.65);
    }

#if LSPOIRR_AUTO_GAIN_ENABLED

    // debug
    [branch]
    if (LSPOIrrDebugType == ___LSPOIRR_DEBUG_BLUR_MAX_SAMPLES_POSITIONS___) {
        float3 samplesPositionColor = DrawBlurMaxSamplesPositions(screenUV);
        return samplesPositionColor.r < 0.01 ? color : samplesPositionColor;
    }

    // get the damped blur max from history buffer
    float blurMax = tex2D(BlurMaxHistorySampler, screenUV).r;

    // debug
    [branch]
    if (LSPOIrrDebugType == ___LSPOIRR_DEBUG_BLUR_MAX___) {
        return float3(blurMax, blurMax, blurMax);
    }

    float blurGain = ComputeBlurGain(blurMax, LSPOIRR_BLUR_MAX_RECIPROCAL_THRESHOLD);

    // clamp it
    blurGain = clamp(blurGain, 1.0, 4.0); // 4.0 was established empirically

    // debug
    [branch]
    if (LSPOIrrDebugType == ___LSPOIRR_DEBUG_BLUR_GAIN___) {
        return float3(blurGain, blurGain, blurGain);
    }

    // factor in the auto-gain amount
    blurGain = lerp(1.0, blurGain, LSPOIrrAutoGain);

    // apply auto gain to overlay
    overlayColor *= blurGain;

    // debug
    [branch]
    if (LSPOIrrDebugType == ___LSPOIRR_DEBUG_GAINED_BLUR___) {
        return overlayColor;
    }

#endif // LSPOIRR_AUTO_GAIN_ENABLED

    // scale the overlay occlusion and irradiance components independently
    overlayColor = ScaleOcclusionAndIrradiance(overlayColor, LSPOIrrOcclusionIntensity, LSPOIrrIrradianceIntensity);

    // debug
    [branch]
    if (LSPOIrrDebugType == ___LSPOIRR_DEBUG_SCALED_BLUR___) {
        return overlayColor;
    }

    // overlay the saturated overlay color onto the scene color
#if ___CUSTOM_OCCLUSSION_IRRADIANCE_NEUTRAL_POINT
    finalColor = OverlayExtendedBlend(finalColor, overlayColor, LSPOIrrOcclusionIrradianceNeutralPoint);
#else // ___CUSTOM_OCCLUSSION_IRRADIANCE_NEUTRAL_POINT
    finalColor = OverlayBlend(finalColor, overlayColor);
#endif // ___CUSTOM_OCCLUSSION_IRRADIANCE_NEUTRAL_POINT

    // compute recovery overlay
    float3 recoveryOverlayColor = tex2D(ShortBlurSampler, screenUV).rgb;
    recoveryOverlayColor = SATURATE_COLOR(recoveryOverlayColor, 0.0);
    recoveryOverlayColor = 1.0 - recoveryOverlayColor;

    // debug
    [branch]
    if (LSPOIrrDebugType == ___LSPOIRR_DEBUG_RECOVERY_BLUR___) {
        return recoveryOverlayColor;
    }

    // debug
    [branch]
    if (LSPOIrrDebugType == ___LSPOIRR_DEBUG_RECOVERY_OCCLUSION_IRRADIANCE_MAP___) {
        return lerp(color, 1.0 - step(recoveryOverlayColor, 0.5), 0.65);
    }
    // scale the recovery overlay
    recoveryOverlayColor = (recoveryOverlayColor - 0.5) * LSPOIrrOcclusionIrradianceRecovery + 0.5;

    // scale the overlay occlusion and irradiance components independently
    recoveryOverlayColor = ScaleOcclusionAndIrradiance(recoveryOverlayColor, LSPOIrrIrradianceIntensity, LSPOIrrOcclusionIntensity);

    // debug
    [branch]
    if (LSPOIrrDebugType == ___LSPOIRR_DEBUG_SCALED_RECOVERY_BLUR___) {
        return recoveryOverlayColor;
    }

    // overlay the recovery overlay color onto the scene color  
    finalColor = OverlayBlend(finalColor, recoveryOverlayColor);

    // debug
    [branch]
    if (LSPOIrrDebugType == ___LSPOIRR_DEBUG_NO_TONING___) {
        return finalColor;
    }

    // apply gamma
    finalColor = pow(max(0.0, finalColor), LSPOIrrGamma);

    // apply gain
    finalColor *= LSPOIrrGain;

    // apply contrast
    finalColor = (finalColor - 0.5) * LSPOIrrContrast + 0.5;

    // apply saturation
    finalColor = SATURATE_COLOR(finalColor, LSPOIrrSaturation);

    // back-up the final color for comparison
    float3 originalFinalColor = finalColor;

    // debug
    [branch]
    if (LSPOIrrDebugType == ___LSPOIRR_DEBUG_NO_INTENSITY___) {
        return finalColor;
    }

    // apply intensity
    finalColor = lerp(color, finalColor, LSPOIrrEffectIntensity);

    return finalColor;
}

// -------------------------------------------------------------------------- //

#if LSPOIRR_AUTO_GAIN_ENABLED

float BlendBlurMaxIntoHistoryPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR {
    float blurMax = tex2D(BlurMaxSampler, texcoord).r;
    float blurMaxHistory = tex2D(BlurMaxHistorySampler, texcoord).r;

    // apply Exponential Moving Average Infinite Impulse Response low-pass filter
    blurMaxHistory = lerp(blurMaxHistory, blurMax, LSPOIRR_AUTO_GAIN_SPEED);

    return blurMaxHistory;
}

float CopyBlurMaxHistoryTempPS(in float4 vpos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR {
    return tex2D(BlurMaxHistoryTempSampler, texcoord).r;
}

#endif // LSPOIRR_AUTO_GAIN_ENABLED

// -------------------------------------------------------------------------- //

technique FGFXLSPOIrr <
    ui_label = "FGFX::LSPOIrr";
    ui_tooltip =
        "+------------------------------------------------------------------------+\n"
        "|-=[ FGFX::LSPOIrr - Large Scale Perceptual Obscurance and Irradiance ]=-|\n"
        "+------------------------------------------------------------------------+\n"
        "\n"

        "The Large Scale Perceptual Obscurance and Irradiance is a post-processing\n"
        "effect that attempts to inject obscurance and irradiance in the scene at a\n"
        "large scale (low frequency).\n"
        "\n"

        "Due to the fact that the effect operates on the low frequencies of the\n"
        "input image, the effect often plays just on a perceptual level rather\n"
        "than being an actual physically correct rendition of scene obscurrance and\n"
        "irradiance.\n"
        "\n"

        "* How does it work? *\n"
        "\n"

        "The concept sitting at the core of the effect is really simple and relies\n"
        "on some assumptions that more than often are correct. If we take an\n"
        "arbitrary image, blur it with a large gaussian and then overlay (as in\n"
        "standard overlay blending operation) the blurred image onto the original\n"
        "image, we get the illusion that some statistically-correct occlusion and\n"
        "irradiance shows up in the image.\n"
        "\n"

        "* Why does it work? *\n"
        "\n"

        "The effect relies on the statistical fact that if there's a part in the\n"
        "input image that is predominantly dark, chances are that the entire part\n"
        "contains objects that obscure each other, reducing the amount of light\n"
        "radiated in that particular area.\n"
        "\n"

        "Admittedly, the opposite is also true: If a part of the input image is\n"
        "predominantly bright, chances are that the objects in that part of the\n"
        "image have an increased amount of light inter-radiation, as a result of\n"
        "objects in that part of the image bouncing light to each other.\n"
        "\n"

        "* What about performance? *\n"
        "\n"

        "The implementation uses the Fast Cascaded Separable Blur technique,\n"
        "which is blazing-fast. The entire effect executes in less than 0.35 ms\n"
        "on a machine with a i7-8700K running at 4.2Ghz CPU and a GTX 1080Ti\n"
        "running at 2000Mhz GPU in 2560x1440 resolution.\n"
        "\n"

        "And if you think you don't need the auto-gain feature (by disabling it\n"
        "in preprocessor definitions), you can cut 0.05 ms and get the total\n"
        "execution time down to 0.3 ms.\n"
        "\n"

        "* Where is this effect best placed? *\n"
        "\n"

        "Since the effect addresses the lighting in the scene, it's best put\n"
        "after any Global Illumination technique like Ambient Occlusion,\n"
        "Obscurance, RTGI and before tone-mapping, film grain, color grading\n"
        "of any sort, bloom, CA or any lens & sensor effects.\n"
        "\n"
        

        "The Large Scale Perceptual Obscurance and Irradiance is written by\n"
        "Alex Tuduran.\n";
> {

// -------------------------------------------------------------------------- //
// back-buffer reduction
// -------------------------------------------------------------------------- //

    pass CopyBB {
        VertexShader = PostProcessVS;
        PixelShader  = CopyBBPS;
        RenderTarget = HalfBlurTex;
    }

    pass CopyHalf {
        VertexShader = PostProcessVS;
        PixelShader  = CopyHalfPS;
        RenderTarget = QuadBlurTex;
    }

    pass CopyQuad {
        VertexShader = PostProcessVS;
        PixelShader  = CopyQuadPS;
        RenderTarget = OctoBlurTex;
    }

    pass CopyOcto {
        VertexShader = PostProcessVS;
        PixelShader  = CopyOctoPS;
        RenderTarget = HexaBlurTex;
    }

// -------------------------------------------------------------------------- //
// blur cascades
// -------------------------------------------------------------------------- //

    pass CopyHexa {
        VertexShader = PostProcessVS;
        PixelShader  = CopyHexaPS;
        RenderTarget = VBlurTex;
    }

    
#if 1 // cascade 0 rectangular

    pass HBlurC0R {
        VertexShader = PostProcessVS;
        PixelShader  = HBlurC0PS;
        RenderTarget = HBlurTex;
    }

    pass VBlurC0R {
        VertexShader = PostProcessVS;
        PixelShader  = VBlurC0PS;
        RenderTarget = VBlurTex;
    }

#endif

#if 1 // cascade 0 smooth

    pass HBlurC0S {
        VertexShader = PostProcessVS;
        PixelShader  = HBlurC0PS;
        RenderTarget = HBlurTex;
    }

    pass VBlurC0S {
        VertexShader = PostProcessVS;
        PixelShader  = VBlurC0PS;
        RenderTarget = VBlurTex;
    }

#endif

#if 1 // cascade 0 super-smooth

    pass HBlurC0SS {
        VertexShader = PostProcessVS;
        PixelShader  = HBlurC0PS;
        RenderTarget = HBlurTex;
    }

    pass VBlurC0SS {
        VertexShader = PostProcessVS;
        PixelShader  = VBlurC0PS;
        RenderTarget = VBlurTex;
    }

#endif

#if 1 // cascade 1 rectangular

    pass HBlurC1R {
        VertexShader = PostProcessVS;
        PixelShader  = HBlurC1PS;
        RenderTarget = HBlurTex;
    }

    pass VBlurC1R {
        VertexShader = PostProcessVS;
        PixelShader  = VBlurC1PS;
        RenderTarget = VBlurTex;
    }

#endif

#if 0 // store short blur

    pass ShortBlur {
        VertexShader = PostProcessVS;
        PixelShader  = CopyVBlurPS;
        RenderTarget = ShortBlurTex;
    }

#endif

#if 1 // cascade 2 rectangular

    pass HBlurC2R {
        VertexShader = PostProcessVS;
        PixelShader  = HBlurC2PS;
        RenderTarget = HBlurTex;
    }

    pass VBlurC2R {
        VertexShader = PostProcessVS;
        PixelShader  = VBlurC2PS;
        RenderTarget = VBlurTex;
    }

#endif

#if 1 // store short blur

    pass ShortBlur {
        VertexShader = PostProcessVS;
        PixelShader  = CopyVBlurPS;
        RenderTarget = ShortBlurTex;
    }

#endif

#if 1 // cascade 2 smooth

    pass HBlurC2S {
        VertexShader = PostProcessVS;
        PixelShader  = HBlurC2PS;
        RenderTarget = HBlurTex;
    }

    pass VBlurC2S {
        VertexShader = PostProcessVS;
        PixelShader  = VBlurC2PS;
        RenderTarget = VBlurTex;
    }

#endif

#if LSPOIRR_CASCADE_3_ON // cascade 3 rectangular

    pass HBlurC3R {
        VertexShader = PostProcessVS;
        PixelShader  = HBlurC3PS;
        RenderTarget = HBlurTex;
    }

    pass VBlurC3R {
        VertexShader = PostProcessVS;
        PixelShader  = VBlurC3PS;
        RenderTarget = VBlurTex;
    }

#endif // LSPOIRR_CASCADE_3_ON

#if 1 // cascade 0 ultra-smooth

    pass HBlurC0US {
        VertexShader = PostProcessVS;
        PixelShader  = HBlurC0PS;
        RenderTarget = HBlurTex;
    }

    pass VBlurC0US {
        VertexShader = PostProcessVS;
        PixelShader  = VBlurC0PS;
        RenderTarget = VBlurTex;
    }

#endif

// -------------------------------------------------------------------------- //

#if LSPOIRR_AUTO_GAIN_ENABLED

    pass PassComputeBlurMax {
        VertexShader = PostProcessVS;
        PixelShader  = ComputeBlurMaxPS;
        RenderTarget = BlurMaxTex;
    }

    pass PassBlendBlurMaxIntoHistoryTemp {
        VertexShader = PostProcessVS;
        PixelShader  = BlendBlurMaxIntoHistoryPS;
        RenderTarget = BlurMaxHistoryTempTex;
    }

    pass CopyBlurMaxHistoryTemp {
        VertexShader = PostProcessVS;
        PixelShader = CopyBlurMaxHistoryTempPS;
        RenderTarget = BlurMaxHistoryTex;
    }

#endif // LSPOIRR_AUTO_GAIN_ENABLED

// -------------------------------------------------------------------------- //

    pass PassLSPOIrr {
        VertexShader = PostProcessVS;
        PixelShader  = LSPOIrrPS;
#if LSPOIRR_SRGB
        SRGBWriteEnable = true;
#endif // LSPOIRR_SRGB
    }

// -------------------------------------------------------------------------- //

} // technique

// -------------------------------------------------------------------------- //
