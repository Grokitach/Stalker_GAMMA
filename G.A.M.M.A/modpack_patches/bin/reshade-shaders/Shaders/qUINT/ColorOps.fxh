/*=============================================================================

    Copyright (c) Pascal Gilcher. All rights reserved.

 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential

=============================================================================*/

#pragma once
#include "Colorspaces.fxh"

/*===========================================================================*/

namespace ColorOps
{

/*=============================================================================
	Color Remapper
=============================================================================*/   

float3 color_remapper(in float3 rgb, float3 modifier_red, 
    	                             float3 modifier_orange, 
                                     float3 modifier_yellow, 
                                     float3 modifier_green, 
                                     float3 modifier_aqua, 
                                     float3 modifier_blue, 
                                     float3 modifier_magenta)
{
    static const float hue_nodes[8] = {	 0.0, 1.0/12.0, 2.0/12.0, 4.0/12.0, 6.0/12.0, 8.0/12.0, 10.0/12.0, 1.0};

    float hue = Colorspace::rgb_to_hsl(rgb).x;

    float risingedges[7];
	for(int j = 0; j < 7; j++) risingedges[j] = linearstep(hue_nodes[j], hue_nodes[j+1], hue);
    
    float hueweights[7];    
    hueweights[0] = ((1.0 - risingedges[0]) + risingedges[6]); //this goes over the 2 pi boundary, so this needs special treatment
    for(int j = 1; j < 7; j++) hueweights[j] = ((1.0 - risingedges[j]) * risingedges[j - 1]); 

    float3 hue_modifiers[7] = {modifier_red, modifier_orange, modifier_yellow, modifier_green, modifier_aqua, modifier_blue, modifier_magenta};
    float3 LChmod = 0;

    [loop]
    for(int hue = 0; hue < 7; hue++)
    {
        float w = hueweights[hue];
        w = w * w * (3.0 - 2.0 * w); //smoothstep - integral is energy conserving vs linear, otherwise we'd need to normalize weights here!!
        LChmod.z += abs(hue_modifiers[hue].x) * hue_modifiers[hue].x * w;
        LChmod.xy += hue_modifiers[hue].zy * w;  
    }

    float3 oklab = Colorspace::rgb_to_oklab(rgb);

   //oklab.x *= exp2(LChmod.x * 0.33333); //legacy - visual parity to HSL based tools
    oklab.x = pow(oklab.x, exp2(-LChmod.x * 4 * length(oklab.yz))); //better, leaves greys untouched. Not sure if sqrt is needed

    float2 huesc; sincos(-3.14159265 * LChmod.z, huesc.x, huesc.y); 
    oklab.yz = mul(oklab.yz, float2x2(huesc.y, -huesc.x, huesc.x, huesc.y)); 

    oklab.yz = LChmod.y < 0 
             ? oklab.yz * (1 + LChmod.y) //reduce saturation -> saturation 0%-100%
             : normalize(oklab.yz) * pow(length(oklab.yz) * 2.0, exp2(-LChmod.y * 0.5)) * 0.5; //increase saturation -> vibrance

    return Colorspace::oklab_to_rgb(oklab);
}

/*=============================================================================
	Tone Curve
=============================================================================*/

float p(float x)  
{ 
    return x < 0.3333333 ? x * (-3.0 * x * x + 1.0) 
                         : 1.5 * x * (1.0 + x * (x - 2.0)); 
}

float shadows(float x)
{
    return p(saturate(x * 2.0)) * 0.5;
}

float darks(float x)
{
    return p(x);    
}

float lights(float x)
{
    return p(1.0 - x);
}

float highlights(float x)
{
    return lights(saturate(x * 2.0 - 1.0)) * 0.5;
}

float tonecurve(float x, float int_s, float int_d, float int_l, float int_h, float int_dw, float r_dw)
{    
    float s = x;

    x += shadows(s) * int_s;
    x += darks(x) * int_d;
    x += lights(s) * int_l;
    x += highlights(x) * int_h;

    float t = x / (r_dw + 1e-6);
    float dw = (10.0 * r_dw  - x) * t * t * (1.0 / 31.25) + r_dw;

    x = max(x, (dw - x) * int_dw + x);
	return x;
}

float3 tonecurve(float3 rgb, float int_s, float int_d, float int_l, float int_h, float int_dw, float r_dw)
{    
    rgb.x = tonecurve(rgb.x, int_s, int_d, int_l, int_h, int_dw, r_dw);
    rgb.y = tonecurve(rgb.y, int_s, int_d, int_l, int_h, int_dw, r_dw);
    rgb.z = tonecurve(rgb.z, int_s, int_d, int_l, int_h, int_dw, r_dw);
    return rgb;
}

/*=============================================================================
	Levels
=============================================================================*/

float3 input_remap( float3 x,   
					 float3 blacklevel, 
					 float3 whitelevel,
                     float3 blacklevel_out,
                     float3 whitelevel_out)
{
    x = linearstep(blacklevel, whitelevel + 1e-6, x);   
    x = lerp(blacklevel_out, whitelevel_out, x); 
	return x;
}

/*=============================================================================
	Lift Gamma Gain
=============================================================================*/

float3 lgg(float3 x, int mode, float3 lift, float3 gamma, float3 gain)
{
    switch(mode)
    {
        //https://en.wikipedia.org/wiki/ASC_CDL
        case 0: 
        {
            lift = lift - 0.5;
            gamma = 1.0 - gamma + 0.5;
            gain = gain + 0.5;     
            x = pow(saturate((x * gain) + lift), gamma);
            break; //can't early out here due to DX compiler being a jackass (uninitialized variable...)
        }
        case 1:
        {
            x = lerp(lift - 0.5, 1 + (gain - 0.5), x);
            x = pow(saturate(x), 1 - gamma + 0.5);  
            break;
        }
    }
    return x;
}

/*=============================================================================
	Split Toning
=============================================================================*/

float3 extended_overlay(float3 base, float3 blend)
{
    float sharpness = 7; //max ~100 without precision loss
    float3 poly_tri = 1 - pow(pow(base, sharpness) + pow(1 - base, sharpness), rcp(sharpness)); //form smooth triangle (vs hard triangle in regular overlay)
    return base + poly_tri * (blend * 2 - 1);
}

float3 soft_light(float3 base, float3 blend)
{	
	return pow(base, exp2(1 - 2 * blend));
}

float3 splittone(float3 c, uint mode, uint blend, float in_balance, float3 col_a, float3 col_b)
{
    float luma = Colorspace::get_srgb_luma(c);
    float balance = 0;

    switch(mode)
    {
        case 0:
        {
            float expo = exp2(in_balance * 3 - 1.13); //adjust range so it's perceptually balanced at 0, gamma 2.2
            balance = expo > 1 ? pow(luma, expo) : 1 - pow(1 - luma, rcp(expo));
            break;
        }
        case 1: 
        {
            float3 v_sat = c - luma;
            float3 k = v_sat < 0.0.xxx ? c : 1 - c;
            k /= abs(v_sat) + 1e-6;
            float min_k = min(min(k.x, k.y), k.z); //which component saturates earliest?
            float sat = saturate(rcp(1 + min_k));

            float expo = exp2(in_balance * 6);
            balance = expo > 1 ? pow(sat, expo) : 1 - pow(1 - sat, rcp(expo));
            break;
        }            
    }

    float3 tintcolor = Colorspace::oklab_to_rgb(lerp(Colorspace::rgb_to_oklab(col_a),
                                                        Colorspace::rgb_to_oklab(col_b),
                                                        balance));
                                        
    c = blend == 1 ? extended_overlay(c, tintcolor) : soft_light(c, tintcolor);                        
    return c;
}

/*=============================================================================
	Color Balance
=============================================================================*/

float3 color_balance(float3 c, float2 bal_sh, float2 bal_mid, float2 bal_hi)
{
    //better use some perceptually well fitting estimate
    float luma = Colorspace::linear_to_srgb(dot(Colorspace::srgb_to_linear(c), float3(0.2126729, 0.7151522, 0.0721750))).x;

    float3 offsetSMH = float3(0, 0.5, 1);
    float3 widthSMH = float3(2.0, 1.0, 2.0);

    float3 weightSMH = saturate(1 - 2 * abs(luma - offsetSMH) / widthSMH);
    weightSMH = weightSMH * weightSMH * (3 - 2 * weightSMH);
    weightSMH *= weightSMH; //these do not sum up to 1.0, makes no sense in Lightroom either
    weightSMH.z *= 2.0;

    float3 tintcolorS = Colorspace::hsl_to_rgb(float3(frac(0.5 + bal_sh.x), 1, 0.5));
    float3 tintcolorM = Colorspace::hsl_to_rgb(float3(frac(0.5 + bal_mid.x), 1, 0.5));
    float3 tintcolorH = Colorspace::hsl_to_rgb(float3(frac(0.5 + bal_hi.x), 1, 0.5));

    return length(c) * normalize(pow(c, exp2(tintcolorS * weightSMH.x * bal_sh.y*bal_sh.y
                                           + tintcolorM * weightSMH.y * bal_mid.y*bal_mid.y
                                           + tintcolorH * weightSMH.z * bal_hi.y*bal_hi.y)));
}

/*=============================================================================
	Adjustments
=============================================================================*/

float3 adjustments(float3 col, float exposure, float contrast, float gamma, float vibrance, float saturation, float filmic_gamma)
{
    col = Colorspace::srgb_to_linear(col);
    col *= exp2(exposure); //exposure in linear space - this makes no _visual_ difference but alters the response of the exposure curve
    col = Colorspace::linear_to_srgb(col);
    col = saturate(col);

    float3 tcol = col * filmic_gamma * (filmic_gamma > 0 ? 6.0 : 0.6);
    col = (tcol + col) / (tcol + 1);
    col = saturate(col);

    col = pow(col, exp2(-gamma));
    float3 contrasted = col - 0.5;
    contrasted = (contrasted / (0.5 + abs(contrasted))) + 0.5; //CJ.dk
    col = lerp(col, contrasted, contrast);

    float luma = Colorspace::linear_to_srgb(dot(Colorspace::srgb_to_linear(col), float3(0.2126729, 0.7151522, 0.0721750))).x;
    float3 v_sat = col - luma;

    float3 k = v_sat < 0.0.xxx ? col : 1 - col;
    k /= abs(v_sat) + 1e-6;
    float min_k = min(min(k.x, k.y), k.z); //which component saturates earliest?

    float vib = vibrance;
    vib *= vib > 0 ? min_k * rsqrt(vib * vib + min_k * min_k) : saturate(1 - rcp(1 + min_k));

    float final_sat = vib * (1 + saturation) + saturation;
    final_sat = clamp(final_sat, -1, min_k); //force limit to prevent hueshifts

    col += v_sat * final_sat;
    return col;
}

/*=============================================================================
	Special FX
=============================================================================*/

float3 specialfx(float3 c, float bleach_amt, float2 gamma_l_ch)
{
    //after removing all back and forth math involved with negative film process
    //at the end bleach bypass is just subtractive (multiplicative) mix with image luma

    //better use some perceptually well fitting estimate
    float luma = Colorspace::linear_to_srgb(dot(Colorspace::srgb_to_linear(c), float3(0.2126729, 0.7151522, 0.0721750))).x;
    c *= lerp(1.0, luma, bleach_amt);    
    c = pow(saturate(c), rcp(1.0 + bleach_amt * 0.5));

    float k = 1.73205; //sqrt(3)
    float l = length(c);
    float3 ch = c / (l + 1e-6);

    ch = pow(ch, exp2(gamma_l_ch.y));
    l = pow(l / k, exp2(-gamma_l_ch.x)) * k;

    c = normalize(ch + 1e-6) * l; 

    return c;
}

/*=============================================================================
	White Balance / Calibration
=============================================================================*/

float3 blackbody_xyz(float temperature) 
{
    float term = 1000.0 / temperature;

    const float4 xc_coefficients[2] = 
    {
        float4(-3.0258469, 2.1070379, 0.2226347, 0.240390), 
        float4(-0.2661293,-0.2343589, 0.8776956, 0.179910) 
    };

    const float4 yc_coefficients[3] =
    {
        float4(-1.1063814,-1.34811020, 2.18555832,-0.20219683), 
        float4(-0.9549476,-1.37418593, 2.09137015,-0.16748867), 
        float4( 3.0817580,-5.87338670, 3.75112997,-0.37001483)
    };

    float3 xyz;

    float4 xc;
    xc.w = 1.0;
    xc.xyz = term;
    xc.xy *= term;
    xc.x *= term;

    float x = dot(xc, temperature > 4000.0 ? xc_coefficients[0] : xc_coefficients[1]); //xc

    float4 yc;
    yc.w = 1.0;
    yc.xyz = x;
    yc.xy *= x;
    yc.x *= x;

    float y = dot(yc, temperature < 2222.0 ? yc_coefficients[0] : (temperature < 4000.0 ? yc_coefficients[1] : yc_coefficients[2])); //yc

    float3 XYZ;
    XYZ.y = 1.0;
    XYZ.x = XYZ.y / y * x;
    XYZ.z = XYZ.y / y * (1.0 - x - y);

    return XYZ;
}

float3x3 chromatic_adaptation(float3 xyz_src, float3 xyz_dst)
{
    //https://en.wikipedia.org/wiki/LMS_color_space
    //Hunt-Pointer-Estevez transformation, old LMS <-> XYZ, also called von Kries transform
    //using newer XYZ <-> LMS matrices won't work here
    const float3x3 xyz_to_lms = float3x3(0.4002, 0.7076, -0.0808,           
                                        -0.2263, 1.1653, 0.0457,
                                         0,0,0.9182);
    const float3x3 lms_to_xyz = float3x3(1.8601 ,  -1.1295, 0.2199,
                                        0.3612, 0.6388 , -0.0000,
                                        0, 0, 1.0891);                                

    float3 lms_src = mul(xyz_src, xyz_to_lms);
    float3 lms_dst = mul(xyz_dst, xyz_to_lms);

    float3x3 von_kries_transform = float3x3(lms_dst.x / lms_src.x, 0, 0,
                                            0, lms_dst.y / lms_src.y, 0,
                                            0, 0, lms_dst.z / lms_src.z);

    return mul(mul(xyz_to_lms, von_kries_transform), lms_to_xyz);
}

float3 calibration(float3 rgb, float temperature, float lab_A_shift, float lab_B_shift, float3 primary_hues, float3 primary_sat, int primary_mode)
{
    float3 xyz_src = blackbody_xyz(6500.0);
    float3 xyz_dst = blackbody_xyz(temperature);

    float3 adjusted = Colorspace::rgb_to_xyz(rgb);
    adjusted = mul(adjusted, chromatic_adaptation(xyz_src, xyz_dst));
    adjusted = Colorspace::xyz_to_rgb(adjusted);
    adjusted = saturate(adjusted);

    float3 lab = Colorspace::rgb_to_oklab(adjusted);
    lab.yz += float2(lab_A_shift, lab_B_shift) * 0.05;
    adjusted = Colorspace::oklab_to_rgb(lab);
    adjusted = saturate(adjusted);

    float3 c = adjusted;
    float minc = min(min(c.x, c.y), c.z);
    
    if(primary_mode == 0 || primary_mode == 2) c -= minc;

    float3 prim_R = float3(1, saturate(primary_hues.x), saturate(-primary_hues.x));
    float3 prim_G = float3(saturate(-primary_hues.y), 1, saturate(primary_hues.y));
    float3 prim_B = float3(saturate(primary_hues.z), saturate(-primary_hues.z), 1);
    
    if(primary_mode != 0)
    {
        prim_R = lerp(dot(prim_R, 0.33333), prim_R, 1 + primary_sat.x);
        prim_G = lerp(dot(prim_G, 0.33333), prim_G, 1 + primary_sat.y);
        prim_B = lerp(dot(prim_B, 0.33333), prim_B, 1 + primary_sat.z);
    }
    else 
    {
        prim_R = lerp(dot(prim_R, 0.33333), prim_R, dot(c / dot(c, 1), 1 + primary_sat));
        prim_G = lerp(dot(prim_G, 0.33333), prim_G, dot(c / dot(c, 1), 1 + primary_sat));
        prim_B = lerp(dot(prim_B, 0.33333), prim_B, dot(c / dot(c, 1), 1 + primary_sat));
    }    

    prim_R = normalize(prim_R);
    prim_G = normalize(prim_G);
    prim_B = normalize(prim_B);

    c = normalize(c.r * prim_R + c.g * prim_G + c.b * prim_B) * length(c); 

    if(primary_mode == 0 || primary_mode == 2) c += minc;
    c = saturate(c);
    return c;
}

/*=============================================================================
	Unused
=============================================================================*/  

//calculates saturation very similar to how Adobe LrC does it
float3 colorsat_lightroom(float3 c)
{
    float minc = min(min(c.x, c.y), c.z);
    c -= minc;
    float maxc = max(max(c.x, c.y), c.z);

    float sat = 2.0;
    c = lerp(dot(c, 0.33333), c, sat);
    c *= maxc / max(max(c.x, c.y), c.z);
    c += minc;

    return c;
}

} //Namespace