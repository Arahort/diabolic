local Addon, ns = ...
ns.AuraStyles = ns.AuraStyles or {}

-- Addon API
local Colors = ns.Colors

-- Create custom font object for aura cooldown timers with small size
if not DiabolicAuraCooldownFont then
	DiabolicAuraCooldownFont = CreateFont("DiabolicAuraCooldownFont")
	-- Use Arial Narrow (compact and supports Cyrillic) with size 9
	DiabolicAuraCooldownFont:SetFont("Fonts\\ARIALN.ttf", 9, "OUTLINE")
	DiabolicAuraCooldownFont:SetShadowColor(0, 0, 0, 1)
	DiabolicAuraCooldownFont:SetShadowOffset(1, -1)
end
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

local UpdateTooltip = function(self)
	if (GameTooltip:IsForbidden()) then return end
	if (ns.IsWrath) then
		GameTooltip:SetUnitAura(self:GetParent().__owner.unit, self:GetID(), self.filter)
	else
		if (self.isHarmful) then
			GameTooltip:SetUnitDebuffByAuraInstanceID(self:GetParent().__owner.unit, self.auraInstanceID)
		else
			GameTooltip:SetUnitBuffByAuraInstanceID(self:GetParent().__owner.unit, self.auraInstanceID)
		end
	end
end

local OnEnter = function(self)
	if (GameTooltip:IsForbidden() or not self:IsVisible()) then return end
	-- Avoid parenting GameTooltip to frames with anchoring restrictions,
	-- otherwise it'll inherit said restrictions which will cause issues with
	-- its further positioning, clamping, etc
	GameTooltip:SetOwner(self, self:GetParent().__restricted and "ANCHOR_CURSOR" or self:GetParent().tooltipAnchor)
	self:UpdateTooltip()
end

local OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

local OnClick = function(self, button, down)
	if (button == "RightButton") and (not InCombatLockdown()) then
		local unit = self:GetParent().__owner.unit
		if (not self.isDebuff) and (UnitExists(unit)) then
			CancelUnitBuff(unit, self:GetID(), self.filter)
		end
	end
end

-- WoW 12.0.0: Non-secure version for player buffs/debuffs to avoid ADDON_ACTION_BLOCKED in combat
-- Player can't cancel buffs in combat anyway, so no need for SecureActionButton
ns.AuraStyles.CreateButtonWithBar_NonSecure = function(element, position)
	-- Regular Button instead of SecureActionButtonTemplate
	local aura = CreateFrame("Button", element:GetDebugName() .. "Button" .. position, element)
	aura:RegisterForClicks("RightButtonUp")
	-- Use OnClick handler instead of secure attributes
	aura:SetScript("OnClick", OnClick)

	local icon = aura:CreateTexture(nil, "BACKGROUND", nil, 1)
	icon:SetAllPoints()
	icon:SetMask(GetMedia("actionbutton-mask-square"))
	aura.Icon = icon

	local border = CreateFrame("Frame", nil, aura, ns.BackdropTemplate)
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	border:SetBackdropBorderColor(Colors.xp[1], Colors.xp[2], Colors.xp[3])
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(aura:GetFrameLevel() + 2)
	aura.Border = border

	local count = aura.Border:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(GetFont(14,true))
	count:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	count:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", -2, 3)
	aura.Count = count

	-- WoW 12.0.0: Create real CooldownFrame for SetCooldownFromDurationObject support
	local cd = CreateFrame("Cooldown", nil, aura, "CooldownFrameTemplate")
	cd:SetAllPoints()
	cd:SetDrawEdge(false)
	cd:SetDrawSwipe(false)
	cd:SetHideCountdownNumbers(false)
	-- Set countdown font - use custom Morpheus font for compact display
	if cd.SetCountdownFont then
		cd:SetCountdownFont("DiabolicAuraCooldownFont")
	end
	aura.Cooldown = cd

	local bar = element.__owner:CreateBar(nil, aura)
	bar:SetPoint("TOP", aura, "BOTTOM", 0, 0)
	bar:SetPoint("LEFT", aura, "LEFT", 1, 0)
	bar:SetPoint("RIGHT", aura, "RIGHT", -1, 0)
	bar:SetHeight(6)
	bar:SetStatusBarTexture(GetMedia("bar-small"))
	bar.bg = bar:CreateTexture(nil, "BACKGROUND", nil, -7)
	bar.bg:SetPoint("TOPLEFT", -1, 1)
	bar.bg:SetPoint("BOTTOMRIGHT", 1, -1)
	bar.bg:SetColorTexture(.05, .05, .05, .85)
	aura.Bar = bar

	-- WoW 12.0.0: Hook real cooldown to update bar
	ns.Widgets.RegisterCooldown(cd, bar)

	-- Replacing oUF's aura tooltips, as they are not secure.
	if (not element.disableMouse) then
		aura.UpdateTooltip = UpdateTooltip
		aura:SetScript("OnEnter", OnEnter)
		aura:SetScript("OnLeave", OnLeave)
	end

	return aura
end

ns.AuraStyles.CreateButtonWithBar = function(element, position)
	local aura = CreateFrame("Button", element:GetDebugName() .. "Button" .. position, element, "SecureActionButtonTemplate")
	aura:RegisterForClicks("RightButtonUp")
	aura:SetAttribute("type", "cancelaura")
	aura:SetAttribute("unit", element.__owner.unit)

	local icon = aura:CreateTexture(nil, "BACKGROUND", nil, 1)
	icon:SetAllPoints()
	icon:SetMask(GetMedia("actionbutton-mask-square"))
	aura.Icon = icon

	local border = CreateFrame("Frame", nil, aura, ns.BackdropTemplate)
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	border:SetBackdropBorderColor(Colors.xp[1], Colors.xp[2], Colors.xp[3])
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(aura:GetFrameLevel() + 2)
	aura.Border = border

	local count = aura.Border:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(GetFont(14,true))
	count:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	count:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", -2, 3)
	aura.Count = count

	-- WoW 12.0.0: Create real CooldownFrame for SetCooldownFromDurationObject support
	local cd = CreateFrame("Cooldown", nil, aura, "CooldownFrameTemplate")
	cd:SetAllPoints()
	cd:SetDrawEdge(false)
	cd:SetDrawSwipe(false)
	cd:SetHideCountdownNumbers(false)
	-- Set countdown font - use custom Morpheus font for compact display
	if cd.SetCountdownFont then
		cd:SetCountdownFont("DiabolicAuraCooldownFont")
	end
	aura.Cooldown = cd

	local bar = element.__owner:CreateBar(nil, aura)
	bar:SetPoint("TOP", aura, "BOTTOM", 0, 0)
	bar:SetPoint("LEFT", aura, "LEFT", 1, 0)
	bar:SetPoint("RIGHT", aura, "RIGHT", -1, 0)
	bar:SetHeight(6)
	bar:SetStatusBarTexture(GetMedia("bar-small"))
	bar.bg = bar:CreateTexture(nil, "BACKGROUND", nil, -7)
	bar.bg:SetPoint("TOPLEFT", -1, 1)
	bar.bg:SetPoint("BOTTOMRIGHT", 1, -1)
	bar.bg:SetColorTexture(.05, .05, .05, .85)
	aura.Bar = bar

	-- WoW 12.0.0: Hook real cooldown to update bar
	ns.Widgets.RegisterCooldown(cd, bar)

	-- Replacing oUF's aura tooltips, as they are not secure.
	if (not element.disableMouse) then
		aura.UpdateTooltip = UpdateTooltip
		aura:SetScript("OnEnter", OnEnter)
		aura:SetScript("OnLeave", OnLeave)
	end

	return aura
end

ns.AuraStyles.CreateButton = function(element, position)
	local aura = CreateFrame("Button", element:GetDebugName() .. "Button" .. position, element, "SecureActionButtonTemplate")
	aura:RegisterForClicks("RightButtonUp")
	aura:SetAttribute("type", "cancelaura")
	aura:SetAttribute("unit", element.__owner.unit)

	local icon = aura:CreateTexture(nil, "BACKGROUND", nil, 1)
	icon:SetAllPoints()
	icon:SetMask(GetMedia("actionbutton-mask-square"))
	aura.Icon = icon

	local border = CreateFrame("Frame", nil, aura, ns.BackdropTemplate)
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	border:SetBackdropBorderColor(Colors.xp[1], Colors.xp[2], Colors.xp[3])
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(aura:GetFrameLevel() + 2)
	aura.Border = border

	local count = aura.Border:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(GetFont(12,true))
	count:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	count:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", -2, 3)
	aura.Count = count

	-- WoW 12.0.0: Create real CooldownFrame for SetCooldownFromDurationObject support
	local cd = CreateFrame("Cooldown", nil, aura, "CooldownFrameTemplate")
	cd:SetAllPoints()
	cd:SetDrawEdge(false)
	cd:SetDrawSwipe(false)
	cd:SetHideCountdownNumbers(false)
	-- Set countdown font - use custom Morpheus font for compact display
	if cd.SetCountdownFont then
		cd:SetCountdownFont("DiabolicAuraCooldownFont")
	end
	aura.Cooldown = cd

	-- Replacing oUF's aura tooltips, as they are not secure.
	if (not element.disableMouse) then
		aura.UpdateTooltip = UpdateTooltip
		aura:SetScript("OnEnter", OnEnter)
		aura:SetScript("OnLeave", OnLeave)
	end

	return aura
end

-- WoW 12.0.0: Non-secure version of CreateButton for Target auras
-- Target auras can't be cancelled anyway, so no need for SecureActionButton
ns.AuraStyles.CreateButton_NonSecure = function(element, position)
	local aura = CreateFrame("Button", element:GetDebugName() .. "Button" .. position, element)
	aura:RegisterForClicks("RightButtonUp")

	local icon = aura:CreateTexture(nil, "BACKGROUND", nil, 1)
	icon:SetAllPoints()
	icon:SetMask(GetMedia("actionbutton-mask-square"))
	aura.Icon = icon

	local border = CreateFrame("Frame", nil, aura, ns.BackdropTemplate)
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	border:SetBackdropBorderColor(Colors.xp[1], Colors.xp[2], Colors.xp[3])
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(aura:GetFrameLevel() + 2)
	aura.Border = border

	local count = aura.Border:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(GetFont(12,true))
	count:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	count:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", -2, 3)
	aura.Count = count

	-- WoW 12.0.0: Create real CooldownFrame for SetCooldownFromDurationObject support
	local cd = CreateFrame("Cooldown", nil, aura, "CooldownFrameTemplate")
	cd:SetAllPoints()
	cd:SetDrawEdge(false)
	cd:SetDrawSwipe(false)
	cd:SetHideCountdownNumbers(false)
	if cd.SetCountdownFont then
		cd:SetCountdownFont("DiabolicAuraCooldownFont")
	end
	aura.Cooldown = cd

	-- Replacing oUF's aura tooltips
	if (not element.disableMouse) then
		aura.UpdateTooltip = UpdateTooltip
		aura:SetScript("OnEnter", OnEnter)
		aura:SetScript("OnLeave", OnLeave)
	end

	return aura
end
