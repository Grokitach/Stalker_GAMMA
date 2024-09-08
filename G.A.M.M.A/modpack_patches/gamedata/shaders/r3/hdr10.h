#ifndef HDR10_H_
#define HDR10_H_

#define HDR_ST2084_MAX_NITS (10000.0f)

uniform float4 hdr_parameters1;
uniform float4 hdr_parameters2;

#define HDR_WHITEPOINT_NITS  (hdr_parameters1.x)
#define HDR_UI_NITS_SCALAR   (hdr_parameters1.y)
#define HDR_IS_ENABLED       (hdr_parameters1.z != 0.0)
#define HDR_IS_RENDERING_PDA (hdr_parameters1.w != 0.0)
#define HDR_COLORSPACE       (hdr_parameters2.x)

#define HDR_USE_COLORSPACE_REC709  (HDR_COLORSPACE == 0.0)
#define HDR_USE_COLORSPACE_DCIP3   (HDR_COLORSPACE == 1.0)
#define HDR_USE_COLORSPACE_REC2020 (HDR_COLORSPACE == 2.0)

// from: https://panoskarabelas.com/blog/posts/hdr_in_under_10_minutes/
// NOTE: this should be applied before any tonemapping/gamma correction/etc
float3 sRGBToHDR10(float3 color, float scalar)
{
    // just don't tonemap if HDR is disabled
    if (!HDR_IS_ENABLED) {
        return color;
    }

    // avoid NaNs
    color = max(0, color);
    // undo 2.2 gamma since input is gamma corrected and we want linear
    color = pow(color, 2.2);

    if (HDR_USE_COLORSPACE_DCIP3) {
        // Convert Rec.709 to DCI-P3 color space to broaden the palette
        // see: http://endavid.com/index.php?entry=79
        // see: https://tech.metail.com/introduction-colour-spaces-dci-p3/ (take the inv matrix)
        static const float3x3 color_xform_dcip3 = {
            {0.8224750f, 0.1773780f, 0.00000f},
            {0.0331548f, 0.9669350f, 0.00000f},
            {0.0171315f, 0.0724068f, 0.91083f}
        };
        color = mul(color_xform_dcip3, color);

    } else if (HDR_USE_COLORSPACE_REC2020) {
        // Convert Rec.709 to Rec.2020 color space to broaden the palette
        // see: https://www.itu.int/dms_pubrec/itu-r/rec/bt/R-REC-BT.2087-0-201510-I!!PDF-E.pdf p4
        static const float3x3 color_xform_rec2020 = {
            {0.6274040f, 0.3292820f, 0.0433136f},
            {0.0690970f, 0.9195400f, 0.0113612f},
            {0.0163916f, 0.0880132f, 0.8955950f}
        };
        color = mul(color_xform_rec2020, color);

    } else {
        // No color transform (keep in Rec.709/sRGB)
    }

    // Normalize HDR scene values ([0..>1] to [0..1]) for ST.2084 curve
    color *= HDR_WHITEPOINT_NITS * scalar / HDR_ST2084_MAX_NITS;

    // Apply ST.2084 (PQ curve) for HDR10 standard
    static const float m1 = 2610.0 / 4096.0 / 4;
    static const float m2 = 2523.0 / 4096.0 * 128;
    static const float c1 = 3424.0 / 4096.0;
    static const float c2 = 2413.0 / 4096.0 * 32;
    static const float c3 = 2392.0 / 4096.0 * 32;
    float3             cp = pow(abs(color), m1);
    color                 = pow((c1 + c2 * cp) / (1 + c3 * cp), m2);

    return color;
}

#endif
