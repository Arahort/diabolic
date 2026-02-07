--[[
	DiabolicUI3 Settings Import/Export
	Allows users to export and import their settings as a string
--]]
local Addon, ns = ...
local ImportExport = ns:NewModule("ImportExport", "AceEvent-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")
local L = ns.L
local exportFrame
local function deepMerge(target, source)
	for k, v in pairs(source) do
		if type(v) == "table" and type(target[k]) == "table" then
			deepMerge(target[k], v)
		else
			target[k] = v
		end
	end
	return target
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
		version = "3.0.0",
		exportDate = date("%Y-%m-%d %H:%M:%S"),
		char = db.char,
		global = db.global
	}
	local serialized = AceSerializer:Serialize(data)
	local frame = CreateExportFrame()
	frame.editBox:SetText(serialized)
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
			local serialized = frame.editBox:GetText()
			if not serialized or serialized == "" then
				print("|cffaa0022DiabolicUI3:|r No settings string found")
				return
			end
			local ok, data = AceSerializer:Deserialize(serialized)
			if not ok or not data then
				print("|cffaa0022DiabolicUI3:|r Failed to deserialize settings")
				return
			end
			if not data.char and not data.global then
				print("|cffaa0022DiabolicUI3:|r Invalid settings data")
				return
			end
			local db = ns.db
			local version = data.version or "unknown"
			local exportDate = data.exportDate or "unknown"
			if data.char then
				deepMerge(db.char, data.char)
			end
			if data.global then
				deepMerge(db.global, data.global)
			end
			frame:Hide()
			print("|cff00ff00DiabolicUI3:|r Settings imported successfully!")
			if version ~= "unknown" then
				print("|cff00ff00DiabolicUI3:|r Version: " .. version .. ", Exported: " .. exportDate)
			end
			print("|cff00ff00DiabolicUI3:|r Type /reload to apply changes.")
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
