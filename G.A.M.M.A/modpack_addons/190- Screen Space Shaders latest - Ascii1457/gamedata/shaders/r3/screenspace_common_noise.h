/**
 * @ Version: SCREEN SPACE SHADERS - UPDATE 9
 * @ Description: Main file - Noise
 * @ Modified time: 2022-07-31 05:12
 * @ Author: https://www.moddb.com/members/ascii1457
 * @ Mod: https://www.moddb.com/mods/stalker-anomaly/addons/screen-space-shaders
 */

float SSFX_noise(float2 tc)
{
	float2	noise = frac(tc.xy * 0.5f);
	return noise.x + noise.y * 0.5f;
}

float2 SSFX_noise2(float2 p)
{
	p = p % 289;
	float x = (34 * p.x + 1) * p.x % 289 + p.y;
	x = (34 * x + 1) * x % 289;
	x = frac(x / 41) * 2 - 1;
	return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
}

float SSFX_gradientNoise(float2 p)
{
	float2 ip = floor(p);
	float2 fp = frac(p);
	float d00 = dot(SSFX_noise2(ip), fp);
	float d01 = dot(SSFX_noise2(ip + float2(0, 1)), fp - float2(0, 1));
	float d10 = dot(SSFX_noise2(ip + float2(1, 0)), fp - float2(1, 0));
	float d11 = dot(SSFX_noise2(ip + float2(1, 1)), fp - float2(1, 1));
	fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
	return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
}