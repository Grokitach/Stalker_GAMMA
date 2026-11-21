"""Run with Python and lupa (Lua 5.1); the game API is stubbed per scenario."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


ADDONS = Path(__file__).resolve().parents[1] / "G.A.M.M.A/modpack_addons"
DESPAWNER = ADDONS / "G.A.M.M.A. Dynamic Despawner/gamedata/scripts/grok_dynamic_despawner.script"
LOOT = ADDONS / "G.A.M.M.A. NPC Loot Claim Remade/gamedata/scripts/grok_loot_claim.script"


class GameplayRegressions(unittest.TestCase):
    def despawner(self, config="{}"):
        lua = LuaRuntime()
        lua.execute("""
            callbacks = {}
            now = 0
            released = {}
            objects = {}
            db = {actor = {position = function() return {} end}}
            function time_global() return now end
            function RegisterScriptCallback(name, fn) callbacks[name] = fn end
            function get_object_story_id() return nil end
            function get_object_squad() return nil end
            function get_object_by_id(id) return objects[id] end
            function alife_object(id) return objects[id] end
            function alife_release(obj)
                assert(obj, 'cannot release a missing server object')
                released[#released + 1] = obj:id()
            end
            function shuffle_table(t)
                for i = #t, 2, -1 do
                    local j = math.random(i)
                    t[i], t[j] = t[j], t[i]
                end
            end
            axr_task_manager = {ongoing_tasks = {}, generate_ongoing_tasks = function() end}
            function npc(id, section)
                local obj = {
                    id = function() return id end,
                    section = function() return section or 'ordinary_npc' end,
                    has_info = function() return false end,
                }
                objects[id] = obj
                return obj
            end
        """)
        lua.execute("config = " + config + """
            grok_dynamic_despawner_mcm = {get_config = function(key) return config[key] end}
        """)
        lua.execute(DESPAWNER.read_text(encoding="utf-8-sig"))
        lua.execute("on_game_start()")
        return lua

    def test_disabled_options_survive_initialization(self):
        lua = self.despawner("{enabled = false, check_tasks = false}")
        lua.execute("assert(enabled == false); assert(check_tasks == false)")

    def test_important_npc_is_not_collected(self):
        lua = self.despawner()
        lua.execute("""
            local obj = npc(500, 'esc_m_trader')
            callbacks.npc_on_update(obj)
            now = 31
            callbacks.npc_on_update(obj)
            assert(next(online_npcs) == nil, 'important NPC was collected')
        """)

    def test_monster_timer_rearms_without_resetting_npc_timer(self):
        lua = self.despawner()
        lua.execute("""
            local obj = npc(500)
            callbacks.npc_on_update(obj)
            callbacks.monster_on_update(obj)
            now = 23
            callbacks.monster_on_update(obj)
            assert(trigger == 1, 'monster callback reset NPC timer')
            assert(trigger3 == 0, 'monster timer did not rearm')
        """)

    def test_one_excess_npc_is_removed(self):
        lua = self.despawner("{npc_threshold = 2}")
        lua.execute("""
            for _, id in ipairs({500, 700, 900}) do npc(id); online_npcs[id] = id end
            callbacks.actor_on_update()
            now = 2601
            callbacks.actor_on_update()
            assert(#released == 1, 'expected exactly one release')
            assert(next(online_npcs) == nil)
        """)

    def test_sparse_ids_and_task_protection(self):
        lua = self.despawner("{npc_threshold = 1}")
        lua.execute("""
            for _, id in ipairs({500, 700, 900}) do npc(id); online_npcs[id] = id end
            axr_task_manager.ongoing_tasks[500] = true
            callbacks.actor_on_update()
            now = 2601
            callbacks.actor_on_update()
            assert(#released == 2, 'protected NPC consumed removal budget')
            for _, id in ipairs(released) do assert(id ~= 500, 'quest NPC released') end
        """)

    def test_missing_server_object_is_skipped(self):
        lua = self.despawner("{npc_threshold = 1}")
        lua.execute("""
            for _, id in ipairs({500, 700, 900}) do npc(id); online_npcs[id] = id end
            function alife_object(id) if id ~= 500 then return objects[id] end end
            callbacks.actor_on_update()
            now = 2601
            callbacks.actor_on_update()
            assert(#released == 2)
        """)

    def loot(self):
        lua = LuaRuntime()
        lua.execute("""
            db = {actor = {id = function() return 0 end}}
            function get_object_story_id() return nil end
            function character_community(obj) assert(obj); return 'stalker' end
            function IsStalker(obj) return obj ~= nil end
            function IsMonster() return false end
            function printf() end
            victim = {id = function() return 500 end}
        """)
        lua.execute(LOOT.read_text(encoding="utf-8-sig"))
        return lua

    def test_death_without_killer(self):
        lua = self.loot()
        lua.execute("npc_on_death_callback(victim, nil); assert(next(claimed) == nil)")

    def test_stalker_kill_still_claims_loot(self):
        lua = self.loot()
        lua.execute("""
            local killer = {id = function() return 700 end, has_info = function() return false end}
            npc_on_death_callback(victim, killer)
            assert(claimed[500] == 700)
        """)


if __name__ == "__main__":
    unittest.main()
