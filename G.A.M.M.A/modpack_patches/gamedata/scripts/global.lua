--// General 
jit.opt.start(2)

string.gfind = string.gmatch
math.mod = math.fmod

--// LuaPandas
DebuggerMode = false

function debug_jit_off()
	if DebuggerMode then
		if jit then jit.off() end
	end
end

function debug_jit_on()
	if DebuggerMode then
		if jit then jit.on() end
	end
end

function debugger_attach() 
	if DebuggerMode then
		log('LuaPanda: Disabling jit...')
		debug_jit_off()
		log('LuaPanda: Reconnecting')
		LuaPanda.reConnect()
		log('LuaPanda: reconnected')
		debug_jit_on()
		log('LuaPanda: Started')
	else
		log('LuaPanda: Disabling jit...')
		debug_jit_off()
		log('LuaPanda: Connecting')
		LuaPanda.start("127.0.0.1", 8818)
		log('LuaPanda: Connected')
		DebuggerMode = true
		debug_jit_on()
		log('LuaPanda: Started')
	end
end