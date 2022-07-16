#include "common.h"

struct vi
{
	float4	p		: POSITION;
	float4	c		: COLOR0;
	float3	tc0		: TEXCOORD0;
	float3	tc1		: TEXCOORD1;
};

struct v2p
{
	float4	c		: COLOR0;
	float3	tc0		: TEXCOORD0;
	float3	tc1		: TEXCOORD1;
	float4	hpos	: SV_Position;
};

v2p main (vi v)
{
	v2p		o;
	//v.c.rgb = v.c.bgr; // fix skybox color

    float4 tpos = float4(2000*v.p.x, 2000*v.p.y, 2000*v.p.z, 2000*v.p.w);
    o.hpos = mul (m_WVP, tpos);
	o.hpos.z = o.hpos.w;
	o.tc0 = v.tc0;                      					// copy tc
	o.tc1 = v.tc1;                      					// copy tc
	float	scale = s_tonemap.Load(int3(0,0,0) ).x;
    o.c = float4(v.c.rgb*scale*1.7, v.c.a );    		// copy color, pre-scale by tonemap //float4 (v.c.rgb*scale*2, v.c.a );

	return	o;
}