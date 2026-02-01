local Addon, ns = ...
local UnitStyles = ns.UnitStyles
if (not UnitStyles) then
	return
end

-- WoW API
local CreateFrame = CreateFrame

-- Addon API
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local SetObjectScale = ns.API.SetUnitFramesObjectScale
local UIHider = ns.Hider

-- This is temporary, just to move the default frames to a better position.
Boss1TargetFrame:SetPoint("TOPRIGHT", 0, -420) -- Default is "TOPRIGHT", 55, -236
for i = 1, MAX_BOSS_FRAMES do
	local frame = SetObjectScale(_G["Boss"..i.."TargetFrame"])
	frame:Show() -- Remind me... why?
end
