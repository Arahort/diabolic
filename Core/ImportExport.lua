--[[
	DiabolicUI3 Settings Import/Export
	Allows users to export and import their settings as a string
--]]
local Addon, ns = ...
local ImportExport = ns:NewModule("ImportExport", "AceEvent-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")
local L = ns.L
local exportFrame
local base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function base64encode(data)
	local result = {}
	local padding = ""
	local length = #data
	local i = 1
	while i <= length do
		local a = data:byte(i)
		local b = data:byte(i + 1)
		local c = data:byte(i + 2)
		local bits = a * 65536
		if b then bits = bits + b * 256 end
		if c then bits = bits + c end
		local char1 = base64chars:sub(bit.rshift(bits, 18) + 1, bit.rshift(bits, 18) + 1)
		local char2 = base64chars:sub(bit.band(bit.rshift(bits, 12), 0x3F) + 1, bit.band(bit.rshift(bits, 12), 0x3F) + 1)
		local char3 = b and base64chars:sub(bit.band(bit.rshift(bits, 6), 0x3F) + 1, bit.band(bit.rshift(bits, 6), 0x3F) + 1) or "="
		local char4 = c and base64chars:sub(bit.band(bits, 0x3F) + 1, bit.band(bits, 0x3F) + 1) or "="
		result[#result + 1] = char1 .. char2 .. char3 .. char4
		i = i + 3
	end
	return table.concat(result)
end
local function base64decode(data)
	local result = {}
	data = data:gsub("[^" .. base64chars .. "=]", "")
	local padding = data:match("(=*)$")
	data = data:gsub("=", "")
	local length = #data
	local i = 1
	while i <= length do
		local chars = data:sub(i, i + 3)
		local bits = 0
		for j = 1, #chars do
			local char = chars:sub(j, j)
			local value = base64chars:find(char, 1, true) - 1
			bits = bits * 64 + value
		end
		local byte1 = bit.rshift(bits, 16)
		local byte2 = bit.band(bit.rshift(bits, 8), 0xFF)
		local byte3 = bit.band(bits, 0xFF)
		result[#result + 1] = string.char(byte1)
		if #chars > 2 or #padding < 2 then
			result[#result + 1] = string.char(byte2)
		end
		if #chars > 3 or #padding < 1 then
			result[#result + 1] = string.char(byte3)
		end
		i = i + 4
	end
	return table.concat(result)
end
local function CreateExportFrame()
	if exportFrame then
		return exportFrame
	end
	local frame = CreateFrame("Frame", "DiabolicUI3ExportFrame", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(600, 400)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()
	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.title:SetPoint("TOP", frame, "TOP", 0, -5)
	frame.title:SetText("DiabolicUI3 - " .. (L["ExportImport"] or "Export/Import Settings"))
	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
	scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 50)
	local editBox = CreateFrame("EditBox", nil, scrollFrame)
	editBox:SetMultiLine(true)
	editBox:SetFontObject(ChatFontNormal)
	editBox:SetWidth(scrollFrame:GetWidth())
	editBox:SetAutoFocus(false)
	editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
	editBox:SetScript("OnTextChanged", function(self)
		local _, max = scrollFrame.ScrollBar:GetMinMaxValues()
		if max > 0 and self:GetCursorPosition() == #self:GetText() then
			scrollFrame.ScrollBar:SetValue(max)
		end
	end)
	scrollFrame:SetScrollChild(editBox)
	frame.editBox = editBox
	local selectAllButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	selectAllButton:SetSize(120, 25)
	selectAllButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
	selectAllButton:SetText(L["SelectAll"] or "Select All")
	selectAllButton:SetScript("OnClick", function()
		editBox:SetFocus()
		editBox:HighlightText()
	end)
	local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	closeButton:SetSize(80, 25)
	closeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
	closeButton:SetText(CLOSE)
	closeButton:SetScript("OnClick", function() frame:Hide() end)
	exportFrame = frame
	return frame
end
ImportExport.ExportSettings = function(self)
	local db = ns.db
	if not db then
		print("|cffaa0022DiabolicUI3:|r Failed to export settings - database not found")
		return
	end
	local data = {
		char = db.char,
		global = db.global
	}
	local serialized = AceSerializer:Serialize(data)
	local encoded = base64encode(serialized)
	local frame = CreateExportFrame()
	frame.editBox:SetText(encoded)
	frame.editBox:SetFocus()
	frame.editBox:HighlightText()
	frame:Show()
	print("|cff00ff00DiabolicUI3:|r Settings exported! Copy the text and save it.")
end
ImportExport.ImportSettings = function(self)
	local frame = CreateExportFrame()
	frame.editBox:SetText("")
	frame:Show()
	StaticPopupDialogs["DIABOLICUI3_IMPORT_SETTINGS"] = {
		text = "Paste your settings string and click Import.\n\n|cffff0000Warning:|r This will overwrite your current settings!",
		button1 = L["ImportButton"] or "Import",
		button2 = CANCEL,
		OnAccept = function()
			local encoded = frame.editBox:GetText()
			if not encoded or encoded == "" then
				print("|cffaa0022DiabolicUI3:|r No settings string found")
				return
			end
			local success, serialized = pcall(base64decode, encoded)
			if not success then
				print("|cffaa0022DiabolicUI3:|r Failed to decode settings string")
				return
			end
			local ok, data = AceSerializer:Deserialize(serialized)
			if not ok or not data then
				print("|cffaa0022DiabolicUI3:|r Failed to deserialize settings")
				return
			end
			if not data.char or not data.global then
				print("|cffaa0022DiabolicUI3:|r Invalid settings data")
				return
			end
			local db = ns.db
			if data.char then
				for k, v in pairs(data.char) do
					db.char[k] = v
				end
			end
			if data.global then
				for k, v in pairs(data.global) do
					db.global[k] = v
				end
			end
			frame:Hide()
			print("|cff00ff00DiabolicUI3:|r Settings imported successfully! Type /reload to apply changes.")
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show("DIABOLICUI3_IMPORT_SETTINGS")
end
ImportExport.OnInitialize = function(self)
end
