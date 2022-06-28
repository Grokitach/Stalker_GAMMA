// Screen Space Shaders - MAIN File
// Update 7 [ 2022/06/27 ]

#define SSFX_READY

#include "common.h"
#include "hmodel.h"

#include "check_screenspace.h"

uniform float4 sky_color;

static const float4 SSFX_ripples_timemul = float4(1.0f, 0.85f, 0.93f, 1.13f); 
static const float4 SSFX_ripples_timeadd = float4(0.0f, 0.2f, 0.45f, 0.7f);

struct RayTrace
{
	float2 r_pos;
	float2 r_step;
	float2 r_start;
	float r_length;
	float z_start;
	float z_end;
};

bool SSFX_is_saturated(float2 value) { return (value.x == saturate(value.x) && value.y == saturate(value.y)); }

bool SSFX_is_valid_uv(float2 value) { return (value.x >= 0.0f && value.x <= 1.0f) || (value.y >= 0.0f && value.y <= 1.0f); }

float2 SSFX_view_to_uv(float3 Pos)
{
	float4 tc = mul(m_P, float4(Pos, 1));
	return (tc.xy / tc.w) * float2(0.5f, -0.5f) + 0.5f;
}


float3 SSFX_yaw_vector(float3 Vec, float Rot)
{
	float s = sin(Rot);
	float c = cos(Rot);
	
	// y-axis rotation matrix
	float3x3 rot_mat = 
	{
		c, 0, s,
		0, 1, 0,
		-s, 0, c
	};
	return mul(rot_mat, Vec);
}


float SSFX_get_depth(float2 tc, uint iSample : SV_SAMPLEINDEX)
{
	#ifndef USE_MSAA
		return s_position.Sample(smp_nofilter, tc).z;
	#else
		return s_position.Load(int3(tc * screen_res.xy, 0), iSample).z;
	#endif
}


float3 SSFX_get_position(float2 tc, uint iSample : SV_SAMPLEINDEX)
{
	#ifndef USE_MSAA
		return s_position.Sample(smp_nofilter, tc).xyz;
	#else
		return s_position.Load(int3(tc * screen_res.xy, 0), iSample).xyz;
	#endif
}


RayTrace SSFX_ray_init(float3 ray_start_vs, float3 ray_dir_vs, float ray_max_dist, int ray_steps, float noise)
{
	RayTrace rt;
	
	float3 ray_end_vs = ray_start_vs + ray_dir_vs * ray_max_dist;
	
	// Ray depth ( from start and end point )
	rt.z_start 		= ray_start_vs.z;
	rt.z_end   		= ray_end_vs.z;
    
    // Compute ray start and end (in UV space)
    rt.r_start 		= SSFX_view_to_uv(ray_start_vs);
    float2 ray_end  = SSFX_view_to_uv(ray_end_vs);

    // Compute ray step
    float2 ray_diff	= ray_end - rt.r_start;
    rt.r_step     	= ray_diff / (float)ray_steps; 
	rt.r_length   	= length(ray_diff);
	
	rt.r_pos 		= rt.r_start + rt.r_step * noise;
	
	return rt;
}


float3 SSFX_ray_intersect(RayTrace Ray, uint iSample)
{
	float len = length(Ray.r_pos - Ray.r_start);
	float alpha = len / Ray.r_length;
	float depth_ray = (Ray.z_start * Ray.z_end) / lerp(Ray.z_end, Ray.z_start, alpha);
	float depth_scene = SSFX_get_depth(Ray.r_pos, iSample);
	
	return float3(depth_ray - depth_scene, depth_scene, len);
}


// Half-way scene lighting
float4 SSFX_get_fast_scenelighting(float2 tc, uint iSample : SV_SAMPLEINDEX)
{
	#ifndef USE_MSAA
		float4 rL = s_accumulator.Sample(smp_nofilter, tc);
		float4 C = s_diffuse.Sample( smp_nofilter, tc );
	#else
		float4 rL = s_accumulator.Load(int3(tc * screen_res.xy, 0), iSample);
		float4 C = s_diffuse.Load(int3( tc * screen_res.xy, 0 ), iSample);
	#endif
	
	#ifdef SSFX_ENHANCED_SHADERS // We have Enhanced Shaders installed
		
		float3 hdiffuse = C.rgb + L_ambient.rgb;
		
		rL.rgb += rL.a * SRGBToLinear(C.rgb);
		
		return float4(LinearTosRGB((rL.rgb + hdiffuse) * saturate(rL.rrr * 100)), C.w);
		
	#else
		
		float3 hdiffuse = C.rgb + L_ambient.rgb;

		return float4((rL.rgb + hdiffuse) * saturate(rL.rrr * 100), C.w);
		
	#endif
}


float3 SSFX_get_scenelighting(float2 tc, uint iSample : SV_SAMPLEINDEX)
{ 
	// Same way of building color and lighting in "combine_1.ps" but we can sample a especific uv
	gbuffer_data rgbd = gbuffer_load_data(GLD_P(tc, tc * screen_res.xy, iSample));
	
	// Sky from albedo
	if (rgbd.mtl <= 0.05)
	{
		// No idea why, but with MSAA the rgbd.C return a bugged value for the sky
		#ifndef USE_MSAA
			return rgbd.C.rgb;
		#else
			return fog_color.rgb; // Ugly solution, but at least simulates the right color for day and night cycle. TODO: Find a real solution
		#endif
	}
	float4 rD = float4(rgbd.C.rgb, rgbd.gloss);
	
	// Lighting
	#ifndef USE_MSAA
		float4 rL = s_accumulator.Sample(smp_nofilter, tc);
	#else
		float4 rL = s_accumulator.Load(int3(tc * screen_res.xy, 0), iSample);
	#endif

	#ifdef SSFX_ENHANCED_SHADERS // We have Enhanced Shaders installed
		
		if (abs(rgbd.mtl - MAT_FLORA) <= 0.05) 
		{
			float	fAtten = 1 - smoothstep(0, 50, rgbd.P.z);
			rD.a	*= (fAtten * fAtten);
		}
		rL.rgb += rL.a * SRGBToLinear(rD.rgb);

		// hemisphere
		float3 hdiffuse, hspecular;
		hmodel(hdiffuse, hspecular, rgbd.mtl, rgbd.hemi, rD, rgbd.P, rgbd.N);

		// Final color 
		float3 rcolor = rL.rgb + hdiffuse.rgb;
		return LinearTosRGB(rcolor);
		
	#else // !SSFX_ENHANCED_SHADERS
	
		// hemisphere
		float3 hdiffuse, hspecular;
		hmodel(hdiffuse, hspecular, rgbd.mtl, rgbd.hemi, rgbd.gloss, rgbd.P, rgbd.N);

		// Final color
		float4 light = float4(rL.rgb + hdiffuse, rL.w);
		float4 C = rD * light;
		float3 spec = C.www * rL.rgb + hspecular * C.rgba;
		
		return C.rgb + spec;
		
	#endif
}


#ifndef REFLECTIONS_H
	TextureCube s_env0;
	TextureCube s_env1;
#endif

float3 SSFX_calc_sky(float3 dir)
{
	dir = SSFX_yaw_vector(dir, -sky_color.w); // Sky rotation
	
	dir.y = (dir.y - max(cos(dir.x) * 0.65f, cos(dir.z) * 0.65f)) * 2.1f; // Fix perspective
	dir.y -= -0.35; // Altitude
	
	float3 sky0 = s_env0.SampleLevel(smp_base, dir, 0).xyz;
	float3 sky1 = s_env1.SampleLevel(smp_base, dir, 0).xyz;
	
	// Use hemi color or real sky color if the modded executable is installed.
#ifndef SSFX_MODEXE
	return saturate(L_hemi_color.rgb * 3.0f) * lerp(sky0, sky1, L_ambient.w);
#else
	return saturate(sky_color.bgr * 3.0f) * lerp(sky0, sky1, L_ambient.w);
#endif
}


// https://www.scratchapixel.com/lessons/3d-basic-rendering/introduction-to-shading/reflection-refraction-fresnel
// 1.3f water ~ 1.5f glass ~ 1.8f diamond
float SSFX_calc_fresnel(float3 V, float3 N, float ior)
{
	float cosi = clamp(-1, 1, dot(V, N));
	float etai = 1, etat = ior;
	if (cosi > 0)
	{
		etai = ior;
		etat = 1;
	}
	// Compute sini using Snell's law
	float sint = etai / etat * sqrt(max(0.f, 1 - cosi * cosi));
	// Total internal reflection
	if (sint >= 1)
		return 1.0f;

	float cost = sqrt(max(0.f, 1 - sint * sint));
	cosi = abs(cosi); 
	float Rs = ((etat * cosi) - (etai * cost)) / ((etat * cosi) + (etai * cost));
	float Rp = ((etai * cosi) - (etat * cost)) / ((etai * cosi) + (etat * cost));

	return (Rs * Rs + Rp * Rp) / 2;
}


// https://seblagarde.wordpress.com/2013/01/03/water-drop-2b-dynamic-rain-and-its-effects/
float3 SSFX_computeripple(float4 Ripple, float CurrentTime, float Weight)
{
    Ripple.yz = Ripple.yz * 2 - 1; // Decompress perturbation

    float DropFrac = frac(Ripple.w + CurrentTime); // Apply time shift
    float TimeFrac = DropFrac - 1.0f + Ripple.x;
    float DropFactor = saturate(0.2f + Weight * 0.8f - DropFrac);
    float FinalFactor = DropFactor * Ripple.x * 
                        sin( clamp(TimeFrac * 9.0f, 0.0f, 3.0f) * 3.14159265359);

    return float3(Ripple.yz * FinalFactor * 0.65f, 1.0f);
}


float3 SSFX_ripples( Texture2D ripple_tex, float2 tc ) 
{
	float4 Times = (timers.x * SSFX_ripples_timemul + SSFX_ripples_timeadd) * 1.5f;
	Times = frac(Times);

	float4 Weights = float4( 0, 1.0, 0.65, 0.25);

	float3 Ripple1 = SSFX_computeripple(ripple_tex.Sample( smp_base, tc + float2( 0.25f,0.0f)), Times.x, Weights.x);
	float3 Ripple2 = SSFX_computeripple(ripple_tex.Sample( smp_base, tc + float2(-0.55f,0.3f)), Times.y, Weights.y);
	float3 Ripple3 = SSFX_computeripple(ripple_tex.Sample( smp_base, tc + float2(0.6f, 0.85f)), Times.z, Weights.z);
	float3 Ripple4 = SSFX_computeripple(ripple_tex.Sample( smp_base, tc + float2(0.5f,-0.75f)), Times.w, Weights.w);
	
	Weights = saturate(Weights * 4);
	float4 Z = lerp(1, float4(Ripple1.z, Ripple2.z, Ripple3.z, Ripple4.z), Weights);
	float3 Normal = float3( Weights.x * Ripple1.xy +
							Weights.y * Ripple2.xy + 
							Weights.z * Ripple3.xy +
							Weights.w * Ripple4.xy, 
							Z.x * Z.y * Z.z * Z.w);
	
	return normalize(Normal) * 0.5 + 0.5;
}