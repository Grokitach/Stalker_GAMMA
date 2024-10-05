#ifndef HDR10_LENS_FLARE_H_
#define HDR10_LENS_FLARE_H_

#include "common.h"
#include "hdr10.h"

#define HDR10_FLARE_SRC_DX   (hdr10_flare_sparams.x)
#define HDR10_FLARE_SRC_DY   (hdr10_flare_sparams.y)
#define HDR10_FLARE_SRC_DXDY (hdr10_flare_sparams.xy)
#define HDR10_FLARE_HORZ     (hdr10_flare_sparams.z != 0.0)

/* --- HDR10 Lens Flare Uniforms --- */

uniform float4 hdr10_flare_sparams;

/* --- HDR10 Lens Flare Textures --- */

Texture2D s_hdr10_game;
Texture2D s_hdr10_halfres;

/* --- HDR10 Lens Flare Functions --- */

float3 HDR10_SampleGameTexel(float x, float y)
{
    return HDR10_sRGBToLinear(s_hdr10_game.Sample(smp_rtlinear, float2(x, y)).rgb);
}

float3 HDR10_SampleGameTexel(float2 tc)
{
    return HDR10_sRGBToLinear(s_hdr10_game.Sample(smp_rtlinear, tc).rgb);
}

float3 HDR10_SampleFlareTexel(float x, float y)
{
	return s_hdr10_halfres.Sample(smp_rtlinear, float2(x, y)).rgb;
}

float3 HDR10_SampleFlareTexel(float2 tc)
{
	return s_hdr10_halfres.Sample(smp_rtlinear, tc).rgb;
}

#endif
