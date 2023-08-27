local tex_env0	= "$user$sky0"
local tex_env1	= "$user$sky1"

function normal   (shader, t_base, t_second, t_detail)
	shader:begin	("model_env_lq","model_exohealth")
      : fog			(true)
      : zb			(true,false)
      : blend		(true,blend.srcalpha,blend.invsrcalpha)
      : aref		(true,0)
      : sorting		(2,true)
      : distort		(true)
	shader:sampler  ("s_base")		:texture	(t_base) 
end
