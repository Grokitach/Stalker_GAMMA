/*=============================================================================

    Copyright (c) Pascal Gilcher. All rights reserved.

 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential

=============================================================================*/

#pragma once

/*===========================================================================*/

namespace Denoise
{

struct FilterSample
{
    float4 gbuffer;
    float4 val;
};

FilterSample fetch_sample(in float2 uv, sampler gi)
{
    FilterSample o;
    o.gbuffer = tex2Dlod(sGBufferTex, uv, 0);
    o.val     = tex2Dlod(gi, uv, 0);
    return o;
}

float3 srgb_to_acescg(float3 srgb)
{
    float3x3 m = float3x3(  0.613097, 0.339523, 0.047379,
                            0.070194, 0.916354, 0.013452,
                            0.020616, 0.109570, 0.869815);
    return mul(m, srgb);           
}

float3 acescg_to_srgb(float3 acescg)
{     
    float3x3 m = float3x3(  1.704859, -0.621715, -0.083299,
                            -0.130078,  1.140734, -0.010560,
                            -0.023964, -0.128975,  1.153013);
    return mul(m, acescg);            
}

float3 unpack_hdr(float3 color)
{
    color  = saturate(color);
    if(RT_USE_SRGB) color *= color;    
    if(RT_USE_ACESCG) color = srgb_to_acescg(color);
    color = color * rcp(1.04 - saturate(color));   
    
    return color;
}

float3 pack_hdr(float3 color)
{
    color =  1.04 * color * rcp(color + 1.0);   
    if(RT_USE_ACESCG) color = acescg_to_srgb(color);    
    color  = saturate(color);    
    if(RT_USE_SRGB) color = sqrt(color);   
    return color;     
}  

float4 atrous(in VSOUT i, in sampler gi, int iteration, int mode)
{
    FilterSample center = fetch_sample(i.uv, gi); 
    
    if(mode != 0 && mode != 4)
        return center.val;

    float4 kernel = float4(2,4,8,16); //float4(27,9,3,51);
    float4 sigma_z = 2;
    float4 sigma_n = 5;
    float4 sigma_v = exp2(iteration * 1.5 * 0.5);

    float4 weight_sum = 0.01;
    float4 value_sum = center.val * weight_sum;     

    float3 center_pos = Projection::uv_to_proj(i.uv, center.gbuffer.w);
    float3 eyevec = normalize(center_pos);
    float view_angle = dot(center.gbuffer.xyz, eyevec);

    float z_tolerance = rsqrt(1 + (1 - view_angle * view_angle) * rcp(view_angle * view_angle));
    sigma_z *= z_tolerance;

    int stacksize = round(tex2D(sStackCounterTex, i.uv).x); 
    float mip = clamp(log2(max(1, 8 - stacksize)), 0, 2); 

    float multi = exp2(mip);
    kernel *= multi;

    float expectederrormult = sqrt(RT_RAY_AMOUNT);//sqrt(RT_RAY_AMOUNT * stacksize);
    sigma_v *= expectederrormult * lerp(0.3, 3.0, saturate(RT_FILTER_DETAIL));   

    if(mode == 4) 
    {
        kernel = 3;
        mip = 0;
    }

    //float2 randjitter = frac(tex2Dfetch(sJitterTex, i.vpos.xy % 32).xy + iteration * 0.618)*2-1;

    for(float x = -1; x <= 1; x++)
    for(float y = -1; y <= 1; y++)
    {
        float2 uv = i.uv + (float2(x, y)) * kernel[iteration] * BUFFER_PIXEL_SIZE;
        FilterSample tap = fetch_sample(uv, gi);

        float sz = sigma_z[iteration];
        float sn = sigma_n[iteration];
        float sv = sigma_v[iteration];

        float wz = sz * 16.0 * (1.0 - tap.gbuffer.w / center.gbuffer.w);
        wz = saturate(0.5 - lerp(wz, abs(wz), 0.75));

        float wn = saturate(dot(tap.gbuffer.xyz, center.gbuffer.xyz) * (sn + 1) - sn); 

        float2 wi;
        wi.x = dot(0.3333, abs(pack_hdr(tap.val.rgb) - pack_hdr(center.val.rgb)));
        wi.y = abs(tap.val.w - center.val.w);
        wi *= sv;
        wi.y *= 1.5;
        wi = exp2(-wi * wi); 

        wn = lerp(wn, 1, wz * wz);

        float4 w = saturate(wi.xxxy * wn * wz);

        value_sum += tap.val * w;
        weight_sum += w;
    }

    float4 result = value_sum / weight_sum;
    return result;
}

} //Namespace