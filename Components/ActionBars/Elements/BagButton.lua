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
	-- Set button size
	button:SetSize(46, 46)
	-- Hide default textures
	if button.NormalTexture then
		button.NormalTexture:SetAlpha(0)
	end
	if button:GetNormalTexture() then
		button:GetNormalTexture():SetTexture(nil)
	end
	-- Hide the count text (free slots number)
	if button.Count then
		button.Count:SetAlpha(0)
	end
	-- Create custom icon with circular mask
	if not button.__DiabolicIcon then
		local icon = button:CreateTexture(nil, "ARTWORK", nil, 1)
		icon:SetPoint("TOPLEFT", button, 4, -4)
		icon:SetPoint("BOTTOMRIGHT", button, -4, 4)
		icon:SetMask(GetMedia("actionbutton-mask-circular"))
		icon:SetTexture([[Interface\Buttons\Button-Backpack-Up]])
		icon:SetAlpha(.85)
		button.__DiabolicIcon = icon
		-- Hide original icon if exists
		if button.icon then
			button.icon:SetAlpha(0)
		elseif button.Icon then
			button.Icon:SetAlpha(0)
		end
	end
	-- Create circular border (like ExtraActionButton)
	if not button.__DiabolicBorder then
		local border = button:CreateTexture(nil, "BACKGROUND", nil, -7)
		border:SetTexture(GetMedia("button-big-circular"))
		border:SetVertexColor(.8, .76, .72)
		border:SetPoint("TOPLEFT", -6, 6)
		border:SetPoint("BOTTOMRIGHT", 6, -6)
		button.__DiabolicBorder = border
	end
	-- Create highlight texture
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
	-- Create pushed texture
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
	-- Hide bag slot buttons
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
	-- Hide the expand toggle (arrow button)
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
	if settings.hideBagButton then
		-- Completely hide BagsBar
		if BagsBar then
			BagsBar:SetParent(ns.Hider)
			BagsBar:Hide()
		end
		return
	end
	-- Show BagsBar and reparent to UIParent
	if BagsBar then
		BagsBar:SetParent(UIParent)
		BagsBar:Show()
		BagsBar:SetAlpha(1)
	end
	-- Hide bag slots and arrow
	self:HideBagSlots()
	-- Style the main backpack button
	local bagButton = MainMenuBarBackpackButton
	if bagButton then
		self:StyleButton(bagButton)
	end
end
BagButton.OnInitialize = function(self)
	-- Don't interfere with bag addons that replace the bag button itself
	local bagAddons = { "AdiBags", "ArkInventory", "Bagnon", "Combuctor", "ElvUI" }
	for _, addon in ipairs(bagAddons) do
		if IsAddOnEnabled(addon) then
			return self:Disable()
		end
	end
	-- Register for PLAYER_ENTERING_WORLD to ensure UI is ready
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
end
BagButton.OnPlayerEnteringWorld = function(self)
	-- Unregister after first fire
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	-- Delay slightly to ensure all frames are created
	C_Timer.After(0.2, function()
		self:SetupBagsBar()
	end)
end
BagButton.OnEnable = function(self)
	-- Nothing needed here, setup happens in PLAYER_ENTERING_WORLD
end
