"""Isolated Lua 5.1 regressions for artefact belt rules and knife loot quality."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaRuntime


SCRIPTS = (Path(__file__).resolve().parents[1] / "G.A.M.M.A/modpack_addons"
           / "G.A.M.M.A. Artefacts Reinvention/gamedata/scripts")


class ArtefactRegressions(unittest.TestCase):
    def loot(self):
        lua = LuaRuntime()
        lua.execute("""
            utils_item = {in_actor_ruck = function() end, is_degradable = function() end}
            itms_manager = {}
            zz_item_artefact_mcm = {op = {gr = {}}}
            item_artefact = {artefact_binder = {}}
            se_artefact = {se_artefact = {}}
            utils_ui = {stats_table = {}, UICellItem = {}}
            ui_inventory = {}
            ui_mutant_loot = {}
            zz_ui_mutant_loot_hunter_backpacks = {}
            function CScriptXmlInit() return {ParseFile = function() end} end
            function alife_create_item(section, owner, props) return props end
            inventory = {}
            db = {actor = {iterate_inventory = function(self, fn)
                for _, item in ipairs(inventory) do fn(self, item) end
            end}}
            function knife(section) return {section = function() return section end} end
        """)
        lua.execute((SCRIPTS / "zz_item_artefact.script").read_text(encoding="utf-8-sig"))
        return lua

    def test_harvest_quality_tracks_current_knife_after_downgrade(self):
        lua = self.loot()
        lua.execute("""
            inventory = {knife('wpn_knife6')}
            local high = ui_mutant_loot.alife_create_item('hide_boar', db.actor, {})
            assert(high.cond_r[1] == 75 and high.cond_r[2] == 98)
            inventory = {knife('wpn_knife')}
            local low = ui_mutant_loot.alife_create_item('hide_boar', db.actor, {})
            assert(low.cond_r[1] == 25 and low.cond_r[2] == 40,
                   'removed knife still controls mutant loot quality')
            assert(low.cond_cr[1] == 25 and low.cond_cr[2] == 40)
        """)

    def test_harvest_uses_best_current_knife_in_both_inventory_orders(self):
        lua = self.loot()
        lua.execute("""
            for _, sections in ipairs({{'wpn_knife', 'wpn_knife6'},
                                       {'wpn_knife6', 'wpn_knife'}}) do
                inventory = {knife(sections[1]), knife(sections[2])}
                local props = zz_ui_mutant_loot_hunter_backpacks.alife_create_item(
                    'hide_boar', db.actor, {})
                assert(props.cond_r[1] == 75 and props.cond_r[2] == 98)
                assert(props.cond_cr[1] == 75 and props.cond_cr[2] == 98)
            end
        """)

    def belt(self):
        lua = LuaRuntime()
        lua.execute("""
            belt_items = {}
            removed = {}
            function SYS_GetParam(_, section)
                if section:find('_af_iam$', 1) or section:find('_af_aam$', 1)
                   or section:find('_af_aac$', 1) or section:find('_lead_box$', 1) then
                    return 'i_arty_cont'
                end
                if section == 'af_black' then return 'i_arty_junk' end
                return 'i_arty'
            end
            function item(id, section)
                return {id = function() return id end, section = function() return section end}
            end
            db = {actor = {
                iterate_belt = function(self, fn)
                    for _, obj in ipairs(belt_items) do fn(self, obj) end
                end,
                move_to_ruck = function(self, obj) removed[#removed + 1] = obj:id() end,
            }}
            function check(first, second, should_remove)
                belt_items = {item(1, first), item(2, second)}
                removed = {}
                set_on_slot(belt_items[2])
                assert((#removed > 0) == should_remove,
                       first .. ' + ' .. second .. ': wrong duplicate decision')
                for _, id in ipairs(removed) do assert(id == 2, 'removed existing item') end
            end
        """)
        lua.execute((SCRIPTS / "grok_remove_belt_duplicates.script").read_text(encoding="utf-8-sig"))
        return lua

    def test_same_contained_artefact_is_rejected(self):
        self.belt().execute("check('af_medusa_af_iam', 'af_medusa_af_iam', true)")

    def test_container_added_after_raw_duplicate_is_rejected(self):
        self.belt().execute("check('af_medusa', 'af_medusa_af_iam', true)")

    def test_raw_added_after_contained_duplicate_is_rejected(self):
        self.belt().execute("check('af_medusa_af_iam', 'af_medusa', true)")

    def test_same_artefact_in_different_containers_is_rejected(self):
        self.belt().execute("check('af_medusa_af_iam', 'af_medusa_af_aac', true)")

    def test_distinct_contained_artefacts_remain_allowed(self):
        self.belt().execute("check('af_medusa_af_iam', 'af_blood_af_iam', false)")

    def test_raw_duplicates_remain_rejected(self):
        self.belt().execute("check('af_medusa', 'af_medusa', true)")

    def test_equipment_category_duplicates_remain_rejected(self):
        self.belt().execute("check('af_plates', 'af_kevlar_up', true)")

    def test_junk_duplicates_remain_allowed(self):
        self.belt().execute("check('af_black', 'af_black', false)")

    def test_container_parser_does_not_reuse_previous_artefact(self):
        self.belt().execute("""
            assert(get_artefact_from_container('af_medusa_af_iam') == 'af_medusa')
            assert(get_artefact_from_container('af_medusa') == nil,
                   'container parser returned a result from the previous call')
            assert(get_artefact_from_container(nil) == nil)
        """)


if __name__ == "__main__":
    unittest.main()
