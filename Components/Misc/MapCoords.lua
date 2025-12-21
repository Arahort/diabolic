--[[
	The MIT License (MIT)
	Copyright (c) 2024 Lars Norberg
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
local MapCoords = ns:NewModule("MapCoords")
-- Lua API
local floor = math.floor
local format = string.format
-- WoW API
local C_Map = C_Map
local CreateFrame = CreateFrame
local GetFramerate = GetFramerate
-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
-- Utility Functions
local function round(float)
	return floor(float + 0.5)
end
local function formatCoord(num, useDecimals)
	if num == nil then
		return 0
	elseif useDecimals then
		return format("%1.1f", round(num * 1000) / 10)
	else
		return round(num * 100)
	end
end
local function getPlayerCoords()
	local mapID = C_Map.GetBestMapForUnit("player")
	if mapID then
		local mapPos = C_Map.GetPlayerMapPosition(mapID, "player")
		if mapPos then
			return mapPos:GetXY()
		end
	end
	return 0, 0
end
-- Minimap Coordinates Update
MapCoords.UpdateMinimapCoords = function(self)
	local minimapModule = ns:GetModule("Minimap", true)
	if not minimapModule or not minimapModule.coordinates then
		return
	end
	local coords = minimapModule.coordinates
	if not ns.db or not ns.db.char or not ns.db.char.mapcoords then
		coords:SetText("")
		return
	end
	if ns.db.char.mapcoords.minimap then
		local x, y = getPlayerCoords()
		if x == 0 and y == 0 then
			coords:SetText("n/a")
		else
			local useDecimals = ns.db.char.mapcoords.decimals or false
			coords:SetFormattedText("%s / %s", formatCoord(x, useDecimals), formatCoord(y, useDecimals))
		end
	else
		coords:SetText("")
	end
end
-- WorldMap Coordinates Update
MapCoords.UpdateWorldMapCoords = function(self)
	if not self.worldMapFrame then
		return
	end
	if not ns.db or not ns.db.char or not ns.db.char.mapcoords then
		self.worldMapText:SetText("")
		return
	end
	local output = ""
	local useDecimals = ns.db.char.mapcoords.decimals or false
	-- Cursor coordinates
	if ns.db.char.mapcoords.worldmapCursor then
		local adjustedX, adjustedY = WorldMapFrame:GetNormalizedCursorPosition()
		if adjustedX > 0 and adjustedY > 0 and adjustedX < 1 and adjustedY < 1 then
			output = format("Cursor: %s / %s", formatCoord(adjustedX, useDecimals), formatCoord(adjustedY, useDecimals))
		end
	end
	-- Separator
	if ns.db.char.mapcoords.worldmapCursor and ns.db.char.mapcoords.worldmapPlayer then
		if output ~= "" then
			output = output .. " - "
		end
	end
	-- Player coordinates
	if ns.db.char.mapcoords.worldmapPlayer then
		local x, y = getPlayerCoords()
		if x == 0 and y == 0 then
			output = output .. "Player: n/a"
		else
			output = output .. format("Player: %s / %s", formatCoord(x, useDecimals), formatCoord(y, useDecimals))
		end
	end
	-- Dynamic positioning based on map state
	if WorldMapFrame:IsMaximized() then
		self.worldMapText:SetPoint("CENTER", WorldMapFrame.BorderFrame, "BOTTOM", 0, 10)
		self.worldMapText:SetTextColor(GameFontNormal:GetTextColor())
	else
		if QuestMapFrame and QuestMapFrame:IsVisible() then
			self.worldMapText:SetPoint("CENTER", WorldMapFrame.BorderFrame, "BOTTOM", -145, 10)
		else
			self.worldMapText:SetPoint("CENTER", WorldMapFrame.BorderFrame, "BOTTOM", 0, 10)
		end
		self.worldMapText:SetTextColor(1, 1, 1, 1)
	end
	self.worldMapFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	self.worldMapText:SetText(output)
end
-- Throttled update system to reduce CPU usage
MapCoords.ThrottledUpdate = function(self, elapsed)
	self.updateTimer = (self.updateTimer or 0) + elapsed
	if self.updateTimer >= 0.1 then -- Update 10 times per second
		self:UpdateMinimapCoords()
		if WorldMapFrame and WorldMapFrame:IsShown() then
			self:UpdateWorldMapCoords()
		end
		self.updateTimer = 0
	end
end
MapCoords.OnInitialize = function(self)
	-- Setup minimap coordinates positioning
	local minimapModule = ns:GetModule("Minimap", true)
	if minimapModule and minimapModule.coordinates then
		local coords = minimapModule.coordinates
		coords:SetTextColor(unpack(Colors.offwhite))
		coords:SetAlpha(.75)
		coords:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 30)
	end
	-- Create WorldMap coordinates frame
	local worldMapFrame = CreateFrame("Frame", "DiabolicUI3WorldMapCoords", WorldMapFrame)
	worldMapFrame:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 10)
	self.worldMapFrame = worldMapFrame
	local worldMapText = worldMapFrame:CreateFontString(nil, "OVERLAY")
	worldMapText:SetFontObject(GameFontNormal)
	worldMapText:SetJustifyH("CENTER")
	worldMapText:SetJustifyV("BOTTOM")
	self.worldMapText = worldMapText
	-- Setup update frame with throttling
	self.updateFrame = CreateFrame("Frame")
	self.updateFrame:SetScript("OnUpdate", function(frame, elapsed)
		self:ThrottledUpdate(elapsed)
	end)
	self.updateTimer = 0
end
MapCoords.OnEnable = function(self)
	-- Initial update
	self:UpdateMinimapCoords()
end
