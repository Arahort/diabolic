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

-- WoW 12.1: auras are displayed through AuraContainer and AuraButton intrinsics.
-- The container owns the aura data, creates the buttons and drives every widget
-- registered on them, so a button style is now purely about building widgets and
-- handing them over. Tooltips, stack counts, durations and buff cancelling are all
-- driven by the container, and addon script handlers on these buttons are forbidden.

-- Builds the shared look: masked icon, aura border, stack counter and cooldown spiral.
--
-- element - the aura element created through frame:CreateAuras()
-- options - group or slot options, falling back to element wide values
-- button  - the AuraButton to dress up
ns.AuraStyles.CreateButton = function(element, options, button)
	local size = options.size or element.size or 36
	button:SetSize(options.width or element.width or size, options.height or element.height or size)

	local icon = button:CreateTexture(nil, "BACKGROUND", nil, 1)
	icon:SetAllPoints()
	icon:SetMask(GetMedia("actionbutton-mask-square"))
	button.Icon = icon
	button:SetIcon(icon)

	local border = CreateFrame("Frame", nil, button, ns.BackdropTemplate)
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	local borderColor = options.borderColor or element.borderColor or Colors.verydarkgray
	border:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3])
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(button:GetFrameLevel() + 2)
	button.Border = border

	if (not (options.disableCooldown or element.disableCooldown)) then
		local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
		cooldown:SetAllPoints()
		cooldown:SetDrawEdge(false)
		cooldown:SetDrawSwipe(false)
		cooldown:SetHideCountdownNumbers(false)
		if (cooldown.SetCountdownFont) then
			cooldown:SetCountdownFont("DiabolicAuraCooldownFont")
		end
		button.Cooldown = cooldown
		button:SetDurationCooldown(cooldown)
	end

	-- The counter lives on the border frame so it renders above the cooldown spiral.
	local count = border:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(GetFont(options.countFontSize or element.countFontSize or 12, true))
	count:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 3)
	button.Count = count
	button:SetApplicationCount(count)

	-- Shows the dispel type as a small icon in the corner. The border itself is a
	-- backdrop, and the container can only recolor plain textures, so the dispel
	-- type is surfaced here instead of through the border color.
	if (options.showDispelType or element.showDispelType) then
		local dispelType = button:CreateTexture(nil, "OVERLAY", nil, 1)
		dispelType:SetPoint("CENTER", button, "TOPRIGHT", -2, -2)
		dispelType:SetSize(16, 16)
		button.DispelType = dispelType
		button:AddDispelTypeTexture(dispelType, {
			style = Enum.CustomAuraButtonDispelTypeTextureStyle.Icon,
			showWhenHarmful = true,
			showWhenHelpful = options.showDispelTypeOnBuffs or element.showDispelTypeOnBuffs or false,
		})
	end

	if (not (options.disableMouse or element.disableMouse)) then
		button:SetTooltipAnchorPoint(options.tooltipAnchor or element.tooltipAnchor or "ANCHOR_BOTTOMRIGHT")
		button:SetHideTooltipInCombat(options.tooltipHideInCombat or element.tooltipHideInCombat or false)
	else
		button:EnableMouse(false)
	end

	-- Right click to cancel is only meaningful on our own buffs, and the container
	-- is what performs the cancel now, so it is opt-in per group.
	local cancelButton = options.cancelButton or element.cancelButton
	if (cancelButton) then
		button:SetCancelAuraButtons(cancelButton)
	end

	if (element.PostCreateButton) then
		element:PostCreateButton(button, options)
	end
end

-- Resizes buttons that a group has already created. The container builds its
-- buttons through CreateButton once, so a size change from the settings has to be
-- applied to the existing ones by hand.
ns.AuraStyles.UpdateButtonSizes = function(element, groupKey, size)
	for index = 1, element:GetAuraGroupFrameCount(groupKey) do
		local button = element:GetAuraGroupFrame(groupKey, index)
		if (button) then
			button:SetSize(size, size)
		end
	end
end

-- Dims auras that were not cast by the player. Used as a PostCreateButton on the
-- groups that are filtered down to foreign auras, since the cast source is no
-- longer readable from Lua and has to be expressed as a filter instead.
ns.AuraStyles.PostCreateForeignButton = function(element, button)
	button.Icon:SetDesaturated(true)
	button.Icon:SetVertexColor(.6, .6, .6)
end
