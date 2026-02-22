--[[
	DiabolicUI3 Raid Frames Customization
	Applies custom fonts and textures to Blizzard CompactUnitFrames
--]]
local Addon, ns = ...
local RaidFrames = ns:NewModule("RaidFrames", "AceEvent-3.0")
-- API
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
-- Cache
local pairs = pairs
local hooksecurefunc = hooksecurefunc
-- Textures
local BORDER_TEXTURE = GetMedia("border-tooltip")
local HEALTH_TEXTURE = GetMedia("bar-progress")
local POWER_TEXTURE = [[Interface\AddOns\DiabolicUI3\Assets\statusbar\Abzorb-Bar.tga]]
-- Text settings (hardcoded, not configurable via UI yet)
local textSettings = {
	nameSize = 11,       -- font size for name
	nameOffsetY = -2,    -- vertical offset for name (negative = down)
	statusSize = 9       -- font size for status/percentage text
}
-- Helper function to get settings from saved variables
local function GetSetting(key, default)
	if ns.db and ns.db.global and ns.db.global.experiments then
		local value = ns.db.global.experiments[key]
		if value ~= nil then
			return value
		end
	end
	return default
end
-- Styled frames cache (to avoid re-styling)
local styledFrames = {}
-- Check if module should be enabled
local function IsEnabled()
	return ns.db and ns.db.global and ns.db.global.experiments and ns.db.global.experiments.customizeRaidFrames
end
-- Create or update border for frame (same style as Tooltips, no background)
local function CreateBorder(frame)
	if not frame.diabolicBorder then
		local border = CreateFrame("Frame", nil, frame, ns.BackdropTemplate)
		-- Disable mouse so it doesn't block clicks on frame elements
		border:EnableMouse(false)
		frame.diabolicBorder = border
	end
	-- Set frame strata and level every time to ensure it's on top
	local border = frame.diabolicBorder
	border:SetFrameStrata("TOOLTIP")
	border:SetFrameLevel(1)
	local top = GetSetting("raidFramesBorderTop", 6)
	local bottom = GetSetting("raidFramesBorderBottom", 8)
	local left = GetSetting("raidFramesBorderLeft", 2)
	local right = GetSetting("raidFramesBorderRight", 2)
	local edgeSize = GetSetting("raidFramesBorderSize", 15)
	border:ClearAllPoints()
	border:SetPoint("TOPLEFT", frame, "TOPLEFT", -left, top)
	border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", right, -bottom)
	-- WoW 12.0: Wrap SetBackdrop in pcall to prevent taint from secret values
	pcall(function()
		border:SetBackdrop({
			edgeFile = BORDER_TEXTURE,
			edgeSize = edgeSize,
			insets = { left = 6, right = 6, top = 6, bottom = 6 }
		})
	end)
	border:Show()
end
-- Update all styled frames with new border settings
local function UpdateAllBorders()
	for frame in pairs(styledFrames) do
		if frame and frame.diabolicBorder then
			CreateBorder(frame)
		end
	end
end
-- Update all styled frames with new text settings
local function UpdateAllText()
	for frame in pairs(styledFrames) do
		if frame and not frame:IsForbidden() then
			StyleName(frame)
			StyleStatusText(frame)
		end
	end
	print("|cffaa0022DiabolicUI3|r: Text updated - nameSize:", textSettings.nameSize, "nameOffsetY:", textSettings.nameOffsetY, "statusSize:", textSettings.statusSize)
end
-- Style the health bar texture
local function StyleHealthBar(frame)
	if frame.healthBar then
		frame.healthBar:SetStatusBarTexture(HEALTH_TEXTURE)
	end
end
-- Style the power bar texture
local function StylePowerBar(frame)
	if frame.powerBar then
		frame.powerBar:SetStatusBarTexture(POWER_TEXTURE)
	end
end
-- Style role icon - ensure visible and apply offset
local function StyleRoleIcon(frame)
	if frame.roleIcon then
		pcall(function()
			frame.roleIcon:SetDrawLayer("OVERLAY", 7)
			-- Apply offset from TOPLEFT corner
			local roleOffsetX = GetSetting("raidFramesRoleOffsetX", 5)
			local roleOffsetY = GetSetting("raidFramesRoleOffsetY", 5)
			frame.roleIcon:ClearAllPoints()
			frame.roleIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", roleOffsetX, -1 - roleOffsetY)
		end)
	end
end
-- Update all role icons with new settings
local function UpdateAllRoleIcons()
	for frame in pairs(styledFrames) do
		if frame and not frame:IsForbidden() then
			StyleRoleIcon(frame)
		end
	end
end
-- Style the name text
local function StyleName(frame)
	if frame.name and GetFont then
		frame.name:SetFontObject(GetFont(textSettings.nameSize, true))
		-- Apply vertical offset (like line-height padding)
		-- Store original position to avoid accumulating offset on each call
		if textSettings.nameOffsetY ~= 0 then
			pcall(function()
				-- Save original position once
				if not frame.diabolicNameOrigY then
					local point, relativeTo, relativePoint, xOfs, yOfs = frame.name:GetPoint(1)
					if point then
						frame.diabolicNameOrigY = yOfs or 0
						frame.diabolicNameOrigX = xOfs or 0
						frame.diabolicNamePoint = point
						frame.diabolicNameRelativeTo = relativeTo
						frame.diabolicNameRelativePoint = relativePoint
					end
				end
				-- Apply offset from original position
				if frame.diabolicNamePoint then
					frame.name:ClearAllPoints()
					frame.name:SetPoint(
						frame.diabolicNamePoint,
						frame.diabolicNameRelativeTo,
						frame.diabolicNameRelativePoint,
						frame.diabolicNameOrigX,
						frame.diabolicNameOrigY + textSettings.nameOffsetY
					)
				end
			end)
		end
	end
end
-- Style the status text (health percentage, etc.)
local function StyleStatusText(frame)
	if frame.statusText and GetFont then
		frame.statusText:SetFontObject(GetFont(textSettings.statusSize, true))
	end
end
-- Main styling function for CompactUnitFrame
local function StyleFrame(frame)
	if not frame then return end
	if frame:IsForbidden() then return end
	-- Skip nameplates - they use CompactUnitFrame but are restricted
	local frameName = frame:GetName()
	if frameName and frameName:match("NamePlate") then return end
	-- Skip if already fully styled
	if styledFrames[frame] then
		return
	end
	StyleHealthBar(frame)
	StylePowerBar(frame)
	StyleName(frame)
	StyleStatusText(frame)
	StyleRoleIcon(frame)
	CreateBorder(frame)
	styledFrames[frame] = true
end
-- Hook into CompactUnitFrame updates
local function SetupHooks()
	-- Hook frame setup
	if CompactUnitFrame_SetUpFrame then
		hooksecurefunc("CompactUnitFrame_SetUpFrame", function(frame, ...)
			if frame and not frame:IsForbidden() then
				styledFrames[frame] = nil -- Reset to re-style
				StyleFrame(frame)
			end
		end)
	end
	-- Hook name updates
	if CompactUnitFrame_UpdateName then
		hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
			if frame and not frame:IsForbidden() then
				StyleName(frame)
			end
		end)
	end
	-- Hook all updates
	if CompactUnitFrame_UpdateAll then
		hooksecurefunc("CompactUnitFrame_UpdateAll", function(frame)
			if frame and not frame:IsForbidden() then
				StyleFrame(frame)
			end
		end)
	end
	-- Hook health bar updates to reapply texture
	if CompactUnitFrame_UpdateHealthColor then
		hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
			if frame and not frame:IsForbidden() then
				StyleHealthBar(frame)
			end
		end)
	end
	-- Hook power bar updates to reapply texture
	if CompactUnitFrame_UpdatePowerColor then
		hooksecurefunc("CompactUnitFrame_UpdatePowerColor", function(frame)
			if frame and not frame:IsForbidden() then
				StylePowerBar(frame)
			end
		end)
	end
	-- Hook role icon updates to ensure it stays visible
	if CompactUnitFrame_UpdateRoleIcon then
		hooksecurefunc("CompactUnitFrame_UpdateRoleIcon", function(frame)
			if frame and not frame:IsForbidden() then
				StyleRoleIcon(frame)
			end
		end)
	end
end
-- Style existing frames on load
local function StyleExistingFrames()
	-- Style party frames
	if CompactPartyFrame then
		for i = 1, 5 do
			local frame = _G["CompactPartyFrameMember" .. i]
			if frame and not frame:IsForbidden() then
				StyleFrame(frame)
			end
		end
	end
	-- Style raid frames (up to 40)
	for i = 1, 40 do
		local frame = _G["CompactRaidFrame" .. i]
		if frame and not frame:IsForbidden() then
			StyleFrame(frame)
		end
	end
	-- Style raid group frames
	for group = 1, 8 do
		for member = 1, 5 do
			local frame = _G["CompactRaidGroup" .. group .. "Member" .. member]
			if frame and not frame:IsForbidden() then
				StyleFrame(frame)
			end
		end
	end
end
function RaidFrames:OnInitialize()
	if not IsEnabled() then
		return
	end
	SetupHooks()
end
function RaidFrames:OnEnable()
	if not IsEnabled() then
		return
	end
	self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		C_Timer.After(1, StyleExistingFrames)
	end)
	self:RegisterEvent("GROUP_ROSTER_UPDATE", function()
		C_Timer.After(0.1, StyleExistingFrames)
	end)
	-- Register callback for settings changes (real-time updates from UI)
	ns.RegisterCallback(self, "RaidFrames_Settings_Updated", function()
		UpdateAllBorders()
		UpdateAllRoleIcons()
	end)
end
