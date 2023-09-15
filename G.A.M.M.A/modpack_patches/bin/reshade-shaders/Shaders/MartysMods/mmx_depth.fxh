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

//depth input handling

#ifndef RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
	#define RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN          0
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_REVERSED
	#define RESHADE_DEPTH_INPUT_IS_REVERSED             1
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
	#define RESHADE_DEPTH_INPUT_IS_LOGARITHMIC          0
#endif
#ifndef RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
	#define RESHADE_DEPTH_LINEARIZATION_FAR_PLANE       1000.0
#endif
#ifndef RESHADE_DEPTH_MULTIPLIER
	#define RESHADE_DEPTH_MULTIPLIER                    1	//mcfly: probably not a good idea, many shaders depend on having depth range 0-1
#endif
#ifndef RESHADE_DEPTH_INPUT_X_SCALE
	#define RESHADE_DEPTH_INPUT_X_SCALE                 1
#endif
#ifndef RESHADE_DEPTH_INPUT_Y_SCALE
	#define RESHADE_DEPTH_INPUT_Y_SCALE                 1
#endif
#ifndef RESHADE_DEPTH_INPUT_X_OFFSET
	#define RESHADE_DEPTH_INPUT_X_OFFSET                0   // An offset to add to the X coordinate, (+) = move right, (-) = move left
#endif
#ifndef RESHADE_DEPTH_INPUT_Y_OFFSET
	#define RESHADE_DEPTH_INPUT_Y_OFFSET                0   // An offset to add to the Y coordinate, (+) = move up, (-) = move down
#endif
#ifndef RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET
	#define RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET          0   // An offset to add to the X coordinate, (+) = move right, (-) = move left
#endif
#ifndef RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET
	#define RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET          0   // An offset to add to the Y coordinate, (+) = move up, (-) = move down
#endif

namespace Depth 
{

//this is maybe a bit awkward but the only easy way to create overloads without redundant code
#define TRANSFORM_LOG(x)        x
#define TRANSFORM_REVERSE(x)    x

#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
 #undef TRANSFORM_LOG
 #define TRANSFORM_LOG(x) ((x) * lerp((x), 1.0, 0.04975)) //extremely precise approximation that does not rely on transcendentals
#endif

#if RESHADE_DEPTH_INPUT_IS_REVERSED
 #undef TRANSFORM_REVERSE
 #define TRANSFORM_REVERSE(x) (1.0 - (x))
#endif

#define LINEARIZE_OVERLOAD(_type) _type linearize(_type x)    \
{                                                    \
    x *= RESHADE_DEPTH_MULTIPLIER;                   \
    x = TRANSFORM_LOG(x);                            \
    x = TRANSFORM_REVERSE(x);                        \
    x /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - x * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - 1.0); \
    return saturate(x);                              \
}           

LINEARIZE_OVERLOAD(float)
LINEARIZE_OVERLOAD(float2)
LINEARIZE_OVERLOAD(float3)
LINEARIZE_OVERLOAD(float4)

float2 correct_uv(float2 uv)
{
#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
    uv.y = 1.0 - uv.y;
#endif
    uv *= rcp(float2(RESHADE_DEPTH_INPUT_X_SCALE, RESHADE_DEPTH_INPUT_Y_SCALE));
#if RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET
	uv.x -= RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET * BUFFER_RCP_WIDTH;
#else
	uv.x -= RESHADE_DEPTH_INPUT_X_OFFSET / 2.000000001;
#endif
#if RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET
	uv.y += RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET * BUFFER_RCP_HEIGHT;
#else
	uv.y += RESHADE_DEPTH_INPUT_Y_OFFSET / 2.000000001;
#endif
    return uv;
}

float get_depth(float2 uv)
{
    return tex2Dlod(DepthInput, float4(correct_uv(uv), 0, 0)).x;
}

float get_linear_depth(float2 uv)
{
    float depth = get_depth(uv);
    depth = linearize(depth);
    return depth;
}

} //namespace


