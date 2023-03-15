/*=============================================================================

    Copyright (c) Pascal Gilcher. All rights reserved.

 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 
=============================================================================*/

#pragma once

/*===========================================================================*/

namespace RayTracing
{

struct RayDesc 
{
    float3 origin;
    float3 pos;
    float3 dir;
    float2 uv;
    float length;
    float width; //faux cone tracing
};

float compute_intersection_deinterleaved(float4 screenuv, uint2 tile_count, float3 cam_dir, inout RayDesc ray, float maxT, float incT, float epsilon, bool snap_intersection)
{	
	float intersected = 0;

    float2 uv = ray.uv;
    float4 prev = float4(ray.origin, 0);

	[loop]
	while(ray.length < maxT)
	{
		float lambda = ray.length / maxT;  
		lambda = lambda * (lambda * (1.25 * lambda - 0.375) + 0.125);

		ray.pos = ray.origin + ray.dir * lambda * maxT; 
		ray.uv = Projection::proj_to_uv(ray.pos);

		if(!all(saturate(-ray.uv * ray.uv + ray.uv))) break;

		float z = tex2Dlod(sZTex, screenuv.xy + (ray.uv - screenuv.zw) / tile_count, 0).x;
		float3 pos = Projection::uv_to_proj(ray.uv, z);

		float delta = dot(cam_dir, pos - ray.pos);

		float z_tolerance = epsilon * maxT;
		z_tolerance *= lerp(0.2, 10.0, lambda); 
		 z_tolerance *= 1 + abs(ray.dir.z);

		[branch]
		if(abs(delta * 2.0 + z_tolerance) < z_tolerance)
		{
			intersected = saturate(1 - ray.length / maxT); 
			ray.uv = prev.w < 0 ? ray.uv : Projection::proj_to_uv(lerp(prev.xyz, ray.pos, prev.w / (prev.w + abs(delta))));
			if(snap_intersection)
				ray.dir = normalize(lerp(pos - ray.origin, ray.dir, saturate(0.111 * maxT * lambda)));
			break;
		}
	
		ray.length += incT;
		prev = float4(ray.pos, delta);  
	}

	return saturate(intersected);
}
/*

float compute_intersection(inout RayDesc ray, float maxT, float incT, float epsilon, bool snap_intersection)
{
	float intersected = 0;

    float2 uv = ray.uv;
    float4 prev = float4(ray.origin, 0);
	float2 prevuv = uv;

	[loop]
	while(ray.length < maxT)
	{
		float lambda = ray.length / maxT;  
		lambda = lambda * (lambda * (1.25 * lambda - 0.375) + 0.125);

		ray.pos = ray.origin + ray.dir * lambda * maxT; 
		ray.uv = Projection::proj_to_uv(ray.pos);

		if(!all(saturate(-ray.uv * ray.uv + ray.uv))) break; 

		float2 pixel_delta_total = BUFFER_SCREEN_SIZE * abs(ray.uv - uv);
		float2 pixel_delta_step  = BUFFER_SCREEN_SIZE * abs(ray.uv - prevuv);
		ray.width = log2(max(length(pixel_delta_total) * 0.0625, max(pixel_delta_step.x, pixel_delta_step.y) * 0.2));

#if MATERIAL_TYPE == 1
		ray.width = min(ray.width, 3 - saturate(1 - RT_ROUGHNESS * 2.0) * 3); 
#else 
		ray.width = min(ray.width, 3); //required for DX9 - mip chains are always generated fully, can't rely on application clamping it
#endif
		//ray.width = 0;

		float3 pos = Projection::uv_to_proj(ray.uv, sZTex, ray.width);
		float delta = pos.z - ray.pos.z;

		float z_tolerance = epsilon * maxT;
		z_tolerance *= lerp(0.2, 10.0, lambda); 
		z_tolerance *= abs(ray.dir.z); 

		[branch]
		if(abs(delta * 2.0 + z_tolerance) < z_tolerance)
		{
			intersected = saturate(1 - lambda);
			ray.uv = prev.w < 0 ? ray.uv : Projection::proj_to_uv(lerp(prev.xyz, ray.pos, prev.w / (prev.w + abs(delta))));
			if(snap_intersection)  
				ray.dir = normalize(lerp(pos - ray.origin, ray.dir, saturate(0.111 * maxT * lambda)));
			break;
		}
	
		ray.length += incT;
		prev = float4(ray.pos, delta);
		prevuv = ray.uv;       
	}

	return saturate(intersected);
}
*/
} //namespace
