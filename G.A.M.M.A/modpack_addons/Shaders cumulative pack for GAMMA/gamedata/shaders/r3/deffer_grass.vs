#include "common.h"

float4 consts; // {1/quant,1/quant,diffusescale,ambient}
float4 wave; // cx,cy,cz,tm
float4 dir2D; 
float4 array[61*4];
/*
	Updated grass shader
	
	-Supports normal mapping
	-Simple SSS approx. (Spherical normals)
	
	Credits: 
	-Zagolski - Faster normal mapping code

	Keep this header in, and put credits onto your mod page. 
	Thanks.
*/

v2p_bumped 	main (v_detail v)
{
	v2p_bumped 		O;
	// index
	int 	i 	= v.misc.w;
	float4  m0 	= array[i+0];
	float4  m1 	= array[i+1];
	float4  m2 	= array[i+2];
	float4  c0 	= array[i+3];

	// Transform pos to world coords
	float4 pos;
 	pos.x = dot(m0, v.pos);
 	pos.y = dot(m1, v.pos);
 	pos.z = dot(m2, v.pos);
	pos.w = 1;
	
	//Wave effect
	float base = m1.w;
	float dp = calc_cyclic   (dot(pos,wave));
	float H = pos.y - base;			// height of vertex (scaled)
	float frac = v.misc.z*consts.x;		// fractional
	float inten = H * dp;
	float2 result = calc_xz_wave(dir2D.xz*inten,frac);
	pos = float4(pos.x+result.x, pos.y, pos.z+result.y, 1);
	
	
	//Normal mapping
	float randNum		= frac;
	float3 normUp		= float3(0,1,0);
	float3 posOffset = float3(sin(randNum*40), 1, cos(randNum*30)) * 1.25; 
	//float3 posOffset = float3(0.25, 0.75, 0.5) * 1; 
	float3 normSphereOffset		=  normalize(v.pos.xyz + posOffset);
	float3 normSphere		=  normalize(v.pos.xyz);
	float3 N = lerp(normSphereOffset, normUp, 0.25);
	//float3 N = lerp(normSphereOffset, normSphere, 0.25);
	
	//N = float3(0,1,0);
	//N.y *= sign(N.y); //no downwards facing normals
	N = normalize(N);
	
	float3 B = float3(0,0,1);
	//float3 B = float3(0,1,0);

	if (abs(dot(N, B)) > 0.99f) 
		B = float3(0,1,0);
		
	float3 T = normalize(cross(N, B));
	T = float3(0,0,0);
	
	B = normalize(cross(N, T));
		
	//T = float3(0,0,0);
	//B = float3(0,1,0);
	
	
	//TBN matrix
	float3x3 xform	= mul((float3x3)m_WV, float3x3(
						T.x,B.x,N.x,
						T.y,B.y,N.y,
						T.z,B.z,N.z
				));

	O.M1 = xform[0]; 
	O.M2 = xform[1]; 
	O.M3 = xform[2]; 

	// Final out
	float4 Pp = mul(m_WVP,	pos);
	O.hpos = Pp;
	float3 Pe = mul(m_WV,  pos);
	O.tcdh = float4((v.misc * consts).xyyy);

#if defined(USE_R2_STATIC_SUN)
	O.tcdh.w = c0.x; // (,,,dir-occlusion)
#endif
	O.position = float4(Pe, c0.w);

	return O;
}
FXVS;
