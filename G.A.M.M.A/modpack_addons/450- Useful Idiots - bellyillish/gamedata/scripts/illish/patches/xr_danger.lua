local NPC = require "illish.lib.npc"


local PATCH = {}

-- Fix values in Anomaly that got incorrectly overwritten
xr_danger.bd_types[danger_object.entity_attacked] = "entity_attacked"
xr_danger.bd_types[danger_object.bullet_ricochet] = "bullet_ricochet"
xr_danger.bd_types[danger_object.attack_sound]    = "attack_sound"


-- Add IsStalker() check to corpses for Anomaly
function xr_danger.get_danger_time(danger)
  if danger:type() ~= danger_object.entity_corpse then
    return danger:time()
  end

  local corpse = danger:object()
  if corpse then
    return IsStalker(corpse) and corpse:death_time()
  else
    return 0
  end
end


-- Add has_danger() check for Anomaly
local PATCH_npc_on_hear_callback = xr_danger.npc_on_hear_callback

function xr_danger.npc_on_hear_callback(npc, ...)
  if not xr_danger.has_danger(npc) then
    PATCH_npc_on_hear_callback(npc, ...)
  end
end


-- disable buggy hit callback in Anomaly
function xr_danger.npc_on_hit_callback()
end


-- Overwrite with bug fixes
function xr_danger.is_danger(npc, danger)
  if not npc then return end

  if xr_wounded.is_heavy_wounded_by_id(npc:id()) then
    return false
  end

  if axr_task_manager.hostages_by_id[npc:id()] then
    return false
  end

  local dangerObject = danger:object()
  local dangerType   = danger:type()

  -- Grenade
  if dangerType == danger_object.grenade then
    if danger:dependent_object() and character_community(npc) ~= "zombied" then
      return xr_danger.danger_in_radius(npc, danger, dangerType)
    end

    return false
  end

  if xr_combat_ignore.npc_in_safe_zone(npc) then
    return false
  end

  -- Corpse
  if dangerType == danger_object.entity_corpse then
    if not (dangerObject and IsStalker(dangerObject) and character_community(dangerObject) == character_community(npc)) then
      return false
    end

    local corpse = db.storage[dangerObject:id()]

    if not (corpse and corpse.death_time and corpse.death_by_id) then
      return false
    end

    local killer = db.storage[corpse.death_by_id] and db.storage[corpse.death_by_id].object

    if not (killer and (IsMonster(killer) or IsStalker(killer)) and killer:alive() and npc:relation(killer) > 0 and character_community(killer) ~= character_community(npc)) then
      return false
    end

    if xr_combat_ignore.ignore_enemy_by_overrides(npc, killer) then
      return false
    end

    if game.get_game_time():diffSec(corpse.death_time) > 120000 then
      return false
    end

    return xr_danger.danger_in_radius(npc, danger, dangerType)
  end

  if danger:perceive_type() == danger_object.hit then
    return xr_danger.danger_in_radius(npc, danger, dangerType)
  end

  if xr_corpse_detection.is_under_corpse_detection(npc) or xr_help_wounded.is_under_help_wounded(npc) or xrs_kill_wounded.is_under_kill_wounded(npc) then
    return false
  end

  if get_object_story_id(npc:id()) then
    return false
  end

  if danger:dependent_object() then
    dangerObject = danger:dependent_object()
  end

  if not dangerObject or not dangerObject:alive() or not IsMonster(dangerObject) and not IsStalker(dangerObject) then
    return false
  end

  if dangerType ~= 0 and dangerType ~= 1 and not xr_combat_ignore.is_enemy(npc, dangerObject, true) then
    return false
  end

  if dangerObject:id() == 0 and npc:relation(dangerObject) < 1 or dangerObject:id() ~= 0 and npc:relation(dangerObject) < 2 then
    return false
  end

  return xr_danger.danger_in_radius(npc, danger, dangerType)
end


-- Custom danger state for companions
function PATCH.onEvalDanger(npc, flags)
  if not npc then return end
  if not NPC.isCompanion(npc) then
    return
  end

  local danger = npc:best_danger()
  if not danger then
    return
  end

  -- Always react to grenades
  if danger:type() == danger_object.grenade then
    return
  end

  local enemy = danger:dependent_object() or danger:object()

  if enemy and xr_combat_ignore.is_enemy(npc, enemy) then
    -- Always react when hit
    if danger:perceive_type() == danger_object.hit then
      return
    end

    local hitBy = db.storage[npc:id()].hitted_by
    if hitBy and enemy and hitBy == enemy:id() then
      return
    end

    -- Otherwise turn towards enemy danger
    NPC.lookAtPoint(npc, enemy:position())
  end

  -- Ignore all other danger types
  flags.ret_value = false
end


RegisterScriptCallback("idiots_on_start", function()
  RegisterScriptCallback("npc_on_eval_danger", PATCH.onEvalDanger)
end)


return PATCH
