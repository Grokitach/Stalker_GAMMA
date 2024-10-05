#ifndef HDR10_BLOOM_H_
#define HDR10_BLOOM_H_

#include "common.h"
#include "hdr10.h"

#define HDR10_BLOOM_SRC_DX  (hdr10_bloom_sparams.x)
#define HDR10_BLOOM_SRC_DY  (hdr10_bloom_sparams.y)
#define HDR10_BLOOM_HORZ    (hdr10_bloom_sparams.z != 0.0)

/* --- HDR10 Bloom Uniforms --- */

uniform float4 hdr10_bloom_sparams;

/* --- HDR10 Bloom Textures --- */

Texture2D s_hdr10_game;
Texture2D s_hdr10_halfres;

/* --- HDR10 Bloom Functions --- */

float3 HDR10_SampleGameTexel(float x, float y)
{
    return HDR10_sRGBToLinear(s_hdr10_game.Sample(smp_rtlinear, float2(x, y)).rgb);
}

float3 HDR10_SampleBloomTexel(float x, float y)
{
	return s_hdr10_halfres.Sample(smp_rtlinear, float2(x, y)).rgb;
}

#endif
