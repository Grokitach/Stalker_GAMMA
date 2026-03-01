--// General 
jit.opt.start(2)

string.gfind = string.gmatch
math.mod = math.fmod

--// LuaPandas
DebuggerMode = false

function debug_jit_off()
	if jit then jit.off() end
end

function debug_jit_on()
	if jit then jit.on() end
end

function debugger_attach()
	if DebuggerMode then
		debugger_reconnect()
	else
		debugger_start()
	end
end

function debugger_start()
	if DebuggerMode then
		return
	end

	log('LuaPanda: Disabling jit...')
	debug_jit_off()
	log('LuaPanda: Connecting')
	LuaPanda.start("127.0.0.1", 8818)
	log('LuaPanda: Connected')
	DebuggerMode = true
	debug_jit_on()
	log('LuaPanda: Started')
end

function debugger_reconnect()
	if not DebuggerMode then
		return
	end

	log('LuaPanda: Disabling jit...')
	debug_jit_off()
	log('LuaPanda: Reconnecting')
	LuaPanda.reConnect()
	log('LuaPanda: reconnected')
	debug_jit_on()
	log('LuaPanda: Started')
end

function debugger_stop()
	if not DebuggerMode then
		return
	end

	log('LuaPanda: Disabling jit...')
	debug_jit_off()
	log('LuaPanda: Disconnecting')
	LuaPanda.stopAttach()
	log('LuaPanda: Disconnected')
	DebuggerMode = false
	log('LuaPanda: Stopped')
end