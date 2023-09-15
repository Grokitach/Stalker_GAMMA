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
#include "mmx_depth.fxh"

#ifndef _MARTYSMODS_GLOBAL_FOV
 #define _MARTYSMODS_GLOBAL_FOV     60.0
#endif

//All sorts coordinate transforms for world/view/projection

namespace Camera
{

float depth_to_z(float depth)
{
    return depth * RESHADE_DEPTH_LINEARIZATION_FAR_PLANE + 1.0;
}

float z_to_depth(float z)
{
    float ifar = rcp(RESHADE_DEPTH_LINEARIZATION_FAR_PLANE);
    return z * ifar - ifar;
}

float2 proj_to_uv(float3 pos)
{
    //optimized math to simplify matrix mul
    static const float3 uvtoprojADD = float3(-tan(radians(_MARTYSMODS_GLOBAL_FOV) * 0.5).xx, 1.0) * BUFFER_ASPECT_RATIO.yxx;
    static const float3 uvtoprojMUL = float3(-2.0 * uvtoprojADD.xy, 0.0);
    static const float4 projtouv    = float4(rcp(uvtoprojMUL.xy), -rcp(uvtoprojMUL.xy) * uvtoprojADD.xy); 
    return (pos.xy / pos.z) * projtouv.xy + projtouv.zw;          
}

float3 uv_to_proj(float2 uv, float z)
{
    //optimized math to simplify matrix mul
    static const float3 uvtoprojADD = float3(-tan(radians(_MARTYSMODS_GLOBAL_FOV) * 0.5).xx, 1.0) * BUFFER_ASPECT_RATIO.yxx;
    static const float3 uvtoprojMUL = float3(-2.0 * uvtoprojADD.xy, 0.0);
    static const float4 projtouv    = float4(rcp(uvtoprojMUL.xy), -rcp(uvtoprojMUL.xy) * uvtoprojADD.xy); 
    return (uv.xyx * uvtoprojMUL + uvtoprojADD) * z;
}

float3 uv_to_proj(float2 uv)
{
    float z = depth_to_z(Depth::get_linear_depth(uv));
    return uv_to_proj(uv, z);
}

float3 uv_to_proj(float2 uv, sampler2D linearz, int mip)
{
    float z = tex2Dlod(linearz, float4(uv.xyx, mip)).x;
    return uv_to_proj(uv, z);
}

}