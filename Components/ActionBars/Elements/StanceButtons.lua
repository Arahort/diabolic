--[[
	DiabolicUI3 StanceButtons
	Simple cosmetic styling for Blizzard's default stance bar buttons
	Adds square border frames like buffs/auras
--]]
local Addon, ns = ...
local ActionBars = ns:GetModule("ActionBars")
local StanceButtons = ActionBars:NewModule("StanceButtons", "LibMoreEvents-1.0", "AceHook-3.0")
-- Lua API
local pairs = pairs
local ipairs = ipairs
-- WoW API
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame
local GetNumShapeshiftForms = GetNumShapeshiftForms
-- Addon API
local Colors = ns.Colors
local GetMedia = ns.API.GetMedia
-- Styled buttons cache
local styledButtons = {}
StanceButtons.StyleButton = function(self, button)
	if not button then return end
	if styledButtons[button] then return end
	styledButtons[button] = true
	-- Add border frame like auras
	local border = CreateFrame("Frame", nil, button, ns.BackdropTemplate)
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	border:SetBackdropBorderColor(Colors.verydarkgray[1], Colors.verydarkgray[2], Colors.verydarkgray[3])
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(button:GetFrameLevel() + 2)
	button.__diabolicBorder = border
	-- Slightly darken the icon
	if button.icon then
		button.icon:SetVertexColor(.85, .85, .85)
	end
	-- Hide default border/flash elements if they exist
	if button.NormalTexture then
		button.NormalTexture:SetAlpha(0)
	end
	if button.NormalTexture2 then
		button.NormalTexture2:SetAlpha(0)
	end
end
StanceButtons.StyleAllButtons = function(self)
	if not StanceBar then return end
	for i = 1, 10 do
		local button = _G["StanceButton"..i]
		if button then
			self:StyleButton(button)
		end
	end
end
StanceButtons.OnInitialize = function(self)
end
StanceButtons.OnEnable = function(self)
	-- Style buttons after a short delay to ensure they're created
	C_Timer.After(0.5, function()
		self:StyleAllButtons()
	end)
	-- Re-style when forms change
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS", "StyleAllButtons")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "StyleAllButtons")
end
