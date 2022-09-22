//=================================================================================================
//LMT - Technicolor from http://enbseries.enbdev.com/forum/viewtopic.php?f=7&t=3552
//Saturation boost that emulates the vibrancy of 3 strip technicolor
//=================================================================================================

void Technicolor( inout float3 aces)
{
	float3 x = aces;
	
	float3 colStrength   = .4;
	float brightness   = 0;
	float Technicolor_Amount   = .4;
	
	x = x/(1+x); //compress to LDR
	
	float3 source = saturate(x.rgb);
	float3 temp = 1-source.rgb;
	float3 target = temp.grg;
	float3 target2 = temp.bbr;
	float3 temp2 = source.rgb * target.rgb;
	temp2.rgb *= target2.rgb;
	temp.rgb = temp2.rgb * colStrength.rgb;
	temp2.rgb *= brightness;
	target.rgb = temp.grg;
	target2.rgb = temp.bbr;
	temp.rgb = source.rgb - target.rgb;
	temp.rgb += temp2.rgb;
	temp2.rgb = saturate(temp.rgb - target2.rgb);
	
	x.rgb          = lerp( source.rgb, temp2.rgb, Technicolor_Amount );
	
	x = min(HALF_MAX, x/((1+HALF_MIN)-x)); //expand to HDR
	
	aces = x;
}