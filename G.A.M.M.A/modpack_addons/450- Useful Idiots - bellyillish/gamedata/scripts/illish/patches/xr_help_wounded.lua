local NPC = require "illish.lib.npc"


-- Change beh_companion's help_wounded_enabled to support a condlist
local PATCH_help_wounded_evaluate = xr_help_wounded.evaluator_wounded_exist.evaluate

function xr_help_wounded.evaluator_wounded_exist:evaluate()
  local npc = self.object
  local st  = self.a

  if not npc then return end

  if NPC.isCompanion(npc) then
    if not st.help_wounded_cond then
      st.help_wounded_cond = xr_logic.parse_condlist(npc, "beh", "help_wounded_enabled", tostring(st.help_wounded_enabled))
    end

    st.help_wounded_enabled = xr_logic.pick_section_from_condlist(db.actor, npc, st.help_wounded_cond) == "true"
  end

  return PATCH_help_wounded_evaluate(self)
end


-- Change xr_help_wounded's always_help_distance to support a condlist
local PATCH_help_wounded_execute  = xr_help_wounded.action_help_wounded.execute

function xr_help_wounded.action_help_wounded:execute()
    local npc = self.object
    local st  = self.a

    if not npc then return end

    if not st.always_help_cond then
      local ini = ini_file("ai_tweaks\\xr_help_wounded.ltx")
      st.always_help_cond = xr_logic.parse_condlist(npc, "settings", "always_help_distance", ini:r_string_ex("settings", "always_help_distance"))
    end

    xr_help_wounded.AlwaysHelpDistance = tonumber(xr_logic.pick_section_from_condlist(db.actor, npc, st.always_help_cond))

    return PATCH_help_wounded_execute(self)
end
