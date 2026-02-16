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
local MinimapButtons = ns:NewModule("MinimapButtons", "LibMoreEvents-1.0")
-- Lua API
local pairs = pairs
local ipairs = ipairs
local type = type
local tinsert = table.insert
local sort = table.sort
local strfind = string.find
local strlower = string.lower
-- WoW API
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local hooksecurefunc = hooksecurefunc
local GetFramerate = GetFramerate
-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local L = ns.L
-- Constants
local BUTTON_SIZE = 32
local DEFAULT_MAIN_BUTTON_SIZE = 40
local FRAME_STRATA = "MEDIUM"
local FRAME_LEVEL = 7
local BUTTON_SPACING = 4
-- Module variables
local mainButton
local buttonContainer
local collectedButtons = {}
local collectedButtonMap = {}
local buttonOriginalFunctions = {}
local isContainerVisible = false
local autohideTimer
-- Utility Functions
local function doNothing() end
-- Get LibDBIcon
local function getLibDBIcon()
	return _G.LibStub and _G.LibStub:GetLibrary('LibDBIcon-1.0', true)
end
-- Get LibMapButton
local function getLibMapButton()
	return _G.LibStub and _G.LibStub:GetLibrary('LibMapButton-1.1', true)
end
-- Check if frame is valid
local function isValidFrame(frame)
	if type(frame) ~= 'table' then
		return false
	end
	return (frame.IsObjectType and frame:IsObjectType('Frame'))
end
-- Check if button is blacklisted
local function isButtonBlacklisted(button)
	if not button then return true end
	local name = button:GetName()
	if not name then return true end
	-- Blacklist DiabolicUI3 buttons
	if strfind(name, "DiabolicUI3") then
		return true
	end
	-- Check custom blacklist
	if ns.db and ns.db.char and ns.db.char.minimapbuttons and ns.db.char.minimapbuttons.blacklist then
		if ns.db.char.minimapbuttons.blacklist[name] then
			return true
		end
	end
	return false
end
-- Update layout when button visibility changes
local function updateLayoutIfVisibilityChanged(frame)
	local visibility = frame:IsShown()
	if collectedButtonMap[frame] ~= visibility then
		collectedButtonMap[frame] = visibility
		MinimapButtons:UpdateLayout()
	end
end
-- Collect a button
local function collectButton(button)
	if not button or not isValidFrame(button) then return end
	if collectedButtonMap[button] ~= nil then return end
	if isButtonBlacklisted(button) then return end
	-- Store original visibility
	local wasVisible = button:IsShown()
	-- Save original functions BEFORE blocking
	buttonOriginalFunctions[button] = {
		ClearAllPoints = button.ClearAllPoints,
		SetPoint = button.SetPoint,
		SetParent = button.SetParent,
		SetScale = button.SetScale
	}
	-- Set parent to container
	button:SetParent(buttonContainer)
	button:SetFrameStrata("HIGH")
	button:SetFrameLevel(25)
	button:SetScript('OnDragStart', nil)
	button:SetScript('OnDragStop', nil)
	button:SetIgnoreParentScale(false)
	-- Scale button
	local buttonScale = 1
	if ns.db and ns.db.char and ns.db.char.minimapbuttons then
		buttonScale = ns.db.char.minimapbuttons.buttonScale or 1
	end
	button:SetScale(buttonScale)
	-- Clear old position BEFORE blocking
	button:ClearAllPoints()
	button:Hide()
	-- Prevent button from moving itself
	button.ClearAllPoints = doNothing
	button.SetPoint = doNothing
	button.SetParent = doNothing
	button.SetScale = doNothing
	-- Add to collection
	tinsert(collectedButtons, button)
	collectedButtonMap[button] = wasVisible
end
-- Collect LibDBIcon buttons
local function collectLibDBIconButtons()
	local LibDBIcon = getLibDBIcon()
	if not LibDBIcon then return end
	for _, buttonName in ipairs(LibDBIcon:GetButtonList()) do
		local button = LibDBIcon:GetMinimapButton(buttonName)
		if button then
			collectButton(button)
		end
	end
end
-- Collect LibMapButton buttons
local function collectLibMapButtonButtons()
	local LibMapButton = getLibMapButton()
	if not LibMapButton then return end
	for _, button in pairs(LibMapButton.buttons or {}) do
		collectButton(button)
	end
end
-- Collect minimap children
local function collectMinimapChildren()
	if not Minimap then return end
	local children = {Minimap:GetChildren()}
	for _, child in ipairs(children) do
		if isValidFrame(child) and child:IsShown() then
			local name = child:GetName()
			if name and not isButtonBlacklisted(child) then
				-- Check if it looks like a minimap button
				local width = child:GetWidth()
				local height = child:GetHeight()
				if width and height and width > 0 and height > 0 and width < 60 and height < 60 then
					collectButton(child)
				end
			end
		end
	end
end
-- Collect Blizzard expansion landing page button (Dragonflight, War Within, etc.)
local function collectExpansionLandingButton()
	local button = ExpansionLandingPageMinimapButton
	if button and isValidFrame(button) and button:IsShown() then
		collectButton(button)
	end
end
-- Update button layout
MinimapButtons.UpdateLayout = function(self)
	if not buttonContainer or not ns.db or not ns.db.char or not ns.db.char.minimapbuttons then
		return
	end
	local buttonsPerRow = ns.db.char.minimapbuttons.buttonsPerRow or 5
	local direction = ns.db.char.minimapbuttons.direction or "leftdown"
	-- Get buttons that should be visible (based on original state)
	local visibleButtons = {}
	for _, button in ipairs(collectedButtons) do
		if collectedButtonMap[button] then
			tinsert(visibleButtons, button)
		end
	end
	if #visibleButtons == 0 then
		return
	end
	-- Position buttons in grid
	local row = 0
	local col = 0
	for i, button in ipairs(visibleButtons) do
		-- Calculate offset to CENTER of grid cell
		local xOffset = col * (BUTTON_SIZE + BUTTON_SPACING) + 8 + BUTTON_SIZE / 2
		local yOffset = -row * (BUTTON_SIZE + BUTTON_SPACING) - 8 - BUTTON_SIZE / 2
		-- Use saved original functions to position
		local originalFuncs = buttonOriginalFunctions[button]
		if originalFuncs then
			-- Divide offset by scale to account for scaled buttons
			local scale = button:GetScale()
			local scaledX = xOffset / scale
			local scaledY = yOffset / scale
			originalFuncs.ClearAllPoints(button)
			if direction == "leftdown" then
				originalFuncs.SetPoint(button, "CENTER", buttonContainer, "TOPLEFT", scaledX, scaledY)
			elseif direction == "rightdown" then
				originalFuncs.SetPoint(button, "CENTER", buttonContainer, "TOPRIGHT", -scaledX, scaledY)
			elseif direction == "leftup" then
				originalFuncs.SetPoint(button, "CENTER", buttonContainer, "BOTTOMLEFT", scaledX, -scaledY)
			else
				originalFuncs.SetPoint(button, "CENTER", buttonContainer, "BOTTOMRIGHT", -scaledX, -scaledY)
			end
		end
		-- Show button if container is shown
		if buttonContainer:IsShown() then
			button:Show()
		end
		col = col + 1
		if col >= buttonsPerRow then
			col = 0
			row = row + 1
		end
	end
	-- Resize container
	local numRows = row + 1
	local numCols = col > 0 and buttonsPerRow or col
	if col == 0 and #visibleButtons > 0 then
		numCols = buttonsPerRow
	end
	local width = numCols * BUTTON_SIZE + (numCols - 1) * BUTTON_SPACING + 16
	local height = numRows * BUTTON_SIZE + (numRows - 1) * BUTTON_SPACING + 16
	buttonContainer:SetSize(width, height)
end
-- Show container
MinimapButtons.ShowContainer = function(self)
	if not buttonContainer then
		return
	end
	buttonContainer:Show()
	isContainerVisible = true
	self:UpdateLayout()
	-- Cancel autohide timer
	if autohideTimer then
		autohideTimer:Cancel()
		autohideTimer = nil
	end
end
-- Hide container
MinimapButtons.HideContainer = function(self)
	if not buttonContainer then return end
	-- Hide all collected buttons
	for _, button in ipairs(collectedButtons) do
		if collectedButtonMap[button] then
			button:Hide()
		end
	end
	buttonContainer:Hide()
	isContainerVisible = false
	if autohideTimer then
		autohideTimer:Cancel()
		autohideTimer = nil
	end
end
-- Toggle container
MinimapButtons.ToggleContainer = function(self)
	if isContainerVisible then
		self:HideContainer()
	else
		self:ShowContainer()
		-- Setup autohide
		if ns.db and ns.db.char and ns.db.char.minimapbuttons then
			local autohide = ns.db.char.minimapbuttons.autohide or 0
			if autohide > 0 then
				autohideTimer = C_Timer.NewTimer(autohide, function()
					self:HideContainer()
				end)
			end
		end
	end
end
-- Collect all buttons
MinimapButtons.CollectButtons = function(self)
	collectLibDBIconButtons()
	collectLibMapButtonButtons()
	collectMinimapChildren()
	collectExpansionLandingButton()
	self:UpdateLayout()
end
-- Update main button size
MinimapButtons.UpdateMainButtonSize = function(self)
	if not mainButton then return end
	local buttonSize = DEFAULT_MAIN_BUTTON_SIZE
	if ns.db and ns.db.char and ns.db.char.minimapbuttons then
		buttonSize = ns.db.char.minimapbuttons.mainButtonSize or DEFAULT_MAIN_BUTTON_SIZE
	end
	mainButton:SetSize(buttonSize, buttonSize)
	-- Update border size (35% bigger than button)
	if mainButton.border then
		local borderSize = buttonSize * 1.35
		mainButton.border:SetSize(borderSize, borderSize)
	end
end
-- Create main button
MinimapButtons.CreateMainButton = function(self)
	if mainButton then return end
	-- Get button size from settings
	local buttonSize = DEFAULT_MAIN_BUTTON_SIZE
	if ns.db and ns.db.char and ns.db.char.minimapbuttons then
		buttonSize = ns.db.char.minimapbuttons.mainButtonSize or DEFAULT_MAIN_BUTTON_SIZE
	end
	-- Create button frame
	mainButton = CreateFrame("Button", "DiabolicUI3MinimapButtonsButton", UIParent)
	mainButton:SetSize(buttonSize, buttonSize)
	mainButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 10, 10)
	mainButton:SetFrameStrata("HIGH")
	mainButton:SetFrameLevel(20)
	mainButton:SetClampedToScreen(true)
	-- Circular border (35% bigger than button for visibility)
	local borderSize = buttonSize * 1.35
	local border = mainButton:CreateTexture(nil, "OVERLAY", nil, 2)
	border:SetTexture(GetMedia("button-big-circular"))
	border:SetVertexColor(.8, .76, .72)
	border:SetPoint("CENTER")
	border:SetSize(borderSize, borderSize)
	mainButton.border = border
	-- Background shade
	local shade = mainButton:CreateTexture(nil, "BACKGROUND", nil, -7)
	shade:SetTexture(GetMedia("shade-circle"))
	shade:SetVertexColor(0, 0, 0, .5)
	shade:SetAllPoints()
	mainButton.shade = shade
	-- Bag icon with circular mask (on top of border!)
	local icon = mainButton:CreateTexture(nil, "OVERLAY", nil, 3)
	icon:SetTexture([[Interface\Icons\INV_Misc_Bag_10]])
	icon:SetAllPoints(mainButton)
	icon:SetMask(GetMedia("actionbutton-mask-circular"))
	icon:SetAlpha(.85)
	mainButton.icon = icon
	-- Click handler
	mainButton:SetScript("OnClick", function()
		self:ToggleContainer()
	end)
	-- Make draggable
	mainButton:SetMovable(true)
	mainButton:RegisterForDrag("LeftButton")
	mainButton:SetScript("OnDragStart", function(btn)
		btn:StartMoving()
	end)
	mainButton:SetScript("OnDragStop", function(btn)
		btn:StopMovingOrSizing()
	end)
end
-- Create button container
MinimapButtons.CreateContainer = function(self)
	if buttonContainer then return end
	-- Create container frame with backdrop
	buttonContainer = CreateFrame("Frame", "DiabolicUI3MinimapButtonsContainer", UIParent, ns.BackdropTemplate)
	buttonContainer:SetParent(mainButton)
	buttonContainer:SetSize(200, 200)
	buttonContainer:SetPoint("TOPRIGHT", mainButton, "TOPLEFT", -5, 0)
	-- DiabolicUI style backdrop with border
	buttonContainer:SetBackdrop({
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
		edgeFile = GetMedia("border-tooltip"),
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 7, bottom = 7 }
	})
	-- Semi-transparent background (50% transparent = 0.5 alpha)
	buttonContainer:SetBackdropColor(0, 0, 0, 0.5)
	-- Border color matching DiabolicUI dark theme
	buttonContainer:SetBackdropBorderColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], 0.5)
	-- Set frame strata/level
	buttonContainer:SetFrameStrata("HIGH")
	buttonContainer:SetFrameLevel(5)
	buttonContainer:Hide()
end
-- Update visibility based on settings
MinimapButtons.UpdateVisibility = function(self)
	if not mainButton then return end
	if ns.db and ns.db.char and ns.db.char.minimapbuttons and ns.db.char.minimapbuttons.enabled then
		mainButton:Show()
	else
		mainButton:Hide()
		if buttonContainer then
			buttonContainer:Hide()
		end
		isContainerVisible = false
	end
end
MinimapButtons.OnInitialize = function(self)
	-- Check if minimap is disabled in settings
	if ns.db.global.minimap.disabled then
		return
	end
	-- Create UI elements
	self:CreateMainButton()
	self:CreateContainer()
	-- Set initial visibility
	self:UpdateVisibility()
end
MinimapButtons.OnEnable = function(self)
	if not ns.db or not ns.db.char or not ns.db.char.minimapbuttons or not ns.db.char.minimapbuttons.enabled then
		return
	end
	-- Delay collection to let other addons load
	C_Timer.After(2, function()
		self:CollectButtons()
	end)
	C_Timer.After(5, function()
		self:CollectButtons()
	end)
	C_Timer.After(10, function()
		self:CollectButtons()
	end)
	-- Register callback for settings updates
	if ns.RegisterCallback then
		ns.RegisterCallback(self, "MinimapButtons_Settings_Updated", "UpdateVisibility")
		ns.RegisterCallback(self, "MinimapButtons_MainButtonSize_Updated", "UpdateMainButtonSize")
	end
end
