/*=============================================================================

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
 
=============================================================================*/

#pragma once 

#include "mmx_global.fxh"

namespace Sampling 
{

//for LUTs, when the volumes are placed below each other
float4 sample_volume_trilinear(sampler s, float3 uvw, int3 size, int atlas_idx)
{
    uvw = saturate(uvw);
    uvw = uvw * size - uvw;
    float3 rcpsize = rcp(size);
    uvw.xy = (uvw.xy + 0.5) * rcpsize.xy;
    
    float zlerp = frac(uvw.z);
    uvw.x = (uvw.x + uvw.z - zlerp) * rcpsize.z;

    float2 uv_a = uvw.xy;
    float2 uv_b = uvw.xy + float2(1.0/size.z, 0);
    
    int atlas_size = tex2Dsize(s).y * rcpsize.y;
    uv_a.y = (uv_a.y + atlas_idx) / atlas_size;
    uv_b.y = (uv_b.y + atlas_idx) / atlas_size;

    return lerp(tex2Dlod(s, uv_a, 0), tex2Dlod(s, uv_b, 0), zlerp);
}

//tetrahedral volume interpolation
//also DX9 safe - emulated integers suck...
float4 sample_volume_tetrahedral(sampler s, float3 uvw, int3 size, int atlas_idx)
{    
    float3 p = saturate(uvw) * (size - 1);   //p += float3(1.0/4096.0, 0, 1.0/2048.0); 
    float3 c000 = floor(p); float3 c111 = ceil(p);
    float3 delta = p - c000;
    
    //work out the axes with most/least delta (min axis goes backwards from 111)
    float3 comp = delta.xyz > delta.yzx; 
    float3 minaxis = comp.zxy * (1.0 - comp);
    float3 maxaxis = comp * (1.0 - comp.zxy);   
    
    float maxv = dot(maxaxis, delta);
    float minv = dot(minaxis, delta);
    float medv = dot(1 - maxaxis - minaxis, delta);

    float4 w = float4(1, maxv, medv, minv);
    w.xyz -= w.yzw;

    //3D coords of the 2 dynamic interpolants in the lattice    
    int3 cmin = lerp(c111, c000, minaxis);
    int3 cmax = lerp(c000, c111, maxaxis);

    return  tex2Dfetch(s, int2(c000.x + c000.z * size.x, c000.y + size.y * atlas_idx)) * w.x      
          + tex2Dfetch(s, int2(cmax.x + cmax.z * size.x, cmax.y + size.y * atlas_idx)) * w.y
          + tex2Dfetch(s, int2(cmin.x + cmin.z * size.x, cmin.y + size.y * atlas_idx)) * w.z
          + tex2Dfetch(s, int2(c111.x + c111.z * size.x, c111.y + size.y * atlas_idx)) * w.w;
}

float4 tex3D(sampler s, float3 uvw, int3 size)
{
    return sample_volume_trilinear(s, uvw, size, 0);
}

//Optimized Bspline bicubic filtering
//FXC assembly: 37->25 ALU, 5->3 registers
//One texture coord known early, better for latency
float4 sample_bicubic(sampler s, float2 iuv, int2 size)
{
    float4 uv;
	uv.xy = iuv * size;

    float2 center = floor(uv.xy - 0.5) + 0.5;
	float4 d = float4(uv.xy - center, 1 + center - uv.xy);
	float4 d2 = d * d;
	float4 d3 = d2 * d;

    float4 o = d2 * 0.12812 + d3 * 0.07188; //approx |err|*255 < 0.2 < bilinear precision
	uv.xy = center - o.zw;
	uv.zw = center + 1 + o.xy;
	uv /= size.xyxy;

    float4 w = 0.16666666 + d * 0.5 + 0.5 * d2 - d3 * 0.3333333;
	w = w.wwyy * w.zxzx;

    return w.x * tex2Dlod(s, uv.xy, 0)
	     + w.y * tex2Dlod(s, uv.zy, 0)
		 + w.z * tex2Dlod(s, uv.xw, 0)
		 + w.w * tex2Dlod(s, uv.zw, 0);
}

float4 tex2Dbicub(sampler s, float2 iuv)
{
	return sample_bicubic(s, iuv, tex2Dsize(s));
}

float4 sample_biquadratic(sampler s, float2 iuv, int2 size)
{
	float2 q = frac(iuv * size);
	float2 c = (q * (q - 1.0) + 0.5) * rcp(size);
    float4 uv = iuv.xyxy + float4(-c, c);
	return (tex2Dlod(s, uv.xy, 0)
          + tex2Dlod(s, uv.xw, 0)
		  + tex2Dlod(s, uv.zw, 0)
		  + tex2Dlod(s, uv.zy, 0)) * 0.25;
}

float4 tex2Dbiquadratic(sampler s, float2 iuv)
{
    return sample_biquadratic(s, iuv, tex2Dsize(s));
}

/* //commented for now, causes potentially uninitialized variable error... for no reason...
float4 sample_tricubic(sampler s, float3 uvw, int3 size, int atlas_idx)
{
    //end condition, no way to handle this easily without potentially introducing wrong values    
    if(any(abs(uvw - 0.5) > 0.5 - rcp(size) * 0.5))
        return sample_volume_trilinear(s, uvw, size, atlas_idx);

    uvw = saturate(uvw) * size;
    float3 tc = floor(uvw - 0.5) + 0.5;

    float3 f = uvw - tc;
    float3 f2 = f * f;
    float3 f3 = f2 * f;

    float3 w0 = f2 - 0.5 * (f3 + f);
    float3 w1 = 1.5 * f3 - 2.5 * f2 + 1;
    float3 w3 = 0.5 * (f3 - f2);

    float3 s0 = w0 + w1; 

    float3 t0 = tc - 1 + w1 / s0;
    float3 t1 = tc + 1 + w3 / (1 - s0); 

    t0 /= size; t1 /= size;

    float4 X00 = lerp(sample_volume_trilinear(s, float3(t1.x, t0.y, t0.z), size, atlas_idx),
                      sample_volume_trilinear(s, float3(t0.x, t0.y, t0.z), size, atlas_idx), s0.x);

    float4 X10 = lerp(sample_volume_trilinear(s, float3(t1.x, t1.y, t0.z), size, atlas_idx),
                      sample_volume_trilinear(s, float3(t0.x, t1.y, t0.z), size, atlas_idx), s0.x);

    float4 XX0 = lerp(X10, X00,  s0.y);

    float4 X01 = lerp(sample_volume_trilinear(s, float3(t1.x, t0.y, t1.z), size, atlas_idx),
                      sample_volume_trilinear(s, float3(t0.x, t0.y, t1.z), size, atlas_idx), s0.x);

    float4 X11 = lerp(sample_volume_trilinear(s, float3(t1.x, t1.y, t1.z), size, atlas_idx),
                      sample_volume_trilinear(s, float3(t0.x, t1.y, t1.z), size, atlas_idx), s0.x);

    float4 XX1 = lerp(X11, X01,  s0.y);
    return lerp(XX1, XX0,  s0.z);
}
*/
}