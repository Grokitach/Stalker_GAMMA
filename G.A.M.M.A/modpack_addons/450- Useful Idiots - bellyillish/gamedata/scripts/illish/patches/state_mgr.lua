local UTIL = require "illish.lib.util"
local VEC  = require "illish.lib.vector"
local NPC  = require "illish.lib.npc"


local PATCH = {}


-- Patch with various fixes
local PATCH_set_state = state_mgr.set_state

function state_mgr.set_state(npc, state, callback, timeout, target, extra)
  -- Swap prone with prone_idle after "in" animation because otherwise
  -- companions get up with every direction change
  if NPC.isCompanion(npc) then
    local st = db.storage[npc:id()]

    if state == "prone" then
      st.IDIOTS_PRONE_FIX = st.IDIOTS_PRONE_FIX or time_plus(1000)
      if time_expired(st.IDIOTS_PRONE_FIX) then
        state = "prone_idle"
      end
    else
      st.IDIOTS_PRONE_FIX = nil
    end
  end

  -- Force {fast_set = true} on all companion animations because it seems to
  -- fix some issues with them getting stuck or being unresponsive
  if NPC.isCompanion(npc) then
    extra = extra or {}
    extra.fast_set = extra.fast_set ~= false

    -- Except while a revived companion is still playing its getup animation
    if wounded_getup and wounded_getup.is_held(npc) then
      extra.fast_set = false
    end
  end

  -- Validate look_position and look_dir because directions with very small
  -- or zero magnitudes can make NPCs/companions disappear
  if target and target.look_position then
    local dir = VEC.direction(npc:position(), target.look_position)
    if UTIL.round(dir:magnitude()) == 0 then
      target.look_position = nil
    end
  end

  -- Do the same for look_dir just as an extra precaution
  if target and target.look_dir then
    if UTIL.round(target.look_dir:magnitude()) == 0 then
      target.look_dir = nil
    end
  end

  return PATCH_set_state(npc, state, callback, timeout, target, extra)
end


-- Various fixes for prone stance
state_lib.states.prone.movement              = move.stand
state_lib.states.prone_idle.movement         = move.stand
state_lib.states.prone_fire.movement         = move.stand
state_lib.states.prone_sniper_fire.movement  = move.stand
state_lib.states.prone_sniper_fire.direction = nil

state_mgr_animation_list.animations.prone.prop.moving      = nil
state_mgr_animation_list.animations.prone_idle.prop.moving = nil
