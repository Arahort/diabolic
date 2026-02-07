local Addon, ns = ...
-- This file is only loaded in Classic (NOT in Retail)
if (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) then
	return
end
ns.AuraStyles = ns.AuraStyles or {}

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

ns.AuraStyles.PlayerPostUpdateButton = function(element, unit, button, index, position, duration, expiration, debuffType, isStealable)

	local color
	if (button.isDebuff) then
		color = debuffType and Colors.debuff[debuffType] or Colors.debuff.none
	else
		color = button.isDebuff and Colors.debuff.none or Colors.xp
	end

	if (color) then
		if button.Border and button.Border.SetBackdropBorderColor then
			button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
		end
		if button.Bar then
			button.Bar:SetStatusBarColor(color[1], color[2], color[3])
		end
	end

	if button.Icon then
		if (button.isPlayer or button.isDebuff) then
			button.Icon:SetDesaturated(false)
			button.Icon:SetVertexColor(1, 1, 1)
		else
			button.Icon:SetDesaturated(true)
			button.Icon:SetVertexColor(.6, .6, .6)
		end
	end

end

ns.AuraStyles.TargetPostUpdateButton = function(element, unit, button, index, position, duration, expiration, debuffType, isStealable)

	if(not button.isDebuff and isStealable and element.showStealableBuffs and not UnitIsUnit("player", unit)) then
	end

	local color
	if (button.isDebuff and element.showDebuffType) or (not button.isDebuff and element.showBuffType) or (element.showType) then
		color = Colors.debuff[debuffType] or Colors.debuff.none
	else
		color = Colors.verydarkgray
	end
	if (color) then
		if button.Border and button.Border.SetBackdropBorderColor then
			button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
		end
	end

	if button.Icon then
		if (button.isPlayer) then
			button.Icon:SetDesaturated(false)
			button.Icon:SetVertexColor(1, 1, 1)
		else
			button.Icon:SetDesaturated(true)
			button.Icon:SetVertexColor(.6, .6, .6)
		end
	end

end

ns.AuraStyles.NameplatePostUpdateButton = function(element, unit, button, index, position, duration, expiration, debuffType, isStealable)

	if(not button.isDebuff and isStealable and element.showStealableBuffs and not UnitIsUnit("player", unit)) then
	end

	local color
	if (button.isDebuff and element.showDebuffType) or (not button.isDebuff and element.showBuffType) or (element.showType) then
		color = Colors.debuff[debuffType] or Colors.debuff.none
	else
		color = Colors.verydarkgray
	end

	if (color) then
		button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
	end

end
