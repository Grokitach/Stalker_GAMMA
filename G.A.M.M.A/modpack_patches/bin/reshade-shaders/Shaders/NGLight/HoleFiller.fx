//HoleFiller
//Written by MJ_Ehsan for Reshade
//Version 1.0

//license
//CC0 ^_^

///////////////Include/////////////////////

#include "ReShadeUI.fxh"
#include "ReShade.fxh"

#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

///////////////Include/////////////////////
///////////////Textures-Samplers///////////

texture2D TexColor : COLOR;
sampler  sTexColor {Texture = TexColor; };

texture2D TexDDepth { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f;};
sampler  sTexDDepth {Texture = TexDDepth; };

texture2D TexCColor { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;};
sampler  sTexCColor {Texture = TexCColor; };

///////////////Textures-Samplers///////////
///////////////UI//////////////////////////

uniform float T <
	ui_label = "Depth Threshold";
	ui_Tooltip = "Increase to prevent depth shifting";
	ui_type = "slider";
> = 0.1;

uniform bool Thin <
	ui_label = "Keep Edges";
	ui_type = "radio";
> = 1;
///////////////UI//////////////////////////
///////////////Functions///////////////////

float3 Color( in float2 texcoord)
{
	return tex2D(sTexColor, texcoord).rgb;
}

float Depth( in float2 texcoord)
{
	return ReShade::GetLinearizedDepth(texcoord);
}

///////////////Functions///////////////////
///////////////Vertex Shader///////////////
///////////////Vertex Shader///////////////
///////////////Pixel Shader////////////////

float3 Fuck( float4 Postion : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float2 p = pix;
	float3 o = float3(-1, 0, 1);

	float3 sColor[5];
	float  sDepth[5];
	
	//| |x |y |z |
	//============
	//|z|xz|yz|zz|
	//|y|xy|yy|zy|
	//|x|xx|yx|zx|
	
	sColor[0] = Color(texcoord + o.yz*p);//up
	sColor[1] = Color(texcoord + o.xy*p);//left
	sColor[2] = Color(texcoord + o.yy*p);//center
	sColor[3] = Color(texcoord + o.zy*p);//right
	sColor[4] = Color(texcoord + o.yx*p);//down
	
	sDepth[0] = Depth(texcoord + o.yz*p);//up
	sDepth[1] = Depth(texcoord + o.xy*p);//left
	sDepth[2] = Depth(texcoord + o.yy*p);//center
	sDepth[3] = Depth(texcoord + o.zy*p);//right
	sDepth[4] = Depth(texcoord + o.yx*p);//down
	
	float Weight;
	float3 C = sColor[3];
	
	if( sDepth[2] > sDepth[0]+T ) {Weight += 1; C += sColor[0];}
	if( sDepth[2] > sDepth[1]+T ) {Weight += 1; C += sColor[1];}
	if( sDepth[2] > sDepth[3]+T ) {Weight += 1; C += sColor[3];}
	if( sDepth[2] > sDepth[4]+T ) {Weight += 1; C += sColor[4];}
	
	float W = Weight; if(Thin) if(Weight <= 1) W = 0;
	
	C = lerp(sColor[2], C/(Weight+1), W/4);
	
	return C;
}

///////////////Pixel Shader////////////////
///////////////Techniques//////////////////

technique HoleFiller
{
    pass
    {	
        VertexShader = PostProcessVS;
        PixelShader =  Fuck;
    }
}

///////////////Techniques//////////////////
