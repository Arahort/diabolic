local Addon, ns = ...
local ActionBars = ns:GetModule("ActionBars")
local KeyBound = LibStub("LibKeyBound-1.0")

-- Lua API
local select = select
local setmetatable = setmetatable
local string_format = string.format

-- WoW API
local AutoCastShine_AutoCastStart = AutoCastShine_AutoCastStart
local AutoCastShine_AutoCastStop = AutoCastShine_AutoCastStop
local CooldownFrame_Set = CooldownFrame_Set
local GetBindingKey = GetBindingKey
local GetBindingText = GetBindingText
local GetPetActionInfo = GetPetActionInfo
local GetPetActionCooldown = GetPetActionCooldown
local GetPetActionsUsable = GetPetActionsUsable
local InCombatLockdown = InCombatLockdown
local IsAltKeyDown = IsAltKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsModifiedClick = IsModifiedClick
local IsShiftKeyDown = IsShiftKeyDown
local PickupPetAction = PickupPetAction
local SetBinding = SetBinding
local SetDesaturation = SetDesaturation

ns.PetButtons = {}

-- Tooltip wrapper functions to preserve PetActionButtonTemplate tooltips
local onEnter = function(self)
	if (self.OnEnter) then
		self:OnEnter()
	end
end

local onLeave = function(self)
	if (self.OnLeave) then
		self:OnLeave()
	end
end

local PetButton = CreateFrame("CheckButton")
local PetButton_MT = { __index = PetButton }
ns.PetButton = PetButton

PetButton.Create = function(self, id, name, parent)

	local button = setmetatable(CreateFrame("CheckButton", name, parent, "PetActionButtonTemplate"), PetButton_MT)
	button.showgrid = 0
	button.id = id
	button.parent = parent

	button:SetID(id)
	button:SetAttribute("type", "pet")
	button:SetAttribute("action", id)
	button:SetAttribute("buttonLock", true)

	button:RegisterForDrag("LeftButton", "RightButton")
	if ns.IsRetail then
		button:RegisterForClicks("AnyUp", "AnyDown")
	else
		button:RegisterForClicks("AnyUp")
	end

	button:UnregisterAllEvents()
	button:SetScript("OnEvent", nil)

	-- Preserve original tooltip handlers from PetActionButtonTemplate
	button.OnEnter = button:GetScript("OnEnter")
	button.OnLeave = button:GetScript("OnLeave")

	-- Set wrapper functions that call original handlers
	button:SetScript("OnEnter", onEnter)
	button:SetScript("OnLeave", onLeave)
	button:SetScript("OnDragStart", PetButton.OnDragStart)
	button:SetScript("OnReceiveDrag", PetButton.OnReceiveDrag)

	ns.PetButtons[#ns.PetButtons + 1] = button

	return button
end

PetButton.Update = function(self)
	local name, texture, isToken, isActive, autoCastAllowed, autoCastEnabled, spellID = GetPetActionInfo(self.id)

	if (not isToken) then
		self.icon:SetTexture(texture)
		self.tooltipName = name
	else
		self.icon:SetTexture(_G[texture])
		self.tooltipName = _G[name]
	end

	self.isToken = isToken
	self:SetChecked(isActive)

	if self.AutoCastable and self.AutoCastShine then
		if (autoCastAllowed and not autoCastEnabled) then
			self.AutoCastable:Show()
			AutoCastShine_AutoCastStop(self.AutoCastShine)
		elseif (autoCastAllowed) then
			self.AutoCastable:Hide()
			AutoCastShine_AutoCastStart(self.AutoCastShine)
		else
			self.AutoCastable:Hide()
			AutoCastShine_AutoCastStop(self.AutoCastShine)
		end
	end

	if (texture) then
		if (GetPetActionsUsable()) then
			SetDesaturation(self.icon, nil)
		else
			SetDesaturation(self.icon, 1)
		end
		self.icon:Show()
		self:ShowButton()
	else
		self.icon:Hide()
		self:HideButton()
		if (self.showgrid == 0) then

		end
	end
	self:UpdateCooldown()
	self:UpdateHotkeys()
end

PetButton.UpdateCooldown = function(self)
	local start, duration, enable = GetPetActionCooldown(self.id)
	CooldownFrame_Set(self.cooldown, start, duration, enable)
end

PetButton.UpdateHotkeys = function(self)
	local key = self:GetHotkey() or ""
	local hotkey = self.HotKey
	if (key == "" or self.parent.config.hidehotkey) then
		hotkey:Hide()
	else
		hotkey:SetText(key)
		hotkey:Show()
	end
end

PetButton.ShowButton = function(self)
	self.pushedTexture:SetTexture(self.textureCache.pushed)
	self.highlightTexture:SetTexture(self.textureCache.highlight)
	self:SetAlpha(1)
end

PetButton.HideButton = function(self)
	self.textureCache.pushed = self.pushedTexture:GetTexture()
	self.textureCache.highlight = self.highlightTexture:GetTexture()

	self.pushedTexture:SetTexture("")
	self.highlightTexture:SetTexture("")

	if (self.showgrid == 0 and not self.parent.config.showgrid) then
		self:SetAlpha(0)
	end
end

PetButton.ShowGrid = function(self)
	self.showgrid = self.showgrid + 1
	self:SetAlpha(1)
end

PetButton.HideGrid = function(self)
	if (self.showgrid > 0) then
		self.showgrid = self.showgrid - 1
	end
	if (self.showgrid == 0) and not (GetPetActionInfo(self.id)) and (not self.parent.config.showgrid) then
		self:SetAlpha(0)
	end
end

PetButton.GetHotkey = function(self)
	local key = GetBindingKey(format("BONUSACTIONBUTTON%d", self.id)) or GetBindingKey("CLICK "..self:GetName()..":LeftButton")
	return key and KeyBound:ToShortKey(key)
end

PetButton.GetBindings = function(self)
	local keys, binding = ""

	binding = string_format("BONUSACTIONBUTTON%d", self.id)
	for i = 1, select("#", GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if (keys ~= "") then
			keys = keys .. ", "
		end
		keys = keys .. GetBindingText(hotKey,"KEY_")
	end

	binding = "CLICK "..self:GetName()..":LeftButton"
	for i = 1, select("#", GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if (keys ~= "") then
			keys = keys .. ", "
		end
		keys = keys.. GetBindingText(hotKey,"KEY_")
	end

	return keys
end

PetButton.SetKey = function(self, key)
	SetBinding(key, string_format("BONUSACTIONBUTTON%d", self.id))
end

PetButton.ClearBindings = function(self)
	local binding = string_format("BONUSACTIONBUTTON%d", self:GetID())
	while GetBindingKey(binding) do
		SetBinding(GetBindingKey(binding), nil)
	end

	binding = "CLICK "..self:GetName()..":LeftButton"
	while GetBindingKey(binding) do
		SetBinding(GetBindingKey(binding), nil)
	end
end

PetButton.OnDragStart = function(self)
	if InCombatLockdown() then
		return
	end
	if (IsAltKeyDown() and IsControlKeyDown() or IsShiftKeyDown()) or (IsModifiedClick("PICKUPACTION")) then
		self:SetChecked(false)
		PickupPetAction(self.id)
		self:Update()
	end
end

PetButton.OnReceiveDrag = function(self)
	if InCombatLockdown() then
		return
	end
	self:SetChecked(false)
	PickupPetAction(self.id)
	self:Update()
end
