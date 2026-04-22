local Addon, ns = ...
-- BagDump: iterates all bag slots, collects detailed item info, saves to SavedVariables.
-- Usage: /bagdump          — scan all bags (default)
--        /bagdump bank     — include bank (must be open at a banker)
--        /bagdump clear    — clear saved dump
-- After scan, do /reload or logout so SavedVariables are flushed to disk.
-- Output is written to _G.DiabolicUI3_BagDump (persisted via toc SavedVariablesPerCharacter).
local BagDump = ns:NewModule("BagDump", "LibMoreEvents-1.0")
local string_format = string.format
local tinsert = table.insert
-- Item quality names (readable output)
local QUALITY_NAMES = {
	[0] = "Poor",
	[1] = "Common",
	[2] = "Uncommon",
	[3] = "Rare",
	[4] = "Epic",
	[5] = "Legendary",
	[6] = "Artifact",
	[7] = "Heirloom",
	[8] = "WoWToken",
}
-- Item type/subtype + equip slot names come from GetItemInfo (cached once item is loaded)
local ScanBag = function(bag, results)
	local numSlots = C_Container.GetContainerNumSlots(bag) or 0
	for slot = 1, numSlots do
		local info = C_Container.GetContainerItemInfo(bag, slot)
		if (info and info.itemID) then
			-- Extra info via GetItemInfo (classname, subclass, equipLoc, etc.)
			local name, link, quality, iLevel, reqLevel, itemClass, itemSubClass, maxStack,
				equipSlot, iconTex, sellPrice, classID, subClassID, bindType, expacID,
				setID, isCraftingReagent = GetItemInfo(info.itemID)
			local quest = C_Container.GetContainerItemQuestInfo(bag, slot)
			local entry = {
				bag = bag,
				slot = slot,
				itemID = info.itemID,
				name = info.itemName or name,
				link = info.hyperlink or link,
				quality = info.quality,
				qualityName = QUALITY_NAMES[info.quality or 0] or "Unknown",
				count = info.stackCount or 1,
				isLocked = info.isLocked and true or false,
				isBound = info.isBound and true or false,
				hasLoot = info.hasLoot and true or false,
				isReadable = info.isReadable and true or false,
				iconFileID = info.iconFileID,
				-- From GetItemInfo (may be nil if not yet cached)
				itemLevel = iLevel,
				reqLevel = reqLevel,
				itemClass = itemClass,       -- e.g., "Quest", "Consumable", "Trade Goods", "Weapon"
				itemSubClass = itemSubClass, -- finer category
				equipLoc = equipSlot,        -- "INVTYPE_HEAD" etc. (or "")
				maxStack = maxStack,
				sellPrice = sellPrice,       -- copper; 0 = can't sell
				bindType = bindType,         -- 0=none,1=BoP,2=BoE,3=BoU,4=Quest
				expansionID = expacID,       -- 0=classic, 1=tbc, 2=wrath, ..., see LE_EXPANSION_*
				classID = classID,
				subClassID = subClassID,
				isCraftingReagent = isCraftingReagent and true or false,
				-- Quest
				isQuestItem = quest and quest.isQuestItem and true or false,
				questID = quest and quest.questID or nil,
				questActive = quest and quest.isActive and true or false,
			}
			tinsert(results, entry)
		end
	end
end
local RunScan = function(scanBank)
	local results = {}
	-- Main backpack + bags + reagent bag (0 .. 5)
	for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or 5 do
		ScanBag(bag, results)
	end
	-- Bank (if requested and open)
	if (scanBank) then
		if (BANK_CONTAINER) then ScanBag(BANK_CONTAINER, results) end
		for bag = (NUM_BAG_SLOTS or 4) + 1, (NUM_BAG_SLOTS or 4) + (NUM_BANKBAGSLOTS or 7) do
			ScanBag(bag, results)
		end
	end
	-- Sort by bag, then slot
	table.sort(results, function(a, b)
		if (a.bag ~= b.bag) then return a.bag < b.bag end
		return a.slot < b.slot
	end)
	return results
end
local PromiseItemLoad = function(itemID)
	-- Force server request if not cached; result becomes available on next frame.
	if (C_Item and C_Item.RequestLoadItemDataByID) then
		C_Item.RequestLoadItemDataByID(itemID)
	end
end
local Prescan = function(scanBank)
	-- Touch every item to populate GetItemInfo cache before saving.
	for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or 5 do
		local numSlots = C_Container.GetContainerNumSlots(bag) or 0
		for slot = 1, numSlots do
			local itemID = C_Container.GetContainerItemID(bag, slot)
			if (itemID) then PromiseItemLoad(itemID) end
		end
	end
	if (scanBank) then
		if (BANK_CONTAINER) then
			local numSlots = C_Container.GetContainerNumSlots(BANK_CONTAINER) or 0
			for slot = 1, numSlots do
				local itemID = C_Container.GetContainerItemID(BANK_CONTAINER, slot)
				if (itemID) then PromiseItemLoad(itemID) end
			end
		end
		for bag = (NUM_BAG_SLOTS or 4) + 1, (NUM_BAG_SLOTS or 4) + (NUM_BANKBAGSLOTS or 7) do
			local numSlots = C_Container.GetContainerNumSlots(bag) or 0
			for slot = 1, numSlots do
				local itemID = C_Container.GetContainerItemID(bag, slot)
				if (itemID) then PromiseItemLoad(itemID) end
			end
		end
	end
end
BagDump.Dump = function(self, scanBank)
	Prescan(scanBank)
	-- Wait two frames so the client has time to cache item info after requests
	C_Timer.After(0.3, function()
		local results = RunScan(scanBank)
		_G.DiabolicUI3_BagDump = {
			timestamp = date("%Y-%m-%d %H:%M:%S"),
			character = UnitName("player") .. "-" .. GetRealmName(),
			realmLocale = GetLocale(),
			scanBank = scanBank and true or false,
			totalItems = #results,
			items = results,
		}
		print(string_format("|cff00ff00DiabolicUI3 BagDump:|r %d items scanned. Do /reload or logout to flush to SavedVariables.",
			#results))
		-- Count unloaded names (items without cached GetItemInfo)
		local unloaded = 0
		for _, e in ipairs(results) do
			if (not e.itemClass) then unloaded = unloaded + 1 end
		end
		if (unloaded > 0) then
			print(string_format("|cffff9900DiabolicUI3 BagDump:|r %d items didn't have full info cached — re-run /bagdump in a few seconds.", unloaded))
		end
	end)
end
BagDump.Clear = function(self)
	_G.DiabolicUI3_BagDump = nil
	print("|cff00ff00DiabolicUI3 BagDump:|r cleared.")
end
-- Slash command
_G.SLASH_BAGDUMP1 = "/bagdump"
_G.SlashCmdList.BAGDUMP = function(msg)
	msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if (msg == "clear") then
		BagDump:Clear()
	elseif (msg == "bank") then
		BagDump:Dump(true)
	else
		BagDump:Dump(false)
	end
end
