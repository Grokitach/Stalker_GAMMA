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

static const float PI      = 3.1415926535;
static const float HALF_PI = 1.5707963268;
static const float TAU     = 6.2831853072;

static const float FLOAT32MAX = 3.402823466e+38f;
static const float FLOAT16MAX = 65504.0;

//Useful math functions

namespace Math 
{

/*=============================================================================
	Fast Math
=============================================================================*/

float fast_sign(float x){return x >= 0.0 ? 1.0 : -1.0;}
float2 fast_sign(float2 x){return x >= 0.0.xx ? 1.0.xx : -1.0.xx;}
float3 fast_sign(float3 x){return x >= 0.0.xxx ? 1.0.xxx : -1.0.xxx;}
float4 fast_sign(float4 x){return x >= 0.0.xxxx ? 1.0.xxxx : -1.0.xxxx;}

#if COMPUTE_SUPPORTED != 0
 #define fast_sqrt(_x) asfloat(0x1FBD1DF5 + (asint(_x) >> 1))
#else 
 #define fast_sqrt(_x) sqrt(_x) //not bitwise shenanigans :(
#endif

float fast_acos(float x)                      
{                                                   
    float o = -0.156583 * abs(x) + HALF_PI;
    o *= fast_sqrt(1.0 - abs(x));              
    return x >= 0.0 ? o : PI - o;                   
}

float2 fast_acos(float2 x)                      
{                                                   
    float2 o = -0.156583 * abs(x) + HALF_PI;
    o *= fast_sqrt(1.0 - abs(x));              
    return x >= 0.0.xx ? o : PI - o;                   
}

/*=============================================================================
	Geometry
=============================================================================*/

float4 get_rotator(float phi)
{
    float2 t;
    sincos(phi, t.x, t.y);
    return float4(t.yx, -t.x, t.y);
}

float4 merge_rotators(float4 ra, float4 rb)
{
    return ra.xyxy * rb.xxzz + ra.zwzw * rb.yyww;
}

float2 rotate_2D(float2 v, float4 r)
{
    return float2(dot(v, r.xy), dot(v, r.zw));
}

//this somewhat strange formulation actually results in far fewer instructions than baseline
float3x3 base_from_vector(float3 n)
{
    bool bestside = n.z < n.y;
    float3 n2 = bestside ? n.xzy : n;
    float3 k = (-n2.xxy * n2.xyy) * rcp(1.0 + n2.z) + float3(1, 0, 1);
    float3 u = float3(k.xy, -n2.x);
    float3 v = float3(k.yz, -n2.y);
    u = bestside ? u.xzy : u;
    v = bestside ? v.xzy : v;
    return float3x3(u, v, n);
}

float3 aabb_clip(float3 p, float3 mincorner, float3 maxcorner)
{
    float3 center = 0.5 * (maxcorner + mincorner);
    float3 range  = 0.5 * (maxcorner - mincorner);
    float3 delta = p - center;

    float3 t = abs(range / (delta + 1e-7));
    float mint = saturate(min(min(t.x, t.y), t.z));

    return center + delta * mint;
}

float2 aabb_hit_01(float2 origin, float2 dir)
{
    float2 hit_t = abs((dir < 0.0.xx ? origin : 1.0.xx - origin) / dir);
    return origin + dir * min(hit_t.x, hit_t.y);
}

float3 aabb_hit_01(float3 origin, float3 dir)
{
    float3 hit_t = abs((dir < 0.0.xxx ? origin : 1.0.xxx - origin) / dir);
    return origin + dir * min(min(hit_t.x, hit_t.y), hit_t.z);
}

bool inside_screen(float2 uv)
{
    return all(saturate(uv - uv * uv));
}

//TODO move to a packing header

//normalized 3D in, [0, 1] 2D out
float2 octahedral_enc(in float3 v) 
{
    float2 result = v.xy * rcp(dot(abs(v), 1));
    float2 t = (1.0 - abs(result.yx)) * fast_sign(result.xy);
    return (v.z < 0 ? t : result) * 0.5 + 0.5;
}

//[0, 1] 2D in, normalized 3D out
float3 octahedral_dec(float2 o) 
{
    o = o * 2.0 - 1.0;
    float3 v = float3(o.xy, 1.0 - abs(o.x) - abs(o.y));
    //v.xy = v.z < 0 ? (1.0 - abs(v.yx)) * fast_sign(v.xy) : v.xy;
    float t = saturate(-v.z);
    v.xy += v.xy >= 0.0.xx ? -t.xx : t.xx;
    return normalize(v);
}

float3x3 invert(float3x3 m)
{
    float3x3 adj;
    adj[0][0] =  (m[1][1] * m[2][2] - m[1][2] * m[2][1]); 
    adj[0][1] = -(m[0][1] * m[2][2] - m[0][2] * m[2][1]); 
    adj[0][2] =  (m[0][1] * m[1][2] - m[0][2] * m[1][1]);
    adj[1][0] = -(m[1][0] * m[2][2] - m[1][2] * m[2][0]);
    adj[1][1] =  (m[0][0] * m[2][2] - m[0][2] * m[2][0]); 
    adj[1][2] = -(m[0][0] * m[1][2] - m[0][2] * m[1][0]);
    adj[2][0] =  (m[1][0] * m[2][1] - m[1][1] * m[2][0]); 
    adj[2][1] = -(m[0][0] * m[2][1] - m[0][1] * m[2][0]); 
    adj[2][2] =  (m[0][0] * m[1][1] - m[0][1] * m[1][0]); 

    float det = dot(float3(adj[0][0], adj[0][1], adj[0][2]), float3(m[0][0], m[1][0], m[2][0]));
    return adj * rcp(det + (abs(det) < 1e-8));
}

float4x4 invert(float4x4 m)  
{
    float4x4 adj;
    adj[0][0] = m[2][1] * m[3][2] * m[1][3] - m[3][1] * m[2][2] * m[1][3] + m[3][1] * m[1][2] * m[2][3] - m[1][1] * m[3][2] * m[2][3] - m[2][1] * m[1][2] * m[3][3] + m[1][1] * m[2][2] * m[3][3];
    adj[0][1] = m[3][1] * m[2][2] * m[0][3] - m[2][1] * m[3][2] * m[0][3] - m[3][1] * m[0][2] * m[2][3] + m[0][1] * m[3][2] * m[2][3] + m[2][1] * m[0][2] * m[3][3] - m[0][1] * m[2][2] * m[3][3];
    adj[0][2] = m[1][1] * m[3][2] * m[0][3] - m[3][1] * m[1][2] * m[0][3] + m[3][1] * m[0][2] * m[1][3] - m[0][1] * m[3][2] * m[1][3] - m[1][1] * m[0][2] * m[3][3] + m[0][1] * m[1][2] * m[3][3];
    adj[0][3] = m[2][1] * m[1][2] * m[0][3] - m[1][1] * m[2][2] * m[0][3] - m[2][1] * m[0][2] * m[1][3] + m[0][1] * m[2][2] * m[1][3] + m[1][1] * m[0][2] * m[2][3] - m[0][1] * m[1][2] * m[2][3];

    adj[1][0] = m[3][0] * m[2][2] * m[1][3] - m[2][0] * m[3][2] * m[1][3] - m[3][0] * m[1][2] * m[2][3] + m[1][0] * m[3][2] * m[2][3] + m[2][0] * m[1][2] * m[3][3] - m[1][0] * m[2][2] * m[3][3];
    adj[1][1] = m[2][0] * m[3][2] * m[0][3] - m[3][0] * m[2][2] * m[0][3] + m[3][0] * m[0][2] * m[2][3] - m[0][0] * m[3][2] * m[2][3] - m[2][0] * m[0][2] * m[3][3] + m[0][0] * m[2][2] * m[3][3];
    adj[1][2] = m[3][0] * m[1][2] * m[0][3] - m[1][0] * m[3][2] * m[0][3] - m[3][0] * m[0][2] * m[1][3] + m[0][0] * m[3][2] * m[1][3] + m[1][0] * m[0][2] * m[3][3] - m[0][0] * m[1][2] * m[3][3];
    adj[1][3] = m[1][0] * m[2][2] * m[0][3] - m[2][0] * m[1][2] * m[0][3] + m[2][0] * m[0][2] * m[1][3] - m[0][0] * m[2][2] * m[1][3] - m[1][0] * m[0][2] * m[2][3] + m[0][0] * m[1][2] * m[2][3];

    adj[2][0] = m[2][0] * m[3][1] * m[1][3] - m[3][0] * m[2][1] * m[1][3] + m[3][0] * m[1][1] * m[2][3] - m[1][0] * m[3][1] * m[2][3] - m[2][0] * m[1][1] * m[3][3] + m[1][0] * m[2][1] * m[3][3];
    adj[2][1] = m[3][0] * m[2][1] * m[0][3] - m[2][0] * m[3][1] * m[0][3] - m[3][0] * m[0][1] * m[2][3] + m[0][0] * m[3][1] * m[2][3] + m[2][0] * m[0][1] * m[3][3] - m[0][0] * m[2][1] * m[3][3];
    adj[2][2] = m[1][0] * m[3][1] * m[0][3] - m[3][0] * m[1][1] * m[0][3] + m[3][0] * m[0][1] * m[1][3] - m[0][0] * m[3][1] * m[1][3] - m[1][0] * m[0][1] * m[3][3] + m[0][0] * m[1][1] * m[3][3];
    adj[2][3] = m[2][0] * m[1][1] * m[0][3] - m[1][0] * m[2][1] * m[0][3] - m[2][0] * m[0][1] * m[1][3] + m[0][0] * m[2][1] * m[1][3] + m[1][0] * m[0][1] * m[2][3] - m[0][0] * m[1][1] * m[2][3];

    adj[3][0] = m[3][0] * m[2][1] * m[1][2] - m[2][0] * m[3][1] * m[1][2] - m[3][0] * m[1][1] * m[2][2] + m[1][0] * m[3][1] * m[2][2] + m[2][0] * m[1][1] * m[3][2] - m[1][0] * m[2][1] * m[3][2];
    adj[3][1] = m[2][0] * m[3][1] * m[0][2] - m[3][0] * m[2][1] * m[0][2] + m[3][0] * m[0][1] * m[2][2] - m[0][0] * m[3][1] * m[2][2] - m[2][0] * m[0][1] * m[3][2] + m[0][0] * m[2][1] * m[3][2];
    adj[3][2] = m[3][0] * m[1][1] * m[0][2] - m[1][0] * m[3][1] * m[0][2] - m[3][0] * m[0][1] * m[1][2] + m[0][0] * m[3][1] * m[1][2] + m[1][0] * m[0][1] * m[3][2] - m[0][0] * m[1][1] * m[3][2];
    adj[3][3] = m[1][0] * m[2][1] * m[0][2] - m[2][0] * m[1][1] * m[0][2] + m[2][0] * m[0][1] * m[1][2] - m[0][0] * m[2][1] * m[1][2] - m[1][0] * m[0][1] * m[2][2] + m[0][0] * m[1][1] * m[2][2];

    float det = dot(float4(adj[0][0], adj[1][0], adj[2][0], adj[3][0]), float4(m[0][0], m[0][1],  m[0][2],  m[0][3]));
    return adj * rcp(det + (abs(det) < 1e-8));
}

#define chebyshev_weight(_mean, _variance, _sample) saturate((_variance) * rcp((_variance) + ((_sample) - (_mean)) * ((_sample) - (_mean))))

//DX9 safe float emulated bitfields... needed this for something that didn't work out
//so I dumped it here in case I need it again. Works up to 24 (25?) digits and must be init with 0!
bool bitfield_get(float bitfield, int bit)
{
	float state = floor(bitfield / exp2(bit)); //"right shift"
	return frac(state * 0.5) > 0.25; //"& 1"
}

void bitfield_set(inout float bitfield, int bit, bool value)
{
	bool is_set = bitfield_get(bitfield, bit);
	//bitfield += exp2(bit) * (is_set != value) * (value ? 1 : -1);
	bitfield += exp2(bit) * (value - is_set);	
}

}