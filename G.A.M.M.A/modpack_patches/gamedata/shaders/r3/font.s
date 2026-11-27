function normal(shader, t_base, t_second, t_detail)
	shader:begin("stub_notransform_t","hud_default")
		:blend(true,blend.srcalpha,blend.invsrcalpha)
		:zb(false,false)
		:aref(true,32)
	shader:dx10texture("s_base", t_base)
	shader:dx10sampler("smp_base"):clamp()
end
