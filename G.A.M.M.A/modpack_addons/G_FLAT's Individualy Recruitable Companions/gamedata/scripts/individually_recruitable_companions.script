-- Individually Recruitable Companions, written by G_FLAT

-- Allows the player to recruit and hire stalkers as companions, one at a time, 
-- regardless of the size of the squad or if the stalker is the commander of the squad he belongs to.

-- Works by separating the stalker from his squad, by creating a clone and deleting the original.
-- The resulting clone is automatically added to the player's "companion squad"
-- In case of dismissal, the stalker can be re-recruited through the "vanilla" game dialogs. 

-- Custom Companion Squad Size by Catspaw compatibility
local custom_actor_squadsize 			= 2
local custom_actor_squadsize_folkhero 	= 4
local hascustomsquadsize				= false

function become_actor_companion_individually(actor, npc)
	
	local npc = dialogs.who_is_npc(actor, npc)
	local clone_id = stalker_cloning_utility.clone_stalker(npc)
	
	if clone_id then
		alife_release(npc)
		
		CreateTimeEvent("clone_become_companion_event", "clone_become_companion_" .. clone_id, 0, function(id)
			local clone = level.object_by_id(id)
			if clone then
				dialogs_axr_companion.become_actor_companion(db.actor, clone)
				db.actor:run_talk_dialog(clone)
				return true
			else
				return false
			end
		end, clone_id)
	else
		actor:run_talk_dialog(npc)
	end

end

function become_paid_actor_companion_individually_and_register(actor, npc)
	
	local npc = dialogs.who_is_npc(actor, npc)
	local clone_id = stalker_cloning_utility.clone_stalker(npc)
	
	if clone_id then
		alife_release(npc)
	
		CreateTimeEvent("clone_become_paid_companion_event", "clone_become_paid_companion_" .. clone_id, 0, function(id)
			local clone = level.object_by_id(id)
			if clone then
				dialogs_axr_companion.become_actor_companion(db.actor, clone)
				txr_paid_companions.register_paid_companion(db.actor, clone)
				db.actor:run_talk_dialog(clone)
				return true
			else
				return false
			end
		end, clone_id)
	else
		actor:run_talk_dialog(npc)
	end

end

-- precondition: must have at least one free spot 
function is_room_for_one_in_actor_squad(actor, npc)
	local max_size = 0

	-- Custom Companion Squad Size by Catspaw compatibility
	if hascustomsquadsize then
		if game_achievements.has_achievement("patriarch") then
			max_size = custom_actor_squadsize_folkhero
		else
			max_size = custom_actor_squadsize
		end
	else
		max_size = axr_companions.max_actor_squad_size + (game_achievements.has_achievement("patriarch") and 2 or 0)
	end

	if axr_companions.get_companion_count() + 1 <= max_size then
		return true
	end
	return false
end

-- precondition: don't show the new dialog for stalkers that are alone in a squad
function not_a_one_man_squad(actor, npc)
	if utils_obj.get_squad_count(npc) > 1 then
		return true
	end
	return false
end

-- precondition: is_actor_stronger
-- this makes it fine for grok's script to not be available, for non-gamma installs
function get_is_actor_stronger_if_script_is_available(actor, npc)
	if grok_get_companions then
		return grok_get_companions.is_actor_stronger(actor, npc)
	end
	return true
end

-- Hey friend, wanna leave your squad and come with me instead?
function get_friend_companion_ask_join_individually_text()
	return game.translate_string("st_friend_companion_ask_join_individually", true)
end

-- I can pay you to leave your squad and work as my escort, interested?
function get_paid_companion_dialog_text_individually_text()
	return game.translate_string("st_paid_companion_dialog_text_individually", true)
end

function on_game_start()
	-- Custom Companion Squad Size by Catspaw compatibility
	RegisterScriptCallback("on_game_load", update_settings)
	RegisterScriptCallback("on_option_change", update_settings)
end

function update_settings()
	-- Custom Companion Squad Size by Catspaw compatibility
	if ui_mcm and custom_companion_squad_size then 
		custom_actor_squadsize 				= ui_mcm.get("customsquadsize/maxsquadsize")
		custom_actor_squadsize_folkhero 	= ui_mcm.get("customsquadsize/maxsquadsize_folkhero")
		hascustomsquadsize 					= true
	end
end