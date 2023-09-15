//NiceGuy Lamps
//Written by MJ_Ehsan with the contribution of LVunter(tnx <3) for Reshade
//Version 1.1 beta

//license
//CC0 ^_^
///////////////Include/////////////////////

#include "ReShade.fxh"

#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
#define LDepth ReShade::GetLinearizedDepth

uniform float Frame < source = "framecount"; >;
#pragma warning(disable : 3571)
///////////////Include/////////////////////
///////////////PreProcessor-Definitions////

static const float fov = 60;
#define PI 3.1415927
#define PI2 2*PI
#define rad(x) (x/360)*PI2
#define FAR_PLANE RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
#define CENTER_POINT 0.5

#define ICON_SIZE 0.02
#define IconOcclusionTransparency 0.1

#ifndef SMOOTH_NORMALS
 #define SMOOTH_NORMALS 2
#endif
//Smooth Normals configs. It uses a separable bilateral blur which uses only normals as determinator. 
#define SNThreshold 0.5 //Bilateral Blur Threshold for Smooth normals passes. default is 0.5
#define SNDepthW FAR_PLANE*SNThreshold //depth weight as a determinator. default is 100/SNThreshold
#if SMOOTH_NORMALS <= 1 //13*13 8taps
 #define LODD 0.5    //Don't touch this for God's sake
 #define SNWidth 5.5 //Blur pixel offset for Smooth Normals
 #define SNSamples 1 //actually SNSamples*4+4!
#elif SMOOTH_NORMALS == 2 //16*16 16taps
 #define LODD 0.5
 #define SNWidth 2.5
 #define SNSamples 3
#elif SMOOTH_NORMALS > 2 //31*31 84taps
 #warning "SMOOTH_NORMALS 3 is slow and should to be used for photography or old games. Otherwise set to 2 or 1."
 #define LODD 0
 #define SNWidth 1
 #define SNSamples 30
#endif

///////////////PreProcessor-Definitions////
///////////////Textures-Samplers///////////

texture TexColor : COLOR;
sampler sTexColor {Texture = TexColor; };

texture LampIcon <source = "NGLamp-Lamp-Icon.jpg";>{ Width = 814; Height = 814; Format = R8; MipLevels = 6; };
sampler sLampIcon { Texture = LampIcon; AddressU = CLAMP; AddressV = CLAMP; };

texture NormTex  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sNormTex { Texture = NormTex; };

texture NormTex1  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sNormTex1 { Texture = NormTex1; };

texture VarianceTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f;};
sampler sVarianceTex {Texture = VarianceTex;};

texture ShadowTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f;};
sampler sShadowTex {Texture = ShadowTex;};

texture BGColorTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f;};
sampler sBGColorTex {Texture = BGColorTex;};

texture LightingTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f;};
sampler sLightingTex {Texture = LightingTex;};

texture BlendedTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f;};
sampler sBlendedTex {Texture = BlendedTex;};

texture LitHistTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f;};
sampler sLitHistTex {Texture = LitHistTex;};

texture NGLa_BlueNoise <source="BlueNoise-64frames128x128.png";> { Width = 1024; Height = 1024; Format = RGBA8;};
sampler sNGLa_BlueNoise { Texture = NGLa_BlueNoise; AddressU = REPEAT; AddressV = REPEAT; MipFilter = Point; MinFilter = Point; MagFilter = Point; };

texture texMotionVectors { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
sampler SamplerMotionVectors { Texture = texMotionVectors; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Point; MagFilter = Point; };

///////////////Textures-Samplers///////////
///////////////UI//////////////////////////

uniform int Hints<
	ui_text = "This shader lacks an internal denoiser at the moment.\n"
			  "Use either FXAA or TFAA and set the denoiser option accordingly."
			  "Bump mapping may break the look. I'm trying to solve it tho.";
			  
	ui_category = "Hints - Please Read for good results.";
	ui_category_closed = true;
	ui_label = " ";
	ui_type = "radio";
>;

uniform bool debug <
	ui_label = "Debug";
	ui_category = "General";
> = 0;

uniform bool ShowIcon <
	ui_label = "Show lamp icons";
	ui_category = "General";
> = 1;

uniform bool LimitPos <
	ui_label = "Limit lamp to depth";
	ui_tooltip = "Limit lamp position to the wall behind them";
	ui_category = "General";
> = 0;

uniform float OGLighting <
	ui_label = "Original lighting";
	ui_type = "slider";
	ui_category = "General";
> = 1;

uniform float BUMP <
	ui_label = "Bump mapping";
	ui_type = "slider";
	ui_category = "General";
	ui_min = 0.0;
	ui_max = 1;
> = 0;

uniform int Shadow_Quality <
	ui_label = "Shadow quality";
	ui_type = "combo";
	ui_items = "Low (16 steps)\0Medium (48 steps)\0High (256 steps)\0";
	ui_category = "Shadows";
> = 0;

uniform float Shadow_Depth <
	ui_label = "Surface Depth";
	ui_type = "drag";
	ui_tooltip = "Depth buffer doesn't have information\n"
				 "about the depth of each object. Thus\n"
				 "we have to take this number as that.";
	ui_category = "Shadows";
	ui_max = 10;
	ui_min = 0;
	ui_step = 0.01;
> = 3;

uniform float UI_FOG_DENSITY <
	ui_type = "slider";
	ui_label = "Fog Density";
	ui_category = "Fog";
	ui_max = 1;
> = 0.2;
#define UI_FOG_DENSITY UI_FOG_DENSITY/3000

uniform float3 UI_FOG_COLOR <
	ui_type = "color";
	ui_label = "Fog Color";
	ui_category = "Fog";
> = 1;

uniform bool UI_FOG_DEPTH_MASK <
	ui_type = "radio";
	ui_label = "Mask Fog with depth";
	ui_tooltip = "Uses depth to mask the fog,\n"
				 "faking volumetric shadows to make to fog appear behind objects";
	ui_category = "Fog";
> = 0;

uniform float roughness <
	ui_type = "slider";
	ui_category = "Reflections";
	ui_label = "Roughness";
	ui_tooltip = "How wide it should search for variation in roughness?\n"
				 "Low = Detailed\nHigh = Soft";
	ui_max = 1;
> = 1;

uniform float specular <
	ui_type = "slider";
	ui_category = "Reflections";
	ui_min = 0;
	ui_max = 1;
> = 0.1;

/*_________________________________________
                                           |
Lamp 1 Inputs                              |
__________________________________________*/

uniform bool L1 <
	ui_label = "Enable Lamp 1";
	ui_category = "Lamp 1";
	ui_category_closed = true;
> = 1;

uniform bool UI_FOG1 <
	ui_label = "Enable fog";
	ui_category = "Lamp 1";
	ui_category_closed = true;
> = 1;

uniform bool UI_S_ENABLE1 <
	ui_label = "Enable Shadows";
	ui_category = "Lamp 1";
	ui_category_closed = true;
> = 1;

uniform float3 UI_LAMP1 <
	ui_type = "slider";
	ui_label= "Position";
	ui_category = "Lamp 1";
	ui_category_closed = true;
> = float3(0.5, 0.5, 0.03125);

uniform float3 UI_LAMP1_PRECISE <
	ui_type = "slider";
	ui_label= "Precise Position";
	ui_max =  0.02;
	ui_min = -0.02;
	ui_category = "Lamp 1";
	ui_category_closed = true;
> = float3(0, 0, 0);

uniform float3 UI_COLOR1 <
	ui_type = "color";
	ui_label= "Color";
	ui_category = "Lamp 1";
	ui_category_closed = true;
> = 1;

uniform float UI_POWER1 <
	ui_type = "slider";
	ui_label= "Power";
	ui_max  = 10;
	ui_category = "Lamp 1";
	ui_category_closed = true;
> = 5;

uniform float UI_SOFT_S1 <
	ui_type = "slider";
	ui_label= "Shadow Softness";
	ui_max  = 10;
	ui_category = "Lamp 1";
	ui_category_closed = true;
> = 0;

/*_________________________________________
                                           |
Lamp 2 Inputs                              |
__________________________________________*/
uniform bool L2 <
	ui_label = "Enable Lamp 2";
	ui_category = "Lamp 2";
	ui_category_closed = true;
> = 0;

uniform bool UI_FOG2 <
	ui_label = "Enable fog";
	ui_category = "Lamp 2";
	ui_category_closed = true;
> = 1;

uniform bool UI_S_ENABLE2 <
	ui_label = "Enable Shadows";
	ui_category = "Lamp 2";
	ui_category_closed = true;
> = 1;

uniform float3 UI_LAMP2 <
	ui_type = "slider";
	ui_label= "Position";
	ui_category = "Lamp 2";
	ui_category_closed = true;
> = float3(0.5, 0.25, 0.03125);

uniform float3 UI_LAMP2_PRECISE <
	ui_type = "slider";
	ui_label= "Precise Position";
	ui_max =  0.02;
	ui_min = -0.02;
	ui_category = "Lamp 2";
	ui_category_closed = true;
> = float3(0, 0, 0);

uniform float3 UI_COLOR2 <
	ui_type = "color";
	ui_label= "Color";
	ui_category = "Lamp 2";
	ui_category_closed = true;
> = 1;

uniform float UI_POWER2 <
	ui_type = "slider";
	ui_label= "Power";
	ui_max  = 10;
	ui_category = "Lamp 2";
	ui_category_closed = true;
> = 5;

uniform float UI_SOFT_S2 <
	ui_type = "slider";
	ui_label= "Shadow Softness";
	ui_max  = 10;
	ui_category = "Lamp 2";
	ui_category_closed = true;
> = 0;

/*_________________________________________
                                           |
Lamp 3 Inputs                              |
__________________________________________*/
uniform bool L3 <
	ui_label = "Enable Lamp 3";
	ui_category = "Lamp 3";
	ui_category_closed = true;
> = 0;

uniform bool UI_FOG3 <
	ui_label = "Enable fog";
	ui_category = "Lamp 3";
	ui_category_closed = true;
> = 1;

uniform bool UI_S_ENABLE3 <
	ui_label = "Enable Shadows";
	ui_category = "Lamp 3";
	ui_category_closed = true;
> = 1;

uniform float3 UI_LAMP3 <
	ui_type = "slider";
	ui_label= "Position";
	ui_category = "Lamp 3";
	ui_category_closed = true;
> = float3(0.5, 0.75, 0.03125);

uniform float3 UI_LAMP3_PRECISE <
	ui_type = "slider";
	ui_label= "Precise Position";
	ui_max =  0.02;
	ui_min = -0.02;
	ui_category = "Lamp 3";
	ui_category_closed = true;
> = float3(0, 0, 0);

uniform float3 UI_COLOR3 <
	ui_type = "color";
	ui_label= "Color";
	ui_category = "Lamp 3";
	ui_category_closed = true;
> = 1;

uniform float UI_POWER3 <
	ui_type = "slider";
	ui_label= "Power";
	ui_max  = 10;
	ui_category = "Lamp 3";
	ui_category_closed = true;
> = 5;

uniform float UI_SOFT_S3 <
	ui_type = "slider";
	ui_label= "Shadow Softness";
	ui_max  = 10;
	ui_category = "Lamp 3";
	ui_category_closed = true;
> = 0;

/*_________________________________________
                                           |
Lamp 4 Inputs                              |
__________________________________________*/
uniform bool L4 <
	ui_label = "Enable Lamp 4";
	ui_category = "Lamp 4";
	ui_category_closed = true;
> = 0;

uniform bool UI_FOG4 <
	ui_label = "Enable fog";
	ui_category = "Lamp 4";
	ui_category_closed = true;
> = 1;

uniform bool UI_S_ENABLE4 <
	ui_label = "Enable Shadows";
	ui_category = "Lamp 4";
	ui_category_closed = true;
> = 1;

uniform float3 UI_LAMP4 <
	ui_type = "slider";
	ui_label= "Position";
	ui_category = "Lamp 4";
	ui_category_closed = true;
> = float3(0.25, 0.5, 0.03125);

uniform float3 UI_LAMP4_PRECISE <
	ui_type = "slider";
	ui_label= "Precise Position";
	ui_max =  0.02;
	ui_min = -0.02;
	ui_category = "Lamp 4";
	ui_category_closed = true;
> = float3(0, 0, 0);

uniform float3 UI_COLOR4 <
	ui_type = "color";
	ui_label= "Color";
	ui_category = "Lamp 4";
	ui_category_closed = true;
> = 1;

uniform float UI_POWER4 <
	ui_type = "slider";
	ui_label= "Power";
	ui_max  = 10;
	ui_category = "Lamp 4";
	ui_category_closed = true;
> = 5;

uniform float UI_SOFT_S4 <
	ui_type = "slider";
	ui_label= "Shadow Softness";
	ui_max  = 10;
	ui_category = "Lamp 4";
	ui_category_closed = true;
> = 0;

///////////////UI//////////////////////////
///////////////Vertex Shader///////////////
///////////////Vertex Shader///////////////
///////////////Functions///////////////////

#include "NGLamps-GGX.fxh"

float noise(float2 co)
{
  return frac(sin(dot(co.xy ,float2(1.0,73))) * 437580.5453);
}

float IGN(float2 n) {
    float f = 0.06711056 * n.x + 0.00583715 * n.y;
    return frac(52.9829189 * frac(f));
}


float3 noise3dts(float2 co, float s, float frame)
{
	co += sin(frame/120.347668756453546);
	co += s/16.3542625435332254;
	return float3( noise(co), noise(co+0.6432168421), noise(co+0.19216811));
}

float3 BN3dts(float2 texcoord)
{
	texcoord *= BUFFER_SCREEN_SIZE; //convert to pixel index
	
	texcoord = texcoord%128; //limit to texture size
	
	float frame = Frame%64; //limit frame index to history length
	int2 F;
	F.x = frame%8; //Go from left to right each frame. start over after 8th
	F.y = floor(frame/8)%8; //Go from top to buttom each 8 frame. start over after 8th
	F *= 128; //Each step jumps to the next texture 
	texcoord += F;
	texcoord /= 1024; //divide by atlas size
	float3 Tex = tex2D(sNGLa_BlueNoise, texcoord).rgb;
	return Tex;
}

float3 UVtoPos(float2 texcoord)
{
	float3 scrncoord = float3(texcoord.xy*2-1, LDepth(texcoord) * FAR_PLANE);
	scrncoord.xy *= scrncoord.z * (rad(fov*0.5));
	scrncoord.x *= BUFFER_ASPECT_RATIO;
	
	return scrncoord.xyz;
}

float3 UVtoPos(float2 texcoord, float depth)
{
	float3 scrncoord = float3(texcoord.xy*2-1, depth * FAR_PLANE);
	scrncoord.xy *= scrncoord.z * (rad(fov*0.5));
	scrncoord.x *= BUFFER_ASPECT_RATIO;
	
	return scrncoord.xyz;
}

float2 PostoUV(float3 position)
{
	float2 scrnpos = position.xy;
	scrnpos.x /= BUFFER_ASPECT_RATIO;
	scrnpos /= position.z*rad(fov/2);
	
	return scrnpos/2 + 0.5;
}

float3 Normal(float2 texcoord)
{
	float2 p = pix;
	float3 u,d,l,r,u2,d2,l2,r2;
	
	u = UVtoPos( texcoord + float2( 0, p.y));
	d = UVtoPos( texcoord - float2( 0, p.y));
	l = UVtoPos( texcoord + float2( p.x, 0));
	r = UVtoPos( texcoord - float2( p.x, 0));
	
	p *= 2;
	
	u2 = UVtoPos( texcoord + float2( 0, p.y));
	d2 = UVtoPos( texcoord - float2( 0, p.y));
	l2 = UVtoPos( texcoord + float2( p.x, 0));
	r2 = UVtoPos( texcoord - float2( p.x, 0));
	
	u2 = u + (u - u2);
	d2 = d + (d - d2);
	l2 = l + (l - l2);
	r2 = r + (r - r2);
	
	float3 c = UVtoPos( texcoord);
	
	float3 v = u-c; float3 h = r-c;
	
	if( abs(d2.z-c.z) < abs(u2.z-c.z) ) v = c-d;
	if( abs(l2.z-c.z) < abs(r2.z-c.z) ) h = c-l;
	
	return normalize(cross( v, h));
}


float3 Tonemapper(float3 color)
{//Timothy Lottes fast_reversible
	return color.rgb / (1.0 + color);
}

float InvTonemapper(float color)
{//Reinhardt reversible
	return color / (1.0 - color);
}

float3 InvTonemapper(float3 color)
{//Timothy Lottes fast_reversible
	return color / (1.001 - color);
}

float lum(in float3 color)
{
	return 0.333333 * (color.r + color.g + color.b);
}

#define BT 1000
float3 Bump(float2 texcoord, float height)
{
	float2 p = pix;
	
	float3 s[3];
	s[0] = tex2D(sTexColor, texcoord + float2(p.x, 0)).rgb;
	s[1] = tex2D(sTexColor, texcoord + float2(0, p.y)).rgb;
	s[2] = tex2D(sTexColor, texcoord).rgb;
	float LC = rcp(lum(s[0]+s[1]+s[2])) * height;
	LC = min(LC, 4);
	s[0] *= LC; s[1] *= LC; s[2] *= LC;
	float d[3];
	d[0] = LDepth(texcoord + float2(p.x, 0));
	d[1] = LDepth(texcoord + float2(0, p.y));
	d[2] = LDepth(texcoord);
	
	//s[0] *= saturate(1-abs(d[0] - d[2])*1000);
	//s[1] *= saturate(1-abs(d[1] - d[2])*1000);
	
	float3 XB = s[2]-s[0];
	float3 YB = s[2]-s[1];
	
	float3 bump = float3(lum(XB)*saturate(1-abs(d[0] - d[2])*BT), lum(YB)*saturate(1-abs(d[1] - d[2])*BT), 1);
	bump = normalize(bump);
	return bump;
}

float3 blend_normals(float3 n1, float3 n2)
{
    n1 += float3( 0, 0, 1);
    n2 *= float3(-1, -1, 1);
    return n1*dot(n1, n2)/n1.z - n2;
}

bool is_saturated(float2 uv)
{
	return uv.x>1||uv.y>1||uv.x<0||uv.y<0;
}

//from: https://www.shadertoy.com/view/XsSfzV
// by Nikos Papadopoulos, 4rknova / 2015
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
float3 toYCC(float3 rgb)
{
	float Y  =  .299 * rgb.x + .587 * rgb.y + .114 * rgb.z; // Luminance
	float Cb = -.169 * rgb.x - .331 * rgb.y + .500 * rgb.z; // Chrominance Blue
	float Cr =  .500 * rgb.x - .419 * rgb.y - .081 * rgb.z; // Chrominance Red
    return float3(Y,Cb + 128./255.,Cr + 128./255.);
}

///////////////Functions///////////////////
///////////////Pixel Shader////////////////

struct i
{
	float4 vpos : SV_Position;
	float2 texcoord : TexCoord0;
};

float3 GetRoughTex(float2 texcoord, float4 normal)
{
	float2 p = pix;

	//depth threshold to validate samples
	const float Threshold = 0.00003;
	float facing = dot(normal.rgb, normalize(UVtoPos(texcoord, normal.a)));
	facing *= facing;
	
	//calculating curve and levels
	float roughfac; float2 fromrough, torough;
	roughfac = (1 - roughness);
	fromrough.x = lerp(0, 0.1, saturate(roughness*10));
	fromrough.y = 0.8;
	torough = float2(0, pow(roughness, roughfac));
	
	float3 center = toYCC(tex2D(sTexColor, texcoord).rgb);
	float depth = LDepth(texcoord);

	float Roughness;
	//cross (+)
	float2 offsets[4] = {float2(p.x,0), float2(-p.x,0),float2( 0,-p.y),float2(0,p.y)};
	[unroll]for(int x; x < 4; x++)
	{
		float2 SampleCoord = texcoord + offsets[x];
		float  SampleDepth = LDepth(SampleCoord);
		if(abs(SampleDepth - depth)*facing < Threshold)
		{
			float3 SampleColor = toYCC(tex2D( sTexColor, SampleCoord).rgb);
			SampleColor = min(abs(center.g - SampleColor.g), 0.25);
			Roughness += SampleColor.r;
		}
	}
	
	Roughness = pow( Roughness, roughfac*0.66);
	Roughness = clamp(Roughness, fromrough.x, fromrough.y);
	Roughness = (Roughness - fromrough.x) / ( 1 - fromrough.x );
	Roughness = Roughness / fromrough.y;
	Roughness = clamp(Roughness, torough.x, torough.y);
	
	return saturate(Roughness);
}

void GBuffer1(i i, out float4 normal : SV_Target) //SSSR_NormTex
{
	normal.rgb = Normal(i.texcoord.xy);
	normal.a   = LDepth(i.texcoord.xy);
#if SMOOTH_NORMALS <= 0
	normal.rgb = blend_normals( Bump(i.texcoord, -BUMP), normal.rgb);
	normal.a   = GetRoughTex(i.texcoord, normal);
#endif
}

float4 SNH(i i) : SV_Target
{
	float4 color = tex2D(sNormTex, i.texcoord);
	float4 s, s1; float sc;
	
	float2 p = pix; p*=SNWidth;
	float T = SNThreshold * saturate(2*(1-color.a)); T = rcp(max(T, 0.0001));
	for (int x = -SNSamples; x <= SNSamples; x++)
	{
		s = tex2D(sNormTex, float2(i.texcoord.xy + float2(x*p.x, 0)/*, 0, LODD*/));
		float diff = dot(0.333, abs(s.rgb - color.rgb)) + abs(s.a - color.a)*SNDepthW;
		diff = 1-saturate(diff*T);
		s1 += s*diff;
		sc += diff;
	}
	
	//SNFilter( texcoord, color, s, s1, sc, T, p, 0);
	
	return s1.rgba/sc;
}

float4 SNV(i i) : SV_Target
{
	float4 color = tex2Dlod(sNormTex1, float4(i.texcoord, 0, 0));
	float4 s, s1; float sc;

	float2 p = pix; p*=SNWidth;
	float T = SNThreshold * saturate(2*(1-color.a)); T = rcp(max(T, 0.0001));
	for (int x = -SNSamples; x <= SNSamples; x++)
	{
		s = tex2D(sNormTex1, float2(i.texcoord + float2(0, x*p.y)/*, 0, LODD*/));
		float diff = dot(0.333, abs(s.rgb - color.rgb)) + abs(s.a - color.a)*SNDepthW;
		diff = 1-saturate(diff*T*2);
		s1 += s*diff;
		sc += diff;
		}
	
	//SNFilter( texcoord, color, s, s1, sc, T, p, 1);
	
	s1.rgba = s1.rgba/sc;
	s1.rgb = blend_normals( Bump(i.texcoord, BUMP), s1.rgb);
	return 
	float4
	(
		s1.rgb, 
		GetRoughTex
		(
			i.texcoord,
			float4(Normal(i.texcoord).rgb, s1.a)
		).r
	);
}

// Settings
#define STEPNOISE 1
#define MINBIAS 0

float GetShadows(float3 position, float3 lamppos, float2 texcoord, float penumbra)
{
    // Compute ray position and direction (in view-space)
    float i; float Check; float a;

	int STEPCOUNT_Selector[3] = {16, 48, 256};
	int STEPCOUNT = STEPCOUNT_Selector[Shadow_Quality];
	
	float3 BlueNoise  = BN3dts(texcoord);
	const float penum_mult = 3000/(FAR_PLANE);
	float3 lamppos_soft;
    lamppos_soft = lamppos + (BlueNoise-0.5)*penumbra*penum_mult*0.1;
    
    if(LDepth(PostoUV(lamppos.xyz))>=lamppos.z)
    	lamppos_soft.z = min(lamppos_soft.z, LDepth(texcoord));
    	
    float3 raydir = normalize(lamppos_soft - position);
    raydir *= min(1 * FAR_PLANE, distance(position, lamppos_soft))/STEPCOUNT;
    
	float3 raypos = position + raydir * (1 + BlueNoise.x * STEPNOISE);
    // Ray march towards the light
    [loop]for( i; i < STEPCOUNT; i++)
	{
		Check = LDepth(PostoUV(raypos)) * FAR_PLANE - raypos.z;
		if(Check < 0 && Check > -Shadow_Depth)
		{a = 1; break;}
		
		raypos += raydir;
	}
    return 1-a;
}

float3 GetLampPos(float3 UI_LAMP)
{
	float3 sspos = UI_LAMP - float3(0.5, 0.5, 0);
	sspos.y = -sspos.y;
	sspos.x *= BUFFER_ASPECT_RATIO;
	sspos.xy *= 1.047;
	sspos.y = sspos.y/2;
	sspos.xy *= sspos.z;
	
	return sspos * FAR_PLANE;
}
	

float3 GetLighting(
	inout float3 FinalColor, inout float spr, inout float3 Specular, inout float3 fog, inout float ShadowOnly,
	float alpha, float3 position, float3 normal, float3 eyedir, float NdotV, float F0, float2 texcoord, float2 sprite,
	float3 UI_LAMP, float3 UI_LAMP_PRECISE, float3 UI_COLOR, float UI_POWER, float UI_SOFT_S, float UI_S_ENABLE, bool UI_FOG)
{
	float3 lamppos, lamp, lampdir, light; float2 icopos; float DepthLimit, AngFalloff, backfacing, sprtex, Shadow;

	//lamp data
	UI_POWER *= FAR_PLANE;
	//lamppos    = UI_LAMP+UI_LAMP_PRECISE-float3(CENTER_POINT,CENTER_POINT,0);
	lamppos = GetLampPos(UI_LAMP + UI_LAMP_PRECISE);
	if(LimitPos)
	{
	DepthLimit = LDepth(PostoUV(lamppos.xyz));
	lamppos.z  = min(lamppos.z, DepthLimit*FAR_PLANE-5);
	}
	lamp       = 1/pow(distance(position, lamppos), 2);
	lampdir    = normalize(lamppos - position);
	
	//Dots and shit
	float3 H    = normalize(lampdir + eyedir);
	float NdotH = dot(normal, H);
	float VdotH = dot(eyedir, H);
	float NdotL = dot(normal, lampdir);
	float LdotV = dot(lampdir, eyedir);
	backfacing = dot(-lampdir, normal);
	
	//Compute Screen Space Ray Marched Shadows
	Shadow = 1;
	if(UI_S_ENABLE&&backfacing>0)Shadow = GetShadows(position, lamppos, texcoord, UI_SOFT_S);
	
	//Lambertian Diffuse Lighting
	AngFalloff = dot(lampdir, normal); 
	float DisFalloff = 1/pow(distance(position, lamppos), 2);
	light = lamp*UI_POWER*UI_COLOR*(1-AngFalloff);
	
	//FinalColor += hammon(LdotV, NdotH, NdotL, NdotV, alpha, diffusecolor) * (backfacing >= 0) * UI_COLOR * UI_POWER * DisFalloff * Shadow;
	FinalColor+= lerp( 0, light, backfacing>0) * Shadow;
	//Specular Lighting
	float3 ThisSpecular = ggx_smith_brdf(NdotL, NdotV, NdotH, VdotH, F0, alpha, texcoord) * NdotL;
	ThisSpecular *= DisFalloff;
	ThisSpecular *= UI_POWER*UI_COLOR*Shadow;
	Specular += ThisSpecular;
	//View to UV projection of the light. Used for icon and fog sprites
	icopos = sprite - (PostoUV(lamppos) * 2 - 1)*float2(1.7778, 2);
	icopos *= sqrt(max(1,lamppos.z))/(16*ICON_SIZE);
	icopos = icopos * 0.5 + 0.5;
	sprtex = 1-(tex2D(sLampIcon, icopos).r);
	if(lamppos.z>position.z)sprtex *= IconOcclusionTransparency; //Z test
	if(is_saturated(icopos))sprtex = 0;//Border UV address
	spr += sprtex;
	
	//Volumetric Lighting
	if(UI_FOG)
	{
		float3 ThisFog = UI_POWER * UI_COLOR * UI_FOG_DENSITY * FAR_PLANE * 0.1;
		ThisFog *= (UI_FOG_DEPTH_MASK?saturate((position.z - lamppos.z + 1)/16):1);
		float d = length(icopos-0.5);
		ThisFog /= (d*d);
		fog += ThisFog;
	}
	//Accumulate Shadows for Variance estimation
	ShadowOnly += Shadow;
	
	return 0;
}

void Lighting(i i, out float3 FinalColor : SV_Target0, out float4 Fog : SV_Target1, out float ShadowOnly : SV_Target2)
{
	FinalColor = 0; ShadowOnly = 0;
	float3 raypos, Check; float2 UVraypos; float a; bool hit; //ss shadows ray marcher
	float3 lamppos, lamp, lampdir, light, fog, Specular,K,R; float2 icopos; float AngFalloff, backfacing, sprtex, spr; //lamps data
	
	float3 diffusecolor = tex2D(sTexColor, i.texcoord).rgb;
	//sprites coords
	float2 sprite = i.texcoord;
	sprite = sprite * 2 - 1; //range 0~1 to -1~1
	sprite.x *= BUFFER_ASPECT_RATIO; //1:1 aspect ratio as of the icon
	//GBuffer Data
	float3 position  = UVtoPos(i.texcoord);
	float4 GBuff     = tex2D(sNormTex, i.texcoord);
	float3 normal    = GBuff.rgb;
	float  roughness = GBuff.a;
	float3 eyedir    = -normalize(position); //should be inverted for GGX
	float  NdotV     = dot(normal, eyedir);
	float  F0        = specular*0.08; //reflectance at 0deg angle
	float  alpha     = roughness * roughness; //roughness used for GGX
	//Lamp 1
	if(L1)
	GetLighting(
		FinalColor, spr, Specular, fog, ShadowOnly,
		alpha, position, normal, eyedir, NdotV, F0, i.texcoord, sprite,
		UI_LAMP1, UI_LAMP1_PRECISE, UI_COLOR1, UI_POWER1, UI_SOFT_S1, UI_S_ENABLE1, UI_FOG1);
	//Lamp2
	if(L2)
	GetLighting(
		FinalColor, spr, Specular, fog, ShadowOnly,
		alpha, position, normal, eyedir, NdotV, F0, i.texcoord, sprite,
		UI_LAMP2, UI_LAMP2_PRECISE, UI_COLOR2, UI_POWER2, UI_SOFT_S2, UI_S_ENABLE2, UI_FOG2);
	//Lamp3
	if(L3)
	GetLighting(
		FinalColor, spr, Specular, fog, ShadowOnly,
		alpha, position, normal, eyedir, NdotV, F0, i.texcoord, sprite,
		UI_LAMP3, UI_LAMP3_PRECISE, UI_COLOR3, UI_POWER3, UI_SOFT_S3, UI_S_ENABLE3, UI_FOG3);
	//Lamp4
	if(L4)
	GetLighting(
		FinalColor, spr, Specular, fog, ShadowOnly,
		alpha, position, normal, eyedir, NdotV, F0, i.texcoord, sprite,
		UI_LAMP4, UI_LAMP4_PRECISE, UI_COLOR4, UI_POWER4, UI_SOFT_S4, UI_S_ENABLE4, UI_FOG4);
/*_________________________________________

Here is the rest of the code.
__________________________________________*/
	
	FinalColor += -min(Specular*specular, 0);
	FinalColor = Tonemapper(FinalColor);
	
	Fog.a = spr * ShowIcon;
	Fog.rgb = fog*UI_FOG_COLOR;
	ShadowOnly /= (L1+L2+L3+L4);
}

float add4comp(in float4 input){ return input.x+input.y+input.z+input.w;}
float add2comp(in float2 input){ return input.x+input.y;}

void GetVariance(i i, out float Var : SV_Target0)
{
	float2 p = pix;
	float PreSqr, PostSqr; int x,y;
	//To do: Optimize with tex2Dgather
#if __RENDERER__ < 0xa000 //use 49 taps for DX9- :((
	float S;
	for(x = -3; x <= 3; x++){
	for(y = -3; y <= 3; y++)
	{
		S = tex2D(sShadowTex, i.texcoord + float2(x,y) * p).r;
		PreSqr += S * S;
		PostSqr += S;
	}}
#else //use 16 taps for DX10+
	float4 sGather;
	//Row1//////////////////////////////////////////////////////////////////////////
	sGather = tex2DgatherR(sShadowTex, i.texcoord + float2(-3,-3) * p);
	PostSqr += add4comp(sGather);
	PreSqr  += add4comp(sGather * sGather);
	
	sGather = tex2DgatherR(sShadowTex, i.texcoord + float2(-1,-3) * p);
	PostSqr += add4comp(sGather);
	PreSqr  += add4comp(sGather * sGather);
	
	sGather = tex2DgatherR(sShadowTex, i.texcoord + float2( 1,-3) * p);
	PostSqr += add4comp(sGather);
	PreSqr  += add4comp(sGather * sGather);
	
	sGather = tex2DgatherR(sShadowTex, i.texcoord + float2( 3,-3) * p);
	PostSqr += add2comp(sGather.xw);
	PreSqr  += add2comp(sGather.xw * sGather.xw);
	
	//Row2//////////////////////////////////////////////////////////////////////////
	sGather = tex2DgatherR(sShadowTex, i.texcoord + float2(-3,-1) * p);
	PostSqr += add4comp(sGather);
	PreSqr  += add4comp(sGather * sGather);
	
	sGather = tex2DgatherR(sShadowTex, i.texcoord + float2(-1,-1) * p);
	PostSqr += add4comp(sGather);
	PreSqr  += add4comp(sGather * sGather);
	
	sGather = tex2DgatherR(sShadowTex, i.texcoord + float2( 1,-1) * p);
	PostSqr += add4comp(sGather);
	PreSqr  += add4comp(sGather * sGather);
	
	sGather = tex2DgatherR(sShadowTex, i.texcoord + float2( 3,-1) * p);
	PostSqr += add2comp(sGather.xw);
	PreSqr  += add2comp(sGather.xw * sGather.xw);
	
	//Row3//////////////////////////////////////////////////////////////////////////
	sGather = tex2DgatherR(sShadowTex, i.texcoord + float2(-3, 1) * p);
	PostSqr += add4comp(sGather);
	PreSqr  += add4comp(sGather * sGather);
	
	sGather = tex2DgatherR(sShadowTex, i.texcoord + float2(-1, 1) * p);
	PostSqr += add4comp(sGather);
	PreSqr  += add4comp(sGather * sGather);
	
	sGather = tex2DgatherR(sShadowTex, i.texcoord + float2( 1, 1) * p);
	PostSqr += add4comp(sGather);
	PreSqr  += add4comp(sGather * sGather);
	
	sGather = tex2DgatherR(sShadowTex, i.texcoord + float2( 3, 1) * p);
	PostSqr += add2comp(sGather.xw);
	PreSqr  += add2comp(sGather.xw * sGather.xw);
	
	//Row4//////////////////////////////////////////////////////////////////////////
	sGather = tex2DgatherR(sShadowTex, i.texcoord + float2(-3, 3) * p);
	PostSqr += add2comp(sGather.zw);
	PreSqr  += add2comp(sGather.zw * sGather.zw);
	
	sGather = tex2DgatherR(sShadowTex, i.texcoord + float2(-1, 3) * p);
	PostSqr += add2comp(sGather.zw);
	PreSqr  += add2comp(sGather.zw * sGather.zw);
	
	sGather = tex2DgatherR(sShadowTex, i.texcoord + float2( 1, 3) * p);
	PostSqr += add2comp(sGather.zw);
	PreSqr  += add2comp(sGather.zw * sGather.zw);
	
	sGather = tex2D(sShadowTex, i.texcoord + float2( 3, 3) * p).x;
	PostSqr += sGather.x;
	PreSqr += sGather.x * sGather.x;
	
	////////////////////////////////////////////////////////////////////////////

#endif
	PostSqr /= 49;
	PreSqr  /= 49;
	
	PostSqr *= PostSqr;
	
	Var = sqrt(abs(PostSqr - PreSqr));
}

void Filter(i i, out float3 FinalColor : SV_Target0)
{
	float2 p = pix;
	float Var  = tex2D(sVarianceTex, i.texcoord + float2( 0.5, 0.5) * p).r;
	float3 Current = tex2D(sLightingTex, i.texcoord).rgb;
	FinalColor = Current;
	
	//Make sure to denoise only where there is noise in the shadows (penumberas)
	if(Var > 0.01)
	{
		float2 MV = tex2D(SamplerMotionVectors, i.texcoord).xy;
		float3 History = tex2D(sLitHistTex, i.texcoord + MV).rgb;
		
		float3 S,
		PreSqr = Current * Current, PostSqr = Current,
		Min = 1000000, Max = -1000000;
		int x,y;
		//To do: Optimize
		for(x = -1; x <= 1; x++){
		for(y = -1; y <= 1; y++)
		{
			if(x==0&&y==0)continue;
			S = tex2Dlod(sLightingTex, float4(i.texcoord + float2(x,y) * p, 0, 0)).rgb;
			PreSqr += S * S;
			PostSqr += S;
			Min = min(S, Min);
			Max = max(S, Max);
		}}
		PostSqr /= 9;
		PreSqr /= 9;
		float3 mean = PreSqr;
		
		PostSqr *= PostSqr;
		float3 SD = sqrt(abs(PostSqr - PreSqr));
		
		FinalColor = lerp(Current, History, clamp(Var*8, 0, 0.9));
		FinalColor = lerp(clamp(FinalColor, Current-SD, Current+SD), FinalColor, clamp(Var*8, 0, 1));
	}
}

float3 CopyBuffer(i i) : SV_Target0
{ return tex2D(sBlendedTex, i.texcoord).rgb;}

float3 OutColor(i i) : SV_Target0
{
	float3 Lighting      = tex2D(sBlendedTex, i.texcoord).rgb;
	float4 Fog           = tex2D(sBGColorTex, i.texcoord).rgba;
	float3 DiffuseAlbedo = tex2D(sTexColor, i.texcoord).rgb;

	Lighting = InvTonemapper(Lighting);
	Lighting *= debug?1:DiffuseAlbedo;
	DiffuseAlbedo = InvTonemapper(DiffuseAlbedo);
	DiffuseAlbedo  = Tonemapper(Lighting + DiffuseAlbedo * OGLighting * !debug + Fog.rgb) + Fog.a;

	return DiffuseAlbedo;
}

///////////////Pixel Shader////////////////
///////////////Techniques//////////////////

technique NGLamps<
	ui_label   = "NiceGuy Lamps";
	ui_tooltip = "NiceGuy Lamps 1.1 Beta\n"
				 "    ||By Ehsan2077||  \n";	
>
{
	pass GBuffer
	{
		VertexShader  = PostProcessVS;
		PixelShader   = GBuffer1;
		RenderTarget0 = NormTex;
	}
#if SMOOTH_NORMALS > 0
	pass SmoothNormalHpass
	{
		VertexShader = PostProcessVS;
		PixelShader = SNH;
		RenderTarget = NormTex1;
	}
	pass SmoothNormalVpass
	{
		VertexShader = PostProcessVS;
		PixelShader = SNV;
		RenderTarget = NormTex;
	}
#endif
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Lighting;
		RenderTarget0 = LightingTex;
		RenderTarget1 = BGColorTex;
		RenderTarget2 = ShadowTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = GetVariance;
		RenderTarget = VarianceTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Filter;
		RenderTarget = BlendedTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CopyBuffer;
		RenderTarget = LitHistTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = OutColor;
	}
}

///////////////Techniques//////////////////
