function normal(shader, t_base, t_second, t_detail)
	shader:begin("stub_screen_space", "ui_icons_pp")
		:fog(false)
		:zb(false, false)
		:blend(false, blend.one, blend.zero)
		:dx10cullmode(1)
		:dx10stencil(false, cmp_func.always, 255, 255,
			stencil_op.keep, stencil_op.keep, stencil_op.keep)
		:color_write_enable(true, true, true, true)
	shader:dx10texture("s_ui_3d_icons", "$user$ui_3d_icons_raw")
	shader:dx10sampler("smp_nofilter"):clamp()
end
