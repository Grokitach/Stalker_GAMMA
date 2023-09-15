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

#include "mmx_math.fxh"

namespace Noise 
{

//found using hash prospector, bias 0.10704308166917044
uint uint_hash(uint x)
{
    x ^= x >> 16;
    x *= 0x21f0aaad;
    x ^= x >> 15;
    x *= 0xd35a2d97;
    x ^= x >> 16;
    return x;
}

float rand1_from_uint(uint x)
{
    return float(x) * exp2(-32.0);
}

float2 rand2_from_uint(uint x)
{
    return float2((x >> uint2(0, 16)) & 0xFFFF) * exp2(-16.0);
}

float3 rand3_from_uint(uint x)
{
    return float3((x >> uint3(0, 10, 20)) & 0x3FF) * exp2(-10.0);
}

float3 rand4_from_uint(uint x)
{
    return float4((x >> uint4(0, 8, 16, 24)) & 0xFF) * exp2(-8.0);
}



//2x uniform [0, 1] -> 2x gaussian distributed with sigma 1   
float2 box_muller(float2 unirand01)
{
    float2 g; sincos(TAU * unirand01.x, g.x, g.y);
    return g * sqrt(-2.0 * log(unirand01.y));
}

//something I recently figured out - a random point on the ND hypersphere
//can be found by normalizing a vector of independent gaussian random numbers
//meaning that if you distribute a point uniformly on a ND hypersphere and
//scale it by the radius used in box muller, you get a vector of independent
//gaussian random numbers.
float3 box_muller(float3 unirand01)
{
    float3 g; sincos(TAU * unirand01.x, g.x, g.y);
    g.z = unirand01.y * 2.0 - 1.0;
    g.xy *= sqrt(1.0 - g.z * g.z);      
    return g * sqrt(-2.0 * log(unirand01.z));
}

}