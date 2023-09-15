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

    SMAA with ad-hoc compute shader extensions (up to 70% faster than reference)

        - swap stencil with compute based selective processing
          pixels in each workgroup are reordered if an edge has been detected,
          and as such, the unprocessed pixels are grouped in warps, making
          sparse edges more efficient.
        
        - replace discard() to set up stencil with just writing 0 in edge detect,
          this allows to remove ClearRenderTargets

        - simplify code surrounding predication, and replace SMAA defines with
          inline ReShade definitions, as it is highly unlikely non-depth based
          SMAA will receive any more updates.

        - replace depth linearization copy by gather based depth linearization CS, 
          which is bypassed when predication is disabled or no edge detect selected

        - extended color edge detection by optionally using euclidean distance
          instead of max channel difference, this yields better results according
          to CMAA2 developers

    All rights to original SMAA code belong to their original authors.
    A copy of their license can be retrieved here:

        https://github.com/iryoku/smaa/blob/master/LICENSE.txt

    Author:         Pascal Gilcher

    More info:      https://martysmods.com
                    https://patreon.com/mcflypg
                    https://github.com/martymcmodding  	

=============================================================================*/

/*=============================================================================
	Preprocessor settings
=============================================================================*/

#ifndef SMAA_USE_EXTENDED_EDGE_DETECTION
 #define SMAA_USE_EXTENDED_EDGE_DETECTION 0
#endif

/*=============================================================================
	UI Uniforms
=============================================================================*/

#define SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR 2.0

uniform int EDGE_DETECTION_MODE < 
    ui_type = "combo";
	ui_items = "Luminance edge detection\0Color edge detection (max)\0Color edge detection (weighted)\0Depth edge detection\0";
	ui_label = "Edge Detection Type";
> = 1;

uniform float SMAA_THRESHOLD < 
    ui_type = "drag";
	ui_min = 0.05; ui_max = 0.20; ui_step = 0.001;
	ui_tooltip = "Edge detection threshold. If SMAA misses some edges try lowering this slightly.";
	ui_label = "Edge Detection Threshold";
> = 0.10;

uniform float SMAA_DEPTH_THRESHOLD < 
    ui_type = "drag";
	ui_min = 0.001; ui_max = 0.10; ui_step = 0.001;
	ui_tooltip = "Depth Edge detection threshold. If SMAA misses some edges try lowering this slightly.";
	ui_label = "Depth Edge Detection Threshold";
> = 0.01;

uniform int SMAA_MAX_SEARCH_STEPS < 
    ui_type = "slider";
	ui_min = 0; ui_max = 112;
	ui_label = "Max Search Steps";
	ui_tooltip = "Determines the radius SMAA will search for aliased edges.";
> = 32;

uniform int SMAA_MAX_SEARCH_STEPS_DIAG < 
    ui_type = "slider";
	ui_min = 0; ui_max = 25;
	ui_label = "Max Search Steps Diagonal";
	ui_tooltip = "Determines the radius SMAA will search for diagonal aliased edges";
> = 16;

uniform int SMAA_CORNER_ROUNDING < 
    ui_type = "slider";
	ui_min = 0; ui_max = 100;
	ui_label = "Corner Rounding";
	ui_tooltip = "Determines the percent of anti-aliasing to apply to corners.";
> = 25;

uniform bool SMAA_PREDICATION < 
	ui_label = "Enable Predicated Thresholding";
> = false;

uniform float SMAA_PREDICATION_THRESHOLD < 
    ui_type = "drag";    
	ui_min = 0.005; ui_max = 1.00; ui_step = 0.01;
	ui_tooltip = "Threshold to be used in the additional predication buffer.";
	ui_label = "Predication Threshold";
> = 0.01;

uniform float SMAA_PREDICATION_SCALE < 
    ui_type = "slider";
	ui_min = 1; ui_max = 8;
	ui_tooltip = "How much to scale the global threshold used for luma or color edge.";
	ui_label = "Predication Scale";
> = 2.0;

uniform float SMAA_PREDICATION_STRENGTH < 
    ui_type = "slider";
	ui_min = 0; ui_max = 4;
	ui_tooltip = "How much to locally decrease the threshold.";
	ui_label = "Predication Strength";
> = 0.4;

uniform int DebugOutput < 
    ui_type = "combo";
	ui_items = "None\0View edges\0View weights\0";
	ui_label = "Debug Output";
> = false;

/*
uniform float4 tempF1 <
    ui_type = "drag";
    ui_min = -100.0;
    ui_max = 100.0;
> = float4(1,1,1,1);

uniform float4 tempF2 <
    ui_type = "drag";
    ui_min = -100.0;
    ui_max = 100.0;
> = float4(1,1,1,1);

uniform float4 tempF3 <
    ui_type = "drag";
    ui_min = -100.0;
    ui_max = 100.0;
> = float4(1,1,1,1);
*/

/*=============================================================================
	Textures, Samplers, Globals, Structs
=============================================================================*/

//do NOT change anything here. "hurr durr I changed this and now it works"
//you ARE breaking things down the line, if the shader does not work without changes
//here, it's by design.

texture ColorInputTex : COLOR;
texture DepthInputTex : DEPTH;
sampler DepthInput  { Texture = DepthInputTex; };

#include ".\MartysMods\mmx_global.fxh"
#include ".\MartysMods\mmx_depth.fxh"
#include ".\MartysMods\mmx_math.fxh"
#include ".\MartysMods\mmx_camera.fxh"

texture DepthTex < pooled = true; > { 	Width = BUFFER_WIDTH;   	Height = BUFFER_HEIGHT;   	Format = R16F;  };
texture EdgesTex < pooled = true; > {	Width = BUFFER_WIDTH;	    Height = BUFFER_HEIGHT;	    Format = RG8;   };
texture BlendTex < pooled = true; > {	Width = BUFFER_WIDTH;   	Height = BUFFER_HEIGHT; 	Format = RGBA8; };

//transposing and putting it as RGBA is ever so slightly faster for some reason
texture areaLUT < source = "AreaLUT.png"; > {	Width = 560;	Height = 80;	Format = RGBA8;};
texture searchLUT  {	Width = 64;	Height = 16;	Format = R8;};

sampler sDepthTex {	Texture = DepthTex; };

#if BUFFER_COLOR_BIT_DEPTH != 10
sampler sColorInputTexGamma {	Texture = ColorInputTex; MipFilter = POINT; MinFilter = LINEAR; MagFilter = LINEAR; SRGBTexture = false;};
sampler sColorInputTexLinear{	Texture = ColorInputTex; MipFilter = POINT; MinFilter = LINEAR; MagFilter = LINEAR; SRGBTexture = true;};
#else 
sampler sColorInputTexGamma {	Texture = ColorInputTex; MipFilter = POINT; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sColorInputTexLinear{	Texture = ColorInputTex; MipFilter = POINT; MinFilter = LINEAR; MagFilter = LINEAR; };
#endif 

sampler edgesSampler { Texture = EdgesTex;	};
sampler blendSampler { Texture = BlendTex;  };

#if _COMPUTE_SUPPORTED
storage stEdgesTex   { Texture = EdgesTex;  };
storage stBlendTex   { Texture = BlendTex;  };
storage stDepthTex   { Texture = DepthTex;  };
#endif

sampler areaLUTSampler {	Texture = areaLUT;	SRGBTexture = false;};
sampler searchLUTSampler {	Texture = searchLUT; MipFilter = POINT; MinFilter = POINT; MagFilter = POINT; };

//SMAA internal
#define SMAA_AREATEX_MAX_DISTANCE       16
#define SMAA_AREATEX_MAX_DISTANCE_DIAG  20
#define SMAA_AREATEX_PIXEL_SIZE         (1.0 / float2(80.0, 560.0))
#define SMAA_AREATEX_SUBTEX_SIZE        (1.0 / 7.0)
#define SMAA_SEARCHTEX_SIZE             float2(66.0, 33.0)
#define SMAA_SEARCHTEX_PACKED_SIZE      float2(64.0, 16.0)
#define SMAA_CORNER_ROUNDING_NORM       (float(SMAA_CORNER_ROUNDING) / 100.0)
#define SMAA_SEARCHTEX_SELECT(sample)   sample.r

//integer divide, rounding up
#define CEIL_DIV(num, denom) (((num - 1) / denom) + 1)

struct VSOUT
{
    float4 vpos : SV_Position;
    float2 uv   : TEXCOORD0;
};

struct CSIN 
{
    uint3 groupthreadid     : SV_GroupThreadID;         //XYZ idx of thread inside group
    uint3 groupid           : SV_GroupID;               //XYZ idx of group inside dispatch
    uint3 dispatchthreadid  : SV_DispatchThreadID;      //XYZ idx of thread inside dispatch
    uint threadid           : SV_GroupIndex;            //flattened idx of thread inside group
};

/*=============================================================================
	Functions
=============================================================================*/

float2 pixel_idx_to_uv(uint2 pos, float2 texture_size)
{
    float2 inv_texture_size = rcp(texture_size);
    return pos * inv_texture_size + 0.5 * inv_texture_size;
}

bool check_boundaries(uint2 pos, uint2 dest_size)
{
    return pos.x < dest_size.x && pos.y < dest_size.y; //>= because dest size e.g. 1920, pos [0, 1919]
}

void SMAAMovc(bool2 cond, inout float2 variable, float2 value) 
{
    //[flatten] if (cond.x) variable.x = value.x;
    //[flatten] if (cond.y) variable.y = value.y;
    variable = cond ? value : variable;
}

void SMAAMovc(bool4 cond, inout float4 variable, float4 value) 
{
    variable = cond ? value : variable;
    //SMAAMovc(cond.xy, variable.xy, value.xy);
    //SMAAMovc(cond.zw, variable.zw, value.zw);
}

float3 SMAAGatherNeighbours(float2 texcoord, float4 offset[3], sampler tex)
{
    return tex2DgatherR(tex, texcoord + BUFFER_PIXEL_SIZE * float2(-0.5, -0.5)).grb;
}

float2 SMAACalculatePredicatedThreshold(float2 texcoord, float4 offset[3], sampler predicationTex) 
{
    float3 neighbours = SMAAGatherNeighbours(texcoord, offset, predicationTex);
    float2 delta = abs(neighbours.xx - neighbours.yz);
    float2 edges = step(SMAA_PREDICATION_THRESHOLD, delta);
    return SMAA_PREDICATION_SCALE * SMAA_THRESHOLD * (1.0 - SMAA_PREDICATION_STRENGTH * edges);
}

void SMAAEdgeDetectionVS(float2 texcoord, out float4 offset[3]) 
{
    offset[0] = mad(BUFFER_PIXEL_SIZE.xyxy, float4(-1.0, 0.0, 0.0, -1.0), texcoord.xyxy);
    offset[1] = mad(BUFFER_PIXEL_SIZE.xyxy, float4( 1.0, 0.0, 0.0,  1.0), texcoord.xyxy);
    offset[2] = mad(BUFFER_PIXEL_SIZE.xyxy, float4(-2.0, 0.0, 0.0, -2.0), texcoord.xyxy);
}

void SMAABlendingWeightCalculationVS(float2 texcoord, out float2 pixcoord, out float4 offset[3]) 
{
    pixcoord = texcoord * BUFFER_SCREEN_SIZE;

    // We will use these offsets for the searches later on (see @PSEUDO_GATHER4):
    offset[0] = mad(BUFFER_PIXEL_SIZE.xyxy, float4(-0.25, -0.125,  1.25, -0.125), texcoord.xyxy);
    offset[1] = mad(BUFFER_PIXEL_SIZE.xyxy, float4(-0.125, -0.25, -0.125,  1.25), texcoord.xyxy);

    // And these for the searches, they indicate the ends of the loops:
    offset[2] = mad(BUFFER_PIXEL_SIZE.xxyy,
                    float4(-2.0, 2.0, -2.0, 2.0) * float(SMAA_MAX_SEARCH_STEPS),
                    float4(offset[0].xz, offset[1].yw));
}

void SMAANeighborhoodBlendingVS(float2 texcoord,  out float4 offset) 
{
    offset = mad(BUFFER_PIXEL_SIZE.xyxy, float4( 1.0, 0.0, 0.0,  1.0), texcoord.xyxy);
}

float edge_metric(float3 A, float3 B)
{   
    float3 t = abs(A - B);
    if(EDGE_DETECTION_MODE == 2) 
        return dot(abs(A - B), float3(0.229, 0.587, 0.114) * 1.33);
    
    return max(max(t.r, t.g), t.b);
}

float2 SMAALumaEdgePredicationDetectionPS(float2 texcoord, float4 offset[3], sampler _colorTex, sampler _predicationTex) 
{
    float2 threshold = float2(SMAA_THRESHOLD, SMAA_THRESHOLD);
    [branch]
    if(SMAA_PREDICATION)
        threshold = SMAACalculatePredicatedThreshold(texcoord, offset, _predicationTex);

    float3 weights = float3(0.2126, 0.7152, 0.0722);
    float L = dot(tex2D(_colorTex, texcoord).rgb, weights);

    float Lleft = dot(tex2Dlod(_colorTex, offset[0].xy, 0).rgb, weights);
    float Ltop  = dot(tex2Dlod(_colorTex, offset[0].zw, 0).rgb, weights);

    float4 delta;
    delta.xy = abs(L - float2(Lleft, Ltop));
    float2 edges = step(threshold, delta.xy);

    //if (dot(edges, float2(1.0, 1.0)) == 0.0) return 0;
     if(edges.x == -edges.y) discard;

    float Lright   = dot(tex2Dlod(_colorTex, offset[1].xy, 0).rgb, weights);
    float Lbottom  = dot(tex2Dlod(_colorTex, offset[1].zw, 0).rgb, weights);
    delta.zw = abs(L - float2(Lright, Lbottom));

    float2 maxDelta = max(delta.xy, delta.zw);    

    float Lleftleft = dot(tex2Dlod(_colorTex, offset[2].xy, 0).rgb, weights);
    float Ltoptop = dot(tex2Dlod(_colorTex, offset[2].zw, 0).rgb, weights);
    delta.zw = abs(float2(Lleft, Ltop) - float2(Lleftleft, Ltoptop));

    maxDelta = max(maxDelta.xy, delta.zw);    
    float finalDelta = max(maxDelta.x, maxDelta.y);   

    edges.xy *= step(finalDelta, SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR * delta.xy);
    return edges;
}

float2 SMAAColorEdgePredicationDetectionPS(float2 texcoord, float4 offset[3], sampler _colorTex , sampler _predicationTex) 
{
	float2 threshold = float2(SMAA_THRESHOLD, SMAA_THRESHOLD);
    [branch]
    if(SMAA_PREDICATION)
        threshold = SMAACalculatePredicatedThreshold(texcoord, offset, _predicationTex);

    float4 delta;
    float3 C = tex2Dlod(_colorTex, texcoord, 0).rgb;

    float3 Cleft = tex2Dlod(_colorTex, offset[0].xy, 0).rgb;
    delta.x = edge_metric(C, Cleft);
    float3 Ctop  = tex2Dlod(_colorTex, offset[0].zw, 0).rgb;
    delta.y = edge_metric(C, Ctop);

    float2 edges = step(threshold, delta.xy);
    //if (dot(edges, 1.0) == 0.0) return 0;
    if(edges.x == -edges.y) discard;

    float3 Cright = tex2Dlod(_colorTex, offset[1].xy, 0).rgb;
    delta.z = edge_metric(C, Cright);
    float3 Cbottom  = tex2Dlod(_colorTex, offset[1].zw, 0).rgb;
    delta.w = edge_metric(C, Cbottom);

    float2 maxDelta = max(delta.xy, delta.zw);  

    float3 Cleftleft  = tex2Dlod(_colorTex, offset[2].xy, 0).rgb;
    delta.z = edge_metric(Cleft, Cleftleft);

    float3 Ctoptop = tex2Dlod(_colorTex, offset[2].zw, 0).rgb;
    delta.w = edge_metric(Ctop, Ctoptop);

    maxDelta = max(maxDelta.xy, delta.zw);  

    float finalDelta = max(maxDelta.x, maxDelta.y);
    edges.xy *= step(finalDelta, SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR * delta.xy);   
    return edges;
}

float2 SMAADepthEdgeDetectionPS(float2 texcoord, float4 offset[3], sampler DepthTex) 
{
    float3 neighbours = SMAAGatherNeighbours(texcoord, offset, DepthTex);
    float2 delta = abs(neighbours.xx - float2(neighbours.y, neighbours.z));
    float2 edges = step(SMAA_DEPTH_THRESHOLD, delta);

    //if (dot(edges, float2(1.0, 1.0)) == 0.0)
    //    return 0;
     if(edges.x == -edges.y) discard;

    return edges;
}

//Allows to decode two binary values from a bilinear-filtered access.
float2 SMAADecodeDiagBilinearAccess(float2 e) 
{
    e.r = e.r * abs(5.0 * e.r - 5.0 * 0.75);
    return round(e);
}

float4 SMAADecodeDiagBilinearAccess(float4 e) 
{
    e.rb = e.rb * abs(5.0 * e.rb - 5.0 * 0.75);
    return round(e);
}

float2 SMAASearchDiag1(sampler EdgesTex, float2 texcoord, float2 dir, out float2 e)
{
    float4 coord = float4(texcoord, -1.0, 1.0);
    float3 t = float3(BUFFER_PIXEL_SIZE.xy, 1.0);
    while(coord.z < float(SMAA_MAX_SEARCH_STEPS_DIAG - 1) && coord.w > 0.9) 
    {
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);
        e = tex2Dlod(EdgesTex, coord.xy, 0).rg;
        coord.w = dot(e, 0.5);
    }
    return coord.zw;
}

float2 SMAASearchDiag2(sampler EdgesTex, float2 texcoord, float2 dir, out float2 e) 
{
    float4 coord = float4(texcoord, -1.0, 1.0);
    coord.x += 0.25 * BUFFER_PIXEL_SIZE.x;
    float3 t = float3(BUFFER_PIXEL_SIZE.xy, 1.0);
    while (coord.z < float(SMAA_MAX_SEARCH_STEPS_DIAG - 1) && coord.w > 0.9) 
    {
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);

        e = tex2Dlod(EdgesTex, coord.xy, 0).rg;
        e = SMAADecodeDiagBilinearAccess(e);
        coord.w = dot(e, 0.5);
    }
    return coord.zw;
}

float2 SMAAAreaDiag(sampler areaTex, float2 dist, float2 e, float offset) 
{
    float2 texcoord = mad(float2(SMAA_AREATEX_MAX_DISTANCE_DIAG, SMAA_AREATEX_MAX_DISTANCE_DIAG), e, dist);

    texcoord = mad(SMAA_AREATEX_PIXEL_SIZE, texcoord, 0.5 * SMAA_AREATEX_PIXEL_SIZE);
    texcoord.y += SMAA_AREATEX_SUBTEX_SIZE * offset;

    return tex2Dlod(areaLUTSampler, texcoord.yx, 0).zw; //diagonals in alpha   
}

float2 SMAACalculateDiagWeights(sampler EdgesTex, sampler areaTex, float2 texcoord, float2 e, float4 subsampleIndices) 
{
    float2 weights = 0;

    // Search for the line ends:
    float4 d;
    float2 end;
    if (e.r > 0.0) 
    {
        d.xz = SMAASearchDiag1(EdgesTex, texcoord, float2(-1.0,  1.0), end);
        d.x += float(end.y > 0.9);
    } 
    else
    {
        d.xz = 0;
    }
        
    d.yw = SMAASearchDiag1(EdgesTex, texcoord, float2(1.0, -1.0), end);

    [branch]
    if (d.x + d.y > 2.0)  // d.x + d.y + 1 > 3
    { 
        // Fetch the crossing edges:
        float4 coords = mad(float4(-d.x + 0.25, d.x, d.y, -d.y - 0.25), BUFFER_PIXEL_SIZE.xyxy, texcoord.xyxy);
        float4 c;
        c.xy = tex2Dlod(EdgesTex, coords.xy + int2(-1,  0) * BUFFER_PIXEL_SIZE, 0).rg;
        c.zw = tex2Dlod(EdgesTex, coords.zw + int2( 1,  0) * BUFFER_PIXEL_SIZE, 0).rg;
        c.yxwz = SMAADecodeDiagBilinearAccess(c.xyzw);

        // Merge crossing edges at each side into a single value:
        float2 cc = mad(float2(2.0, 2.0), c.xz, c.yw);

        // Remove the crossing edge if we didn't found the end of the line:
        SMAAMovc(bool2(step(0.9, d.zw)), cc, float2(0.0, 0.0));
        //cc = bool2(step(0.9.xx, d.zw)) ? 0 : cc;


        // Fetch the areas for this line:
        weights += SMAAAreaDiag(areaTex, d.xy, cc, subsampleIndices.z);
    }

    // Search for the line ends:
    d.xz = SMAASearchDiag2(EdgesTex, texcoord, float2(-1.0, -1.0), end);
    if (tex2Dlod(EdgesTex, texcoord + int2(1, 0) * BUFFER_PIXEL_SIZE, 0).r > 0.0) 
    {
        d.yw = SMAASearchDiag2(EdgesTex, texcoord, float2(1.0, 1.0), end);
        d.y += float(end.y > 0.9);
    } 
    else
    {
        d.yw = 0;
    }        

    [branch]
    if (d.x + d.y > 2.0) // d.x + d.y + 1 > 3
    { 
        // Fetch the crossing edges:
        float4 coords = mad(float4(-d.x, -d.x, d.y, d.y), BUFFER_PIXEL_SIZE.xyxy, texcoord.xyxy);
        float4 c;
        c.x  = tex2Dlod(EdgesTex, coords.xy + int2(-1,  0) * BUFFER_PIXEL_SIZE, 0).g;
        c.y  = tex2Dlod(EdgesTex, coords.xy + int2( 0, -1) * BUFFER_PIXEL_SIZE, 0).r;
        c.zw = tex2Dlod(EdgesTex, coords.zw + int2( 1,  0) * BUFFER_PIXEL_SIZE, 0).gr;
        float2 cc = mad(float2(2.0, 2.0), c.xz, c.yw);

        // Remove the crossing edge if we didn't found the end of the line:
        SMAAMovc(bool2(step(0.9, d.zw)), cc, float2(0.0, 0.0));
       // cc = bool2(step(0.9.xx, d.zw)) ? 0 : cc;

        // Fetch the areas for this line:
        weights += SMAAAreaDiag(areaTex, d.xy, cc, subsampleIndices.w).gr;
    }

    return weights;
}

float SMAASearchLength(sampler searchTex, float2 e, float offset) 
{
    return SMAA_SEARCHTEX_SELECT(tex2Dfetch(searchTex, floor(float2(e.x + offset, 1 - e.y) * 33.0)));
}

float SMAASearchXLeft(sampler EdgesTex, sampler searchTex, float2 texcoord, float end) 
{
    float2 e = float2(0.0, 1.0);
    while (texcoord.x > end  
        && e.g > 0.8281 // Is there some edge not activated?
        &&  e.r == 0.0) // Or is there a crossing edge that breaks the line?
    { 
        e = tex2Dlod(EdgesTex, texcoord, 0).rg;
        texcoord = mad(-float2(2.0, 0.0), BUFFER_PIXEL_SIZE.xy, texcoord);
    }

    float offset = mad(-(255.0 / 127.0), SMAASearchLength(searchTex, e, 0.0), 3.25);
    return mad(BUFFER_PIXEL_SIZE.x, offset, texcoord.x);   
}

float SMAASearchXRight(sampler EdgesTex, sampler searchTex, float2 texcoord, float end) 
{
    float2 e = float2(0.0, 1.0);
    while (texcoord.x < end  
           && e.g > 0.8281  // Is there some edge not activated?
           && e.r == 0.0) // Or is there a crossing edge that breaks the line? 
    { 
        e = tex2Dlod(EdgesTex, texcoord, 0).rg;
        texcoord = mad(float2(2.0, 0.0), BUFFER_PIXEL_SIZE.xy, texcoord);
    }

    float offset = mad(-(255.0 / 127.0), SMAASearchLength(searchTex, e, 1.0), 3.25);
    return mad(-BUFFER_PIXEL_SIZE.x, offset, texcoord.x);
}

float SMAASearchYUp(sampler EdgesTex, sampler searchTex, float2 texcoord, float end) 
{
    float2 e = float2(1.0, 0.0);
    while (texcoord.y > end && 
           e.r > 0.8281 && // Is there some edge not activated?
           e.g == 0.0) { // Or is there a crossing edge that breaks the line?
        e = tex2Dlod(EdgesTex, texcoord, 0).rg;
        texcoord = mad(-float2(0.0, 2.0), BUFFER_PIXEL_SIZE.xy, texcoord);
    }
    float offset = mad(-(255.0 / 127.0), SMAASearchLength(searchTex, e.gr, 0.0), 3.25);
    return mad(BUFFER_PIXEL_SIZE.y, offset, texcoord.y);
}

float SMAASearchYDown(sampler EdgesTex, sampler searchTex, float2 texcoord, float end) 
{
    float2 e = float2(1.0, 0.0);
    while (texcoord.y < end && 
           e.r > 0.8281 && // Is there some edge not activated?
           e.g == 0.0) { // Or is there a crossing edge that breaks the line?
        e = tex2Dlod(EdgesTex, texcoord, 0).rg;
        texcoord = mad(float2(0.0, 2.0), BUFFER_PIXEL_SIZE.xy, texcoord);
    }
    float offset = mad(-(255.0 / 127.0), SMAASearchLength(searchTex, e.gr, 1.0), 3.25);
    return mad(-BUFFER_PIXEL_SIZE.y, offset, texcoord.y);
}

float2 SMAAArea(sampler areaTex, float2 dist, float e1, float e2, float offset) 
{
    // Rounding prevents precision errors of bilinear filtering:
    float2 texcoord = mad(float2(SMAA_AREATEX_MAX_DISTANCE, SMAA_AREATEX_MAX_DISTANCE), round(4.0 * float2(e1, e2)), dist);

    texcoord = mad(SMAA_AREATEX_PIXEL_SIZE, texcoord, 0.5 * SMAA_AREATEX_PIXEL_SIZE);
    texcoord.y = mad(SMAA_AREATEX_SUBTEX_SIZE, offset, texcoord.y);

    return tex2Dlod(areaLUTSampler, texcoord.yx, 0).xy; //diagonals in alpha      
}

void SMAADetectHorizontalCornerPattern(sampler EdgesTex, inout float2 weights, float4 texcoord, float2 d) 
{
    float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - SMAA_CORNER_ROUNDING_NORM) * leftRight;

    rounding /= leftRight.x + leftRight.y; // Reduce blending for pixels in the center of a line.

    float2 factor = float2(1.0, 1.0);

    factor.x -= rounding.x * tex2Dlod(EdgesTex, texcoord.xy + int2(0,  1) * BUFFER_PIXEL_SIZE, 0).r;
    factor.x -= rounding.y * tex2Dlod(EdgesTex, texcoord.zw + int2(1,  1) * BUFFER_PIXEL_SIZE, 0).r;
    factor.y -= rounding.x * tex2Dlod(EdgesTex, texcoord.xy + int2(0, -2) * BUFFER_PIXEL_SIZE, 0).r;
    factor.y -= rounding.y * tex2Dlod(EdgesTex, texcoord.zw + int2(1, -2) * BUFFER_PIXEL_SIZE, 0).r;
 /*   
if(tempF1.x > 0)
{
    rounding *= tempF1.y;
    factor.x -= rounding.x * tex2Dlod(EdgesTex, texcoord.xy + int2(0,  2) * BUFFER_PIXEL_SIZE, 0).r;
    factor.x -= rounding.y * tex2Dlod(EdgesTex, texcoord.zw + int2(1,  2) * BUFFER_PIXEL_SIZE, 0).r;
    factor.y -= rounding.x * tex2Dlod(EdgesTex, texcoord.xy + int2(0, -3) * BUFFER_PIXEL_SIZE, 0).r;
    factor.y -= rounding.y * tex2Dlod(EdgesTex, texcoord.zw + int2(1, -3) * BUFFER_PIXEL_SIZE, 0).r;
}*/
    weights *= saturate(factor);
}

void SMAADetectVerticalCornerPattern(sampler EdgesTex, inout float2 weights, float4 texcoord, float2 d) 
{
    float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - SMAA_CORNER_ROUNDING_NORM) * leftRight;

    rounding /= leftRight.x + leftRight.y;

    float2 factor = float2(1.0, 1.0);
  
    factor.x -= rounding.x * tex2Dlod(EdgesTex, texcoord.xy + int2( 1, 0) * BUFFER_PIXEL_SIZE, 0).g;
    factor.x -= rounding.y * tex2Dlod(EdgesTex, texcoord.zw + int2( 1, 1) * BUFFER_PIXEL_SIZE, 0).g;
    factor.y -= rounding.x * tex2Dlod(EdgesTex, texcoord.xy + int2(-2, 0) * BUFFER_PIXEL_SIZE, 0).g;
    factor.y -= rounding.y * tex2Dlod(EdgesTex, texcoord.zw + int2(-2, 1) * BUFFER_PIXEL_SIZE, 0).g;
 /*if(tempF1.x > 0)
{ 
    rounding *= tempF1.y;
    factor.x -= rounding.x * tex2Dlod(EdgesTex, texcoord.xy + int2( 2, 0) * BUFFER_PIXEL_SIZE, 0).g;
    factor.x -= rounding.y * tex2Dlod(EdgesTex, texcoord.zw + int2( 2, 1) * BUFFER_PIXEL_SIZE, 0).g;
    factor.y -= rounding.x * tex2Dlod(EdgesTex, texcoord.xy + int2(-3, 0) * BUFFER_PIXEL_SIZE, 0).g;
    factor.y -= rounding.y * tex2Dlod(EdgesTex, texcoord.zw + int2(-3, 1) * BUFFER_PIXEL_SIZE, 0).g;
}*/

    weights *= saturate(factor);
}


//Blending Weight Calculation Pixel Shader (Second Pass)
float4 SMAABlendingWeightCalculationPS(float2 texcoord,
                                       float2 pixcoord,
                                       float4 offset[3],
                                       sampler EdgesTex,
                                       sampler areaTex,
                                       sampler searchTex,
                                       float4 subsampleIndices) // Just pass zero for SMAA 1x, see @SUBSAMPLE_INDICES.
{ 
    float4 weights = float4(0.0, 0.0, 0.0, 0.0);
    float2 e = tex2Dfetch(EdgesTex, pixcoord).rg;

    [branch]
    if (e.g > 0.0) 
    { 
        // Edge at north
        // Diagonals have both north and west edges, so searching for them in
        // one of the boundaries is enough.
        weights.rg = SMAACalculateDiagWeights(EdgesTex, areaTex, texcoord, e, subsampleIndices);

        // We give priority to diagonals, so if we find a diagonal we skip 
        // horizontal/vertical processing.
        [branch]
        if (weights.r == -weights.g)  // weights.r + weights.g == 0.0
        {
            float2 d;

            // Find the distance to the left:
            float3 coords;
            coords.x = SMAASearchXLeft(EdgesTex, searchTex, offset[0].xy, offset[2].x);
            coords.y = offset[1].y; // offset[1].y = texcoord.y - 0.25 * SMAA_RT_METRICS.y (@CROSSING_OFFSET)
            d.x = coords.x;

            // Now fetch the left crossing edges, two at a time using bilinear
            // filtering. Sampling at -0.25 (see @CROSSING_OFFSET) enables to
            // discern what value each edge has:
            float e1 = tex2Dlod(EdgesTex, coords.xy, 0).r;

            // Find the distance to the right:
            coords.z = SMAASearchXRight(EdgesTex, searchTex, offset[0].zw, offset[2].y);
            d.y = coords.z;

            // We want the distances to be in pixel units (doing this here allow to
            // better interleave arithmetic and memory accesses):
            d = abs(round(mad(BUFFER_SCREEN_SIZE.xx, d, -pixcoord.xx)));

            // SMAAArea below needs a sqrt, as the areas texture is compressed
            // quadratically:
            float2 sqrt_d = sqrt(d);

            // Fetch the right crossing edges:
            float e2 = tex2Dlod(EdgesTex, coords.zy + int2(1, 0) * BUFFER_PIXEL_SIZE, 0).r;

            // Ok, we know how this pattern looks like, now it is time for getting
            // the actual area:
            weights.rg = SMAAArea(areaTex, sqrt_d, e1, e2, subsampleIndices.y);

            // Fix corners:
            coords.y = texcoord.y;
            SMAADetectHorizontalCornerPattern(EdgesTex, weights.rg, coords.xyzy, d);    
        } 
        else
            e.r = 0.0; // Skip vertical processing.        
    }

    [branch]
    if (e.r > 0.0) // Edge at west
    { 
        float2 d;

        // Find the distance to the top:
        float3 coords;
        coords.y = SMAASearchYUp(EdgesTex, searchTex, offset[1].xy, offset[2].z);
        coords.x = offset[0].x; // offset[1].x = texcoord.x - 0.25 * SMAA_RT_METRICS.x;
        d.x = coords.y;

        // Fetch the top crossing edges:
        float e1 = tex2Dlod(EdgesTex, coords.xy, 0).g;

        // Find the distance to the bottom:
        coords.z = SMAASearchYDown(EdgesTex, searchTex, offset[1].zw, offset[2].w);
        d.y = coords.z;

        // We want the distances to be in pixel units:
        d = abs(round(mad(BUFFER_SCREEN_SIZE.yy, d, -pixcoord.yy)));

        // SMAAArea below needs a sqrt, as the areas texture is compressed 
        // quadratically:
        float2 sqrt_d = sqrt(d);

        // Fetch the bottom crossing edges:
        float e2 = tex2Dlod(EdgesTex, coords.xz + int2(0, 1) * BUFFER_PIXEL_SIZE, 0).g;

        // Get the area for this direction:
        weights.ba = SMAAArea(areaTex, sqrt_d, e1, e2, subsampleIndices.x);

        // Fix corners:
        coords.x = texcoord.x;
        SMAADetectVerticalCornerPattern(EdgesTex, weights.ba, coords.xyxz, d);
    }

    return weights;
}

// Neighborhood Blending Pixel Shader (Third Pass)
float4 SMAANeighborhoodBlendingPS(float2 texcoord,
                                  float4 offset,
                                  sampler colorTex,
                                  sampler BlendTex) 
{
    // Fetch the blending weights for current pixel:
    float4 a;
    a.x = tex2Dlod(BlendTex, offset.xy, 0).a; // Right
    a.y = tex2Dlod(BlendTex, offset.zw, 0).g; // Top
    a.wz = tex2Dlod(BlendTex, texcoord, 0).xz; // Bottom / Left

    // Is there any blending weight with a value greater than 0.0?
    [branch]
    if (dot(a, 1) < 1e-5) 
   //if (((a.x + a.z) + (a.y + a.w)) < 1e-5)
    {
        discard;
    } 
    else 
    {
        bool h = max(a.x, a.z) > max(a.y, a.w); // max(horizontal) > max(vertical)

        // Calculate the blending offsets:
        float4 blendingOffset = float4(0.0, a.y, 0.0, a.w);
        float2 blendingWeight = a.yw;
        SMAAMovc(bool4(h, h, h, h), blendingOffset, float4(a.x, 0.0, a.z, 0.0));
        SMAAMovc(bool2(h, h), blendingWeight, a.xz);
        blendingWeight /= dot(blendingWeight, float2(1.0, 1.0));

        // Calculate the texture coordinates:
        float4 blendingCoord = mad(blendingOffset, float4(BUFFER_PIXEL_SIZE.xy, -BUFFER_PIXEL_SIZE.xy), texcoord.xyxy);

        if(dot(blendingOffset, 1) < 0.01) discard;

        // We exploit bilinear filtering to mix current pixel with the chosen
        // neighbor:
        float4 color = blendingWeight.x * tex2Dlod(colorTex, blendingCoord.xy, 0);
        color += blendingWeight.y * tex2Dlod(colorTex, blendingCoord.zw, 0);       

        return color;
    }
}

/*=============================================================================
	Shader Entry Points - Depth Linearization Prepass
=============================================================================*/

VSOUT MainVS(in uint id : SV_VertexID)
{
    VSOUT o; FullscreenTriangleVS(id, o.vpos, o.uv); return o;
}

#if _COMPUTE_SUPPORTED == 0
void SMAADepthLinearizationPS(in VSOUT i, out float o : SV_Target)
{
	o = Depth::get_linear_depth(i.uv);
}

#else //_COMPUTE_SUPPORTED  

void SMAADepthLinearizationCS(in CSIN i)
{
    if(!check_boundaries(i.dispatchthreadid.xy * 2, BUFFER_SCREEN_SIZE) || (!SMAA_PREDICATION && EDGE_DETECTION_MODE != 3)) return;

    float2 uv = pixel_idx_to_uv(i.dispatchthreadid.xy * 2, BUFFER_SCREEN_SIZE);
    float2 corrected_uv = Depth::correct_uv(uv); //fixed for lookup 

#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
    corrected_uv.y -= BUFFER_PIXEL_SIZE.y * 0.5;    //shift upwards since gather looks down and right
    float4 depth_texels = tex2DgatherR(DepthInput, corrected_uv).wzyx;  
#else
    float4 depth_texels = tex2DgatherR(DepthInput, corrected_uv);
#endif

    depth_texels = Depth::linearize(depth_texels);
    tex2Dstore(stDepthTex, i.dispatchthreadid.xy * 2 + uint2(0, 1), depth_texels.x);
    tex2Dstore(stDepthTex, i.dispatchthreadid.xy * 2 + uint2(1, 1), depth_texels.y);
    tex2Dstore(stDepthTex, i.dispatchthreadid.xy * 2 + uint2(1, 0), depth_texels.z);
    tex2Dstore(stDepthTex, i.dispatchthreadid.xy * 2 + uint2(0, 0), depth_texels.w);   
}

#endif //_COMPUTE_SUPPORTED 

/*=============================================================================
	Shader Entry Points - Edge Detection
=============================================================================*/

float2 SMAAEdgeDetectionWrapPS(in VSOUT i) : SV_Target
{
    float2 texcoord = i.uv;
    //on more recent gen hw it seems faster to do compute this here rather than costing bandwidth
    float4 offset[3]; 
    SMAAEdgeDetectionVS(texcoord, offset);

    [branch]
	if(EDGE_DETECTION_MODE == 0)
		return SMAALumaEdgePredicationDetectionPS(texcoord, offset, sColorInputTexGamma, sDepthTex);
	else 
    [branch]
    if(EDGE_DETECTION_MODE == 3)
		return SMAADepthEdgeDetectionPS(texcoord, offset, sDepthTex);

	return SMAAColorEdgePredicationDetectionPS(texcoord, offset, sColorInputTexGamma, sDepthTex);
}

/*=============================================================================
	Shader Entry Points - Blend Weight Calculation
=============================================================================*/

#if _COMPUTE_SUPPORTED == 0

void SMAABlendingWeightCalculationWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float2 pixcoord : TEXCOORD1,
	out float4 offset[3] : TEXCOORD2
    )
{
	FullscreenTriangleVS(id, position, texcoord);
	SMAABlendingWeightCalculationVS(texcoord, pixcoord, offset);
}

float4 SMAABlendingWeightCalculationWrapPS(	float4 position : SV_Position, float2 texcoord : TEXCOORD0, float2 pixcoord : TEXCOORD1, float4 offset[3] : TEXCOORD2) : SV_Target
{
	return SMAABlendingWeightCalculationPS(texcoord, pixcoord, offset, edgesSampler, areaLUTSampler, searchLUTSampler, 0.0);
}

#else //_COMPUTE_SUPPORTED 

//writes edgetex, clears blend tex for CS
void SMAAEdgeDetectionWrapAndClearPS(in VSOUT i, out PSOUT2 o)
{
    float2 texcoord = i.uv;
    //on more recent gen hw it seems faster to do compute this here rather than costing bandwidth
    float4 offset[3]; 
    SMAAEdgeDetectionVS(texcoord, offset);

    o.t0 = o.t1 = 0; //clear blendtex as well so the CS can be made simpler, fastest option out of many variants tested

    [branch]
	if(EDGE_DETECTION_MODE == 0)
		o.t0 = SMAALumaEdgePredicationDetectionPS(texcoord, offset, sColorInputTexGamma, sDepthTex);
	else 
    [branch]
    if(EDGE_DETECTION_MODE == 3)
		o.t0 = SMAADepthEdgeDetectionPS(texcoord, offset, sDepthTex);
    else 
	    o.t0 =  SMAAColorEdgePredicationDetectionPS(texcoord, offset, sColorInputTexGamma, sDepthTex);        
}

#define GROUP_SIZE_X    16
#define GROUP_SIZE_Y    16
#define BATCH_SIZE      2

groupshared uint g_worker_ids[GROUP_SIZE_X * GROUP_SIZE_Y * BATCH_SIZE];//N slots per thread
groupshared uint g_total_workers;

#define DISPATCH_SIZE_X CEIL_DIV(BUFFER_WIDTH, GROUP_SIZE_X)
#define DISPATCH_SIZE_Y CEIL_DIV(BUFFER_HEIGHT, (GROUP_SIZE_Y*BATCH_SIZE))

void SMAABlendingWeightCalculationWrapCS(in CSIN i)
{   
    const uint2 groupsize = uint2(GROUP_SIZE_X, GROUP_SIZE_Y);
    const uint2 working_area = groupsize * uint2(1, BATCH_SIZE);
    const uint global_counter_idx = working_area.x * working_area.y;

    if(i.threadid == 0) g_total_workers = 0;   
    barrier(); 

    [unroll]
    for(uint batch = 0; batch < BATCH_SIZE; batch++)
    {
        uint id = i.threadid * BATCH_SIZE + batch;
        uint2 pos = i.groupid.xy * working_area + uint2(id % groupsize.x, id / groupsize.x);

        if(any(tex2Dfetch(edgesSampler, pos).xy))
        {
            uint harderworker_id = atomicAdd(g_total_workers, 1u);
            g_worker_ids[harderworker_id] = id;     
        }       
    }

    barrier();

    //load into local registers
    uint total_work = g_total_workers;

    //if we have a reeeally small amount of threads doing anything, skip it
    //raising this too high can cause gaps in single antialiased lines, hence 
    //keep it far below the width/height of a thread group
    if(total_work < 4) 
        return;

    //if we bite the bullet, a cluster of pixels with lots of AA can tank performance here
    //but for a regular image, this is very rarely the case and since the workers are grouped
    //this happens for the least amount of warps/wavefronts possible
    while(i.threadid < total_work)
    {
        uint id = g_worker_ids[i.threadid]; 
        uint2 pos = i.groupid.xy * working_area + uint2(id % groupsize.x, id / groupsize.x);
        
        float2 uv = pixel_idx_to_uv(pos, BUFFER_SCREEN_SIZE);
        float2 pixcoord;
        float4 offset[3];
        SMAABlendingWeightCalculationVS(uv, pixcoord, offset);    
        float4 blend_weights = SMAABlendingWeightCalculationPS(uv, pixcoord, offset, edgesSampler, areaLUTSampler, searchLUTSampler, 0.0);
        tex2Dstore(stBlendTex, pos, blend_weights); 
        i.threadid += groupsize.x * groupsize.y;
    }
}

/*
//GPU Bitonic sort
    for(uint g = 1; g <= logn2; g++) 
    {
		for (uint t = g; t > 0; t--) 
        {			
            uint map = (i.threadid / (1u << (t - 1u))) * (1u << t) + (i.threadid % (1u << (t - 1u)));
            uint pos = (map / (1u << g)) & 1u;
            uint m1 = (pos == 0) ? map : (map + (1u << (t - 1u)));
		    uint m2 = (pos != 0) ? map : (map + (1u << (t - 1u)));
            atomicMin(grouped_work_indices[m1], atomicMax(grouped_work_indices[m2], grouped_work_indices[m1]));
            barrier();			
		}
	}
*/

#endif //_COMPUTE_SUPPORTED

/*=============================================================================
	Shader Entry Points - Neighbourhood Blending
=============================================================================*/

void SMAANeighborhoodBlendingWrapVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0, out float4 offset : TEXCOORD1)
{
    FullscreenTriangleVS(id, position, texcoord);
	SMAANeighborhoodBlendingVS(texcoord, offset);
}

float3 SMAANeighborhoodBlendingWrapPS(float4 position : SV_Position,float2 texcoord : TEXCOORD0,float4 offset : TEXCOORD1) : SV_Target
{
	if(DebugOutput == 1)
		return tex2Dlod(edgesSampler, texcoord, 0).rgb;
	if(DebugOutput == 2)
		return tex2Dlod(blendSampler, texcoord, 0).rgb;

	return SMAANeighborhoodBlendingPS(texcoord, offset, sColorInputTexLinear, blendSampler).rgb;
}

float SMAAMakeLUTTexPS(in VSOUT i) : SV_Target
{
/*
    uint2 p = i.vpos.xy;

    uint dict = 0x306D9B;
    uint dict2 = 0x04000003;

    uint3 t = p.xyx;
    t.xy = min(t.xy % 21u, 12);    

    uint2 left = (dict >> t.xy) & 1u;

    uint second = left.y & (dict2 >> min(31, (t.z - 7u * (t.z > 6u)))) & (p.y < 5);    
    uint firstpart = left.y & (t.z > 32 ? dict >> min(28, t.z - 20u) : left.x);
    return firstpart * 0.5 + second * 0.5;
*/
    float2 pos = floor(i.vpos.xy);
    bool rightside = pos.x > 33;        
    pos.x = pos.x % 33;
    float2 a = max(0, abs(pos - 16.0) - 4.0) - saturate(abs(pos - 16.0) - 10.0);
    float2 u1 = round(abs(sin(a * PI / 3.0)));
    if(rightside) return u1.y * (saturate(1 - 0.5 * pos.x) + saturate(1 - abs(7.5 - pos.x)));
    float h = pos.x < 16.0 && pos.y < 5.0 ? round(saturate(sin(-a.x * PI / 3.0))) : 0;
    return (u1.x + h) * u1.y * 0.5; 
}

/*=============================================================================
	Techniques
=============================================================================*/

technique MartysMods_AntiAliasing_Prepass
<
    hidden = true; 
    enabled = true;
	timeout = 1;
>
{
    pass
	{
		VertexShader = MainVS;
		PixelShader = SMAAMakeLUTTexPS;
		RenderTarget = searchLUT;
	}  
}

technique MartysMods_AntiAliasing
<
    ui_label = "iMMERSE Anti Aliasing";
    ui_tooltip =        
        "                               MartysMods - SMAA                              \n"
         "                   MartysMods Epic ReShade Effects (iMMERSE)                 \n"
        "______________________________________________________________________________\n"
        "\n"

        "This implementation of 'Enhanced subpixel morphological antialiasing' (SMAA)  \n"
        "delivers up to twice the performance of the original depending on settings.   \n"
        "\n"
        "\n"
        "Visit https://martysmods.com for more information.                            \n"
        "\n"       
        "______________________________________________________________________________";
>
{     
#if _COMPUTE_SUPPORTED
    pass 
    { 
        ComputeShader = SMAADepthLinearizationCS<16, 16>;
        DispatchSizeX = CEIL_DIV(BUFFER_WIDTH, 32); 
        DispatchSizeY = CEIL_DIV(BUFFER_HEIGHT, 32);
    } 
    pass SMAAEdgeDetectionWrapAndClearPS
	{
		VertexShader = MainVS;
		PixelShader = SMAAEdgeDetectionWrapAndClearPS;
        ClearRenderTargets = true;
		RenderTarget0 = EdgesTex;
        RenderTarget1 = BlendTex;
    } 
    pass    
    { 
        ComputeShader = SMAABlendingWeightCalculationWrapCS<GROUP_SIZE_X, GROUP_SIZE_Y>;
        DispatchSizeX = DISPATCH_SIZE_X; 
        DispatchSizeY = DISPATCH_SIZE_Y;
    }
#else 
    pass
	{
		VertexShader = MainVS;
		PixelShader = SMAADepthLinearizationPS;
		RenderTarget = DepthTex;
	}
    pass EdgeDetectionPass
	{
		VertexShader = MainVS;
		PixelShader = SMAAEdgeDetectionWrapPS;
		RenderTarget = EdgesTex;
        ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = REPLACE;
		StencilRef = 1;
    }
    pass BlendWeightCalculationPass
	{
		VertexShader = SMAABlendingWeightCalculationWrapVS;
		PixelShader = SMAABlendingWeightCalculationWrapPS;
		RenderTarget = BlendTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = KEEP;
		StencilFunc = EQUAL;
		StencilRef = 1;
	}
#endif

    pass NeighborhoodBlendingPass
	{
		VertexShader = SMAANeighborhoodBlendingWrapVS;
		PixelShader = SMAANeighborhoodBlendingWrapPS;
		StencilEnable = false;
		#if BUFFER_COLOR_BIT_DEPTH != 10
			SRGBWriteEnable = true;
		#endif
	}
}
