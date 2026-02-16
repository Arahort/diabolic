--[[

	The MIT License (MIT)

	Copyright (c) 2025 Arahort

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

	Quality of Life improvements for better user experience

--]]
local Addon, ns = ...
local QoL = ns:NewModule("QualityOfLife")

-- WoW API
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local IsShiftKeyDown = IsShiftKeyDown
local C_AddOns = C_AddOns

QoL.AutoFillDeleteConfirmation = function(self)
	-- Auto-fill DELETE confirmation text when destroying items
	-- DELETE_ITEM_CONFIRM_STRING is localized by Blizzard:
	-- English: "DELETE"
	-- Russian: "УДАЛИТЬ"
	-- etc.
	hooksecurefunc(StaticPopupDialogs["DELETE_GOOD_ITEM"], "OnShow", function(dialog)
		dialog.EditBox:SetText(DELETE_ITEM_CONFIRM_STRING)
	end)
end
QoL.MakeFrameMovable = function(self, frame)
	if not frame then return end
	if InCombatLockdown() then return end
	frame:SetMovable(true)
	frame:SetUserPlaced(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		if InCombatLockdown() then return end
		if IsShiftKeyDown() then
			self:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)
end
QoL.EnableMovableFrames = function(self)
	if not ns.db or not ns.db.char or not ns.db.char.qol then return end
	if not ns.db.char.qol.movableFrames then return end
	if C_AddOns.IsAddOnLoaded("BlizzMove") then return end
	local standardFrames = {
		"CharacterFrame",
		"FriendsFrame",
		"PVEFrame",
		"ContainerFrameCombinedBags",
		"WorldMapFrame",
		"GameMenuFrame",
		"SettingsPanel",
		"MerchantFrame",
	}
	for _, frameName in ipairs(standardFrames) do
		local frame = _G[frameName]
		if frame then
			self:MakeFrameMovable(frame)
		end
	end
	local addonFrames = {
		["Blizzard_Professions"] = "ProfessionsFrame",
		["Blizzard_Communities"] = "CommunitiesFrame",
		["Blizzard_ClassTalentUI"] = "ClassTalentFrame",
		["Blizzard_PlayerSpells"] = "PlayerSpellsFrame",
	}
	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("ADDON_LOADED")
	eventFrame:SetScript("OnEvent", function(_, _, addonName)
		local frameName = addonFrames[addonName]
		if frameName then
			local frame = _G[frameName]
			if frame then
				self:MakeFrameMovable(frame)
			end
		end
	end)
end
QoL.UpdateMovableFrames = function(self)
	if not ns.db or not ns.db.char or not ns.db.char.qol then return end
	if ns.db.char.qol.movableFrames then
		self:EnableMovableFrames()
	end
end
QoL.OnInitialize = function(self)
	self:AutoFillDeleteConfirmation()
	self:EnableMovableFrames()
	if ns.RegisterCallback then
		ns.RegisterCallback(self, "QoL_Settings_Updated", "UpdateMovableFrames")
	end
end
