local Addon, ns = ...
if (not ns.IsWrath) or (not MultiCastActionBarFrame) or (ns.PlayerClass ~= "SHAMAN") then
	return
end

local ActionBars = ns:GetModule("ActionBars")
local MultiCast = ActionBars:NewModule("MultiCast", "LibMoreEvents-1.0", "AceHook-3.0")

-- WoW API
local CreateFrame = CreateFrame

-- Addon API
local SetObjectScale = ns.API.SetUnitFramesObjectScale

MultiCast.UpdateMultiCastBar = function(self)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end
	MultiCastActionBarFrame:ClearAllPoints()
	MultiCastActionBarFrame:SetPoint("CENTER", self:GetParent(), "CENTER", 0, 0)
end

MultiCast.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		self:UpdateMultiCastBar()
	end
end

MultiCast.OnInitialize = function(self)
	local bar = SetObjectScale(CreateFrame("Frame", ns.Prefix.."MultiCastFrame", UIParent), 1.25)
	bar:SetSize(230,38)
	bar:SetPoint("CENTER", 0, -200)

	MultiCastActionBarFrame:SetScript("OnShow", nil)
	MultiCastActionBarFrame:SetScript("OnHide", nil)
	MultiCastActionBarFrame:SetScript("OnUpdate", nil)
	MultiCastActionBarFrame:SetParent(bar)

	self:SecureHook("ShowMultiCastActionBar", "UpdateMultiCastBar")
end

MultiCast.OnEnable = function(self)
	self:UpdateMultiCastBar()
end
