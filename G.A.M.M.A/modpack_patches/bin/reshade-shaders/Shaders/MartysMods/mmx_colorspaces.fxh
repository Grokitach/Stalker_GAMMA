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

namespace Colorspace
{

float3 srgb_to_linear(float3 srgb)
{
	return (srgb < 0.04045) ? srgb / 12.92 : pow(abs((srgb + 0.055) / 1.055), 2.4);
}

float3 linear_to_srgb(float3 lin)
{
	return (lin < 0.0031308) ? 12.92 * lin : 1.055 * pow(abs(lin), 0.41666666) - 0.055;
}

float get_srgb_luma(float3 srgb)
{
    float3 lin = srgb_to_linear(srgb);
    float luma = dot(lin, float3(0.2126729, 0.7151522, 0.072175)); //BT.709
    return (luma < 0.0031308) ? 12.92 * luma : 1.055 * pow(abs(luma), 0.41666666) - 0.055;
}

float3 rgb_to_hcv(in float3 RGB)
{
    RGB = saturate(RGB);
    float Epsilon = 1e-10;
        // Based on work by Sam Hocevar and Emil Persson
    float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0/3.0) : float4(RGB.gb, 0.0, -1.0/3.0);
    float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
    return float3(H, C, Q.x);
}

float3 rgb_to_hsl(in float3 RGB)
{
    float3 HCV = rgb_to_hcv(RGB);
    float L = HCV.z - HCV.y * 0.5;
    float S = HCV.y / (1.0000001 - abs(L * 2 - 1));
    return float3(HCV.x, S, L);
}

float3 hsl_to_rgb(in float3 HSL)
{
    HSL = saturate(HSL);
    float3 RGB = saturate(float3(abs(HSL.x * 6.0 - 3.0) - 1.0,2.0 - abs(HSL.x * 6.0 - 2.0),2.0 - abs(HSL.x * 6.0 - 4.0)));
    float C = (1 - abs(2 * HSL.z - 1)) * HSL.y;
    return (RGB - 0.5) * C + HSL.z;
}

float3 rgb_to_hsv(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 hsv_to_rgb(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float3 rgb_to_xyz(float3 RGB)
{
    static const float3x3 m =   float3x3( 0.4124564, 0.3575761, 0.1804375,        
                                          0.2126729, 0.7151522, 0.0721750,
                                          0.0193339, 0.1191920, 0.9503041);
    return mul(m, srgb_to_linear(RGB));
}


float3 xyz_to_rgb(float3 XYZ)
{
    static const float3x3 m = float3x3(  3.2404542, -1.5371385, -0.4985314,
                                        -0.9692660,  1.8760108,  0.0415560,
                                         0.0556434, -0.2040259,  1.0572252);
    return linear_to_srgb(mul(m, XYZ));
}

float3 xyz_to_cielab(float3 xyz)
{
    xyz *= float3(1.05211, 1.0, 0.91842); // reciprocal of °2 D65 reference values
    xyz = xyz > 0.008856 ? pow(xyz, 1.0/3.0) : xyz * 7.787037 + 4.0/29.0;
    float L = (116.0 * xyz.y) - 16.0;
    float a = 500.0 * (xyz.x - xyz.y);
    float b = 200.0 * (xyz.y - xyz.z);
    return float3(L, a, b) * 0.01; //assumed L = 100 earlier
}

float3 cielab_to_xyz(float3 lab)
{
    lab *= 100.0;
    float3 xyz;
    xyz.y = (lab.x + 16.0) / 116.0;
    xyz.x = xyz.y + lab.y / 500.0;
    xyz.z = xyz.y - lab.z / 200.0;
    xyz = xyz > 0.206897 ? xyz * xyz * xyz : 0.128418 * (xyz - 4.0/29.0);
    return max(0.0, xyz) * float3(0.95047, 1.0, 1.08883); // °2 D65 reference values
}

float3 rgb_to_cielab(float3 rgb) 
{ 
    return xyz_to_cielab(rgb_to_xyz(rgb)); 
}

float3 cielab_to_rgb(float3 lab) 
{ 
    return xyz_to_rgb(cielab_to_xyz(lab)); 
}

float3 xyz_to_lms(float3 xyz)
{
    return mul(xyz, float3x3(0.7328, 0.4296,-0.1624,           
                             -0.7036, 1.6975, 0.0061,
                            0.0030, 0.0136, 0.9834));
}

//https://bottosson.github.io/posts/oklab/
float3 rgb_to_oklab(float3 rgb)
{
    rgb = srgb_to_linear(rgb);
    float3 lms = mul(rgb, float3x3( 0.4122214708, 0.2119034982, 0.0883024619,
                                    0.5363325363, 0.6806995451, 0.2817188376,
                                    0.0514459929, 0.1073969566, 0.6299787005));



    lms = pow(abs(lms), 1.0/3.0);
    return mul(lms, float3x3(0.2104542553, 1.9779984951, 0.0259040371,
                             0.7936177850, -2.4285922050, 0.7827717662,
                            -0.0040720468, 0.4505937099, -0.8086757660));    
}

float3 oklab_to_rgb(float3 oklab)
{
    float3 lms = mul(oklab, float3x3(1,            1,             1,
	                                 0.3963377774, -0.1055613458, -0.0894841775,
	                                 0.2158037573, -0.0638541728, -1.2914855480));
    lms = lms * lms * lms;
    float3 rgb = mul(lms, float3x3(4.0767416621, -1.2684380046, -0.0041960863,
                                    -3.3077115913, 2.6097574011, -0.7034186147,
                                    0.2309699292, -0.3413193965, 1.7076147010));  
    return linear_to_srgb(rgb);  
}

} //Namespace
