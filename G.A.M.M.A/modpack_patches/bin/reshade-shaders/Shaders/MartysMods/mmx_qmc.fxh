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

//All things quasirandom
#include "mmx_global.fxh"

namespace QMC
{

#if _BITWISE_SUPPORTED
// improved golden ratio sequences v2 (P. Gilcher, 2023)
// https://www.shadertoy.com/view/csdGWX
float roberts1(in uint idx, in float seed)
{
    uint useed = uint(seed * exp2(32.0));
    uint phi = 2654435769u;
    return float(phi * idx + useed) * exp2(-32.0);
}

float2 roberts2(in uint idx, in float2 seed)
{
    uint2 useed = uint2(seed * exp2(32.0)); 
    uint2 phi = uint2(3242174889u, 2447445413u);
    return float2(phi * idx + useed) * exp2(-32.0);  
}

float3 roberts3(in uint idx, in float3 seed)
{
    uint3 useed = uint3(seed * exp2(32.0)); 
    uint3 phi = uint3(776648141u, 1412856951u, 2360945575u);
    return float3(phi * idx + useed) * exp2(-32.0);  
}
#else //DX9 is a jackass, nothing new...
//improved golden ratio sequences v1 (P. Gilcher, 2022)
//PG22 improved golden ratio sequences (https://www.shadertoy.com/view/mts3zN)
//these just use complementary coefficients and produce identical (albeit flipped)
//patterns, and run into numerical problems 2x-3x later than the canonical coefficients
float roberts1(float idx, float seed)   {return frac(seed + idx * 0.38196601125);}
float2 roberts2(float idx, float2 seed) {return frac(seed + idx * float2(0.245122333753, 0.430159709002));}
float3 roberts3(float idx, float3 seed) {return frac(seed + idx * float3(0.180827486604, 0.328956393296, 0.450299522098));}

#endif

float  roberts1(in uint idx) {return roberts1(idx, 0.5);}
float2 roberts2(in uint idx) {return roberts2(idx, 0.5.xx);}
float3 roberts3(in uint idx) {return roberts3(idx, 0.5.xxx);}

//this bins random numbers into sectors, to cover a 2D domain evenly
//given a known number of samples. For e.g. 4x4 samples it rescales all
//per-sample random numbers to make sure each lands in its own grid cell
//for non-square numbers the distribution is imperfect but still usable

//calculate the coefficients used in the operation
float3 get_stratificator(int n_samples)
{
    float3 stratificator;
    stratificator.xy = rcp(float2(ceil(sqrt(n_samples)), n_samples));
    stratificator.z = stratificator.y / stratificator.x;
    return stratificator;
}

float2 get_stratified_sample(float2 per_sample_rand, float3 stratificator, int i)
{
    float2 stratified_sample = frac(i * stratificator.xy + stratificator.xz * per_sample_rand);
    return stratified_sample;
}

} //namespace