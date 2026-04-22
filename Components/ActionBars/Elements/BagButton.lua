--[[
	DiabolicUI3 BagButton
	Styles the bag button with a circular border like ExtraActionButton
	and hides unnecessary elements (arrow, bag slots)
--]]
local Addon, ns = ...
local ActionBars = ns:GetModule("ActionBars")
local BagButton = ActionBars:NewModule("BagButton", "LibMoreEvents-1.0", "AceHook-3.0", "AceEvent-3.0")
-- Lua API
local pairs = pairs
local ipairs = ipairs
-- WoW API
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame
-- Addon API
local Colors = ns.Colors
local GetMedia = ns.API.GetMedia
local SetObjectScale = ns.API.SetUnitFramesObjectScale
local IsAddOnEnabled = ns.API.IsAddOnEnabled
-- Local references
local styledButton = false
BagButton.StyleButton = function(self, button)
	if not button then return end
	if styledButton then return end
	styledButton = true
	button:SetSize(46, 46)
	if button.NormalTexture then
		button.NormalTexture:SetAlpha(0)
	end
	if button:GetNormalTexture() then
		button:GetNormalTexture():SetTexture(nil)
	end
	if button.Count then
		button.Count:SetAlpha(0)
	end
	if not button.__DiabolicIcon then
		local icon = button:CreateTexture(nil, "ARTWORK", nil, 1)
		icon:SetPoint("TOPLEFT", button, 4, -4)
		icon:SetPoint("BOTTOMRIGHT", button, -4, 4)
		icon:SetMask(GetMedia("actionbutton-mask-circular"))
		icon:SetTexture([[Interface\Buttons\Button-Backpack-Up]])
		icon:SetAlpha(.85)
		button.__DiabolicIcon = icon
		if button.icon then
			button.icon:SetAlpha(0)
		elseif button.Icon then
			button.Icon:SetAlpha(0)
		end
	end
	if not button.__DiabolicBorder then
		local border = button:CreateTexture(nil, "BACKGROUND", nil, -7)
		border:SetTexture(GetMedia("button-big-circular"))
		border:SetVertexColor(.8, .76, .72)
		border:SetPoint("TOPLEFT", -8, 8)
		border:SetPoint("BOTTOMRIGHT", 8, -8)
		button.__DiabolicBorder = border
	end
	if not button.__DiabolicHighlight then
		local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT", nil, 1)
		highlightTexture:SetTexture(GetMedia("actionbutton-mask-circular"))
		highlightTexture:SetAllPoints(button.__DiabolicIcon)
		highlightTexture:SetVertexColor(1, 1, 1, .15)
		button.__DiabolicHighlight = highlightTexture
		if button:GetHighlightTexture() then
			button:GetHighlightTexture():SetTexture(nil)
		end
		button:SetHighlightTexture(button.__DiabolicHighlight)
	end
	if not button.__DiabolicPushed then
		local pushedTexture = button:CreateTexture(nil, "ARTWORK", nil, 2)
		pushedTexture:SetTexture(GetMedia("actionbutton-mask-circular"))
		pushedTexture:SetAllPoints(button.__DiabolicIcon)
		pushedTexture:SetVertexColor(1, .8, 0, .25)
		button.__DiabolicPushed = pushedTexture
		if button:GetPushedTexture() then
			button:GetPushedTexture():SetTexture(nil)
		end
		button:SetPushedTexture(button.__DiabolicPushed)
	end
end
BagButton.HideBagSlots = function(self)
	local slots = {
		"CharacterBag0Slot",
		"CharacterBag1Slot",
		"CharacterBag2Slot",
		"CharacterBag3Slot",
		"CharacterReagentBag0Slot"
	}
	for _, slotName in ipairs(slots) do
		local slot = _G[slotName]
		if slot then
			slot:SetParent(ns.Hider)
			slot:Hide()
		end
	end
	if BagBarExpandToggle then
		BagBarExpandToggle:SetParent(ns.Hider)
		BagBarExpandToggle:Hide()
	end
end
BagButton.SetupBagsBar = function(self)
	local db = ns.db
	if not db then return end
	local settings = db.global.bagbutton
	if not settings then return end
	-- WoW 12.0: BagsBar is a secure frame — SetParent/Hide on it taints in combat.
	-- Defer the change until combat ends if we're locked down right now.
	if (InCombatLockdown()) then
		self.__pendingSetup = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnRegenEnabled")
		return
	end
	self.__pendingSetup = nil
	if settings.hideBagButton then
		if BagsBar then
			BagsBar:SetParent(ns.Hider)
			BagsBar:Hide()
		end
		return
	end
	if BagsBar then
		BagsBar:SetParent(UIParent)
		BagsBar:Show()
		BagsBar:SetAlpha(1)
	end
	self:HideBagSlots()
	local bagButton = MainMenuBarBackpackButton
	if bagButton then
		self:StyleButton(bagButton)
	end
end
BagButton.OnRegenEnabled = function(self)
	if (self.__pendingSetup) then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:SetupBagsBar()
	end
end
BagButton.OnInitialize = function(self)
	local bagAddons = { "AdiBags", "ArkInventory", "Bagnon", "Combuctor", "ElvUI" }
	for _, addon in ipairs(bagAddons) do
		if IsAddOnEnabled(addon) then
			return self:Disable()
		end
	end
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
end
BagButton.OnPlayerEnteringWorld = function(self)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	C_Timer.After(0.2, function()
		self:SetupBagsBar()
	end)
end
BagButton.OnEnable = function(self)
end
