//===================================================================================================================
//Preprocess Settings
#define DEPTH_TEXTURE_QUALITY		0.5	//[>0.0] 1.0 - Screen resolution. Lowering this might ruin the AO precision. Go from 1.0 to AO texture quality.
#define DEPTH_AO_MIPLEVELS		5	//[>1] Mip levels to increase speed at the cost of quality
#include "ReShade.fxh"
#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif
#undef PixelSize
#define PixelSize  	float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
//DOF Settings
#define DOF_TEXTURE_QUALITY		0.5	//[>0.0] 1.0 - Screen resolution. Lowering this will decrease quality of the DOF, but also increase its radius.
#define DOF_TAPS			4	//[>0] Increasing this increases the radius and quality, but lowers speed.
#define DOF_P_WORD_NEAR			0	//[0 or 1] Makes near blur overlap, only works with DOF_TEXTURE_QUALITY set to 1.0
#define DOF_SCRATCH_FILENAME		"SCRATCH_Example.png"	//Filename for the scratch file
#define DOF_SCRATCH_WIDTH		1024			//Scratch file's width
#define DOF_SCRATCH_HEIGHT		768			//Scratch file's height
//===================================================================================================================
uniform bool DOF_USE_AUTO_FOCUS <
	ui_label = "Auto Focus";
> = 1;
uniform float DOF_RADIUS <
	ui_label = "DOF - Radius";
	ui_tooltip = "1.0 = Pixel perfect radius. Values above 1.0 might create artifacts.";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 10.0;
	> = 1.0;
uniform float DOF_NEAR_STRENGTH <
	ui_label = "DOF - Near Blur Strength";
	ui_tooltip = "Strength of the blur between the camera and focal point.";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	> = 0.5;
uniform float DOF_FAR_STRENGTH <
	ui_label = "DOF - Far Blur Strength";
	ui_tooltip = "Strength of the blur past the focal point.";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	> = 1.0;
uniform float DOF_FOCAL_RANGE <
	ui_label = "DOF - Focal Range";
	ui_tooltip = "Along with Focal Curve, this controls how much will be in focus";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	> = 0.0;
uniform float DOF_FOCAL_CURVE <
	ui_label = "DOF - Focal Curve";
	ui_tooltip = "1.0 = No curve. Values above this put more things in focus, lower values create a macro effect.";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	> = 1.0;
uniform float DOF_HYPERFOCAL <
	ui_label = "DOF - Hyperfocal Range";
	ui_tooltip = "When the focus goes past this point, everything in the distance is focused.";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	> = 0.9;
uniform float DOF_BLEND <
	ui_label = "DOF - Blending Curve";
	ui_tooltip = "Controls the blending curve between the DOF texture and original image. Use this to avoid artifacts where the DOF begins";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	> = 0.3;
uniform float DOF_BOKEH_CONTRAST <
	ui_label = "DOF - Bokeh - Contrast";
	ui_tooltip = "Contrast of bokeh and blurred areas. Use very small values.";
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	> = 0.04;
uniform float DOF_BOKEH_BIAS <
	ui_label = "DOF - Bokeh - Bias";
	ui_tooltip = "0.0 = No Bokeh, 1.0 = Natural bokeh, 2.0 = Forced bokeh.";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	> = 1.0;
uniform float DOF_MANUAL_FOCUS <
	ui_label = "DOF - Manual Focus";
	ui_tooltip = "Only works when manual focus is on.";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	> = 0.5;
uniform float DOF_FOCUS_X <
	ui_label = "DOF - Auto Focus X";
	ui_tooltip = "Horizontal point in the screen to focus. 0.5 = middle";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	> = 0.5;
uniform float DOF_FOCUS_Y <
	ui_label = "DOF - Auto Focus Y";
	ui_tooltip = "Vertical point in the screen to focus. 0.5 = middle";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	> = 0.5;
uniform float DOF_FOCUS_SPREAD <
	ui_label = "DOF - Auto Focus Spread";
	ui_tooltip = "Focus takes the average of 5 points, this is how far away they are. Use low values for a precise focus.";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 0.5;
	> = 0.05;
uniform float DOF_FOCUS_SPEED <
	ui_label = "DOF - Auto Focus Speed";
	ui_tooltip = "How fast focus changes happen. 1.0 = One second. Values above 1.0 are faster, bellow are slower.";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 10.0;
	> = 1.0;
uniform float DOF_SCRATCHES_STRENGTH <
	ui_label = "DOF - Lens Scratches Strength";
	ui_tooltip = "How strong is the scratch effect. Low values are better as this shows up a lot in bright scenes.";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	> = 0.15;
uniform int DOF_DEBUG <
	ui_label = "DOG - Debug - Show Focus";
	ui_tooltip = "Black is in focus, red is blurred.";
	ui_type = "combo";
	ui_items = "No\0Yes\0";
	> = 0;
uniform int LUMA_MODE <
	ui_label = "Luma Mode";
	ui_type = "combo";
	ui_items = "Intensity\0Value\0Lightness\0Luma\0";
	> = 3;
uniform int FOV <
	ui_label = "FoV";
	ui_type = "slider";
	ui_min = 10; ui_max = 90;
	> = 75;

uniform float Frametime < source = "frametime"; >;

//===================================================================================================================
texture2D	TexNormalDepth {Width = BUFFER_WIDTH * DEPTH_TEXTURE_QUALITY; Height = BUFFER_HEIGHT * DEPTH_TEXTURE_QUALITY; Format = RGBA16; MipLevels = DEPTH_AO_MIPLEVELS;};
sampler2D	SamplerND {Texture = TexNormalDepth; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; AddressU = Clamp; AddressV = Clamp;};

texture2D	TexF1 {Width = 1; Height = 1; Format = R16F;};
sampler2D	SamplerFocalPoint {Texture = TexF1; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; AddressU = Clamp; AddressV = Clamp;};
texture2D	TexF2 {Width = 1; Height = 1; Format = R16F;};
sampler2D	SamplerFCopy {Texture = TexF2; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; AddressU = Clamp; AddressV = Clamp;};

#if DOF_P_WORD_NEAR
texture2D	TexFocus {Width = BUFFER_WIDTH * DOF_TEXTURE_QUALITY; Height = BUFFER_HEIGHT * DOF_TEXTURE_QUALITY; Format = R16F;};
sampler2D	SamplerFocus {Texture = TexFocus; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; AddressU = Clamp; AddressV = Clamp;};
#else
texture2D	TexFocus {Width = BUFFER_WIDTH * DOF_TEXTURE_QUALITY; Height = BUFFER_HEIGHT * DOF_TEXTURE_QUALITY; Format = R8;};
sampler2D	SamplerFocus {Texture = TexFocus; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; AddressU = Clamp; AddressV = Clamp;};
#endif

texture2D	TexDOF1 {Width = BUFFER_WIDTH * DOF_TEXTURE_QUALITY; Height = BUFFER_HEIGHT * DOF_TEXTURE_QUALITY; Format = RGBA8;};
sampler2D	SamplerDOF1 {Texture = TexDOF1; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; AddressU = Clamp; AddressV = Clamp;};
texture2D	TexDOF2 {Width = BUFFER_WIDTH * DOF_TEXTURE_QUALITY; Height = BUFFER_HEIGHT * DOF_TEXTURE_QUALITY; Format = RGBA8;};
sampler2D	SamplerDOF2 {Texture = TexDOF2; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; AddressU = Clamp; AddressV = Clamp;};
//===================================================================================================================
float GetDepth(float2 coords)
{
	return saturate(ReShade::GetLinearizedDepth(coords));
}

float3 EyeVector(float3 vec)
{
	vec.xy = vec.xy * 2.0 - 1.0;
	vec.x -= vec.x * (1.0 - vec.z) * sin(radians(FOV));
	vec.y -= vec.y * (1.0 - vec.z) * sin(radians(FOV * (PixelSize.y / PixelSize.x)));
	return vec;
}

float4 GetNormalDepth(float2 coords)
{
	const float2 offsety = float2(0.0, PixelSize.y);
  	const float2 offsetx = float2(PixelSize.x, 0.0);
	
	const float pointdepth = GetDepth(coords);
	#define NORMAL_MODE 2
	
	#if (NORMAL_MODE == 0) 
	const float3 p = EyeVector(float3(coords, pointdepth));
	const float3 py1 = EyeVector(float3(coords + offsety, GetDepth(coords + offsety))) - p;
  	const float3 px1 = EyeVector(float3(coords + offsetx, GetDepth(coords + offsetx))) - p;
	#elif (NORMAL_MODE == 1) 
	const float3 py1 = EyeVector(float3(coords + offsety, GetDepth(coords + offsety))) - EyeVector(float3(coords - offsety, GetDepth(coords - offsety)));
  	const float3 px1 = EyeVector(float3(coords + offsetx, GetDepth(coords + offsetx))) - EyeVector(float3(coords - offsetx, GetDepth(coords - offsetx)));
	#elif (NORMAL_MODE == 2)
	const float3 p = EyeVector(float3(coords, pointdepth));
	float3 py1 = EyeVector(float3(coords + offsety, GetDepth(coords + offsety))) - p;
	const float3 py2 = p - EyeVector(float3(coords - offsety, GetDepth(coords - offsety)));
  	float3 px1 = EyeVector(float3(coords + offsetx, GetDepth(coords + offsetx))) - p;
	const float3 px2 = p - EyeVector(float3(coords - offsetx, GetDepth(coords - offsetx)));
	py1 = lerp(py1, py2, abs(py1.z) > abs(py2.z));
	px1 = lerp(px1, px2, abs(px1.z) > abs(px2.z));
	#endif
  
	float3 normal = cross(py1, px1);
	normal = (normalize(normal) + 1.0) * 0.5;
  
  	return float4(normal, pointdepth);
}

float4 LumaChroma(float4 col) {
	if (LUMA_MODE == 0) { 			// Intensity
		const float i = dot(col.rgb, 0.3333);
		return float4(col.rgb / i, i);
	} else if (LUMA_MODE == 1) {		// Value
		const float v = max(max(col.r, col.g), col.b);
		return float4(col.rgb / v, v);
	} else if (LUMA_MODE == 2) { 		// Lightness
		const float high = max(max(col.r, col.g), col.b);
		const float low = min(min(col.r, col.g), col.b);
		const float l = (high + low) / 2;
		return float4(col.rgb / l, l);
	} else { 				// Luma
		const float luma = dot(col.rgb, float3(0.21, 0.72, 0.07));
		return float4(col.rgb / luma, luma);
	}
}

float3 BlendColorDodge(float3 a, float3 b) {
	return a / (1 - b);
}

float2 Rotate60(float2 v) {
	#define sin60 0.86602540378f
	const float x = v.x * 0.5 - v.y * sin60;
	const float y = v.x * sin60 + v.y * 0.5;
	return float2(x, y);
}

float2 Rotate120(float2 v) {
	#define sin120 0.58061118421f
	const float x = v.x * -0.5 - v.y * sin120;
	const float y = v.x * sin120 + v.y * -0.5;
	return float2(x, y);
}

float2 Rotate(float2 v, float angle) {
	const float x = v.x * cos(angle) - v.y * sin(angle);
	const float y = v.x * sin(angle) + v.y * cos(angle);
	return float2(x, y);
}

float GetFocus(float d) {
	float focus;
	if (!DOF_USE_AUTO_FOCUS)
		focus = min(DOF_HYPERFOCAL, DOF_MANUAL_FOCUS);
	else
		focus = min(DOF_HYPERFOCAL, tex2D(SamplerFocalPoint, 0.5).x);
	float res;
	if (d > focus) {
		res = smoothstep(focus, 1.0, d) * DOF_FAR_STRENGTH;
		res = lerp(res, 0.0, focus / DOF_HYPERFOCAL);
	} else if (d < focus) {
		res = smoothstep(focus, 0.0, d) * DOF_NEAR_STRENGTH;
	} else {
		res = 0.0;
	}
	
	res = pow(smoothstep(DOF_FOCAL_RANGE, 1.0, res), DOF_FOCAL_CURVE);
	#if DOF_P_WORD_NEAR
	res *= 1 - (d < focus) * 2;
	#endif
	
	return res;
}
float4 GenDOF(float2 texcoord, float2 v, sampler2D samp) 
{
	const float4 origcolor = tex2D(samp, texcoord);
	float4 res = origcolor;
	res.w = LumaChroma(origcolor).w;
	
	#if DOF_P_WORD_NEAR
	float bluramount = abs(tex2D(SamplerFocus, texcoord).r);
	#else
	float bluramount = tex2D(SamplerFocus, texcoord).r;
	if (bluramount == 0) return origcolor;
	res.w *= bluramount;
	#endif
	if (!DOF_USE_AUTO_FOCUS)
		v = Rotate(v, tex2D(SamplerFocalPoint, 0.5).x * 2.0);
	float4 bokeh = res;
	res.rgb *= res.w;
	
	#if DOF_P_WORD_NEAR
	float2 calcv = v * DOF_RADIUS * PixelSize / DOF_TEXTURE_QUALITY;
	float depths[DOF_TAPS * 2];
	[unroll] for(int ii=0; ii < DOF_TAPS; ii++)
	{
		float2 tapcoord = texcoord + calcv * (ii + 1);
		depths[ii * 2] = tex2Dlod(SamplerFocus, float4(tapcoord, 0, 0)).r;
		if (depths[ii * 2] < 0)
			bluramount = max(bluramount, -depths[ii * 2]);
		tapcoord = texcoord - calcv * (ii + 1);
		depths[ii * 2 + 1] = tex2Dlod(SamplerFocus, float4(tapcoord, 0, 0)).r;
		if (depths[ii * 2 + 1] < 0)
			bluramount = max(bluramount, -depths[ii * 2 + 1]);
	}
	const float discradius = bluramount * DOF_RADIUS;
	calcv = v * discradius * PixelSize / DOF_TEXTURE_QUALITY;
	#else
	const float discradius = bluramount * DOF_RADIUS;
	if (discradius < PixelSize.x / DOF_TEXTURE_QUALITY)
		return origcolor;
	const float2 calcv = v * discradius * PixelSize / DOF_TEXTURE_QUALITY;
	#endif
	
	for(int i=1; i <= DOF_TAPS; i++)
	{

		// ++++
		float2 tapcoord = texcoord + calcv * i;

		float4 tap = tex2Dlod(samp, float4(tapcoord, 0, 0));
		
		#if DOF_P_WORD_NEAR
		tap.w = abs(depths[(i - 1) * 2]);
		tap.w *= LumaChroma(tap).w;
		#else
		tap.w = tex2Dlod(SamplerFocus, float4(tapcoord, 0, 0)).r * LumaChroma(tap).w;
		#endif

		//bokeh = lerp(bokeh, tap, (tap.w > bokeh.w));
		bokeh = lerp(bokeh, tap, (tap.w > bokeh.w) * tap.w);
		
		res.rgb += tap.rgb * tap.w;
		res.w += tap.w;
		
		// ----
		tapcoord = texcoord - calcv * i;

		tap = tex2Dlod(samp, float4(tapcoord, 0, 0));
		
		#if DOF_P_WORD_NEAR
		tap.w = abs(depths[(i - 1) * 2 + 1]);
		tap.w *= LumaChroma(tap).w;
		#else
		tap.w = tex2Dlod(SamplerFocus, float4(tapcoord, 0, 0)).r * LumaChroma(tap).w;
		#endif
		
		//bokeh = lerp(bokeh, tap, (tap.w > bokeh.w));
		bokeh = lerp(bokeh, tap, (tap.w > bokeh.w) * tap.w);

		res.rgb += tap.rgb * tap.w;
		res.w += tap.w;
		
	}
	
	res.rgb /= res.w;
	#if DOF_P_WORD_NEAR
	if (discradius != 0)
		res.rgb = erp(res.rgb, bokeh.rgb, saturate(bokeh.w * DOF_BOKEH_BIAS));
	#else
	res.rgb = lerp(res.rgb, bokeh.rgb, saturate(bokeh.w * DOF_BOKEH_BIAS));
	#endif
	res.w = 1.0;
	float4 lc = LumaChroma(res);
	lc.w = pow(abs(lc.w), 1.0 + float(DOF_BOKEH_CONTRAST) / 10.0);
	res.rgb = lc.rgb * lc.w;

	return res;
}
//===================================================================================================================
float4 PS_DepthPrePass(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : COLOR
{
	return GetNormalDepth(texcoord);
}
float PS_GetFocus (float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : COLOR
{
	const float lastfocus = tex2D(SamplerFCopy, 0.5).x;
	float res;
	
	const float2 offset[5]=
	{
		float2(0.0, 0.0),
		float2(0.0, -1.0),
		float2(0.0, 1.0),
		float2(1.0, 0.0),
		float2(-1.0, 0.0)
	};
	for(int i=0; i < 5; i++)
	{
		res += tex2D(SamplerND, float2(DOF_FOCUS_X, DOF_FOCUS_Y) + offset[i] * DOF_FOCUS_SPREAD).w;
	}
	res /= 5;
	res = lerp(lastfocus, res, DOF_FOCUS_SPEED * Frametime / 1000.0);
	return res;
}
float PS_CopyFocus (float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : COLOR
{
	return tex2D(SamplerFocalPoint, 0.5).x;
}
float PS_GenFocus (float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : COLOR
{
	return GetFocus(tex2D(SamplerND, texcoord).w);
}
float4 PS_DOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : COLOR
{
	return GenDOF(texcoord, float2(1.0, 0.0), ReShade::BackBuffer);
}
float4 PS_DOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : COLOR
{
	return GenDOF(texcoord, Rotate60(float2(1.0, 0.0)), SamplerDOF1);
}
float4 PS_DOF3(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : COLOR
{
	return GenDOF(texcoord, Rotate120(float2(1.0, 0.0)), SamplerDOF2);
}
float4 PS_DOFCombine(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : COLOR
{
	#if DOF_P_WORD_NEAR
	float4 res = tex2D(SamplerDOF1, texcoord);
	const float bluramount = abs(tex2D(SamplerFocus, texcoord).r);
	if (DOF_DEBUG) res.rgb = abs(tex2D(SamplerFocus, texcoord).r);
		#if GSHADE_DITHER
		return float4(res.rgb + TriDither(res.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH), res.a);
		#else
		return res;
		#endif
	#else
	const float bluramount = tex2D(SamplerFocus, texcoord).r;
	const float4 orig = tex2D(ReShade::BackBuffer, texcoord);
	
	float4 res;
	if (bluramount == 0.0) {
		res = orig;
	} else {
		res = lerp(orig, tex2D(SamplerDOF1, texcoord), smoothstep(0.0, DOF_BLEND, bluramount));
	}
	if (DOF_DEBUG) res = tex2D(SamplerFocus, texcoord);
		#if GSHADE_DITHER
		return float4(res.rgb + TriDither(res.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH), res.a);
		#else
		return res;
		#endif
	#endif
}
//===================================================================================================================
technique Pirate_DOF
{
	pass DepthPre
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_DepthPrePass;
		RenderTarget = TexNormalDepth;
	}

	pass GetFocus
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_GetFocus;
		RenderTarget = TexF1;
	}
	pass CopyFocus
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_CopyFocus;
		RenderTarget = TexF2;
	}
	pass FocalRange
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_GenFocus;
		RenderTarget = TexFocus;
	}
	pass DOF1
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_DOF1;
		RenderTarget = TexDOF1;
	}
	pass DOF2
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_DOF2;
		RenderTarget = TexDOF2;
	}
	pass DOF3
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_DOF3;
		RenderTarget = TexDOF1;
	}
	pass Combine
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_DOFCombine;
	}
}