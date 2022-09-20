#ifndef	common_functions_h_included
#define	common_functions_h_included

#include "srgb.h"

//	contrast function
float Contrast(float Input, float ContrastPower)
{
	 //piecewise contrast function
	 bool IsAboveHalf = Input > 0.5 ;
	 float ToRaise = saturate(2*(IsAboveHalf ? 1-Input : Input));
	 float Output = 0.5*pow(ToRaise, ContrastPower); 
	 Output = IsAboveHalf ? 1-Output : Output;
	 return Output;
}

float3 vibrance( float3 img, float val )
{
	float luminance = dot( img.rgb, LUMINANCE_VECTOR );
	return float3( lerp( luminance, img.rgb, val ));
}

void		tonemap (out half4 low, out half4 high, float3 rgb, float scale)
{
	rgb =		rgb*scale;

	const float fWhiteIntensity = 11.2;

	low =   float4(tonemap_sRGB(rgb, fWhiteIntensity ), 0);
	high = 	half4(rgb/def_hdr, 0);
}

float3 compute_colored_ao(float ao, float3 albedo)
{ //https://www.activision.com/cdn/research/s2016_pbs_activision_occlusion.pptx
	float3 a = 2.0404 * albedo - 0.3324;
	float3 b = -4.7951 * albedo + 0.6417;
	float3 c = 2.7552 * albedo + 0.6903;

	return max(ao, ((ao * a + b) * ao + c) * ao);
}
	
float4 combine_bloom(float3 low, float4 high)	
{
	//return	float4(low + high*high.a, 1); //add
	high.rgb  *= high.a;
	return	float4(1-((1-low.rgb)*(1-high.rgb)), 1); //screen
}	

float		  calc_fogging			   (float4 w_pos)	  
{ 
return dot(w_pos,fog_plane);		 
}


float3		calc_sun_r1				(float3 norm_w)	{ return L_sun_color*saturate(dot((norm_w),-L_sun_dir_w));				 }
float3		calc_model_hemi_r1		 (float3 norm_w)	{ return max(0,norm_w.y)*L_hemi_color;										 }
float3		calc_model_lq_lighting	 (float3 norm_w)	{ return L_material.x*calc_model_hemi_r1(norm_w) + L_ambient + L_material.y*calc_sun_r1(norm_w);		 }

float3   p_hemi		  (float2 tc)						 {
		float4			t_lmh		 = tex2D			 	(s_hemi, tc);
		return t_lmh.a;
}

float   get_hemi( float4 lmh)
{
	return lmh.a;
}

float   get_sun( float4 lmh)
{
	return lmh.g;
}


float3	v_hemi			(float3 n)							{		return L_hemi_color*(.5f + .5f*n.y);				   }
float3	v_hemi_wrap	 (float3 n, float w)					{		return L_hemi_color*(w + (1-w)*n.y);				   }
float3	v_sun		   (float3 n)							{		return L_sun_color*dot(n,-L_sun_dir_w);				}
float3	v_sun_wrap	  (float3 n, float w)					{		return L_sun_color*(w+(1-w)*dot(n,-L_sun_dir_w));	  }


float3		 calc_reflection	 (float3 pos_w, float3 norm_w)
{
	return reflect(normalize(pos_w-eye_position), norm_w);
}

//CUSTOM
float3 blend_soft(float3 a, float3 b)
{
	return 1.0 - (1.0 - a) * (1.0 - b);
}

float4 screen_to_proj(float2 screen, float z)
{
	float4 proj;
	proj.w = 1.0;
	proj.z = z;
	proj.x = screen.x*2 - proj.w;
	proj.y = -screen.y*2 + proj.w;
	return proj;
}


float4 convert_to_screen_space(float4 proj)
{
	float4 screen;
	screen.x = (proj.x + proj.w)*0.5;
	screen.y = (proj.w - proj.y)*0.5;
	screen.z = proj.z;
	screen.w = proj.w;
	return screen;
}

float4 proj_to_screen(float4 proj)
{
	float4 screen = proj;
	screen.x = (proj.x + proj.w);
	screen.y = (proj.w - proj.y);
	screen.xy *= 0.5;
	return screen;
}

float normalize_depth(float depth)
{
	return (saturate(depth/100));
}

#ifndef SKY_WITH_DEPTH
float is_sky(float depth)
{
	return step(depth, SKY_EPS);
}
float is_not_sky(float depth)
{
	return step(SKY_EPS, depth);
}
#else
float is_sky(float depth)
{
	return step(abs(depth - SKY_DEPTH), SKY_EPS);
}
float is_not_sky(float depth)
{
	return step(SKY_EPS, abs(depth - SKY_DEPTH));
}
#endif

float hash(float2 intro)
{
return frac(1.0e4 * sin(17.0*intro.x + 0.1*intro.y) * (0.1 + abs(sin(13.0*intro.y + intro.x))));
}

float hash3D(float3 intro)
{
return hash(float2(hash(intro.xy),intro.z));
}

float hash12(float2 p)
{
	float3 p3  = frac(float3(p.xyx) * .1031);
	p3 += dot(p3, p3.yzx + 19.19);
	return frac((p3.x + p3.y) * p3.z);
}

float2 hash22(float2 p)
{
	float3 p3 = frac(float3(p.xyx) * float3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx+19.19);
	return frac((p3.xx+p3.yz)*p3.zy);
}

float rand(float n)
{
	return frac(cos(n)*343.42);
}

float noise(float2 tc)
{
	return frac(sin(dot(tc, float2(12.0, 78.0) + (timers.x) )) * 43758.0)*0.25f; 
}
#endif	//	common_functions_h_included
