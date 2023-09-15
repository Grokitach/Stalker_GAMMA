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
#include "mmx_math.fxh"

namespace Deferred 
{
//normals, RG8 octahedral encoded 
texture NormalsTex              { Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RG8;       };
sampler sNormalsTex             { Texture = NormalsTex; };

//motion vectors, RGBA16F, XY = delta uv, Z = confidence, W = depth because why not
texture MotionVectorsTex        { Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RG16F;     };
sampler sMotionVectorsTex       { Texture = MotionVectorsTex; };

float3 get_normals(float2 uv)
{
    float2 encoded = tex2Dlod(sNormalsTex, uv, 0).xy;
    return -Math::octahedral_dec(encoded); //fixes bugs in RTGI, positive z gives better precision
}

float2 get_motion(float2 uv)
{
    return tex2Dlod(sMotionVectorsTex, uv, 0).xy;
}

float4 get_motion_wide(float2 uv)
{
    return tex2Dlod(sMotionVectorsTex, uv, 0);
}

}