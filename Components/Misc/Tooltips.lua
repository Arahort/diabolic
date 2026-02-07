--[[

	The MIT License (MIT)

	Copyright (c) 2022 Lars Norberg

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

--]]
local Addon, ns = ...
local Tooltips = ns:NewModule("Tooltips", "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua API
local _G = _G
local ipairs = ipairs
local select = select
local string_find = string.find
local string_format = string.format
local string_lower = string.lower

-- WoW API
local GameTooltip_ClearMoney = GameTooltip_ClearMoney
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetGuildInfo = GetGuildInfo
local GetLocale = GetLocale
local GetMouseFocus = GetMouseFocus or function()
	local foci = GetMouseFoci and GetMouseFoci()
	return foci and foci[1]
end
local GetTooltipUnit = GetTooltipUnit
local SetTooltipMoney = SetTooltipMoney
local SharedTooltip_ClearInsertedFrames = SharedTooltip_ClearInsertedFrames
local UnitClass = UnitClass
local UnitClassification = UnitClassification
local UnitCreatureFamily = UnitCreatureFamily
local UnitCreatureType = UnitCreatureType
local UnitEffectiveLevel = UnitEffectiveLevel or UnitLevel
local UnitFactionGroup = UnitFactionGroup
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitIsAFK = UnitIsAFK
local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsDND = UnitIsDND
local UnitIsPVP = UnitIsPVP
local UnitIsPVPFreeForAll = UnitIsPVPFreeForAll
local UnitLevel = UnitEffectiveLevel or UnitLevel
local UnitName = UnitName
local UnitPVPName = UnitPVPName
local UnitRace = UnitRace
local UnitReaction = UnitReaction

-- WoW 12.0.0: issecretvalue may not exist in older versions
local issecretvalue = issecretvalue or function() return false end

-- Addon API
local Colors = ns.Colors
local AbbreviateNumber = ns.API.AbbreviateNumber
local AbbreviateNumberBalanced = ns.API.AbbreviateNumberBalanced
local GetDifficultyColorByLevel = ns.API.GetDifficultyColorByLevel
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local GetUnitColor = ns.API.GetUnitColor
local SetObjectScale = ns.API.SetObjectScale

local UIHider = ns.Hider
local noop = ns.Noop

-- Tooltip On Mouse tracking
local trackedTooltips = {}

-- Localized Search Patterns
local LEVEL1 = string_lower(_G.TOOLTIP_UNIT_LEVEL:gsub("%s?%%s%s?%-?",""))
local LEVEL2 = _G.TOOLTIP_UNIT_LEVEL_CLASS and string_lower(_G.TOOLTIP_UNIT_LEVEL_CLASS:gsub("^%%2$s%s?(.-)%s?%%1$s","%1"):gsub("^%-?г?о?%s?",""):gsub("%s?%%s%s?%-?","")) or ""

local NOT_SPECIFIED = setmetatable({
	["frFR"] = "Non spécifié",
	["deDE"] = "Nicht spezifiziert",
	["koKR"] = "기타",
	["ruRU"] = "Не указано",
	["zhCN"] = "未指定",
	["zhTW"] = "不明",
	["esES"] = "No especificado",
	["esMX"] = "Sin especificar",
	["ptBR"] = "Não especificado",
	["itIT"] = "Non Specificato"
}, { __index = function(t,k) return "Not specified" end })[(GetLocale())]

-- Localized PvP rank names for both factions (Classic)
-- [RankNum] = { Horde Name, Alliance Name, TextureID }
local PVP_RANKS = {
	[1] = { _G.PVP_RANK_5_0, _G.PVP_RANK_5_1, 136766 },
	[2] = { _G.PVP_RANK_6_0, _G.PVP_RANK_6_1, 136767 },
	[3] = { _G.PVP_RANK_7_0, _G.PVP_RANK_7_1, 136768 },
	[4] = { _G.PVP_RANK_8_0, _G.PVP_RANK_8_1, 136769 },
	[5] = { _G.PVP_RANK_9_0, _G.PVP_RANK_9_1, 136770 },
	[6] = { _G.PVP_RANK_10_0, _G.PVP_RANK_10_1, 136771 },
	[7] = { _G.PVP_RANK_11_0, _G.PVP_RANK_11_1, 136772 },
	[8] = { _G.PVP_RANK_12_0, _G.PVP_RANK_12_1, 136773 },
	[9] = { _G.PVP_RANK_13_0, _G.PVP_RANK_13_1, 136774 },
	[10] = { _G.PVP_RANK_14_0, _G.PVP_RANK_14_1, 136775 },
	[11] = { _G.PVP_RANK_15_0, _G.PVP_RANK_15_1, 136776 },
	[12] = { _G.PVP_RANK_16_0, _G.PVP_RANK_16_1, 136777 },
	[13] = { _G.PVP_RANK_17_0, _G.PVP_RANK_17_1, 136778 },
	[14] = { _G.PVP_RANK_18_0, _G.PVP_RANK_18_1, 136779 },
	[15] = { _G.PVP_RANK_19_0, _G.PVP_RANK_19_1, 136780 }
}

-- WoW Textures
local BOSS_TEXTURE = [[|TInterface\TargetingFrame\UI-TargetingFrame-Skull:14:14:-2:1|t]]

-- Custom Backdrop Cache
local Backdrops = setmetatable({}, { __index = function(t,k)
	local bg = CreateFrame("Frame", nil, k, ns.BackdropTemplate)
	bg:SetAllPoints()
	bg:SetFrameLevel(k:GetFrameLevel())
	-- Hook into tooltip framelevel changes.
	-- Might help with some of the conflicts experienced with Silverdragon and Raider.IO
	hooksecurefunc(k, "SetFrameLevel", function(self) bg:SetFrameLevel(self:GetFrameLevel()) end)
	rawset(t,k,bg)
	return bg
end })

Tooltips.SetBackdropStyle = function(self, tooltip)
	if (not tooltip) or (tooltip.IsEmbedded) or (tooltip:IsForbidden()) then return end

	SetObjectScale(tooltip)

	tooltip:DisableDrawLayer("BACKGROUND")
	tooltip:DisableDrawLayer("BORDER")
	tooltip.SetIgnoreParentScale = noop
	tooltip.SetScale = noop

	-- Don't want or need the extra padding here,
	-- as our current borders do not require them.
	if (tooltip == NarciGameTooltip) then

		-- Note that the WorldMap uses this to fit extra embedded stuff in,
		-- so we can't randomly just remove it from all tooltips, or stuff will break.
		-- Currently the only one we know of that needs tweaking, is the aforementioned.
		if (tooltip.SetPadding) then
			tooltip:SetPadding(0, 0, 0, 0)
			tooltip.SetPadding = noop
		end
	end

	-- Glorious 9.1.5 crap
	-- They decided to move the entire backdrop into its own hashed frame.
	-- We like this, because it makes it easier to kill. Kill. Kill. Kill. Kill.
	if (tooltip.NineSlice) then
		tooltip.NineSlice:SetParent(UIHider)
	end

	-- Textures in the combat pet tooltips
	for _,texName in ipairs({
		"BorderTopLeft",
		"BorderTopRight",
		"BorderBottomRight",
		"BorderBottomLeft",
		"BorderTop",
		"BorderRight",
		"BorderBottom",
		"BorderLeft",
		"Background"
	}) do
		local region = self[texName]
		if (region) then
			region:SetTexture(nil)
			local drawLayer, subLevel = region:GetDrawLayer()
			if (drawLayer) then
				tooltip:DisableDrawLayer(drawLayer)
			end
		end
	end

	-- Region names sourced from SharedXML\NineSlice.lua
	-- *Majority of this, if not all, was moved into frame.NineSlice in 9.1.5
	for _,pieceName in ipairs({
		"TopLeftCorner",
		"TopRightCorner",
		"BottomLeftCorner",
		"BottomRightCorner",
		"TopEdge",
		"BottomEdge",
		"LeftEdge",
		"RightEdge",
		"Center"
	}) do
		local region = tooltip[pieceName]
		if (region) then
			region:SetTexture(nil)
			local drawLayer, subLevel = region:GetDrawLayer()
			if (drawLayer) then
				tooltip:DisableDrawLayer(drawLayer)
			end
		end
	end

	local backdrop = Backdrops[tooltip]
	backdrop:SetBackdrop(nil)
	backdrop:SetBackdrop({
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeSize = 32, edgeFile = GetMedia("border-tooltip"),
		tile = true,
		insets = { left = 8, right = 8, top = 16, bottom = 16 }
	})
	backdrop:ClearAllPoints()
	backdrop:SetPoint("LEFT", -10, 0)
	backdrop:SetPoint("RIGHT", 10, 0)
	backdrop:SetPoint("TOP", 0, 18)
	backdrop:SetPoint("BOTTOM", 0, -18)
	backdrop.offsetBottom = -18
	backdrop.offsetBar = 0
	backdrop.offsetBarBottom = -6
	backdrop:SetBackdropColor(.05, .05, .05, .95)
	--backdrop:SetBackdropBorderColor(ns.Colors.darkgray[1], ns.Colors.darkgray[2], ns.Colors.darkgray[3], 1)

end

Tooltips.StyleTooltips = function(self, event, ...)

	if (event == "PLAYER_ENTERING_WORLD") then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "StyleTooltips")
	end

	for _,tooltip in pairs({
		_G.ItemRefTooltip,
		_G.ItemRefShoppingTooltip1,
		_G.ItemRefShoppingTooltip2,
		_G.FriendsTooltip,
		_G.WarCampaignTooltip,
		_G.EmbeddedItemTooltip,
		_G.ReputationParagonTooltip,
		_G.GameTooltip,
		_G.ShoppingTooltip1,
		_G.ShoppingTooltip2,
		_G.QuickKeybindTooltip,
		_G.QuestScrollFrame and _G.QuestScrollFrame.StoryTooltip,
		_G.QuestScrollFrame and _G.QuestScrollFrame.CampaignTooltip,
		_G.NarciGameTooltip
	}) do
		self:SetBackdropStyle(tooltip)
	end

end

Tooltips.StyleStatusBar = function(self)
	-- IMPORTANT: Don't modify GameTooltipStatusBar directly to avoid taint!
	-- Blizzard code calls SetWatch/ClearWatch on GameTooltip.StatusBar, so we can't replace it.
	-- Instead, hide it visually and create our own custom StatusBar overlay.
	-- Hide original StatusBar visually (don't use SetScript or modify structure!)
	GameTooltipStatusBar:SetAlpha(0)
	-- Create our custom StatusBar (use separate reference, don't replace GameTooltip.StatusBar!)
	local customBar = CreateFrame("StatusBar", "DiabolicTooltipStatusBar", GameTooltip)
	customBar:SetStatusBarTexture(GetMedia("bar-progress"))
	customBar:SetPoint("BOTTOMLEFT", GameTooltip, "BOTTOMLEFT", -1, -4)
	customBar:SetPoint("BOTTOMRIGHT", GameTooltip, "BOTTOMRIGHT", 1, -4)
	customBar:SetHeight(4)
	customBar:Hide()
	-- Create text overlay for HP values
	customBar.Text = customBar:CreateFontString(nil, "OVERLAY")
	customBar.Text:SetFontObject(GetFont(13,true))
	customBar.Text:SetTextColor(ns.Colors.offwhite[1], ns.Colors.offwhite[2], ns.Colors.offwhite[3])
	customBar.Text:SetPoint("CENTER", customBar, "CENTER", 0, 0)
	-- Sync values from original using SAFE hooks (hooksecurefunc doesn't taint)
	hooksecurefunc(GameTooltipStatusBar, "SetValue", function(bar, value)
		customBar:SetValue(value)
	end)
	hooksecurefunc(GameTooltipStatusBar, "SetMinMaxValues", function(bar, min, max)
		customBar:SetMinMaxValues(min, max)
	end)
	hooksecurefunc(GameTooltipStatusBar, "SetStatusBarColor", function(bar, r, g, b, a)
		customBar:SetStatusBarColor(r, g, b, a or 1)
	end)
	hooksecurefunc(GameTooltipStatusBar, "Show", function()
		customBar:Show()
		local backdrop = Backdrops[GameTooltip]
		if (backdrop) then
			backdrop:SetPoint("BOTTOM", 0, backdrop.offsetBottom + backdrop.offsetBarBottom)
		end
	end)
	hooksecurefunc(GameTooltipStatusBar, "Hide", function()
		customBar:Hide()
		local backdrop = Backdrops[GameTooltip]
		if (backdrop) then
			backdrop:SetPoint("BOTTOM", 0, backdrop.offsetBottom)
		end
	end)
	-- Store reference for our functions (DON'T replace GameTooltip.StatusBar!)
	self.CustomStatusBar = customBar
end

Tooltips.SetHealthValue = function(self, unit)
	local customBar = self.CustomStatusBar
	if (not customBar) then return end
	-- WoW 12.0: unit can be nil or secret value, validate before using
	if (not unit) or (type(unit) ~= "string") or issecretvalue(unit) then
		if (customBar:IsShown()) then
			customBar:Hide()
		end
		return
	end
	if (UnitIsDeadOrGhost(unit)) then
		if (customBar:IsShown()) then
			customBar:Hide()
		end
	else
		local msg
		local min,max = UnitHealth(unit), UnitHealthMax(unit)
		-- WoW 12.0.0: Can't format secret values, pass directly
		if issecretvalue(min) or issecretvalue(max) then
			msg = min -- Just show current health if values are secret
		elseif (min and max) then
			if (min == max) then
				msg = string_format("%s", AbbreviateNumberBalanced(min))
			else
				msg = string_format("%s / %s", AbbreviateNumber(min), AbbreviateNumber(max))
			end
		else
			msg = NOT_APPLICABLE
		end
		customBar.Text:SetText(msg)
		if (not customBar.Text:IsShown()) then
			customBar.Text:Show()
		end
		if (not customBar:IsShown()) then
			customBar:Show()
		end
	end
end

Tooltips.OnValueChanged = function(self)
	-- Get unit from GameTooltip (parent of both original and custom bar)
	local unit = select(2, GameTooltip:GetUnit())
	if (not unit) or issecretvalue(unit) then
		local GMF = GetMouseFocus()
		if (GMF and GMF.GetAttribute and GMF:GetAttribute("unit")) then
			unit = GMF:GetAttribute("unit")
		end
	end
	-- WoW 12.0: unit can be nil or secret value
	if (not unit) or (type(unit) ~= "string") or issecretvalue(unit) then
		local customBar = self.CustomStatusBar
		if (customBar) and (customBar:IsShown()) then
			customBar:Hide()
		end
		return
	end
	self:SetHealthValue(unit)
end

Tooltips.OnTooltipCleared = function(self, tooltip)
	if (not tooltip) or (tooltip:IsForbidden()) then return end
	local customBar = self.CustomStatusBar
	if (customBar) and (customBar:IsShown()) then
		customBar:Hide()
	end
end

Tooltips.OnTooltipSetSpell = function(self, tooltip)
	if (not tooltip) or (tooltip:IsForbidden()) then return end

end

Tooltips.OnTooltipSetItem = function(self, tooltip)
	if (not tooltip) or (tooltip:IsForbidden()) then return end

end

Tooltips.OnCompareItemShow = function(self, tooltip)
	if (not tooltip) or (tooltip:IsForbidden()) then return end
	local frameLevel = GameTooltip:GetFrameLevel()
	for i = 1, 2 do
		local tooltip = _G["ShoppingTooltip"..i]
		if (tooltip:IsShown()) then
			if (frameLevel == tooltip:GetFrameLevel()) then
				tooltip:SetFrameLevel(i+1)
			end
		end
	end
end

Tooltips.OnTooltipSetUnit = function(self, tooltip)
	if (not tooltip) or (tooltip:IsForbidden()) then return end

	local _, unit = tooltip:GetUnit()
	if (not unit) then
		local focus = GetMouseFocus()
		if (focus) and (focus.GetAttribute) then
			unit = focus:GetAttribute("unit")
		end
	end
	if (not unit) and (UnitExists("mouseover")) then
		unit = "mouseover"
	end
	if (unit) and UnitIsUnit(unit, "mouseover") then
		unit = "mouseover"
	end
	unit = UnitExists(unit) and unit
	if (not unit) then
		tooltip:Hide()
		return
	end

	GameTooltip_ClearMoney(self)
	SharedTooltip_ClearInsertedFrames(self)

	for i = 3, tooltip:NumLines() do
		local tiptext = _G["GameTooltipTextLeft"..i]
		local linetext = tiptext:GetText()
		if (linetext == _G.PVP) or (linetext == _G.FACTION_ALLIANCE) or (linetext == _G.FACTION_HORDE) then
			tiptext:SetText("")
			tiptext:Hide()
		end
	end

	local levelLine, infoText
	for i = 2, tooltip:NumLines() do
		local tipLine = _G["GameTooltipTextLeft"..i]
		local tipText = tipLine and tipLine:GetText() and string_lower(tipLine:GetText())
		if (tipText) and (string_find(tipText, LEVEL1) or string_find(tipText, LEVEL2)) then
			levelLine = tipLine
			break
		end
	end

	local isPlayer = UnitIsPlayer(unit)
	local unitLevel = UnitLevel(unit)
	local unitEffectiveLevel = UnitEffectiveLevel(unit)
	local unitName, unitRealm = UnitName(unit)
	local isDead = UnitIsDeadOrGhost(unit)

	local displayName = unitName

	local color = GetUnitColor(unit)
	if (color) then
		displayName = color.colorCode..displayName.."|r"
	end

	-- Gather data
	if (isPlayer) then
		local classDisplayName, class, classID = UnitClass(unit)
		local englishFaction, localizedFaction = UnitFactionGroup(unit)
		local guildName, guildRankName, guildRankIndex, guildRealm = GetGuildInfo(unit)
		local raceDisplayName, raceID = UnitRace(unit)
		local isAFK = UnitIsAFK(unit)
		local isDND = UnitIsDND(unit)
		local isDisconnected = not UnitIsConnected(unit)
		local isPVP = UnitIsPVP(unit)
		local isFFA = UnitIsPVPFreeForAll(unit)
		local pvpName = UnitPVPName(unit)
		local inParty = UnitInParty(unit)
		local inRaid = UnitInRaid(unit)
		local uiMapID = (inParty or inRaid) and GetBestMapForUnit and GetBestMapForUnit(unit)
		local pvpRankName, pvpRankNumber

		if (GetPVPRankInfo) and (UnitPVPRank) then
			pvpRankName, pvpRankNumber = GetPVPRankInfo(UnitPVPRank(unit))
		end

		-- Correct the rank names according to faction,
		-- as the above function only returns the names
		-- of your own faction's PvP ranks.
		if (pvpRankNumber and PVP_RANKS[pvpRankNumber]) then
			if (englishFaction == "Horde") then
				pvpRankName = PVP_RANKS[pvpRankNumber][1]
			elseif (englishFaction == "Alliance") then
				pvpRankName = PVP_RANKS[pvpRankNumber][2]
			end
		end

		if (pvpRankName) then
			displayName = displayName .. ns.Colors.quest.gray.colorCode.. " (" .. pvpRankName .. ")|r"
		end

		if (levelLine) then
			if (raceDisplayName) then
				infoText = (infoText and infoText.." " or "") .. raceDisplayName
			end
			if (classDisplayName and class) then
				infoText = (infoText and infoText.." " or "") .. classDisplayName
			end
			if (infoText) then
				levelLine:SetText(infoText)
			else
				levelLine:SetText("")
				levelLine:Hide()
			end
		end

		if (guildName) then
			_G.GameTooltipTextLeft2:SetText(ns.Colors.artifact.colorCode..guildName.."|r")
		end

		if (unitRealm) then
			tooltip:AddLine(" ")
			tooltip:AddLine(_G.FRIENDS_LIST_REALM..unitRealm, ns.Colors.quest.gray[1], ns.Colors.quest.gray[2], ns.Colors.quest.gray[3])
		end

		local levelText
		if (unitEffectiveLevel and unitEffectiveLevel > 0) then
			local r, g, b, colorCode = GetDifficultyColorByLevel(unitEffectiveLevel)
			levelText = colorCode .. unitEffectiveLevel .. "|r"
		end
		if (not levelText) then
			displayName = BOSS_TEXTURE .. " " .. displayName
		end

		if (levelText) then
			_G.GameTooltipTextLeft1:SetText(levelText .. ns.Colors.quest.gray.colorCode .. ": |r" .. displayName)
		else
			_G.GameTooltipTextLeft1:SetText(displayName)
		end

	else
		local englishFaction, localizedFaction = UnitFactionGroup(unit)
		local reaction = UnitReaction(unit, "player")
		local classification = UnitClassification(unit)
		if (unitEffectiveLevel < 0) then
			classification = "worldboss"
		end
		local creatureFamily = UnitCreatureFamily(unit)
		local creatureType = UnitCreatureType(unit)
		if (creatureType == NOT_SPECIFIED) then
			creatureType = nil
		end
		local isBoss = classification == "worldboss"
		if (isBoss) then
			displayName = BOSS_TEXTURE .. " " .. displayName
		elseif (classification == "rare") or (classification == "rareelite") then
			displayName = displayName .. ns.Colors.quality[3].colorCode .. " (" .. _G.ITEM_QUALITY3_DESC .. ")|r"
		elseif (classification == "elite") then
			displayName = displayName .. ns.Colors.title.colorCode .. " (" .. _G.ELITE .. ")|r"
		end

		if (levelLine) then
			if (creatureFamily) then
				infoText = (infoText and infoText.." " or "") .. creatureFamily
			elseif (creatureType) then
				infoText = (infoText and infoText.." " or "") .. creatureType
			end
			if (infoText) then
				levelLine:SetText(infoText)
			else
				levelLine:SetText("")
				levelLine:Hide()
			end
		end

		local levelText
		if (unitEffectiveLevel and unitEffectiveLevel > 0) then
			local r, g, b, colorCode = GetDifficultyColorByLevel(unitEffectiveLevel)
			levelText = colorCode .. unitEffectiveLevel .. "|r"
		end

		-- Add a skull icon for non-classified boss mobs with undetermined unitlevel
		if (not isBoss) and (not levelText) then
			displayName = BOSS_TEXTURE .. " " .. displayName
		end

		if (levelText) then
			_G.GameTooltipTextLeft1:SetText(levelText .. ns.Colors.quest.gray.colorCode .. ": |r" .. displayName)
		else
			_G.GameTooltipTextLeft1:SetText(displayName)
		end

	end

	self:SetHealthValue(unit)

end

local TOOLTIP_UPDATE_THROTTLE = 0.033 -- ~30 updates per second for smooth tooltip following
local updateTooltip = function(tooltip, elapsed)
	if not tooltip.update then return end
	if not ns.db or not ns.db.char or not ns.db.char.tooltips then return end
	if not ns.db.char.tooltips.enabled then return end
	-- Throttle OnUpdate calls (elapsed is only passed from OnUpdate, not direct calls)
	if elapsed then
		tooltip.updateElapsed = (tooltip.updateElapsed or 0) + elapsed
		if tooltip.updateElapsed < TOOLTIP_UPDATE_THROTTLE then
			return
		end
		tooltip.updateElapsed = 0
	end
	local settings = ns.db.char.tooltips
	local scale = UIParent:GetEffectiveScale()
	local mX, mY = GetCursorPosition()
	mX, mY = mX / scale + settings.x, mY / scale + settings.y

	if settings.anchor == "TOPLEFT" then
		mY = mY - tooltip:GetHeight()
	elseif settings.anchor == "TOPRIGHT" then
		mX = mX - tooltip:GetWidth()
		mY = mY - tooltip:GetHeight()
	elseif settings.anchor == "BOTTOMRIGHT" then
		mX = mX - tooltip:GetWidth()
	elseif settings.anchor == "TOP" then
		mX = mX - tooltip:GetWidth() / 2
		mY = mY - tooltip:GetHeight()
	elseif settings.anchor == "BOTTOM" then
		mX = mX - tooltip:GetWidth() / 2
	elseif settings.anchor == "LEFT" then
		mY = mY - tooltip:GetHeight() / 2
	elseif settings.anchor == "RIGHT" then
		mX = mX - tooltip:GetWidth()
		mY = mY - tooltip:GetHeight() / 2
	elseif settings.anchor == "CENTER" then
		mX = mX - tooltip:GetWidth() / 2
		mY = mY - tooltip:GetHeight() / 2
	end

	tooltip:ClearAllPoints()
	tooltip:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", mX, mY)
end

Tooltips.UpdateSettings = function(self)
	if not ns.db or not ns.db.char or not ns.db.char.tooltips then
		ns.db.char.tooltips = {
			enabled = true,
			x = 32,
			y = -32,
			anchor = "TOPLEFT"
		}
	end
end

Tooltips.SetDefaultAnchor = function(self, tooltip, parent)
	if (not tooltip) or (tooltip:IsForbidden()) then return end
	-- WoW 12.0.0: Check if parent is also forbidden to avoid taint errors
	if parent and type(parent.IsForbidden) == "function" and parent:IsForbidden() then return end

	-- WoW 12.0.0: Wrap all tooltip operations in pcall to prevent taint errors
	local success = pcall(function()
		if ns.db and ns.db.char and ns.db.char.tooltips and ns.db.char.tooltips.enabled then
			if parent.unit then
				tooltip:SetOwner(parent, "ANCHOR_PRESERVE")
			else
				tooltip:SetOwner(parent, "ANCHOR_CURSOR")
			end

			updateTooltip(tooltip)
			tooltip.update = true

			if not trackedTooltips[tostring(tooltip)] then
				trackedTooltips[tostring(tooltip)] = true
				tooltip:HookScript("OnUpdate", updateTooltip)
				tooltip:HookScript("OnHide", function()
					tooltip.update = false
				end)
			end
		else
			tooltip:SetOwner(parent, "ANCHOR_NONE")
			tooltip:SetPoint("BOTTOMRIGHT", -40, 40)
		end
	end)
	-- If pcall failed, silently ignore - tooltip will use default positioning
end

Tooltips.SetUnitColor = function(self, unit)
	local customBar = self.CustomStatusBar
	if (not customBar) then return end
	local color = GetUnitColor(unit) or Colors.reaction[5]
	if (color) then
		customBar:SetStatusBarColor(color[1], color[2], color[3])
	end
end

Tooltips.SetFonts = function(self)

	local header = GetFont(15,true)
	local normal = GetFont(13,true)
	local small = GetFont(12,true)

	_G.GameTooltipHeaderText:SetFontObject(header)
	_G.GameTooltipTextSmall:SetFontObject(small)
	_G.GameTooltipText:SetFontObject(normal)

	if (not GameTooltip.hasMoney) then
		SetTooltipMoney(GameTooltip, 1, nil, "", "")
		SetTooltipMoney(GameTooltip, 1, nil, "", "")
		GameTooltip_ClearMoney(GameTooltip)
	end
	if (GameTooltip.hasMoney) then
		for i = 1, GameTooltip.numMoneyFrames do
			_G["GameTooltipMoneyFrame"..i.."PrefixText"]:SetFontObject(normal)
			_G["GameTooltipMoneyFrame"..i.."SuffixText"]:SetFontObject(normal)
			_G["GameTooltipMoneyFrame"..i.."GoldButtonText"]:SetFontObject(normal)
			_G["GameTooltipMoneyFrame"..i.."SilverButtonText"]:SetFontObject(normal)
			_G["GameTooltipMoneyFrame"..i.."CopperButtonText"]:SetFontObject(normal)
		end
	end

	if (_G.DatatextTooltip) then
		_G.DatatextTooltipTextLeft1:SetFontObject(normal)
		_G.DatatextTooltipTextRight1:SetFontObject(normal)
	end

	for _,tooltip in ipairs(GameTooltip.shoppingTooltips) do
		for i = 1,tooltip:GetNumRegions() do
			local region = select(i, tooltip:GetRegions())
			if (region:IsObjectType("FontString")) then
				region:SetFontObject(small)
			end
		end
	end

end

Tooltips.SetHooks = function(self)

	if (_G.SharedTooltip_SetBackdropStyle) then
		self:SecureHook("SharedTooltip_SetBackdropStyle", "SetBackdropStyle")
	else
		self:SecureHook("GameTooltip_SetBackdropStyle", "SetBackdropStyle")
	end

	if GameTooltip_UnitColor then
		self:SecureHook("GameTooltip_UnitColor", "SetUnitColor")
	end
	if GameTooltip_ShowCompareItem then
		self:SecureHook("GameTooltip_ShowCompareItem", "OnCompareItemShow")
	end
	self:SecureHook("GameTooltip_SetDefaultAnchor", "SetDefaultAnchor")

	if GameTooltip and GameTooltip.GetScript and GameTooltip:GetScript("OnTooltipCleared") then
		self:SecureHookScript(GameTooltip, "OnTooltipCleared", "OnTooltipCleared")
	end

	if (not ns.IsRetail) then
		pcall(function() self:SecureHookScript(GameTooltip, "OnTooltipSetSpell", "OnTooltipSetSpell") end)
		pcall(function() self:SecureHookScript(GameTooltip, "OnTooltipSetItem", "OnTooltipSetItem") end)
		pcall(function() self:SecureHookScript(GameTooltip, "OnTooltipSetUnit", "OnTooltipSetUnit") end)
	end

	-- Hook the ORIGINAL GameTooltipStatusBar (not our custom one)
	-- to intercept Blizzard value updates
	if GameTooltipStatusBar then
		self:SecureHookScript(GameTooltipStatusBar, "OnValueChanged", "OnValueChanged")
	end

end

Tooltips.OnInitialize = function(self)

	self:UpdateSettings()
	self:StyleStatusBar()
	self:StyleTooltips()

	self:SetFonts()
	self:SetHooks()
end

Tooltips.OnEnable = function(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "StyleTooltips")
	if ns.callbacks and ns.callbacks.RegisterCallback then
		ns.RegisterCallback(self, "Saved_Settings_Updated", "UpdateSettings")
		ns.RegisterCallback(self, "Tooltips_Settings_Updated", "UpdateSettings")
	end
end
