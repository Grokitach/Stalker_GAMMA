#ifndef        HMODEL_H
#define HMODEL_H

#include "pbr_cubemap_check.h"

TextureCube		env_s0;
TextureCube		env_s1;

uniform float4		env_color;        // color.w = lerp factor
float4 hmodel_stuff;  //x - hemi vibrance // y - hemi contrast // z - wet surface factor

void hmodel
(
	out float3 hdiffuse, out float3 hspecular,
	float m, float h, float4 alb_gloss, float3 Pnt, float3 normal
)
{
	//alb_gloss.a = max(smoothstep(0.25,0.75,rain_params.x*m*2),alb_gloss.a);	//rain test

	//PBR style
	float3 albedo = calc_albedo(alb_gloss.rgb, m);
	float3 f0 = calc_f0(alb_gloss.a, m);
	float rough = calc_rough(alb_gloss.a, m);

	bool m_terrain = abs(m - 0.95) <= 0.02f;

	float roughCube = rough; //cubemap mipmaps (brdf too?)

// hscale - something like diffuse reflection
	normal = normalize(normal);
	float3	nw = mul(m_inv_V, normal );
	float	hscale = h;	//. * (.5h + .5h*nw.y);

	//reflection vector
	float3	v2PntL = normalize(Pnt );
	float3	v2Pnt = mul(m_inv_V, v2PntL );
	v2Pnt = normalize(v2Pnt);
	nw = normalize(nw);

	float3	vreflect= reflect(v2Pnt, nw );
	vreflect = lerp(nw, vreflect, (1-rough) * (sqrt(1-rough) + rough)); //dice normal blend

	float3 vreflectabs = abs(vreflect);
	float vreflectmax = max(vreflectabs.x, max(vreflectabs.y, vreflectabs.z));
	vreflect	  /= vreflectmax;
	if (vreflect.y < 0.999)
	vreflect.y = vreflect.y*2-1;	//fake remapping
	vreflect = normalize(vreflect);

	float3 nwRemap = nw;
	/*
	float3 vnormabs    = abs(nwRemap);
	float  vnormmax    = max(vnormabs.x, max(vnormabs.y, vnormabs.z));
	nwRemap      /= vnormmax;
	if (nwRemap.y < 0.999)
	nwRemap.y= nwRemap.y*2-1;     // fake remapping
	nwRemap = normalize(nwRemap);
	*/

	//diffuse color
	float3 e0d = CubeDiffuse(roughCube, env_s0, nwRemap.xyz ); 		//Valve AmbientCube method
	float3 e1d = CubeDiffuse(roughCube, env_s1, nwRemap.xyz ); 		//could probably be optimized to not sample the cubemap so much if mips worked

	//specular color
	float3	e0s = CubeSpecular(roughCube, env_s0, vreflect.xyz, m); //Sample mipmapped cubemap
	float3	e1s = CubeSpecular(roughCube, env_s1, vreflect.xyz, m);

	float3 env_col = env_color.rgb;
	float3 amb_col = L_ambient.rgb;

	//lerp
	float3 env_d = lerp(e0d, e1d, env_color.w);
	float3 env_s = lerp(e0s, e1s, env_color.w);

	//tint
	env_d *= env_col;
	env_s *= env_col;

	#ifdef USE_PBR_CUBEMAPS
	//square only the tint
	env_d *= env_col;
	env_s *= env_col;
	#else
	//squaring? disabled for PBR cubemaps, it makes the colors inaccurate
	env_d *= env_d;
	env_s *= env_s;//+(rain_params.x/10.0);
	#endif

	//roughness?
	hscale	= s_material.SampleLevel( smp_material, float3( hscale, 0, m ), 0 ).x;

	//directional ambient
	//TODO - make hscale normal mapped
	env_d *= hscale;
	env_s *= hscale;

	//add ambient
	env_d += amb_col;
	env_s += amb_col * (0.2 * !m_terrain);

	env_d = SRGBToLinear(env_d);
	env_s = SRGBToLinear(env_s);

#ifdef USE_PBR
	//BRDF
	float3 light = Amb_BRDF(roughCube, albedo, f0, env_d, env_s, -v2Pnt, nw );
#else
	//float spec = SRGBToLinear(lerp(alb_gloss.w*Ldynamic_color.w,1,rain_params.x*0.25));
	float spec = SRGBToLinear(alb_gloss.w);
	//BRDF
	float3 light = Amb_BRDF(roughCube, 0, f0, env_d, env_s, -v2Pnt, nw );
	light *= spec*0.25;
	light += env_d*albedo;
#endif


	hdiffuse = light.rgb;
	hspecular = 0; //do not use hspec at all

}
#endif
