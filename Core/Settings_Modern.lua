--[[
	DiabolicUI3 Modern Settings Panel
	Beautiful sidebar + tabs design inspired by WaypointUI
	Using standard Blizzard API (no custom framework needed)
--]]
local Addon, ns = ...
local L = ns.L

local SIDEBAR_WIDTH = 180
local TAB_HEIGHT = 50
local CONTENT_PADDING = 20
local ANIMATION_DURATION = 0.2

local ModernSettings = {}
local currentTab = nil
local settingsTabs = {}

local function CreateModernFrame()
	local frame = CreateFrame("Frame", "DiabolicUI_SettingsFrame", UIParent, "BackdropTemplate")
	frame:SetSize(900, 600)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:Hide()

	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 }
	})
	frame:SetBackdropColor(0, 0, 0, 0.9)

	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	local titleBar = frame:CreateTexture(nil, "OVERLAY")
	titleBar:SetColorTexture(0.1, 0.1, 0.1, 0.8)
	titleBar:SetPoint("TOPLEFT", 12, -12)
	titleBar:SetPoint("TOPRIGHT", -12, -12)
	titleBar:SetHeight(40)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", titleBar, "TOP", 0, -10)
	title:SetText("|cffaa0022Diabolic|r |cfffafafaUI|r |cffcccccc3.0|r - " .. (L["Settings"] or "Settings"))

	local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", -8, -8)
	closeButton:SetScript("OnClick", function() frame:Hide() end)

	local divider = frame:CreateTexture(nil, "ARTWORK")
	divider:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	divider:SetSize(2, frame:GetHeight() - 80)
	divider:SetPoint("TOPLEFT", 12 + SIDEBAR_WIDTH, -52)

	return frame
end

local function CreateSidebar(parent)
	local sidebar = CreateFrame("Frame", nil, parent)
	sidebar:SetPoint("TOPLEFT", 12, -52)
	sidebar:SetSize(SIDEBAR_WIDTH, parent:GetHeight() - 80)

	local bg = sidebar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.05, 0.05, 0.05, 0.6)

	local scrollFrame = CreateFrame("ScrollFrame", nil, sidebar, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 5, -5)
	scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)

	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetSize(SIDEBAR_WIDTH - 35, 1)
	scrollFrame:SetScrollChild(scrollChild)

	sidebar.scrollChild = scrollChild
	sidebar.buttons = {}

	return sidebar
end

local function CreateTabButton(parent, tabData, index)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(SIDEBAR_WIDTH - 35, TAB_HEIGHT)
	button:SetPoint("TOP", 0, -(index - 1) * (TAB_HEIGHT + 5))

	button.bg = button:CreateTexture(nil, "BACKGROUND")
	button.bg:SetAllPoints()
	button.bg:SetColorTexture(0.15, 0.15, 0.15, 0.4)

	button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
	button.highlight:SetAllPoints()
	button.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.3)
	button.highlight:SetBlendMode("ADD")

	if tabData.icon then
		button.icon = button:CreateTexture(nil, "ARTWORK")
		button.icon:SetSize(24, 24)
		button.icon:SetPoint("LEFT", 10, 0)
		button.icon:SetTexture(tabData.icon)
	end

	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if tabData.icon then
		button.text:SetPoint("LEFT", button.icon, "RIGHT", 8, 0)
	else
		button.text:SetPoint("LEFT", 10, 0)
	end
	button.text:SetText(tabData.name)
	button.text:SetTextColor(0.8, 0.8, 0.8)

	button.selected = false
	button.tabData = tabData

	button:SetScript("OnEnter", function(self)
		if not self.selected then
			self.bg:SetColorTexture(0.2, 0.2, 0.25, 0.6)
		end
	end)

	button:SetScript("OnLeave", function(self)
		if not self.selected then
			self.bg:SetColorTexture(0.15, 0.15, 0.15, 0.4)
		end
	end)

	button:SetScript("OnClick", function(self)
		ModernSettings:SelectTab(tabData.id)
	end)

	button.Select = function(self)
		self.selected = true
		self.bg:SetColorTexture(0.6, 0.1, 0.1, 0.7)
		self.text:SetTextColor(1, 1, 1)
	end

	button.Deselect = function(self)
		self.selected = false
		self.bg:SetColorTexture(0.15, 0.15, 0.15, 0.4)
		self.text:SetTextColor(0.8, 0.8, 0.8)
	end

	return button
end

local function CreateContentArea(parent)
	local content = CreateFrame("Frame", nil, parent)
	content:SetPoint("TOPLEFT", 12 + SIDEBAR_WIDTH + 10, -52)
	content:SetPoint("BOTTOMRIGHT", -12, 12)

	local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", CONTENT_PADDING, -CONTENT_PADDING)
	scrollFrame:SetPoint("BOTTOMRIGHT", -CONTENT_PADDING - 25, CONTENT_PADDING)

	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetWidth(content:GetWidth() - CONTENT_PADDING * 2 - 30)
	scrollChild:SetHeight(1)
	scrollFrame:SetScrollChild(scrollChild)

	scrollChild.fadeIn = scrollChild:CreateAnimationGroup()
	local fadeInAnim = scrollChild.fadeIn:CreateAnimation("Alpha")
	fadeInAnim:SetFromAlpha(0)
	fadeInAnim:SetToAlpha(1)
	fadeInAnim:SetDuration(ANIMATION_DURATION)
	fadeInAnim:SetSmoothing("OUT")

	content.scrollChild = scrollChild
	content.scrollFrame = scrollFrame

	return content
end

function ModernSettings:SelectTab(tabId)
	if currentTab == tabId then return end

	for _, button in pairs(self.sidebar.buttons) do
		button:Deselect()
		if button.tabData.id == tabId then
			button:Select()
		end
	end

	self:ClearContent()

	local tabData = settingsTabs[tabId]
	if tabData and tabData.populate then
		tabData.populate(self.contentArea.scrollChild)
		self.contentArea.scrollChild:SetAlpha(0)
		self.contentArea.scrollChild.fadeIn:Play()
	end

	currentTab = tabId
end

function ModernSettings:ClearContent()
	local scrollChild = self.contentArea.scrollChild
	for i = scrollChild:GetNumChildren(), 1, -1 do
		local child = select(i, scrollChild:GetChildren())
		child:Hide()
		child:SetParent(nil)
	end
end

function ModernSettings:Initialize()
	self.frame = CreateModernFrame()
	self.sidebar = CreateSidebar(self.frame)
	self.contentArea = CreateContentArea(self.frame)

	self:RegisterTabs()

	for i, tabData in ipairs(settingsTabs) do
		local button = CreateTabButton(self.sidebar.scrollChild, tabData, i)
		table.insert(self.sidebar.buttons, button)
	end

	local totalHeight = #settingsTabs * (TAB_HEIGHT + 5) + 10
	self.sidebar.scrollChild:SetHeight(totalHeight)

	if settingsTabs[1] then
		self:SelectTab(settingsTabs[1].id)
	end
end

local yOffset = 0

local function CreateHeader(parent, text)
	local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	header:SetPoint("TOPLEFT", 0, -yOffset)
	header:SetText(text)
	header:SetTextColor(1, 0.82, 0)
	yOffset = yOffset + 30

	local line = parent:CreateTexture(nil, "ARTWORK")
	line:SetColorTexture(0.3, 0.3, 0.3, 0.5)
	line:SetSize(parent:GetWidth() - 40, 1)
	line:SetPoint("TOPLEFT", 0, -yOffset)
	yOffset = yOffset + 15

	return header
end

local function CreateCheckbox(parent, labelText, dbPath, key, callback)
	local container = CreateFrame("Frame", nil, parent)
	container:SetSize(parent:GetWidth() - 40, 30)
	container:SetPoint("TOPLEFT", 0, -yOffset)

	local checkbox = CreateFrame("CheckButton", nil, container, "InterfaceOptionsCheckButtonTemplate")
	checkbox:SetPoint("LEFT")
	checkbox.Text:SetText(labelText)
	checkbox.Text:SetTextColor(0.9, 0.9, 0.9)

	local db = ns.db
	for segment in dbPath:gmatch("[^.]+") do
		db = db[segment]
	end

	checkbox:SetChecked(db[key])
	checkbox:SetScript("OnClick", function(self)
		db[key] = self:GetChecked()
		if callback then callback(db[key]) end
	end)

	yOffset = yOffset + 35
	return checkbox
end

local function CreateSlider(parent, labelText, dbPath, key, minVal, maxVal, step, formatFunc, callback)
	local container = CreateFrame("Frame", nil, parent)
	container:SetSize(parent:GetWidth() - 40, 60)
	container:SetPoint("TOPLEFT", 0, -yOffset)

	local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("TOPLEFT")
	label:SetText(labelText)
	label:SetTextColor(0.9, 0.9, 0.9)

	local slider = CreateFrame("Slider", nil, container, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", 0, -20)
	slider:SetWidth(parent:GetWidth() - 100)
	slider:SetMinMaxValues(minVal, maxVal)
	slider:SetValueStep(step)
	slider:SetObeyStepOnDrag(true)

	local db = ns.db
	for segment in dbPath:gmatch("[^.]+") do
		db = db[segment]
	end

	slider:SetValue(db[key] or minVal)

	local valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	valueText:SetPoint("TOP", slider, "BOTTOM", 0, -5)

	local updateValue = function(value)
		if formatFunc then
			valueText:SetText(formatFunc(value))
		else
			valueText:SetText(string.format("%.2f", value))
		end
	end

	updateValue(slider:GetValue())

	slider:SetScript("OnValueChanged", function(self, value)
		db[key] = value
		updateValue(value)
		if callback then callback(value) end
	end)

	yOffset = yOffset + 70
	return slider
end

local function CreateButton(parent, buttonText, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(200, 30)
	button:SetPoint("TOPLEFT", 0, -yOffset)
	button:SetText(buttonText)
	button:SetScript("OnClick", onClick)

	yOffset = yOffset + 40
	return button
end

local function ResetYOffset()
	yOffset = 0
end

function ModernSettings:RegisterTabs()
	settingsTabs = {
		{
			id = "core",
			name = L["CoreHeader"] or "Core",
			icon = "Interface\\Icons\\INV_Misc_EngGizmos_20",
			populate = function(parent)
				ResetYOffset()
				CreateHeader(parent, L["CoreHeader"] or "Core Settings")

				CreateSlider(parent, L["UIScale"] or "UI Scale", "global.core", "relativeScale",
					0.5, 1.5, 0.05,
					function(val) return string.format("%.0f%%", val * 100) end,
					function(val) ns:SetScale(tostring(val)) end
				)

				CreateSlider(parent, L["MinimapScale"] or "Minimap Scale", "global.core", "minimapRelativeScale",
					0.75, 1.25, 0.05,
					function(val) return string.format("%.0f%%", val * 100) end,
					function(val) ns:SetMinimapScale(tostring(val)) end
				)

				CreateSlider(parent, L["UnitFramesScale"] or "Unit Frames Scale", "global.core", "unitframesRelativeScale",
					0.75, 1.25, 0.05,
					function(val) return string.format("%.0f%%", val * 100) end,
					function(val) ns:SetUnitFramesScale(tostring(val)) end
				)

				parent:SetHeight(yOffset + 50)
			end
		},
		{
			id = "combat",
			name = L["ActionBarsHeader"] or "Combat",
			icon = "Interface\\Icons\\Ability_Warrior_BattleShout",
			populate = function(parent)
				ResetYOffset()
				CreateHeader(parent, L["ActionBarsHeader"] or "Action Bars")
				CreateCheckbox(parent, L["EnableSecondary"] or "Enable Secondary Bar", "char.actionbars", "enableSecondary",
					function(val) ns.callbacks:Fire("ActionBar_Settings_Updated") end)
				CreateCheckbox(parent, L["ShowPetBar"] or "Show Pet Bar", "char.actionbars", "showPetBar",
					function(val) ns.callbacks:Fire("ActionBar_Settings_Updated") end)
				--[[
				CreateCheckbox(parent, L["ShowStanceBar"] or "Show Stance Bar", "char.actionbars", "showStanceBar",
					function(val) ns.callbacks:Fire("ActionBar_Settings_Updated") end)
				--]]
				CreateSlider(parent, L["PetBarPosX"] or "Pet Bar Position X", "global.petbar", "positionX",
					-500, 500, 5,
					function(val) return tostring(val) end,
					function(val) ns.callbacks:Fire("PetBar_Position_Updated") end)
				CreateSlider(parent, L["PetBarPosY"] or "Pet Bar Position Y", "global.petbar", "positionY",
					0, 200, 5,
					function(val) return tostring(val) end,
					function(val) ns.callbacks:Fire("PetBar_Position_Updated") end)
				--[[
				CreateSlider(parent, L["StanceBarPosX"] or "Stance Bar Position X", "global.stancebar", "positionX",
					-500, 500, 5,
					function(val) return tostring(val) end,
					function(val) ns.callbacks:Fire("StanceBar_Position_Updated") end)
				CreateSlider(parent, L["StanceBarPosY"] or "Stance Bar Position Y", "global.stancebar", "positionY",
					0, 200, 5,
					function(val) return tostring(val) end,
					function(val) ns.callbacks:Fire("StanceBar_Position_Updated") end)
				--]]
				CreateHeader(parent, L["AurasHeader"] or "Auras")
				local alwaysShowCheckbox = CreateCheckbox(parent, L["AlwaysShowAuras"] or "Always Show Auras", "char.auras", "alwaysShowAuras",
					function(val)
						if val and ns.db.char.auras.alwaysHideAuras then
							ns.db.char.auras.alwaysHideAuras = false
						end
						ns.callbacks:Fire("Aura_Settings_Updated")
					end)
				local alwaysHideCheckbox = CreateCheckbox(parent, L["AlwaysHideAuras"] or "Always Hide Auras", "char.auras", "alwaysHideAuras",
					function(val)
						if val and ns.db.char.auras.alwaysShowAuras then
							ns.db.char.auras.alwaysShowAuras = false
						end
						ns.callbacks:Fire("Aura_Settings_Updated")
					end)
				CreateSlider(parent, L["AurasPosX"] or "Auras Position X", "global.auras", "positionX",
					-1000, 0, 5,
					function(val) return tostring(val) end,
					function(val) ns.callbacks:Fire("Auras_Position_Updated") end)
				CreateSlider(parent, L["AurasPosY"] or "Auras Position Y", "global.auras", "positionY",
					-500, 0, 5,
					function(val) return tostring(val) end,
					function(val) ns.callbacks:Fire("Auras_Position_Updated") end)
				CreateHeader(parent, L["CastbarHeader"] or "Castbar")
				CreateCheckbox(parent, L["EnableCastbar"] or "Enable Castbar", "global.castbar", "enableCastbar",
					function(val) ns.callbacks:Fire("Castbar_Settings_Updated") end)
				CreateSlider(parent, L["CastbarPosX"] or "Castbar Position X", "global.castbar", "positionX",
					-1000, 1000, 5,
					function(val) return tostring(val) end,
					function(val) ns.callbacks:Fire("Castbar_Settings_Updated") end)
				CreateSlider(parent, L["CastbarPosY"] or "Castbar Position Y", "global.castbar", "positionY",
					-500, 500, 5,
					function(val) return tostring(val) end,
					function(val) ns.callbacks:Fire("Castbar_Settings_Updated") end)
				parent:SetHeight(yOffset + 50)
			end
		},
		{
			id = "frames",
			name = L["UnitFramesHeader"] or "Unit Frames",
			icon = "Interface\\Icons\\Spell_Holy_PowerWordShield",
			populate = function(parent)
				ResetYOffset()
				CreateHeader(parent, L["UnitFramesHeader"] or "Unit Frames Settings")
				CreateCheckbox(parent, L["EnableNamePlates"] or "Enable DiabolicUI NamePlates", "global.unitframes", "enableNamePlates",
					function(val) ns.callbacks:Fire("NamePlates_Settings_Updated") end)
				CreateCheckbox(parent, L["UseClassColorForPower"] or "Use Class Color for Power", "global.unitframes", "useClassColorForPower",
					function(val) ns.callbacks:Fire("UnitFrames_Settings_Updated") end)
				CreateCheckbox(parent, L["ShowTargetCastbar"] or "Show Target Castbar?", "global.unitframes", "showTargetCastbar",
					function(val) ns.callbacks:Fire("UnitFrames_Settings_Updated") end)
				CreateCheckbox(parent, L["UseHealthColorForTarget"] or "Use Health Color for Target", "global.unitframes", "useHealthColorForTarget",
					function(val) ns.callbacks:Fire("UnitFrames_Settings_Updated") end)
				CreateCheckbox(parent, L["ShowThreatOnTarget"] or "Show Threat on Target", "global.unitframes", "showThreatOnTarget",
					function(val) ns.callbacks:Fire("UnitFrames_Settings_Updated") end)
				CreateSlider(parent, L["TargetPosX"] or "Target Position X", "global.unitframes", "targetPositionX",
					-1000, 1000, 5,
					function(val) return tostring(val) end,
					function(val) ns.callbacks:Fire("Target_Position_Updated") end)
				CreateSlider(parent, L["TargetPosY"] or "Target Position Y", "global.unitframes", "targetPositionY",
					-500, 500, 5,
					function(val) return tostring(val) end,
					function(val) ns.callbacks:Fire("Target_Position_Updated") end)
				CreateSlider(parent, L["TargetRelativeScale"] or "Target Relative Scale", "global.unitframes", "targetRelativeScale",
					0.5, 1.5, 0.05,
					function(val) return string.format("%.2f", val) end,
					function(val) ns.callbacks:Fire("Target_Position_Updated") end)
				parent:SetHeight(yOffset + 50)
			end
		},
		{
			id = "maps",
			name = L["MinimapHeader"] or "Maps",
			icon = "Interface\\Icons\\INV_Misc_Map08",
			populate = function(parent)
				ResetYOffset()
				CreateHeader(parent, L["MinimapHeader"] or "Minimap Settings")
				CreateCheckbox(parent, L["UseServerTime"] or "Use Server Time", "global.minimap", "useServerTime",
					function(val) ns.callbacks:Fire("Minimap_Settings_Updated") end)
				CreateCheckbox(parent, L["UseHalfClock"] or "Use 12-Hour Clock", "global.minimap", "useHalfClock",
					function(val) ns.callbacks:Fire("Minimap_Settings_Updated") end)
				CreateSlider(parent, L["MinimapPosX"] or "Minimap Position X", "global.minimap", "positionX",
					-500, 0, 5,
					function(val) return tostring(val) end,
					function(val) ns.callbacks:Fire("Minimap_Settings_Updated") end)
				CreateSlider(parent, L["MinimapPosY"] or "Minimap Position Y", "global.minimap", "positionY",
					-500, 0, 5,
					function(val) return tostring(val) end,
					function(val) ns.callbacks:Fire("Minimap_Settings_Updated") end)
				CreateHeader(parent, L["MapCoordsHeader"] or "Map Coordinates")
				CreateCheckbox(parent, L["WorldMapCursor"] or "World Map Cursor Coords", "char.mapcoords", "worldmapCursor", nil)
				CreateCheckbox(parent, L["WorldMapPlayer"] or "World Map Player Coords", "char.mapcoords", "worldmapPlayer", nil)
				CreateCheckbox(parent, L["MinimapCoords"] or "Minimap Coords", "char.mapcoords", "minimap", nil)
				CreateCheckbox(parent, L["UseDecimals"] or "Use Decimal Coords", "char.mapcoords", "decimals", nil)
				CreateHeader(parent, L["MinimapButtonsHeader"] or "Minimap Buttons")
				CreateCheckbox(parent, L["EnableMinimapButtons"] or "Enable Minimap Buttons", "char.minimapbuttons", "enabled",
					function(val) ns.callbacks:Fire("MinimapButtons_Settings_Updated") end)
				CreateSlider(parent, L["ButtonsPerRow"] or "Buttons Per Row", "char.minimapbuttons", "buttonsPerRow",
					3, 10, 1,
					function(val) return tostring(val) end,
					nil)
				CreateSlider(parent, L["AutoHideDelay"] or "Auto Hide Delay (seconds)", "char.minimapbuttons", "autohide",
					0, 10, 1,
					function(val) return tostring(val) end,
					nil)
				CreateSlider(parent, L["MainButtonScale"] or "Main Button Scale", "char.minimapbuttons", "mainButtonScale",
					0.75, 1.25, 0.05,
					function(val) return string.format("%.2f", val) end,
					nil)
				CreateSlider(parent, L["CollectedButtonScale"] or "Collected Button Scale", "char.minimapbuttons", "buttonScale",
					0.5, 1.5, 0.05,
					function(val) return string.format("%.2f", val) end,
					nil)
				parent:SetHeight(yOffset + 50)
			end
		},
		{
			id = "interface",
			name = L["TooltipsHeader"] or "Interface",
			icon = "Interface\\Icons\\INV_Misc_Note_01",
			populate = function(parent)
				ResetYOffset()
				CreateHeader(parent, L["TooltipsHeader"] or "Tooltips")
				CreateSlider(parent, L["TooltipOffsetX"] or "Tooltip Offset X", "char.tooltips", "x",
					-100, 100, 5,
					function(val) return tostring(val) end,
					function(val) ns.callbacks:Fire("Tooltips_Settings_Updated") end)
				CreateSlider(parent, L["TooltipOffsetY"] or "Tooltip Offset Y", "char.tooltips", "y",
					-100, 100, 5,
					function(val) return tostring(val) end,
					function(val) ns.callbacks:Fire("Tooltips_Settings_Updated") end)
				CreateHeader(parent, L["QualityOfLifeHeader"] or "Quality of Life")
				CreateCheckbox(parent, L["MovableFrames"] or "Movable Interface Frames (SHIFT+Drag)", "char.qol", "movableFrames",
					function(val) ns.callbacks:Fire("QoL_Settings_Updated") end)
				parent:SetHeight(yOffset + 50)
			end
		},
		{
			id = "reset",
			name = L["ResetHeader"] or "Reset",
			icon = "Interface\\Icons\\Ability_Rogue_FeignDeath",
			populate = function(parent)
				ResetYOffset()
				CreateHeader(parent, L["ResetHeader"] or "Reset Settings")
				local warning = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
				warning:SetPoint("TOPLEFT", 0, -yOffset)
				warning:SetText(L["ResetWarning"] or "Warning: These actions cannot be undone!")
				warning:SetTextColor(1, 0.3, 0.3)
				yOffset = yOffset + 40
				CreateButton(parent, L["ReloadUI"] or "Reload UI", function()
					ReloadUI()
				end)
				CreateButton(parent, L["ResetAllSettings"] or "Reset All Settings", function()
					StaticPopup_Show("DIABOLICUI_RESET_CONFIRM")
				end)
				CreateHeader(parent, L["ImportExportHeader"] or "Import / Export Settings")
				CreateButton(parent, L["ExportButton"] or "Export Settings", function()
					local importExport = ns:GetModule("ImportExport")
					if importExport then
						importExport:ExportSettings()
					end
				end)
				CreateButton(parent, L["ImportSettingsButton"] or "Import Settings", function()
					local importExport = ns:GetModule("ImportExport")
					if importExport then
						importExport:ImportSettings()
					end
				end)
				parent:SetHeight(yOffset + 50)
			end
		}
	}
end

function ModernSettings:Show()
	if not self.frame then
		self:Initialize()
	end
	self.frame:Show()
end

function ModernSettings:Hide()
	if self.frame then
		self.frame:Hide()
	end
end

ns.ModernSettings = ModernSettings

StaticPopupDialogs["DIABOLICUI_RESET_CONFIRM"] = {
	text = L["ResetConfirm"] or "Are you sure you want to reset all DiabolicUI settings?",
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		ns.db = ns:GetDefaults()
		ReloadUI()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

SLASH_DIABOLICUI1 = "/dui"
SLASH_DIABOLICUI2 = "/diabolic"
SlashCmdList["DIABOLICUI"] = function(msg)
	ModernSettings:Show()
end
