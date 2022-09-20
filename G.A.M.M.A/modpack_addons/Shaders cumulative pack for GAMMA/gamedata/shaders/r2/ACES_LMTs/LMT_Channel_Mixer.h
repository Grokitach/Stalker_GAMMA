//=================================================================================================
//LMT - Channel Mixer
//For complex color effects
//=================================================================================================

void Channel_Mixer(inout float3 aces)
{
	float3 Channel_Mixer_r = shader_param_5.rgb + shader_param_5.w;
	float3 Channel_Mixer_g = shader_param_6.rgb + shader_param_6.w;
	float3 Channel_Mixer_b = shader_param_7.rgb + shader_param_7.w;

	aces = float3(
	dot(aces, Channel_Mixer_r),
	dot(aces, Channel_Mixer_g),
	dot(aces, Channel_Mixer_b));
	
	aces = max(0.0, aces);
}
