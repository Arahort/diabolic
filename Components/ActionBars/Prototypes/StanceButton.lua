local Addon, ns = ...
local ActionBars = ns:GetModule("ActionBars")
local KeyBound = LibStub("LibKeyBound-1.0")

-- Lua API
local getmetatable = getmetatable
local pairs = pairs
local setmetatable = setmetatable
local type = type

-- WoW API
local CreateFrame = CreateFrame
local GetBindingKey = GetBindingKey
local GetShapeshiftFormCooldown = GetShapeshiftFormCooldown
local GetShapeshiftFormInfo = GetShapeshiftFormInfo

-- StanceButton Template
local Button = CreateFrame("CheckButton")
local Button_MT = {__index = Button}

ns.StanceButtons = {}
ns.StanceButton = Button

Button.Create = function(self, id, name, parent)

	local button = setmetatable(CreateFrame("CheckButton", name, parent, "StanceButtonTemplate"), Button_MT)
	button.id = id
	button.parent = parent

	button:Hide()
	button:SetID(id)
	button:SetScript("OnEnter", Button.OnEnter)
	button:SetScript("OnLeave", Button.OnLeave)

	ns.StanceButtons[button] = true

	return button
end

Button.OnEnter = function(self)
	if (GameTooltip:IsForbidden()) then
		return
	end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:SetShapeshift(self:GetID())

	self.UpdateTooltip = self.OnEnter
end

Button.OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then
		return
	end
	self.UpdateTooltip = nil
	GameTooltip:Hide()
end

Button.Update = function(self)
	if (not self:IsShown()) then
		return
	end
	local id = self:GetID()
	local texture, isActive, isCastable, spellID = GetShapeshiftFormInfo(id)

	self.icon:SetTexture(texture)

	if (texture) then
		self.cooldown:Show()
	else
		self.cooldown:Hide()
	end

	local start, duration, enable = GetShapeshiftFormCooldown(id)
	self.cooldown:SetCooldown(start, duration)

	if (isActive) then
		self:SetChecked(true)
	else
		self:SetChecked(false)
	end

	if (isCastable) then
		self.icon:SetVertexColor(1, 1, 1)
	else
		self.icon:SetVertexColor(.4, .4, .4)
	end

	self:UpdateHotkeys()

end

Button.UpdateHotkeys = function(self)
	local key = self:GetHotkey() or ""
	local hotkey = self.HotKey

	if key == "" or self.hidehotkey then
		hotkey:Hide()
	else
		hotkey:SetText(key)
		hotkey:Show()
	end
end

Button.GetHotkey = function(self)
	local key = GetBindingKey(format("SHAPESHIFTBUTTON%d", self:GetID()))
	return key and KeyBound:ToShortKey(key)
end

