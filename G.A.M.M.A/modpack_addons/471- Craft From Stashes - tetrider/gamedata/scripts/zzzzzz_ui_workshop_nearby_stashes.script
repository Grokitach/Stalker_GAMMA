--[[
	Monkey patch: ui_workshop.script
	Adds "craft from nearby stashes" functionality for workshop operations

	Provides global helper functions:
	- GetStashesInRange(range)
	- IterateStashesInRange(func, range, exclude_id)
	- collect_amount_in_range(range, section, exclude_id)
--]]

local default_range = 10
local stash_range = default_range

-- Color list for UI (copied from ui_workshop.script)
local clr_list = {
	["g"]    = utils_xml.get_color("d_green"),
	["y"]    = utils_xml.get_color("yellow"),
	["o"]    = utils_xml.get_color("d_orange"),
	["r"]    = utils_xml.get_color("d_red"),
	["b"]    = utils_xml.get_color("d_cyan"),
	["b1"]   = utils_xml.get_color("pda_blue"),
	["b2"]   = utils_xml.get_color("d_blue"),
	["p"]    = utils_xml.get_color("d_purple"),
	["dark"] = utils_xml.get_color("ui_gray_2"),
}

-- Helper function: Get stashes within range (make it globally accessible)
function _G.GetStashesInRange(range)
	if type(range) ~= "number" then
		return {}
	end

	local stashes = {}
	local stash_set = {}  -- Use hash table to track duplicates efficiently

	-- Check player-created stashes
	local m_data = alife_storage_manager.get_state()
	if m_data.player_created_stashes then
		for id, v in pairs(m_data.player_created_stashes) do
			local se_obj = level.object_by_id(id)
			if se_obj and distance_between_safe(db.actor, se_obj) <= range then
				table.insert(stashes, id)
				stash_set[id] = true
			end
		end
	end

	-- Also check treasure/world stashes (static stashes in the world)
	if treasure_manager and treasure_manager.caches then
		for id, v in pairs(treasure_manager.caches) do
			if not stash_set[id] then  -- Skip duplicates using hash lookup
				local se_obj = level.object_by_id(id)
				if se_obj and distance_between_safe(db.actor, se_obj) <= range then
					table.insert(stashes, id)
					stash_set[id] = true
				end
			end
		end
	end

	-- Also check Utjan's Anomalous Stash (single hidden_stash box shared by all markers)
	if anomalous_stash and anomalous_stash.anom_stashes and anomalous_stash.hidden_stash then
		for id, _ in pairs(anomalous_stash.anom_stashes) do
			local se_obj = level.object_by_id(id)
			if se_obj and distance_between_safe(db.actor, se_obj) <= range then
				local hidden_id = anomalous_stash.hidden_stash
				if not stash_set[hidden_id] then
					local hidden_obj = level.object_by_id(hidden_id)
					if hidden_obj then
						table.insert(stashes, hidden_id)
						stash_set[hidden_id] = true
					end
				end
				break  -- hidden_stash is shared, no need to check more markers
			end
		end
	end

	-- Also check furniture workshop stashes
	if m_data.workshop_stashes then
		for id, stash_id in pairs(m_data.workshop_stashes) do
			if not stash_set[stash_id] then  -- Skip duplicates
				local se_obj = level.object_by_id(stash_id)
				if se_obj and distance_between_safe(db.actor, se_obj) <= range then
					table.insert(stashes, stash_id)
					stash_set[stash_id] = true
				end
			end
		end
	end

	return stashes
end

-- Helper function: Iterate stashes in range with function (make it globally accessible)
-- exclude_id: optional stash ID to exclude (to avoid processing workshop stash twice)
function _G.IterateStashesInRange(func, range, exclude_id)
	if type(range) ~= "number" then
		return
	end

	local stashes = GetStashesInRange(range)
	for _, id in pairs(stashes) do
		-- Skip the excluded stash (workshop stash is already processed separately)
		if id ~= exclude_id then
			local inv_box = level.object_by_id(id)
			-- Verify it's actually an inventory box before trying to iterate
			if inv_box and inv_box:clsid() == clsid.inventory_box_s then
				inv_box:iterate_inventory_box(func, inv_box)
			end
		end
	end
end

-- Helper function: Collect items from player and nearby stashes (make it globally accessible)
-- exclude_id: optional stash ID to exclude from nearby iteration (will be accessed directly instead)
function _G.collect_amount_in_range(range, section, exclude_id)
	local amount = {}
	local is_multi = IsItem("multiuse", section)
	local is_ammo = IsItem("ammo", section)

	local function itr(temp, obj)
		if (obj:section() == section) then
			local objId = obj:id()
			amount[objId] = amount[objId] or 0

			if is_multi then
				amount[objId] = amount[objId] + obj:get_remaining_uses()
			elseif is_ammo then
				amount[objId] = amount[objId] + obj:ammo_get_count()
			else
				amount[objId] = 1
			end
		end
	end

	db.actor:iterate_inventory(itr)

	-- Also collect from workshop stash if it exists (unless it will be in nearby iteration)
	-- This ensures workshop stash is always checked even if it's not in player_created_stashes
	if exclude_id then
		local workshop_stash = level.object_by_id(exclude_id)
		if workshop_stash and workshop_stash:clsid() == clsid.inventory_box_s then
			workshop_stash:iterate_inventory_box(itr, workshop_stash)
		end
	end

	IterateStashesInRange(itr, range, exclude_id)

	return amount
end

-- Apply all monkey patches inside on_game_start to ensure ui_workshop module is loaded
function on_game_start()
	-- Monkey patch UIWorkshop:Reset to detect toolkits in range
	function ui_workshop.UIWorkshop:Reset(owner, mechanic, toolkits_workshop, dbg)
		-- Get stash range from MCM
		stash_range = ui_mcm and ui_mcm.get("craft_from_stashes/range") or default_range

		-- Store parameters
		self.dbg = dbg and true or false
		self.owner = owner
		self.mechanic = mechanic
		self.toolkits_workshop = toolkits_workshop or {}
		self.toolkits_state = {}

		-- Check toolkits in player inventory and nearby stashes
		-- For general purpose toolkits (basic/advanced/expert), allow higher tiers to satisfy lower tier requirements
		for i = 1, #ui_workshop.workshop_toolkits do
			local has_toolkit = false

			-- Check if this specific toolkit is available
			local val = next(collect_amount_in_range(stash_range, ui_workshop.workshop_toolkits[i], self.stashId))
			if self.toolkits_workshop[i] or (val and val > 0) then
				has_toolkit = true
			end

			-- For general purpose toolkits, also check higher tiers
			-- Basic (1) can use Advanced (2) or Expert (3)
			-- Advanced (2) can use Expert (3)
			if not has_toolkit and i >= 1 and i <= 2 then
				for j = i + 1, 3 do
					local higher_val = next(collect_amount_in_range(stash_range, ui_workshop.workshop_toolkits[j], self.stashId))
					if self.toolkits_workshop[j] or (higher_val and higher_val > 0) then
						has_toolkit = true
						break
					end
				end
			end

			self.toolkits_state[i] = has_toolkit
		end

		-- Switch to state tab
		self:OnButton_state()

		-- Background depends on UI owner
		if device():is_paused() then
			self.background:Show(true)
		else
			self.background:Show(false)
		end
	end

	-- Monkey patch UIWorkshopRepair:ListInventory to find repairable items in range
	-- This function populates the list of items that can be repaired
	function ui_workshop.UIWorkshopRepair:ListInventory()
		self.CC["parts"]:Reset()

		-- Get stash range from MCM
		stash_range = ui_mcm and ui_mcm.get("craft_from_stashes/range") or default_range

		local inv, size_t = {}, 0

		-- Collect from player inventory
		db.actor:iterate_inventory(function(owner, obj)
			local sec = obj:section()
			sec = ini_sys:r_string_ex(sec, "parent_section") or sec -- for weapons with scopes
			if itms_manager.ini_parts:r_string_ex("con_parts_list", sec) then
				size_t = size_t + 1
				inv[size_t] = obj
			end
		end)

		-- Collect from workshop stash if it exists
		local stashId = self.stashId or (self.owner and self.owner.stashId)
		if stashId then
			local stash_obj = get_object_by_id(stashId)
			if stash_obj then
				stash_obj:iterate_inventory_box(function(_, obj)
					local sec = obj:section()
					sec = ini_sys:r_string_ex(sec, "parent_section") or sec -- for weapons with scopes
					if itms_manager.ini_parts:r_string_ex("con_parts_list", sec) then
						size_t = size_t + 1
						inv[size_t] = obj
					end
				end)
			end
		end

		-- Collect from nearby stashes (excluding workshop stash to avoid duplicates)
		IterateStashesInRange(function(temp, obj)
			local sec = obj:section()
			sec = ini_sys:r_string_ex(sec, "parent_section") or sec -- for weapons with scopes
			if itms_manager.ini_parts:r_string_ex("con_parts_list", sec) then
				size_t = size_t + 1
				inv[size_t] = obj
			end
		end, stash_range, stashId)

		self.CC["inventory"]:Reinit(inv)

		ui_workshop.SetTip("repair_intro", nil, nil, nil, true, self.info_text)
	end

	-- Monkey patch UIWorkshopRepair:ListSpareParts to find parts in range
	-- This function populates the part selection inventory when you click a part slot
	function ui_workshop.UIWorkshopRepair:ListSpareParts()
		if not self.highlight_btn then
			return
		end

		self.selected_btn = self.highlight_btn
		local sec_part = self.parts[self.selected_btn].sec
		local con_part = self.parts[self.selected_btn].con

		-- Get stash range from MCM
		stash_range = ui_mcm and ui_mcm.get("craft_from_stashes/range") or default_range

		local cc = self.CC["parts"]
		local inv, inf, size_t = {}, {}, 0

		-- Collect from player inventory
		db.actor:iterate_inventory(function(owner, obj)
			local sec = obj:section()
			if sec == sec_part then
				size_t = size_t + 1
				inv[size_t] = obj
				inf[size_t] = math.ceil(obj:condition() * 100)
			end
		end)

		-- Collect from workshop stash if it exists
		local stashId = self.stashId or (self.owner and self.owner.stashId)
		if stashId then
			local stash = get_object_by_id(stashId)
			if stash then
				stash:iterate_inventory_box(function(owner, obj)
					local sec = obj:section()
					if sec == sec_part then
						size_t = size_t + 1
						inv[size_t] = obj
						inf[size_t] = math.ceil(obj:condition() * 100)
					end
				end)
			end
		end

		-- Collect from nearby stashes (excluding workshop stash to avoid duplicates)
		IterateStashesInRange(function(temp, obj)
			local sec = obj:section()
			if sec == sec_part then
				size_t = size_t + 1
				inv[size_t] = obj
				inf[size_t] = math.ceil(obj:condition() * 100)
			end
		end, stash_range, stashId)

		cc:Reinit(inv, inf)

		-- Add condition % text to each part
		local fnt = GetFontSmall()
		for idx, ci in pairs(self.CC["parts"].cell) do
			if ci:IsShown() then
				local con100 = ci.flags.info
				local con = ci.flags.info / 100
				local g = clamp(512 * con, 0, 255)
				local r = clamp(512 * (1 - con), 0, 255)
				ci:Add_CustomText(con100 .. "%", nil, nil, GetARGB(255, r, g, 50), fnt)
			end
		end

		-- Hide unusable parts (condition too low)
		for idx, ci in pairs(cc.cell) do
			local obj = ci:IsShown() and cc:GetObj(idx)
			if obj then
				if obj:condition() <= (con_part / 100) then
					ci.flags.usable = false
					ci:Colorize("hide")
				else
					ci.flags.usable = true
					ci:Colorize("def")
				end
			end
		end

		ui_workshop.SetTip("repair_tip_3", "repair_warning_3", "repair_solution_3", sec_part, pst, self.info_text)
	end

	-- Monkey patch UIWorkshopRepair:ListPartScheme to check nearby stashes when showing part buttons
	-- This function determines whether replacement part buttons are visible
	function ui_workshop.UIWorkshopRepair:ListPartScheme()
		local obj = self.CC["inventory"]:GetCell_Selected(true)
		if (not obj) then
			return
		end

		-- Reset
		self.CC["parts"]:Reset()
		empty_table(self.new_con)
		empty_table(self.parts)
		self.selected_btn = nil
		self.highlight_btn = nil
		local ps_cnt = 0

		itms_manager.play_item_sound(obj)

		local sec = obj:section()
		sec = ini_sys:r_string_ex(sec, "parent_section") or sec
		local con = math.ceil(100 * (obj:condition()))
		utils_xml.set_upgr_icon(obj, sec, self.itm_ico_r, self.itm_ico_temp_r)

		if IsWeapon(obj) then
			self.itm_con_r:Show(false)
			self.itm_b_r:Show(false)
		else
			self.itm_con_r:Show(true)
			self.itm_b_r:Show(true)
			self.itm_con_r:SetText(con .. "%")
		end

		-- Prepare toolkit
		local toolkits_num = self:UpdateToolkits(0)

		-- Prepare parts
		local parts = itms_manager.ini_parts:r_string_ex("con_parts_list", sec)
		parts = parts and str_explode(parts, ",") or {}
		local parts_con = item_parts.get_parts_con(obj, nil, true)
		for i = 1, #parts do
			self.parts[i] = {}
			self.parts[i].sec = parts[i]
			self.parts[i].con = parts_con[parts[i]]
		end

		-- Get stash range from MCM
		stash_range = ui_mcm and ui_mcm.get("craft_from_stashes/range") or default_range

		local stashId = self.stashId or (self.owner and self.owner.stashId)
		local stash_obj = nil
		if stashId then
			stash_obj = get_object_by_id(stashId)
		end

		for i = 1, 6 do
			if self.parts[i] and self.parts[i].sec and (self.parts[i].sec ~= "na") and self.parts[i].con then
				local part_name = ui_item.get_sec_name(self.parts[i].sec) or ""
				local con = utils_item.get_cond_static(self.parts[i].con)
				local clr = utils_xml.get_color_con(con)
				local obj_part = nil

				-- Check workshop stash first
				if stash_obj then
					stash_obj:iterate_inventory_box(function(_, obj)
						local sec = obj:section()
						if sec == self.parts[i].sec then
							obj_part = obj
						end
					end)
				end

				-- Check player inventory
				if not obj_part then
					obj_part = db.actor:object(self.parts[i].sec)
				end

				-- Check nearby stashes (excluding workshop stash to avoid duplicates)
				if not obj_part then
					IterateStashesInRange(function(temp, obj)
						if not obj_part then  -- Stop searching once found
							local sec = obj:section()
							if sec == self.parts[i].sec then
								obj_part = obj
							end
						end
					end, stash_range, stashId)
				end

				self.itm_b[i]:Show(true)
				self.itm_selected[i]:InitTexture("ui_button_inv_d")
				self.itm_selected[i]:Show(true)
				self.itm_btn[i]:Show(obj_part and (toolkits_num > 0) and true or false)
				self.itm_name[i]:SetText(part_name)
				self.itm_con[i]:SetText(clr .. con .. "%")
				utils_xml.set_icon(self.parts[i].sec, obj_part == nil, self.itm_ico_temp[i], self.itm_ico[i])
				ps_cnt = ps_cnt + (obj_part and 1 or 0)
			else
				self.itm_line[i]:Show(false)
				self.itm_b[i]:Show(false)
				self.itm_selected[i]:Show(false)
				self.itm_btn[i]:Show(false)
				self.itm_name[i]:SetText("")
				self.itm_con[i]:SetText("")
				self.itm_ico[i]:InitTexture("ui_button_inv_d")
			end
		end

		if (toolkits_num > 0) then
			ui_workshop.SetTip("repair_tip_1", "repair_warning_1", "repair_solution_1", self.toolkit, (ps_cnt == #self.parts), self.info_text)
		else
			ui_workshop.SetTip("repair_tip_1", "repair_warning_2", "repair_solution_2", self.toolkit, false, self.info_text)
		end
	end

	-- Monkey patch UIWorkshopRepair:UpdateToolkits to find toolkits in range
	-- This function returns the number of remaining toolkits after picking 'num' of them
	function ui_workshop.UIWorkshopRepair:UpdateToolkits(num)
		local obj = self.CC["inventory"]:GetCell_Selected(true)
		if not obj then
			return 0
		end

		-- Get stash range from MCM
		stash_range = ui_mcm and ui_mcm.get("craft_from_stashes/range") or default_range

		-- Get workshop stash ID
		local stashId = self.stashId or (self.owner and self.owner.stashId)

		empty_table(self.toolkit_inv)
		empty_table(self.toolkit_pick)
		local toolkits_num = 0
		self.toolkit = "na"

		-- Find the appropriate toolkit for this item
		local main_sec = obj:section()
		local repair_type = ini_sys:r_string_ex(main_sec, "repair_type") or main_sec
		for k, v in pairs(GetItemList("workshop")) do
			if v[repair_type] then
				self.toolkit = k
				break
			end
		end

		if self.toolkit and self.toolkit ~= "na" then
			-- Collect toolkits from player and nearby stashes
			self.toolkit_inv = collect_amount_in_range(stash_range, self.toolkit, stashId)

			-- Calculate total uses
			for _, uses in pairs(self.toolkit_inv) do
				toolkits_num = toolkits_num + uses
			end

			-- Pick 'num' toolkits if requested
			if num and num > 0 then
				for i = 1, num do
					local id = random_key_table(self.toolkit_inv)
					local uses = self.toolkit_inv[id]
					if uses and uses > 0 then
						uses = uses - 1
						self.toolkit_pick[#self.toolkit_pick + 1] = id
						if uses == 0 then
							self.toolkit_inv[id] = nil
						else
							self.toolkit_inv[id] = uses
						end
					end
				end
			end

			-- Calculate remaining toolkits
			local toolkits_remain = toolkits_num - #self.toolkit_pick

			-- Update UI for part buttons
			for i = 1, 6 do
				if self.parts[i] and self.parts[i].sec and (not self.new_con[i]) then
					if toolkits_remain < 1 then
						self.itm_btn[i]:Enable(false)
					else
						self.itm_btn[i]:Enable(true)
					end
				end
			end

			-- Update toolkit icon and text
			utils_xml.set_icon(self.toolkit, toolkits_remain < 1, self.itm_ico_temp_rq, self.itm_ico_rq)
			self.itm_num_rq:SetText((toolkits_remain > 0 and clr_list["g"] or clr_list["r"]) .. tostring(toolkits_remain))

			return toolkits_remain
		else
			return 0
		end
	end

	-- Override the entire UpdateItem function from zzzz_serious_ui_workshop.script
	-- to use nearby stashes instead of single stash
	local SetTip = ui_workshop.SetTip

	function ui_workshop.UIWorkshopCraft:UpdateItem(n, sec, amount, result, toolkit_idx, toolkit_sec)
		-- Get stash range from MCM
		stash_range = ui_mcm and ui_mcm.get("craft_from_stashes/range") or default_range

		-- Text (Amount)
		local amt = amount
		local box = 1
		local belt_ids = {}
		if IsItem("ammo",sec) then
			box = IsItem("ammo",sec)
			amt = box * amount
		end

		-- Text (Name)
		local parts_id = {}
		local name = ui_item.get_sec_name(sec)
		
		db.actor:iterate_belt( function(owner, arty)
			--printf(arty:id())
			belt_ids[arty:id()] = true
		end)

		if (not result) then
			-- Reset
			if self.resetcomplexCraft then
				self.resetcomplexCraft = false
				self.complexCraft = {}
			end

			self.craft_item[n] = {}
			self.craft_item_remain[n] = {}
			self.craft_allow[n] = false

			self.itm_name[n]:SetText(name)
			self.itm_num[n]:SetTextColor(GetARGB(250, 255, 50, 50))

			-- Collect valid items from player inventory
			local function search(temp, item)
				if (item:section() == sec) and (not parts_id[item:id()]) and (not belt_ids[item:id()]) then
					local cnt = IsItem("multiuse",nil,item) and item:get_remaining_uses() or 1
					parts_id[item:id()] = cnt
				end
			end
			db.actor:iterate_inventory(search,nil)

			-- First, collect from the workshop's specific stash (if it has one)
			local stashId = self.stashId or (self.owner and self.owner.stashId)
			if stashId then
				local stash_obj = get_object_by_id(stashId)
				if stash_obj then
					stash_obj:iterate_inventory_box(search, nil)
				end
			end

			-- Then also collect from other nearby stashes
			IterateStashesInRange(search, stash_range, stashId)
			
			
			-- Removal of belt artefacts to be sure
			for id,cnt in pairs(parts_id) do
				if belt_ids[id] then
					parts_id[id] = nil
				end
			end

			-- Check and Allow/Prevent
			local dischargeAmount = amount
			local count = 0
			for _,cnt in pairs(parts_id) do
				count = count + cnt
			end

			-- Ammo boxes (complex crafting logic from zzzz_serious_ui_workshop.script)
			if IsItem("ammo",sec) then
				local full_ammo = 0
				local full_ammo_txt = 0
				local partialComponent = {}

				for id,_ in pairs(parts_id) do
					local ammo = level.object_by_id(id)
					if ammo then
						local size = ammo:ammo_get_count()
						local box_size = ammo:ammo_box_size()
						local similar = partialComponent[sec]

						full_ammo_txt = full_ammo_txt + size

						if (size >= box_size) then
							full_ammo = full_ammo + 1
						else
							if not similar then
								partialComponent[sec] = {
									id = id,
									size = size,
									boxSize = box_size,
									findSimilar = true
								}
							elseif similar and similar.findSimilar and size + similar.size >= box_size then
								full_ammo = full_ammo + 1
								similar.findSimilar = false

								self.complexCraft[#self.complexCraft + 1] = {
									id1 = id,
									id2 = similar.id,
									section = sec,
									newItemSize = size + similar.size - box_size
								}
							end
							parts_id[id] = nil
						end
						if (full_ammo >= amount) then
							self.itm_num[n]:SetTextColor(GetARGB(200, 50, 255, 50))
							self.craft_allow[n] = true
						end
					end
				end
				self.itm_num[n]:SetText(tostring(full_ammo_txt) .. "/" .. tostring(amt))

			-- Normal items
			else
				if (count >= amount) then
					self.itm_num[n]:SetTextColor(GetARGB(200, 50, 255, 50))
					self.craft_allow[n] = true
				end
				self.itm_num[n]:SetText(tostring(count) .. "/" .. tostring(amt))
			end

			-- Store items id
			count = 0
			for id,cnt in pairs(parts_id) do
				count = count + cnt

				-- to delete
				if (count <= amount) then
					self.craft_item[n][#self.craft_item[n] + 1] = id
					dischargeAmount = dischargeAmount - count
				end

				if count == amount then
					break
				end

				-- to discharge
				if count > amount then
					self.craft_item_remain[n] = { id = id , cnt = (count - (count - dischargeAmount)) }
					break
				end
			end

			utils_xml.set_icon(sec, (not self.craft_allow[n]), self.itm_ico_temp[n], self.itm_ico[n])

		-- if its the result item
		else
			local stop = false
			local toolkit_name = ui_item.get_sec_name(toolkit_sec)

			self.resetcomplexCraft = true

			for i=1,4 do
				if self.craft_allow[i] == false then
					stop = true
					SetTip(nil, "craft_warning_4", "craft_solution_4", nil, false, self.info_text)
					break
				end
			end
			if not (stop) then
				if (not self.toolkits_state[toolkit_idx]) then
					stop = true
					SetTip(nil, "craft_warning_3", "craft_solution_3", toolkit_sec, false, self.info_text)
				end
			end

			if (not stop) then
				self.craft_allow_r = true
				self.itm_num_r:SetTextColor(GetARGB(250, 50, 255, 50))
				SetTip("craft_tip_5", nil, nil, sec, true, self.info_text)
				self.btn_craft:Enable(true)
			else
				self.itm_num_r:SetTextColor(GetARGB(250, 255, 50, 50))
				self.btn_craft:Enable(false)
			end

			if IsItem("ammo",sec) then
				amount = box
			end
			self.craft_item_r = {sec , amount}

			-- Represent finale uses if its multi-use item
			local amount_txt = tostring(amount) or ""
			if IsItem("multiuse",sec) then
				local uses = ini_sys:r_float_ex(sec,"max_uses") or amount
				amount_txt = tostring(uses) or ""
			end

			self.itm_name_r:SetText(name)
			self.itm_num_r:SetText(amount_txt)
			utils_xml.set_icon(sec, (not self.craft_allow_r), self.itm_ico_temp_r, self.itm_ico_r)

			self.itm_name_t:SetText(toolkit_name)
			utils_xml.set_icon(toolkit_sec, (not self.toolkits_state[toolkit_idx]), self.itm_ico_temp_t, self.itm_ico_t)
		end
	end

	-- Monkey patch UIWorkshopUpgrade:CollectUpgradekits to find upgrade kits in range
	local original_UIWorkshopUpgrade_CollectUpgradekits = ui_workshop.UIWorkshopUpgrade.CollectUpgradekits
	function ui_workshop.UIWorkshopUpgrade:CollectUpgradekits(sec_add)
		-- Call original to get items from inventory and single stash
		local t = original_UIWorkshopUpgrade_CollectUpgradekits(self, sec_add)

		-- Get stash range from MCM
		stash_range = ui_mcm and ui_mcm.get("craft_from_stashes/range") or default_range

		-- Get workshop stash ID to exclude it from nearby search
		local stashId = self.stashId or (self.owner and self.owner.stashId)

		-- Also collect from nearby stashes
		IterateStashesInRange(function(tmp, obj)
			local sec = obj:section()
			if IsItem("upgrade", sec) or (sec == sec_add) then
				if not t[sec] then
					t[sec] = {}
				end
				local uses = utils_item.get_item_remaining_uses(obj) or 1
				t[sec][obj:id()] = uses
			end
		end, stash_range, stashId)

		return t
	end

	-- Monkey patch the Repair function to add refund mechanism for armor (non-weapon) parts
	-- The zzzzz_ui_workshop_repair_patch only refunds weapon parts, armor parts get deleted
	local previous_Repair = ui_workshop.UIWorkshopRepair.Repair
	function ui_workshop.UIWorkshopRepair:Repair()
		local has_parts = arti_jamming and arti_jamming.has_parts
		local obj = self.CC["inventory"]:GetCell_Selected(true)

		-- Check if this is armor/outfit repair (non-weapon with parts)
		local is_armor_repair = obj and not (has_parts and has_parts(obj)) and is_not_empty(self.new_con)

		if is_armor_repair then
			-- Handle armor repair with refund logic (since zzzzz patch skips it)
			local print_ws = ui_workshop.print_ws
			local tot_con = 0
			local cnt = 0

			for i = 1, 6 do
				if self.parts[i] and self.parts[i].sec and (self.parts[i].sec ~= "na") then
					if self.new_con[i] and self.new_con[i].id then
						-- Save old part condition
						local temp = self.parts[i].con
						self.parts[i].con = self.new_con[i].con
						--print_ws("- UIWorkshopRepair:Repair() | armor part replaced | part: %s - condition: %s - order: %s - id: %s", self.parts[i].sec, self.new_con[i].con, i, self.new_con[i].id)

						-- Refund the old part by setting new part's condition to old value
						if temp < 0 then
							alife_release_id(self.new_con[i].id)
						else
							local part = level.object_by_id(self.new_con[i].id)
							if part then
								part:set_condition(temp / 100)
								--print_ws("- UIWorkshopRepair:Repair() | refunded armor part with old condition: %s", temp)
							end
						end
					end

					tot_con = tot_con + self.parts[i].con
					cnt = cnt + 1
				end
			end

			if cnt == 0 then
				--print_ws("! UIWorkshopRepair:Repair() | no new parts have been replaced")
				return
			end

			-- Discharge tools
			for i = 1, #self.toolkit_pick do
				local obj_tool = level.object_by_id(self.toolkit_pick[i])
				if obj_tool then
					utils_item.discharge(obj_tool)
					--print_ws("/ UIWorkshopRepair:Repair() | discharged toolkit (%s)", self.toolkit_pick[i])
				end
			end

			-- Apply condition changes
			local id = obj:id()
			local sec = obj:section()
			sec = ini_sys:r_string_ex(sec, "parent_section") or sec

			local final_con = clamp(math.ceil(tot_con / cnt), 1, 100) / 100
			local armor = level.object_by_id(id)
			if armor and final_con and (final_con >= 0) and (final_con <= 1) then
				armor:set_condition(final_con)
				--print_ws("- UIWorkshopRepair:Repair() | armor with id (%s) is set to a new condition: %s", id, final_con)
			end

			local result_part_tbl = {}
			result_part_tbl[sec] = math.ceil(tot_con / cnt)
			for i = 1, #self.parts do
				result_part_tbl[self.parts[i].sec] = self.parts[i].con
			end
			item_parts.set_parts_con(id, result_part_tbl)

			-- Effect
			actor_effects.play_item_fx("craft_dummy")
			utils_obj.play_sound("interface\\inv_repair_weapon")

			self:Reset()
		else
			-- Call the original (weapon repair or other cases)
			previous_Repair(self)
		end
	end
end  -- End of on_game_start()
