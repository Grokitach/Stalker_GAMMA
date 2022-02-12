-- monkeypatchable inv upgrades to effect repair cost

-- inv upgrades
ini_parts = itms_manager.ini_parts

function section_has_parts(sec)
	local psec = ini_sys:r_string_ex(sec,"parent_section") or sec
	local parts = ini_parts:r_string_ex("con_parts_list", psec)
	return parts ~= nil
end 
-- mp meeeee
function how_much_repair( item_name, item_condition )	
    local cost = ini_sys:r_u32(item_name, "cost")
	local class = ini_sys:r_string_ex(item_name, "class")
	local cof = game_difficulties.get_eco_factor("repair") or 1.67

	--return math.floor( cost * factor * math.pow(1 - item_condition , 1.63) )
	return math.floor( cost * (1 - item_condition) * cof ) -- CoP formula
end



function inventory_upgrades.can_afford_repair_item( item_name, item_condition )
	local price = how_much_repair( item_name, item_condition )
	if db.actor:money() < price then
		return false
	end
	
	return true
end

function inventory_upgrades.question_repair_item( item_name, item_condition, can, mechanic ) --( string, float, bool, string )
	if(item_name=="pri_a17_gauss_rifle") then
		return game.translate_string("st_gauss_cannot_be_repaired")
	end

	if can then
		local price = how_much_repair( item_name, item_condition )
		if db.actor:money() < price then
			return game.translate_string("st_upgr_cost")..": "..price.." RU\\n"..game.translate_string("ui_inv_not_enought_money")..": "..price-db.actor:money().." RU"
		end
		return game.translate_string("st_upgr_cost").." "..price.." RU. "..game.translate_string("ui_st_inv_repair").."?"
	end
	
	return nil
end

function inventory_upgrades.effect_repair_item( item_name, item_condition)
	local price = how_much_repair( item_name, item_condition )
	db.actor:give_money(-price)

	if (item_name == "wpn_binoc") or (ui_options.get("gameplay/general/mechanic_feature") ~= true) then 
		return
	end

	local item
	local function itr(actor,itm)
		if (itm and itm:section() == item_name and itm:condition() == item_condition) then
			item = itm
			return true
		end
		return false
	end

	db.actor:iterate_inventory(itr,db.actor)

	if (item) then
		local victim = get_speaker()
		if (victim) then
			local damage_factor = 1.0 - clamp(item_condition, 0.0, 1.0)
			inventory_upgrades.lend_item_for_repair(item,victim:section(),6000*damage_factor)
		end
	end
end