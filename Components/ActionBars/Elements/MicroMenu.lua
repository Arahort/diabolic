local Addon, ns = ...
local ActionBars = ns:GetModule("ActionBars")
local MicroMenu = ActionBars:NewModule("MicroMenu", "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua API
local pairs = pairs
local ipairs = ipairs
local table_insert = table.insert
local math_max = math.max
local math_floor = math.floor

-- WoW API
local C_PetBattles = C_PetBattles
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local RegisterStateDriver = RegisterStateDriver

-- Addon API
local GetMedia = ns.API.GetMedia
local SetObjectScale = ns.API.SetUnitFramesObjectScale
local IsAddOnEnabled = ns.API.IsAddOnEnabled

-- Constants
local TOGGLE_SIZE = 48
local BUTTON_SPACING = 2
local PADDING_H = 8
local PADDING_V = 14

MicroMenu.GetButtonSize = function(self)
	local db = ns.db
	return (db and db.global.micromenu.buttonSize) or 34
end

MicroMenu.GetPosition = function(self)
	local db = ns.db
	local posX = (db and db.global.micromenu.positionX) or -11
	local posY = (db and db.global.micromenu.positionY) or 11
	return posX, posY
end

MicroMenu.ResizeButton = function(self, btn, targetSize)
	local nw, nh = btn.nativeWidth, btn.nativeHeight
	if (not nw or nw == 0) then
		nw, nh = 32, 40
	end
	local ratio = nw / nh
	local ew = math_floor(targetSize * ratio + 0.5)
	local eh = targetSize
	btn:SetScale(1)
	btn:SetSize(ew, eh)
	return ew, eh
end

MicroMenu.UpdateLayout = function(self)
	if (InCombatLockdown()) then
		self.needsLayout = true
		return
	end
	if (not self.bar or not self.bar.buttons) then return end
	local btnSize = self:GetButtonSize()
	local totalHeight = PADDING_V
	local visibleCount = 0
	for i, btn in ipairs(self.bar.buttons) do
		if (btn:IsShown()) then
			local ew, eh = self:ResizeButton(btn, btnSize)
			btn:ClearAllPoints()
			btn:SetPoint("BOTTOM", self.bar, "BOTTOM", 0, totalHeight)
			totalHeight = totalHeight + eh + BUTTON_SPACING
			visibleCount = visibleCount + 1
		end
	end
	if (visibleCount > 0) then
		totalHeight = totalHeight - BUTTON_SPACING
	end
	totalHeight = totalHeight + PADDING_V
	local barWidth = btnSize + PADDING_H * 2
	self.bar:SetSize(barWidth, totalHeight)
	if (self.toggle) then
		local posX, posY = self:GetPosition()
		self.toggle:ClearAllPoints()
		self.toggle:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", posX, posY)
	end
end

MicroMenu.InitializeMicroMenu = function(self)
	if (self.bar) then return end
	-- Discover micro buttons dynamically from Blizzard's MicroMenu frame
	local microButtons = {}
	if (_G.MicroMenu) then
		for _, child in pairs({ _G.MicroMenu:GetChildren() }) do
			if (child:IsObjectType("Button") and child:GetName()
				and child:GetName():find("MicroButton")) then
				table_insert(microButtons, child)
			end
		end
	end
	if (#microButtons == 0) then
		return
	end
	-- Menu container - FULLSCREEN_DIALOG so GameTooltip (TOOLTIP strata) renders on top
	local bar = CreateFrame("Frame", ns.Prefix.."MicroMenu", UIParent, "SecureHandlerStateTemplate")
	bar:SetFrameStrata("FULLSCREEN_DIALOG")
	bar:SetClampedToScreen(true)
	bar:Hide()
	self.bar = bar
	-- Dark backdrop with overshoot for border-tooltip edge art
	local backdrop = CreateFrame("Frame", nil, bar, ns.BackdropTemplate)
	backdrop:SetFrameLevel(bar:GetFrameLevel())
	backdrop:SetBackdrop({
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeSize = 32, edgeFile = GetMedia("border-tooltip"),
		tile = true,
		insets = { left = 8, right = 8, top = 16, bottom = 16 }
	})
	backdrop:SetBackdropColor(.05, .05, .05, .85)
	backdrop:SetPoint("TOPLEFT", bar, "TOPLEFT", -6, 6)
	backdrop:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 6, -6)
	bar.backdrop = backdrop
	-- Reparent and resize micro buttons vertically inside our container
	bar.buttons = {}
	local btnSize = self:GetButtonSize()
	local totalHeight = PADDING_V
	for i, btn in ipairs(microButtons) do
		-- Save native dimensions before any modifications
		btn.nativeWidth = btn:GetWidth()
		btn.nativeHeight = btn:GetHeight()
		-- Reparent to our bar
		btn:SetParent(bar)
		btn:SetHitRectInsets(0, 0, 0, 0)
		btn:SetFrameLevel(bar:GetFrameLevel() + 2)
		-- Strip all decorations, keep only the icon
		for _, region in pairs({ btn:GetRegions() }) do
			if (region:IsObjectType("Texture")) then
				local layer = region:GetDrawLayer()
				if (layer == "BACKGROUND" or layer == "BORDER") then
					region:SetAlpha(0)
				end
			end
		end
		if (btn.FlashBorder) then btn.FlashBorder:SetAlpha(0) end
		if (btn.FlashContent) then btn.FlashContent:SetAlpha(0) end
		if (btn.FlashTexture) then btn.FlashTexture:SetAlpha(0) end
		if (btn.Background) then btn.Background:SetAlpha(0) end
		if (btn.Highlight) then btn.Highlight:SetAlpha(0) end
		btn:SetAlpha(1)
		btn:Show()
		-- Resize to target size preserving aspect ratio
		local ew, eh = self:ResizeButton(btn, btnSize)
		btn:ClearAllPoints()
		btn:SetPoint("BOTTOM", bar, "BOTTOM", 0, totalHeight)
		totalHeight = totalHeight + eh + BUTTON_SPACING
		bar.buttons[#bar.buttons + 1] = btn
	end
	totalHeight = totalHeight - BUTTON_SPACING + PADDING_V
	-- Size the bar
	local barWidth = btnSize + PADDING_H * 2
	bar:SetSize(barWidth, totalHeight)
	-- Toggle button
	local posX, posY = self:GetPosition()
	local toggle = SetObjectScale(CreateFrame("CheckButton", ns.Prefix.."MicroMenuToggle", UIParent, "SecureHandlerClickTemplate"))
	toggle:SetFrameStrata("HIGH")
	toggle:RegisterForClicks("AnyUp")
	toggle:SetSize(TOGGLE_SIZE, TOGGLE_SIZE)
	toggle:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", posX, posY)
	self.toggle = toggle
	-- Anchor menu above toggle
	bar:SetPoint("BOTTOM", toggle, "TOP", 0, 4)
	-- Frame references for secure handler
	toggle:SetFrameRef("Bar", bar)
	-- Secure onclick - toggles menu visibility (works in combat)
	toggle:SetAttribute("_onclick", [[
		local bar = self:GetFrameRef("Bar")
		if (bar:IsShown()) then
			bar:Hide()
		else
			bar:Show()
		end
		self:RunMethod("UpdateTexture")
	]])
	-- Toggle textures
	toggle.texPlus = GetMedia("button-toggle-plus")
	toggle.texMinus = GetMedia("button-toggle-minus")
	local texture = toggle:CreateTexture(nil, "ARTWORK", nil, 0)
	texture:SetSize(64, 64)
	texture:SetPoint("CENTER")
	texture:SetTexture(toggle.texPlus)
	toggle.texture = texture
	-- Methods
	toggle.UpdateTexture = function(self)
		if (bar:IsShown()) then
			self.texture:SetTexture(self.texMinus)
		else
			self.texture:SetTexture(self.texPlus)
		end
		self:UpdateAlpha()
	end
	toggle.UpdateAlpha = function(self)
		if (self.mouseOver) or (bar:IsShown()) then
			self:SetAlpha(1)
		else
			self:SetAlpha(0.3)
		end
	end
	toggle.OnEnter = function(self)
		self.mouseOver = true
		self:UpdateAlpha()
	end
	toggle.OnLeave = function(self)
		self.mouseOver = nil
		self:UpdateAlpha()
	end
	toggle:SetScript("OnEnter", toggle.OnEnter)
	toggle:SetScript("OnLeave", toggle.OnLeave)
	-- Visibility driver - hide during pet battle / vehicle
	toggle:SetAttribute("_onstate-vis", [[
		if (not newstate) then
			return
		end
		if (newstate == "hide") then
			self:Hide()
			self:GetFrameRef("Bar"):Hide()
		else
			self:Show()
			self:RunMethod("UpdateTexture")
		end
	]])
	RegisterStateDriver(toggle, "state-vis", "[petbattle][possessbar][overridebar][vehicleui][@vehicle,exists]hide;show")
	-- Auto-hide: close menu when mouse leaves for 3 seconds
	local AUTO_HIDE_DELAY = 3
	local hideTimer = 0
	local function IsMouseOverWidget(widget)
		if (not widget:IsVisible()) then return false end
		local left, bottom, width, height = widget:GetRect()
		if (not left) then return false end
		local scale = widget:GetEffectiveScale()
		local x, y = GetCursorPosition()
		x, y = x / scale, y / scale
		return (x >= left and x <= left + width and y >= bottom and y <= bottom + height)
	end
	bar:SetScript("OnUpdate", function(self, elapsed)
		if (not self:IsShown()) then return end
		if (IsMouseOverWidget(self) or IsMouseOverWidget(toggle)) then
			hideTimer = 0
		else
			hideTimer = hideTimer + elapsed
			if (hideTimer >= AUTO_HIDE_DELAY) then
				hideTimer = 0
				if (not InCombatLockdown()) then
					self:Hide()
				end
			end
		end
	end)
	-- Sync texture when menu is hidden externally
	bar:HookScript("OnHide", function() toggle:UpdateTexture(); hideTimer = 0 end)
	bar:HookScript("OnShow", function() toggle:UpdateTexture(); hideTimer = 0 end)
	-- Initial state
	toggle:UpdateAlpha()
	-- Deferred relayout: Blizzard may hide some buttons after init (e.g. HelpMicroButton)
	C_Timer.After(0.5, function() self:UpdateLayout() end)
	-- Hook Blizzard's reparenting to reclaim buttons
	if (_G.MicroMenu) then
		self:SecureHook(_G.MicroMenu, "SetParent", "DeferReclaimButtons")
	end
	if (C_PetBattles) then
		self:RegisterEvent("PET_BATTLE_CLOSE", "DeferReclaimButtons")
	end
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnCombatEnd")
	ns.RegisterCallback(self, "MicroMenu_Settings_Updated", "OnSettingsUpdated")
end

MicroMenu.OnSettingsUpdated = function(self)
	self:UpdateLayout()
end

MicroMenu.ReclaimButtons = function(self)
	if (InCombatLockdown()) then
		self.needsReclaim = true
		return
	end
	if (not self.bar or not self.bar.buttons) then return end
	local btnSize = self:GetButtonSize()
	local totalHeight = PADDING_V
	local visibleCount = 0
	for i, btn in ipairs(self.bar.buttons) do
		if (btn:GetParent() ~= self.bar) then
			btn:SetParent(self.bar)
		end
		btn:SetHitRectInsets(0, 0, 0, 0)
		btn:SetFrameLevel(self.bar:GetFrameLevel() + 2)
		btn:SetAlpha(1)
		if (btn:IsShown()) then
			local ew, eh = self:ResizeButton(btn, btnSize)
			btn:ClearAllPoints()
			btn:SetPoint("BOTTOM", self.bar, "BOTTOM", 0, totalHeight)
			totalHeight = totalHeight + eh + BUTTON_SPACING
			visibleCount = visibleCount + 1
		end
	end
	if (visibleCount > 0) then
		totalHeight = totalHeight - BUTTON_SPACING
	end
	totalHeight = totalHeight + PADDING_V
	local barWidth = btnSize + PADDING_H * 2
	self.bar:SetSize(barWidth, totalHeight)
end

MicroMenu.DeferReclaimButtons = function(self)
	if (InCombatLockdown()) then
		self.needsReclaim = true
		return
	end
	self:ReclaimButtons()
end

MicroMenu.OnCombatEnd = function(self)
	if (self.needsReclaim) then
		self.needsReclaim = nil
		self:ReclaimButtons()
	end
	if (self.needsLayout) then
		self.needsLayout = nil
		self:UpdateLayout()
	end
end

MicroMenu.OnInitialize = function(self)
	local db = ns:GetSettings()
	if (not db.global.micromenu.enableMicroMenu) then
		return self:Disable()
	end
	if (IsAddOnEnabled("ConsolePort")) then
		return self:Disable()
	end
	if (IsAddOnEnabled("Bartender4") and not ns.BartenderHandled) then
		ns.RegisterCallback(self, "Bartender_Handled", "InitializeMicroMenu")
	else
		self:InitializeMicroMenu()
	end
end
