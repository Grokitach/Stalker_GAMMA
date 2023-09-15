//All credits to LVunter

//BRDF UTILS
//////////////////////////////////////////////////////////////////////////////

//Normal distribution function for GGX
float NDF_GGX(float NdotH, float alpha)
{
    alpha *= alpha;
    float denominator = (NdotH * alpha - NdotH) * NdotH + 1.0;
    return alpha / (PI * denominator * denominator);
}

//Lambda used in G2-G1 functions
float Lambda_Smith(float NdotX, float alpha)
{    
    float alpha_sqr = alpha * alpha;
    float NdotX_sqr = NdotX * NdotX;
    return (-1.0 + sqrt(alpha_sqr * (1.0 - NdotX_sqr) / NdotX_sqr + 1.0)) * 0.5;
}

//Height Correlated Masking-shadowing function
float G2_Smith(float NdotL, float NdotV, float alpha)
{
	float lambdaV = Lambda_Smith(NdotV, alpha);
	float lambdaL = Lambda_Smith(NdotL, alpha);

	return 1.0 / (1.0 + lambdaV + lambdaL);
}

//Returns microfacet normal with GGX distribution
float3 sample_ggx_ndf(float2 Xi, float alpha)
{
	float alpha_sqr = alpha * alpha;
		
	float phi = 2.0 * PI * Xi.x;
				 
	float cos_theta = sqrt((1.0 - Xi.y) / (1.0 + (alpha_sqr - 1.0) * Xi.y));
	float sin_theta = sqrt(1.0 - cos_theta * cos_theta);
    
    //Microfacet normal
	float3 H;
    {
        H.x = sin_theta * cos(phi);
        H.y = sin_theta * sin(phi);
        H.z = cos_theta;
    }
	return H; 
}

//Calculates GGX-Smith BRDF
float3 ggx_smith_brdf(float NdotL, float NdotV, float NdotH, float VdotH, float3 F0, float alpha, float2 texcoord)
{
    //Normal distribution function
    float NDF = NDF_GGX(NdotH, alpha);
    
    //Masking-shadowing
    float G2 = G2_Smith(NdotL, NdotV, alpha);
    
    //Fresnel
    float3 F = F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
    
    //Numerator
    float3 numerator = NDF * G2 * F;
    
    //Denominator
    float denominator = max(4.0 * NdotL * NdotV, 1e-8);
    
    //Output
    return numerator / denominator;
}

float3 hammon(float LdotV, float NdotH, float NdotL, float NdotV, float alpha, float3 diffusecolor)
{
    float facing = 0.5 + 0.5 * LdotV;
    
    float rough = facing * (0.9 - 0.4 * facing) * ((0.5 + NdotH) / NdotH);
    float smooth = 1.05 * (1.0 - pow(1.0-NdotL, 5.0)) * (1.0-pow(1.0-NdotV, 5.0));
    float single = lerp(smooth, rough, alpha) / PI;
    float multi = 0.1159 * alpha;
    return diffusecolor * (single + diffusecolor * multi);
}

//Probablity density function of GGX
//float ggx_smith_pdf(float NdotH, HitInfo ray)
//{
//   return NDF_GGX(NdotH, ray.material.alpha) * NdotH;
//}
