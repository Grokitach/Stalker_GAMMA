"""Reputation callbacks, executed with Lua 5.1 and a minimal game API."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


SCRIPT = Path(__file__).resolve().parents[1] / (
    "G.A.M.M.A/modpack_addons/G.A.M.M.A. Killing Friends Reduces Goodwill/"
    "gamedata/scripts/grok_killing_friends_reduces_goodwill.script"
)


class GoodwillRegressions(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime()
        self.lua.execute("""
            callbacks = {}
            changes = {}
            reputation = 0
            db = {actor = {id = function() return 0 end}}
            function RegisterScriptCallback(name, fn) callbacks[name] = fn end
            function IsStalker(npc) return npc ~= nil end
            function character_community() return 'stalker' end
            victim = {
                id = function() return 500 end,
                has_info = function() return false end,
            }
            xr_conditions = {
                is_enemy_fighting_actor = function() return true end,
                is_factions_friends = function() return true end,
                is_factions_neutrals = function() return false end,
                is_factions_enemies = function() return false end,
            }
            game_relations = {change_factions_community_num = function(_, _, delta)
                changes[#changes + 1] = delta
            end}
            game_statistics = {increment_reputation = function(delta) reputation = reputation + delta end}
            news_manager = {send_tip = function() end}
            game = {translate_string = function(key) return key end}
        """)
        self.lua.execute(SCRIPT.read_text(encoding="utf-8-sig"))
        self.lua.execute("on_game_start()")

    def test_aggression_survives_save_and_load(self):
        self.lua.execute("""
            callbacks.npc_on_before_hit(victim, {draftsman = db.actor})
            local saved = {}
            callbacks.save_state(saved)
            aggressive_npcs = {}
            callbacks.load_state(saved)
            relation_kill_check(victim, db.actor)
            assert(changes[1] == -10, 'self-defense penalty changed after loading')
            assert(reputation == 0)
        """)

    def test_load_without_state_does_not_keep_previous_aggression(self):
        self.lua.execute("""
            callbacks.npc_on_before_hit(victim, {draftsman = db.actor})
            callbacks.load_state({})
            relation_kill_check(victim, db.actor)
            assert(changes[1] == -140, 'aggression leaked from another save')
            assert(reputation == -300)
        """)

    def test_death_without_killer_does_not_penalize_player(self):
        self.lua.execute("""
            relation_kill_check(victim, nil)
            assert(#changes == 0)
            assert(reputation == 0)
        """)

    def test_neutral_kill_still_penalizes_player(self):
        self.lua.execute("""
            relation_kill_check(victim, db.actor)
            assert(changes[1] == -140)
            assert(reputation == -300)
        """)

    def test_aggressive_kill_without_reload_keeps_reduced_penalty(self):
        self.lua.execute("""
            callbacks.npc_on_before_hit(victim, {draftsman = db.actor})
            relation_kill_check(victim, db.actor)
            assert(changes[1] == -10)
            assert(reputation == 0)
        """)


if __name__ == "__main__":
    unittest.main()
