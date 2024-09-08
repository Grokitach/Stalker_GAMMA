function normal(shader, t_base, t_second, t_detail)
  shader:begin("stub_notransform_t","hud_default") -- vs, ps
        :blend(true,blend.srcalpha,blend.invsrcalpha) -- do_blend, src_mode, dst_mode
		:zb(false,false) -- depth_test, depth_write
		:aref(true,0) -- do_alpha_test, alpha_ref
	shader:dx10texture	("s_base", t_base)
	shader:dx10sampler	("smp_base"):clamp()
end
