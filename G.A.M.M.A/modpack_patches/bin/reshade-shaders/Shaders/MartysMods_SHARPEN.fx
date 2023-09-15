/*=============================================================================
                                                           
 d8b 888b     d888 888b     d888 8888888888 8888888b.   .d8888b.  8888888888 
 Y8P 8888b   d8888 8888b   d8888 888        888   Y88b d88P  Y88b 888        
     88888b.d88888 88888b.d88888 888        888    888 Y88b.      888        
 888 888Y88888P888 888Y88888P888 8888888    888   d88P  "Y888b.   8888888    
 888 888 Y888P 888 888 Y888P 888 888        8888888P"      "Y88b. 888        
 888 888  Y8P  888 888  Y8P  888 888        888 T88b         "888 888        
 888 888   "   888 888   "   888 888        888  T88b  Y88b  d88P 888        
 888 888       888 888       888 8888888888 888   T88b  "Y8888P"  8888888888                                                                 
                                                                            
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

===============================================================================

    Depth Enhanced Local Contrast Sharpen v1.0

    Author:         Pascal Gilcher

    More info:      https://martysmods.com
                    https://patreon.com/mcflypg
                    https://github.com/martymcmodding  	

=============================================================================*/

/*=============================================================================
	Preprocessor settings
=============================================================================*/

/*=============================================================================
	UI Uniforms
=============================================================================*/

uniform float SHARP_AMT <
	ui_type = "drag";
    ui_label = "Sharpen Intensity";
	ui_min = 0.0; 
    ui_max = 1.0;
> = 1.0;

uniform int QUALITY <
	ui_type = "combo";
    ui_label = "Sharpen Preset";
    ui_items = "Simple\0Advanced\0";
	ui_min = 0; 
    ui_max = 1;
> = 1;

/*=============================================================================
	Textures, Samplers, Globals, Structs
=============================================================================*/

//do NOT change anything here. "hurr durr I changed this and now it works"
//you ARE breaking things down the line, if the shader does not work without changes
//here, it's by design.

texture ColorInputTex : COLOR;
texture DepthInputTex : DEPTH;
sampler ColorInput 	{ Texture = ColorInputTex;  SRGBTexture = true; };
sampler DepthInput  { Texture = DepthInputTex; };

#include ".\MartysMods\mmx_global.fxh"
#include ".\MartysMods\mmx_depth.fxh"

struct VSOUT
{
    float4 vpos : SV_Position;
    float2 uv   : TEXCOORD0;
};

/*=============================================================================
	Functions
=============================================================================*/

float4 fetch_tap(VSOUT i, int2 offs)
{
    return float4(tex2Dlod(ColorInput, i.uv + offs * BUFFER_PIXEL_SIZE, 0).rgb, 1);    
}

float4 fetch_tap_w_depth(VSOUT i, int2 offs)
{
    return float4(tex2Dlod(ColorInput, i.uv + offs * BUFFER_PIXEL_SIZE, 0).rgb, Depth::get_linear_depth(i.uv + offs * BUFFER_PIXEL_SIZE));
}

float3 soft_min(float3 a, float3 b)
{
    const float k = 1.0;
    float3 h = max(0, k - abs(a - b)) / k;
    return min(a, b) - h*h*h*k*(1.0/6.0);
}

/*=============================================================================
	Shader Entry Points
=============================================================================*/

VSOUT MainVS(in uint id : SV_VertexID)
{
    VSOUT o;
    FullscreenTriangleVS(id, o.vpos, o.uv); //use original fullscreen triangle VS
    return o;
}

void MainPS(in VSOUT i, out float3 o : SV_Target0)
{  
    const int2 offsets[4] = 
    {
        int2(1,0), int2(0,1), //primary
        int2(1,1), int2(1,-1) //aux      
    };

    float4 c = 0; 
    float4 kernel = 0;
    float3 tv = 0;
    float3 prev;

    [branch]
    if(QUALITY > 0)
    {
        c = fetch_tap_w_depth(i, int2(0, 0));
        kernel += float4(c.rgb, 1.0);
        prev = c.rgb;        

        [unroll]        
        for(int j = 0; j < 2; j++)
        {
            float4 t0 = fetch_tap_w_depth(i,  offsets[j]);
            float4 t1 = fetch_tap_w_depth(i, -offsets[j]);   
            float2 w = saturate(1 - 1000.0 * abs(c.w - float2(t0.w, t1.w)));
            kernel += float4(t0.rgb, 1) * w.x + float4(t1.rgb, 1) * w.y;

            tv += (t0.rgb - prev) * (t0.rgb - prev);
            prev = t0.rgb;
            tv += (t1.rgb - prev) * (t1.rgb - prev);
            prev = t1.rgb;

            t0 = fetch_tap_w_depth(i,  offsets[j + 2]);
            t1 = fetch_tap_w_depth(i, -offsets[j + 2]);    
            w = saturate(1 - 1000.0 * abs(c.w - float2(t0.w, t1.w))) * 0.5; //aux * 0.5
            kernel += float4(t0.rgb, 1) * w.x + float4(t1.rgb, 1) * w.y;

            tv += (t0.rgb - prev) * (t0.rgb - prev);
            prev = t0.rgb;
            tv += (t1.rgb - prev) * (t1.rgb - prev);
            prev = t1.rgb;        
        }

        tv /= 8.0;
    }
    else 
    {
        c = fetch_tap(i, int2(0, 0));
        kernel += float4(c.rgb, 1.0);
        prev = c.rgb;

        [unroll]
        for(int j = 0; j < 2; j++)
        {
            float4 t0 = fetch_tap(i,  offsets[j]);
            float4 t1 = fetch_tap(i, -offsets[j]);   
            kernel  += float4(t0.rgb, 1) + float4(t1.rgb, 1);

            tv += (t0.rgb - prev) * (t0.rgb - prev);
            prev = t0.rgb;
            tv += (t1.rgb - prev) * (t1.rgb - prev);
            prev = t1.rgb;
        }

        tv /= 3.0;
    }

    kernel.rgb /= kernel.w;
    tv = sqrt(tv);

    float3 v_sat = c.rgb - kernel.rgb;
    float3 k = v_sat < 0.0.xxx ? c.rgb : 1 - c.rgb;
    k /= abs(v_sat) + 1e-6;
    float min_k = min(min(k.x, k.y), k.z);

    float sharp_amt = 2 * saturate(SHARP_AMT);

    float3 sharpen = soft_min(k, sharp_amt);
    sharpen /= 1 + tv * 64.0;

    float3 sharpened = c.rgb + v_sat * sharpen * sharp_amt;

    const float3 lumc = float3(0.2126729, 0.7151522, 0.072175);
    float sharplum = dot(sharpened, lumc);
    float origlum = dot(c.rgb, lumc) + 1e-6;

    o = lerp(c.rgb / origlum * sharplum, sharpened, 0.5); //a little bit of chroma sharpen
}

/*=============================================================================
	Techniques
=============================================================================*/

technique MartyMods_Sharpen
<
    ui_label = "iMMERSE Sharpen";
    ui_tooltip =        
        "                             MartysMods - Sharpen                             \n"
        "                   MartysMods Epic ReShade Effects (iMMERSE)                  \n"
        "______________________________________________________________________________\n"
        "\n"

        "The Depth Enhanced Local Contrast Sharpen is a high quality sharpen effect for\n"
        "ReShade, which can enhance texture detail and reduce TAA blur.                \n"
        "\n"
        "\n"
        "Visit https://martysmods.com for more information.                            \n"
        "\n"       
        "______________________________________________________________________________";
>
{    
    pass
	{
		VertexShader = MainVS;
		PixelShader  = MainPS;  
        SRGBWriteEnable = true;
	}      
}