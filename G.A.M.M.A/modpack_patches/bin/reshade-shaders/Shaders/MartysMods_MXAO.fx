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

    MXAO v1.0

    Author:         Pascal Gilcher

    More info:      https://martysmods.com
                    https://patreon.com/mcflypg
                    https://github.com/martymcmodding  	

=============================================================================*/

//TODO: fix black lines in bottom and right for DX9 (require threads outside view if not 1:1 mapping)

/*=============================================================================
	Preprocessor settings
=============================================================================*/

#ifndef MXAO_AO_TYPE
 #define MXAO_AO_TYPE       0
#endif 

#ifndef MXAO_USE_LAUNCHPAD_NORMALS
 #define MXAO_USE_LAUNCHPAD_NORMALS       0
#endif

/*=============================================================================
	UI Uniforms
=============================================================================*/

uniform int MXAO_GLOBAL_SAMPLE_QUALITY_PRESET <
	ui_type = "combo";
    ui_label = "Sample Quality";
	ui_items = "Low\0Medium\0High\0Very High\0Ultra\0Extreme\0IDGAF\0";
	ui_tooltip = "Global quality control, main performance knob. Higher radii might require higher quality.";
    ui_category = "Global";
> = 1;

uniform int SHADING_RATE <
	ui_type = "combo";
    ui_label = "Shading Rate";
	ui_items = "Full Rate\0Half Rate\0Quarter Rate\0";
	ui_tooltip = "0: render all pixels each frame\n1: render only 50% of pixels each frame\n2: render only 25% of pixels each frame";
    ui_category = "Global";
> = 1;

uniform float MXAO_SAMPLE_RADIUS <
	ui_type = "drag";
	ui_min = 0.5; ui_max = 10.0;
    ui_label = "Sample Radius";
	ui_tooltip = "Sample radius of MXAO, higher means more large-scale occlusion with less fine-scale details.";  
    ui_category = "Global";      
> = 2.5;

uniform bool MXAO_WORLDSPACE_ENABLE <
    ui_label = "Increase Radius with Distance";
    ui_category = "Global";
> = false;

uniform float MXAO_SSAO_AMOUNT <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
    ui_label = "Ambient Occlusion Amount";        
	ui_tooltip = "Intensity of AO effect. Can cause pitch black clipping if set too high.";
    ui_category = "Blending";
> = 0.8;

uniform float MXAO_FADE_DEPTH <
	ui_type = "drag";
    ui_label = "Fade Out Distance";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Fadeout distance for MXAO. Higher values show MXAO in farther areas.";
    ui_category = "Blending";
> = 0.25;

uniform int MXAO_FILTER_SIZE <
	ui_type = "slider";
    ui_label = "Filter Quality";
    ui_min = 0; ui_max = 2;	
    ui_category = "Blending";
> = 1;

uniform bool MXAO_DEBUG_VIEW_ENABLE <
    ui_label = "Show Raw AO";
    ui_category = "Debug";
> = false;

#define TOKENIZE(s) #s

uniform int HELP1 <
ui_type = "radio";
    ui_label = " ";
    ui_category = "Preprocessor definition Documentation";
    ui_category_closed = false;
    ui_text = 
            "\n"
            TOKENIZE(MXAO_AO_TYPE)
            ":\n\n0: Ground Truth Ambient Occlusion (high contrast, fast)\n"
                 "1: Solid Angle (smoother, fastest)\n"
                 "2: Visibility Bitmask (DX11+ only, highest quality, slower)\n"
                 "3: Visibility Bitmask w/ Solid Angle (like 2, only smoother)\n"
            "\n"
            TOKENIZE(MXAO_USE_LAUNCHPAD_NORMALS)
            ":\n\n0: Compute normal vectors on the fly (fast)\n"
                 "1: Use normals from iMMERSE Launchpad (far slower)\n"
                 "   This allows to use Launchpad's smooth normals feature.";
>;

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

#pragma warning(disable : 4000) //uninitialized variable in AO pass at the early out... bruh

//do NOT change anything here. "hurr durr I changed this and now it works"
//you ARE breaking things down the line, if the shader does not work without changes
//here, it's by design.

texture ColorInputTex : COLOR;
texture DepthInputTex : DEPTH;
sampler ColorInput 	{ Texture = ColorInputTex; };
sampler DepthInput  { Texture = DepthInputTex; };

texture ZSrc { Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = R16F; };
sampler sZSrc { Texture = ZSrc; MinFilter=POINT; MipFilter=POINT; MagFilter=POINT;};

texture AOTex1 { Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RG16F;  };
texture AOTex2 { Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RG16F;  };

#if !_COMPUTE_SUPPORTED
texture AOTexRaw { Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RG16F;  };
sampler sAOTexRaw { Texture = AOTexRaw;  MinFilter=POINT; MipFilter=POINT; MagFilter=POINT; };
#endif

sampler sAOTex1 { Texture = AOTex1; };
sampler sAOTex2 { Texture = AOTex2; };

#include ".\MartysMods\mmx_global.fxh"
#include ".\MartysMods\mmx_depth.fxh"
#include ".\MartysMods\mmx_math.fxh"
#include ".\MartysMods\mmx_camera.fxh"

#if MXAO_USE_LAUNCHPAD_NORMALS 
 #include ".\MartysMods\mmx_deferred.fxh"
#endif 

//#undef _COMPUTE_SUPPORTED

#if _COMPUTE_SUPPORTED == 0
 #if MXAO_AO_TYPE >= 2
 #undef MXAO_AO_TYPE
 #define MXAO_AO_TYPE 1
 #endif
#endif

//integer divide, rounding up
#define CEIL_DIV(num, denom) (((num - 1) / denom) + 1)

#if ((BUFFER_WIDTH/4)*4) == BUFFER_WIDTH
 #define DEINTERLEAVE_HIGH       0
 #define DEINTERLEAVE_TILE_COUNT 4u
#else 
 #define DEINTERLEAVE_HIGH       1
 #define DEINTERLEAVE_TILE_COUNT 5u
#endif

uniform uint FRAMECOUNT < source = "framecount"; >;

#if _COMPUTE_SUPPORTED
storage stZSrc       { Texture = ZSrc;            };
storage stAOTex1       { Texture = AOTex1;        };
storage stAOTex2       { Texture = AOTex2;        };
#endif

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

float2 pixel_idx_to_uv(float2 pos, float2 texture_size)
{
    float2 inv_texture_size = rcp(texture_size);
    return pos * inv_texture_size + 0.5 * inv_texture_size;
}

bool check_boundaries(uint2 pos, uint2 dest_size)
{
    return pos.x < dest_size.x && pos.y < dest_size.y; //>= because dest size e.g. 1920, pos [0, 1919]
}

uint2 deinterleave_pos(uint2 pos, uint2 tiles, uint2 gridsize)
{
    int2 tilesize = CEIL_DIV(gridsize, tiles); //gridsize / tiles;
    int2 tile_idx    = pos % tiles;
    int2 pos_in_tile = pos / tiles;
    return tile_idx * tilesize + pos_in_tile;
}

uint2 reinterleave_pos(uint2 pos, uint2 tiles, uint2 gridsize)
{
    int2 tilesize = CEIL_DIV(gridsize, tiles); //gridsize / tiles;
    int2 tile_idx    = pos / tilesize;
    int2 pos_in_tile = pos % tilesize;
    return pos_in_tile * tiles + tile_idx;
}

float2 deinterleave_uv(float2 uv)
{
    float2 splituv = uv * DEINTERLEAVE_TILE_COUNT;
    float2 splitoffset = floor(splituv) - DEINTERLEAVE_TILE_COUNT * 0.5 + 0.5;
    splituv = frac(splituv) + splitoffset * BUFFER_PIXEL_SIZE;
    return splituv;
}
float2 reinterleave_uv(float2 uv)
{
    uint2 whichtile = floor(uv / BUFFER_PIXEL_SIZE) % DEINTERLEAVE_TILE_COUNT;
    float2 newuv = uv + whichtile;
    newuv /= DEINTERLEAVE_TILE_COUNT;
    return newuv;
}

float3 get_normals(in float2 uv, out float edge_weight)
{
    float3 delta = float3(BUFFER_PIXEL_SIZE, 0);
    //similar system to Intel ASSAO/AMD CACAO/XeGTAO and friends with improved weighting and less ALU
    float3 center = Camera::uv_to_proj(uv);
    float3 deltaL = Camera::uv_to_proj(uv - delta.xz) - center;
    float3 deltaR = Camera::uv_to_proj(uv + delta.xz) - center;   
    float3 deltaT = Camera::uv_to_proj(uv - delta.zy) - center;
    float3 deltaB = Camera::uv_to_proj(uv + delta.zy) - center;
    
    float4 zdeltaLRTB = abs(float4(deltaL.z, deltaR.z, deltaT.z, deltaB.z));
    float4 w = zdeltaLRTB.xzyw + zdeltaLRTB.zywx;
    w = rcp(0.001 + w * w); //inverse weighting, larger delta -> lesser weight

    edge_weight = saturate(1.0 - dot(w, 1));

#if MXAO_USE_LAUNCHPAD_NORMALS //this is a bit hacky, we need the edge weight for filtering but Launchpad doesn't give them to us, so we compute the data till here and read launchpad normals
    float3 normal = Deferred::get_normals(uv);
#else 

    float3 n0 = cross(deltaT, deltaL);
    float3 n1 = cross(deltaR, deltaT);
    float3 n2 = cross(deltaB, deltaR);
    float3 n3 = cross(deltaL, deltaB);

    float4 finalweight = w * rsqrt(float4(dot(n0, n0), dot(n1, n1), dot(n2, n2), dot(n3, n3)));
    float3 normal = n0 * finalweight.x + n1 * finalweight.y + n2 * finalweight.z + n3 * finalweight.w;
    normal *= rsqrt(dot(normal, normal) + 1e-8);
#endif 
    return normal;  
}

float get_jitter(uint2 p)
{
    uint tiles = DEINTERLEAVE_TILE_COUNT;
    uint jitter_idx = dot(p % tiles, uint2(1, tiles));
    jitter_idx *= DEINTERLEAVE_HIGH ? 17u : 11u;
    return ((jitter_idx % (tiles * tiles)) + 0.5) / (tiles * tiles);
}

float get_fade_factor(float depth)
{
    float fade = saturate(1 - depth * depth); //fixed fade that smoothly goes to 0 at depth = 1
    depth /= MXAO_FADE_DEPTH;
    return fade * saturate(exp2(-depth * depth)); //overlaying regular exponential fade
}

/*=============================================================================
	Shader Entry Points
=============================================================================*/

VSOUT MainVS(in uint id : SV_VertexID)
{
    VSOUT o;
    FullscreenTriangleVS(id, o.vpos, o.uv); 
    return o;
}

#if _COMPUTE_SUPPORTED
void DepthInterleaveCS(in CSIN i)
{
    if(!check_boundaries(i.dispatchthreadid.xy * 2, BUFFER_SCREEN_SIZE)) return;

    float2 uv = pixel_idx_to_uv(i.dispatchthreadid.xy * 2, BUFFER_SCREEN_SIZE);
    float2 corrected_uv = Depth::correct_uv(uv); //fixed for lookup 

#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
    corrected_uv.y -= BUFFER_PIXEL_SIZE.y * 0.5;    //shift upwards since gather looks down and right
    float4 depth_texels = tex2DgatherR(DepthInput, corrected_uv).wzyx;  
#else
    float4 depth_texels = tex2DgatherR(DepthInput, corrected_uv);
#endif

    depth_texels = Depth::linearize(depth_texels);
    depth_texels.x = Camera::depth_to_z(depth_texels.x);
    depth_texels.y = Camera::depth_to_z(depth_texels.y);
    depth_texels.z = Camera::depth_to_z(depth_texels.z);
    depth_texels.w = Camera::depth_to_z(depth_texels.w);

    //offsets for xyzw components
    const uint2 offsets[4] = {uint2(0, 1), uint2(1, 1), uint2(1, 0), uint2(0, 0)};

    [unroll]
    for(uint j = 0; j < 4; j++)
    {
        uint2 write_pos = deinterleave_pos(i.dispatchthreadid.xy * 2 + offsets[j], DEINTERLEAVE_TILE_COUNT, BUFFER_SCREEN_SIZE);
        tex2Dstore(stZSrc, write_pos, depth_texels[j]);
    }
}
#else 
void DepthInterleavePS(in VSOUT i, out float o : SV_Target0)
{ 
    float2 get_uv = deinterleave_uv(i.uv);
    o = Camera::depth_to_z(Depth::get_linear_depth(get_uv));
}
#endif

float2 MXAO(in float4 uv, in uint2 tile_idx, in uint2 write_pos)
{ 	
    float z = tex2Dlod(sZSrc, uv.xy, 0).x;
    float d = Camera::z_to_depth(z);

    [branch]
    if(get_fade_factor(d) < 0.001) return float2(1, d);

    float3 p = Camera::uv_to_proj(uv.zw, z); 
    float edge_weight;  
    float3 n = get_normals(uv.zw, edge_weight);
    p = p * 0.996;
    float3 v = normalize(-p);  

    static const float4 texture_scale = float2(1.0 / DEINTERLEAVE_TILE_COUNT, 1.0).xxyy * BUFFER_ASPECT_RATIO.xyxy;

    static const uint2 samples_per_preset[7] = {uint2(2, 2), uint2(4, 2), uint2(5, 4), uint2(6, 6), uint2(6, 9), uint2(8, 12), uint2(10, 24)};//8, 16, 40, 72, 90, 192, 480 samples
    uint slice_count  = samples_per_preset[MXAO_GLOBAL_SAMPLE_QUALITY_PRESET].x;    
    uint sample_count = samples_per_preset[MXAO_GLOBAL_SAMPLE_QUALITY_PRESET].y; 

    float jitter = get_jitter(write_pos);    
    float3 slice_dir = 0; sincos(jitter * PI * (6.0/slice_count), slice_dir.x, slice_dir.y);    
    float2x2 rotslice; sincos(PI / slice_count, rotslice._21, rotslice._11); rotslice._12 = -rotslice._21; rotslice._22 = rotslice._11;    

    float worldspace_radius = MXAO_SAMPLE_RADIUS * 0.5;
    float screenspace_radius = worldspace_radius / p.z * 0.5;

    [flatten]
    if(MXAO_WORLDSPACE_ENABLE)
    {
        screenspace_radius = MXAO_SAMPLE_RADIUS * 0.03;
        worldspace_radius = screenspace_radius * p.z * 2.0;
    }

    float visibility = 0;
    float slicesum = 0;  
    float T = 0.25 * worldspace_radius;  //arbitrary thickness that looks good relative to sample radius  
    float falloff_factor = rcp(worldspace_radius);
    falloff_factor *= falloff_factor;

    while(slice_count-- > 0) //1 less register and a bit faster
    {        
        slice_dir.xy = mul(slice_dir.xy, rotslice);
        float3 ortho_dir = slice_dir - dot(slice_dir.xy, v.xy) * v; //z = 0 so no need for full dot3
        
        float3 slice_n = cross(slice_dir, v); 
        slice_n *= rsqrt(dot(slice_n, slice_n));   

        float4 scaled_dir = (slice_dir.xy * screenspace_radius).xyxy * texture_scale; 

        float3 n_proj_on_slice = n - slice_n * dot(n, slice_n);
        float sliceweight = sqrt(dot(n_proj_on_slice, n_proj_on_slice));
          
        float cosn = saturate(dot(n_proj_on_slice, v) * rcp(sliceweight));
        float normal_angle = Math::fast_acos(cosn) * Math::fast_sign(dot(ortho_dir, n_proj_on_slice));
        
        float2 maxhorizoncos = sin(normal_angle); maxhorizoncos.y = -maxhorizoncos.y; //cos(normal_angle -+ pi/2)  
        uint occlusion_bitfield = 0xFFFFFFFF;        

        [unroll]
        for(int side = 0; side < 2; side++)
        {            
            maxhorizoncos = maxhorizoncos.yx; //can't trust Vulkan to unroll, so make indices natively addressable for that little more efficiency
            float lowesthorizoncos = maxhorizoncos.x; //much better falloff than original GTAO :)

            [loop]         
            for(int _sample = 0; _sample < sample_count; _sample += 2)
            {
                float2 s = (_sample + float2(0, 1) + jitter) / sample_count; s *= s;  
                float4 tap_uv[2] = {uv + s.x * scaled_dir, uv + s.y * scaled_dir};

                float2 zz; //https://developer.nvidia.com/blog/the-peak-performance-analysis-method-for-optimizing-any-gpu-workload/
                zz.x = tex2Dlod(sZSrc, tap_uv[0].xy, 0).x;  
                zz.y = tex2Dlod(sZSrc, tap_uv[1].xy, 0).x; 

                if(!all(saturate(tap_uv[1].zw - tap_uv[1].zw * tap_uv[1].zw))) break;

                [unroll] //less VGPR by splitting
                for(uint pair = 0; pair < 2; pair++)
                {
                    float3 deltavec = Camera::uv_to_proj(tap_uv[pair].zw, zz[pair]) - p;
#if MXAO_AO_TYPE < 2
                    float ddotd = dot(deltavec, deltavec);    
                    float samplehorizoncos = dot(deltavec, v) * rsqrt(ddotd);
                    float falloff = rcp(1 + ddotd * falloff_factor);
                    samplehorizoncos = lerp(lowesthorizoncos, samplehorizoncos, falloff);
                    maxhorizoncos.x = max(maxhorizoncos.x, samplehorizoncos);  
#else      
                    float ddotv = dot(deltavec, v);
                    float ddotd = dot(deltavec, deltavec);
                    float2 h_frontback = float2(ddotv, ddotv - T) * rsqrt(float2(ddotd, ddotd - 2 * T * ddotv + T * T));

                    h_frontback = Math::fast_acos(h_frontback);
                    h_frontback = side ? h_frontback : -h_frontback.yx;//flip sign and sort in the same cmov, efficiency baby!
                    h_frontback = saturate((h_frontback + normal_angle) / PI + 0.5);
#if MXAO_AO_TYPE == 2
                    //this almost perfectly approximates inverse transform sampling for cosine lobe
                    h_frontback = h_frontback * h_frontback * (3.0 - 2.0 * h_frontback); 
#endif
                    uint a = uint(h_frontback.x * 32);
                    uint b = round(saturate(h_frontback.y - h_frontback.x) * 32); //ceil? using half occlusion here
                    uint occlusion = ((1 << b) - 1) << a;
                    occlusion_bitfield &= ~occlusion; //somehow "and" is faster than "or" based occlusion
#endif                
                }              
            }
            scaled_dir = -scaled_dir; //unroll kills that :)                                  
        }
#if MXAO_AO_TYPE == 0
        float2 max_horizon_angle = Math::fast_acos(maxhorizoncos);
        float2 h = float2(-max_horizon_angle.x, max_horizon_angle.y); //already clamped at init
        visibility += dot(cosn + 2.0 * h * sin(normal_angle) - cos(2.0 * h - normal_angle), sliceweight);
        slicesum++;
#elif MXAO_AO_TYPE == 1
        float2 max_horizon_angle = Math::fast_acos(maxhorizoncos);
        visibility += dot(max_horizon_angle, sliceweight);
        slicesum += sliceweight;
#else
        visibility += saturate(countbits(occlusion_bitfield) / 32.0) * sliceweight;
        slicesum += sliceweight;            
#endif
    }

#if MXAO_AO_TYPE == 0
    visibility /= slicesum * 4;
#elif MXAO_AO_TYPE == 1
    visibility /= slicesum * PI;
#else 
    visibility /= slicesum;
#endif
    return float2(saturate(visibility), edge_weight > 0.5 ? -d : d);//store depth negated for pixels with low normal confidence to drive the filter
}

bool shading_rate(uint2 tile_idx)
{
    bool skip_pixel = false;
    switch(SHADING_RATE)
    {
#if _COMPUTE_SUPPORTED //bitwise :yeahboiii:
        case 1: skip_pixel = ((tile_idx.x + tile_idx.y) & 1) ^ (FRAMECOUNT & 1); break;     
        case 2: skip_pixel = (tile_idx.x & 1 + (tile_idx.y & 1) * 2) ^ (FRAMECOUNT & 3); break; 
#else 
        case 1: skip_pixel = ((tile_idx.x + tile_idx.y) % 2) != (FRAMECOUNT % 2); break;     
        case 2: skip_pixel = (tile_idx.x % 2 + (tile_idx.y % 2) * 2) != (FRAMECOUNT % 4); break; 
#endif
    }
    return skip_pixel;
}

#if _COMPUTE_SUPPORTED
void OcclusionWrapCS(in CSIN i)
{
    //need to round up here, otherwise resolutions not divisible by interleave tile amount will cause trouble,
    //as even thread groups that hang over the texture boundaries have draw areas inside. However we cannot allow all
    //of them to attempt to work - I'm not sure why.
    if(!check_boundaries(i.dispatchthreadid.xy, CEIL_DIV(BUFFER_SCREEN_SIZE, DEINTERLEAVE_TILE_COUNT) * DEINTERLEAVE_TILE_COUNT)) return; 

    uint2 write_pos = reinterleave_pos(i.dispatchthreadid.xy, DEINTERLEAVE_TILE_COUNT, BUFFER_SCREEN_SIZE);
    uint2 tile_idx = i.dispatchthreadid.xy / CEIL_DIV(BUFFER_SCREEN_SIZE, DEINTERLEAVE_TILE_COUNT);

    if(shading_rate(tile_idx)) return;
   
    float4 uv;
    uv.xy = pixel_idx_to_uv(i.dispatchthreadid.xy, BUFFER_SCREEN_SIZE);
    uv.zw = pixel_idx_to_uv(write_pos, BUFFER_SCREEN_SIZE);

    float2 ao_and_guide = MXAO(uv, tile_idx, write_pos);
    tex2Dstore(stAOTex1, write_pos, ao_and_guide.xyyy);
}
#else 
void OcclusionWrap1PS(in VSOUT i, out float2 o : SV_Target0) //writes to AOTex2
{
    uint2 dispatchthreadid = floor(i.vpos.xy);
    uint2 write_pos = reinterleave_pos(dispatchthreadid, DEINTERLEAVE_TILE_COUNT, BUFFER_SCREEN_SIZE);
    uint2 tile_idx = dispatchthreadid / CEIL_DIV(BUFFER_SCREEN_SIZE, DEINTERLEAVE_TILE_COUNT);

    if(shading_rate(tile_idx)) discard;   
   

    float4 uv;
    uv.xy = pixel_idx_to_uv(dispatchthreadid, BUFFER_SCREEN_SIZE);
    //uv.zw = pixel_idx_to_uv(write_pos, BUFFER_SCREEN_SIZE);
    uv.zw = deinterleave_uv(uv.xy); //no idea why _this_ works but the other doesn't but that's just DX9 being a jackass I guess
    o = MXAO(uv, tile_idx, write_pos);
}

void OcclusionWrap2PS(in VSOUT i, out float2 o : SV_Target0) 
{
	uint2 dispatchthreadid = floor(i.vpos.xy);
    uint2 read_pos = deinterleave_pos(dispatchthreadid, DEINTERLEAVE_TILE_COUNT, BUFFER_SCREEN_SIZE);
    uint2 tile_idx = dispatchthreadid / CEIL_DIV(BUFFER_SCREEN_SIZE, DEINTERLEAVE_TILE_COUNT);
    
    //need to do it here again because the AO pass writes to AOTex2, which is also intermediate for filter
    //so we only take the new texels and transfer them to AOTex1, so AOTex1 contains unfiltered, reconstructed data
    if(shading_rate(tile_idx)) discard;
    o = tex2Dfetch(sAOTexRaw, read_pos).xy;    
}
#endif
/*
float2 filter_crossbilateral(float2 uv, sampler sAO, int iter)
{
    float2 center = tex2Dlod(sAO, uv, 0).xy;
    float2 axis = float2(iter, !iter) * BUFFER_PIXEL_SIZE;

    int k = 5;
    float sigma = (k + 1.0) * 0.5;
    float falloff = rcp(2 * sigma * sigma);

    float4 mv = float4(center.y, center.y * center.y, center.x, center.x * center.y);
    float wsum = 1;

    [unroll]
    for(int j = 1; j < k; j++)
    {      
        float2 tap = tex2Dlod(sAO, uv + axis * j, 0).xy;
        float w = exp2(-j*j*falloff);
        mv += float4(tap.y, tap.y * tap.y, tap.x, tap.x * tap.y) * w;     
        tap = tex2Dlod(sAO, uv - axis * j, 0).xy;   
        mv += float4(tap.y, tap.y * tap.y, tap.x, tap.x * tap.y) * w;
        wsum += 2.0 * w;
    }

    mv /= wsum;

    float b = (mv.w - mv.x * mv.z) / max(mv.y - mv.x * mv.x, exp2(-28));
    float a = mv.z - b * mv.x;
    return float2(saturate(b * center.y + a), center.y);
}
*/
//todo add direct sample method for DX9
float2 filter(float2 uv, sampler sAO, int iter)
{ 
    float g = tex2D(sAO, uv).y;
    bool blurry = g < 0;
    float flip = iter ? -1 : 1;

    float4 ao, depth, mv;
    ao = tex2DgatherR(sAO, uv + flip * BUFFER_PIXEL_SIZE * float2(-0.5, -0.5));
    depth = abs(tex2DgatherG(sAO, uv + flip * BUFFER_PIXEL_SIZE * float2(-0.5, -0.5))); //abs because sign flip for edge pixels!
    mv += float4(dot(depth, 1), dot(depth, depth), dot(ao, 1), dot(ao, depth));

    ao = tex2DgatherR(sAO, uv + flip * BUFFER_PIXEL_SIZE * float2(1.5, -0.5));
    depth = abs(tex2DgatherG(sAO, uv + flip * BUFFER_PIXEL_SIZE * float2(1.5, -0.5)));
    mv += float4(dot(depth, 1), dot(depth, depth), dot(ao, 1), dot(ao, depth));

    ao = tex2DgatherR(sAO, uv + flip * BUFFER_PIXEL_SIZE * float2(-0.5, 1.5));
    depth = abs(tex2DgatherG(sAO, uv + flip * BUFFER_PIXEL_SIZE * float2(-0.5, 1.5)));
    mv += float4(dot(depth, 1), dot(depth, depth), dot(ao, 1), dot(ao, depth));
    
    ao = tex2DgatherR(sAO, uv + flip * BUFFER_PIXEL_SIZE * float2(1.5, 1.5));
    depth = abs(tex2DgatherG(sAO, uv + flip * BUFFER_PIXEL_SIZE * float2(1.5, 1.5)));
    mv += float4(dot(depth, 1), dot(depth, depth), dot(ao, 1), dot(ao, depth));

    mv /= 16.0;

    float b = (mv.w - mv.x * mv.z) / max(mv.y - mv.x * mv.x, exp2(blurry ? -12 : -30));
    float a = mv.z - b * mv.x;
    return float2(saturate(b * abs(g) + a), g); //abs because sign flip for edge pixels!
}

void Filter1PS(in VSOUT i, out float2 o : SV_Target0)
{    
    if(MXAO_FILTER_SIZE < 2) discard;
    o = filter(i.uv, sAOTex1, 0);
}

void Filter2PS(in VSOUT i, out float3 o : SV_Target0)
{    
    float2 t;
    [branch]
    if(MXAO_FILTER_SIZE == 2)
        t = filter(i.uv, sAOTex2, 1);
    else if(MXAO_FILTER_SIZE == 1)
        t = filter(i.uv, sAOTex1, 1);
    else 
        t = tex2Dlod(sAOTex1, i.uv, 0).xy;

    float mxao = t.x, d = abs(t.y);  //abs because sign flip for edge pixels!

    mxao = lerp(1, mxao, saturate(MXAO_SSAO_AMOUNT)); 
    if(MXAO_SSAO_AMOUNT > 1) mxao = lerp(mxao, mxao * mxao, saturate(MXAO_SSAO_AMOUNT - 1)); //if someone _MUST_ use a higher intensity, switch to gamma
    mxao = lerp(1, mxao, get_fade_factor(d));

    float3 color = tex2D(ColorInput, i.uv).rgb;

    color *= color;
    color = color * rcp(1.1 - color);
    color *= mxao;
    color = 1.1 * color * rcp(color + 1.0); 
    color = sqrt(color); 

    o = MXAO_DEBUG_VIEW_ENABLE ? mxao : color;
}

/*=============================================================================
	Techniques
=============================================================================*/

technique MartysMods_MXAO
<
    ui_label = "iMMERSE MXAO";
    ui_tooltip =        
        "                              MartysMods - MXAO                               \n"
        "                   MartysMods Epic ReShade Effects (iMMERSE)                  \n"
        "______________________________________________________________________________\n"
        "\n"

        "MXAO is a high quality, high performance Screen-Space Ambient Occlusion (SSAO)\n"
        "effect which accurately simulates diffuse shadows in dark corners and crevices\n"
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
        ComputeShader = DepthInterleaveCS<32, 32>;
        DispatchSizeX = CEIL_DIV(BUFFER_WIDTH, 64); 
        DispatchSizeY = CEIL_DIV(BUFFER_HEIGHT, 64);
    }
    pass 
    { 
        ComputeShader = OcclusionWrapCS<16, 16>;
        DispatchSizeX = CEIL_DIV(BUFFER_WIDTH, 16); 
        DispatchSizeY = CEIL_DIV(BUFFER_HEIGHT, 16);
    }
#else 
    pass { VertexShader = MainVS; PixelShader = DepthInterleavePS; RenderTarget = ZSrc; }
    pass { VertexShader = MainVS; PixelShader = OcclusionWrap1PS;  RenderTarget = AOTexRaw; }
    pass { VertexShader = MainVS; PixelShader = OcclusionWrap2PS;  RenderTarget = AOTex1; }
#endif
    pass { VertexShader = MainVS; PixelShader = Filter1PS; RenderTarget = AOTex2; }
    pass { VertexShader = MainVS; PixelShader = Filter2PS; }
}
