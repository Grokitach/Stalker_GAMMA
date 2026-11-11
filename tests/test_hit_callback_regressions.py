"""Lua 5.1 checks for hits without an attacker and ordinary combat callbacks."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


ADDONS = Path(__file__).resolve().parents[1] / "G.A.M.M.A/modpack_addons"
FRIENDLY_FIRE = ADDONS / "G.A.M.M.A. No NPC Friendly Fire/gamedata/scripts/grok_no_npc_friendly_fire.script"
SIN_ALLIES = ADDONS / "G.A.M.M.A. Sin and Mutants are Allies/gamedata/scripts/grok_sin_allied_to_mutants.script"
CQC = ADDONS / "G.A.M.M.A. Close Quarter Combat/gamedata/scripts/grok_bo.script"


class HitCallbackRegressions(unittest.TestCase):
    def module(self, path):
        lua = LuaRuntime()
        lua.execute("""
            callbacks = {}
            function RegisterScriptCallback(name, fn) callbacks[name] = fn end
            function ini_file() return {} end
            function printf() end
            perk_based_artefacts = {}
            game_object = {friend = 1, neutral = 0}
            function character_community(obj) return obj.community end
            function IsMonster(obj) return obj.monster == true end
            function IsStalker(obj) return obj.monster ~= true end
            function get_object_squad() return nil end
            function object(id, community, monster)
                return {
                    id = function() return id end,
                    community = community,
                    monster = monster,
                    set_relation = function(self, relation, other)
                        self.last_relation = relation
                    end,
                    name = function() return 'ordinary_target' end,
                    position = function()
                        return {distance_to = function() return 0 end}
                    end,
                }
            end
            db = {actor = object(0, 'actor_stalker')}
            xr_conditions = {
                is_factions_friends = function() return relationship == 'friends' end,
                is_factions_neutrals = function() return relationship == 'neutral' end,
            }
            level = {object_by_id = function()
                weapon_lookups = (weapon_lookups or 0) + 1
                return nil
            end}
        """)
        lua.execute(path.read_text(encoding="utf-8-sig"))
        lua.execute("on_game_start()")
        if path == SIN_ALLIES:
            lua.execute("load_state({})")
        return lua

    def test_friendly_fire_preserves_hit_without_attacker(self):
        lua = self.module(FRIENDLY_FIRE)
        lua.execute("""
            local damage, flags = {power = 0.4}, {ret_value = true}
            callbacks.npc_on_before_hit(object(1, 'stalker'), damage, 11, flags)
            assert(damage.power == 0.4 and flags.ret_value == true)
        """)

    def test_sin_alliance_preserves_hit_without_attacker(self):
        lua = self.module(SIN_ALLIES)
        lua.execute("""
            local damage, flags = {power = 0.4}, {ret_value = true}
            callbacks.monster_on_before_hit(object(1, 'monster', true), damage, 11, flags)
            assert(damage.power == 0.4 and flags.ret_value == true)
            assert(next(void_pact) == nil)
        """)

    def test_cqc_preserves_npc_hit_without_attacker(self):
        lua = self.module(CQC)
        lua.execute("""
            local damage = {power = 0.4}
            callbacks.npc_on_before_hit(object(1, 'stalker'), damage, 11)
            assert(damage.power == 0.4)
        """)

    def test_cqc_preserves_monster_hit_without_attacker(self):
        lua = self.module(CQC)
        lua.execute("""
            local damage = {power = 0.4}
            callbacks.monster_on_before_hit(object(1, 'monster', true), damage, 11)
            assert(damage.power == 0.4)
        """)

    def test_friendly_and_neutral_fire_is_still_blocked(self):
        lua = self.module(FRIENDLY_FIRE)
        lua.execute("""
            for _, relation in ipairs({'friends', 'neutral'}) do
                relationship = relation
                local shooter, victim = object(2, 'stalker'), object(1, 'stalker')
                local damage, flags = {power = 0.4, draftsman = shooter}, {}
                callbacks.npc_on_before_hit(victim, damage, 11, flags)
                assert(damage.power == 0 and flags.ret_value == false)
                assert(victim.last_relation == (relation == 'friends' and 1 or 0))
                assert(shooter.last_relation == victim.last_relation)
            end
        """)

    def test_actor_enemy_and_monster_damage_is_preserved(self):
        lua = self.module(FRIENDLY_FIRE)
        lua.execute("""
            for _, shooter in ipairs({db.actor, object(2, 'bandit'), object(3, 'monster', true)}) do
                relationship = 'enemies'
                local damage, flags = {power = 0.4, draftsman = shooter}, {ret_value = true}
                callbacks.npc_on_before_hit(object(1, 'stalker'), damage, 11, flags)
                assert(damage.power == 0.4 and flags.ret_value == true)
            end
        """)

    def test_sin_actor_attack_still_breaks_alliance(self):
        lua = self.module(SIN_ALLIES)
        lua.execute("""
            db.actor.community = 'actor_greh'
            local damage = {power = 0.4, draftsman = db.actor}
            callbacks.monster_on_before_hit(object(1, 'monster', true), damage, 11, {})
            assert(void_pact[1] == true and damage.power == 0.4)
        """)

    def test_other_attackers_do_not_break_sin_alliance(self):
        lua = self.module(SIN_ALLIES)
        lua.execute("""
            local damage = {power = 0.4, draftsman = object(2, 'bandit')}
            callbacks.monster_on_before_hit(object(1, 'monster', true), damage, 11, {})
            assert(next(void_pact) == nil and damage.power == 0.4)
        """)

    def test_cqc_preserves_npc_shooter_hits(self):
        lua = self.module(CQC)
        lua.execute("""
            for _, name in ipairs({'npc_on_before_hit', 'monster_on_before_hit'}) do
                local damage = {power = 0.4, draftsman = object(2, 'bandit')}
                callbacks[name](object(1, 'stalker'), damage, 11)
                assert(damage.power == 0.4)
            end
        """)

    def test_cqc_actor_npc_hit_still_reaches_weapon_processing(self):
        lua = self.module(CQC)
        lua.execute("""
            local damage = {power = 0.4, draftsman = db.actor, weapon_id = 5}
            callbacks.npc_on_before_hit(object(1, 'stalker'), damage, 11)
            assert(weapon_lookups == 1 and damage.power == 0.4)
        """)

    def test_cqc_actor_monster_damage_formula_is_preserved(self):
        lua = self.module(CQC)
        lua.execute("""
            local weapon = {
                id = function() return 5 end,
                section = function() return 'wpn_test' end,
                get_ammo_type = function() return 0 end,
                parent = function() return nil end,
            }
            level.object_by_id = function() return weapon end
            function IsGrenade() return false end
            function IsWeapon() return false end
            utils_item = {get_ammo = function() return {'ammo_test'} end}
            ui_wpn_params = {read_float = function() return 1 end}
            ini_sys = {r_float_ex = function(_, section, key)
                return ({k_ap = 0.1, k_hit = 1, k_air_resistance = 0.05})[key]
            end}
            local state = {diff_game = {type = 2}}
            alife_storage_manager = {get_state = function() return state end}
            local damage = {power = 0.4, draftsman = db.actor, weapon_id = 5}
            callbacks.monster_on_before_hit(object(1, 'monster', true), damage, 11)
            assert(math.abs(damage.power - 0.4 * 0.85 * 0.85 * 1.05) < 0.0000001)
        """)

    def test_cqc_sniper_hit_does_not_disable_later_pistol_leg_bonus(self):
        def pistol_ap(after_sniper):
            lua = self.module(CQC)
            lua.execute("""
                active_ammo = 'ammo_9x19_fmj'
                local weapon = {
                    id = function() return 5 end,
                    section = function() return 'wpn_test' end,
                    get_ammo_type = function() return 0 end,
                    parent = function() return nil end,
                    weapon_is_silencer = function() return false end,
                }
                level.object_by_id = function() return weapon end
                function IsGrenade() return false end
                function IsWeapon() return false end
                function alife_object() return {community = function() return 'stalker' end} end
                utils_item = {get_ammo = function() return {active_ammo} end}
                ui_wpn_params = {read_float = function() return 1 end}
                ini_sys = {
                    r_float_ex = function(_, section, key)
                        return ({k_ap = 0.01, k_hit = 1, k_air_resistance = 0.05})[key]
                    end,
                    r_string_ex = function() return nil end,
                }
                local state = {diff_game = {type = 2}}
                alife_storage_manager = {get_state = function() return state end}
                function hit(damage)
                    local copy = {}
                    for k, v in pairs(damage) do copy[k] = v end
                    return copy
                end
                perk_based_artefacts.process_artefacts = function() end
                function printf(format, ...)
                    if format:find('Real AP power', 1, true) then last_ap = (...) end
                end
                function fire_leg(ammo)
                    active_ammo = ammo
                    local npc = object(1, 'stalker')
                    npc.section = function() return 'ordinary_npc' end
                    npc.health = 1
                    npc.set_health_ex = function(self, value) self.health = value end
                    custom_bone_value['1_2'] = 0
                    custom_bone_ap['1_2'] = 1
                    custom_bone_hf['1_2'] = 1
                    local damage = {power = 0.4, draftsman = db.actor, weapon_id = 5}
                    callbacks.npc_on_before_hit(npc, damage, 3)
                    return last_ap
                end
            """)
            if after_sniper:
                lua.execute("fire_leg('ammo_7.62x54_7h1')")
            return lua.eval("fire_leg('ammo_9x19_fmj')")

        self.assertAlmostEqual(pistol_ap(True), pistol_ap(False))


if __name__ == "__main__":
    unittest.main()
