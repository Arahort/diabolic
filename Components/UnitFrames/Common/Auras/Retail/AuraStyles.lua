--[[

	The MIT License (MIT)

	Copyright (c) 2022 Lars Norberg

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
if (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE) then
	return
end
ns.AuraStyles = ns.AuraStyles or {}
-- WoW 12.0.0: issecretvalue may not exist in older versions
local issecretvalue = issecretvalue or function() return false end

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

ns.AuraStyles.PlayerPostUpdateButton = function(self, button, unit, data, position)
	local element = self
	-- WoW 12.0.0: isHarmful can be secret in combat, use isHarmfulAura as fallback
	local isHarmful = data.isHarmfulAura or false
	if not issecretvalue(data.isHarmful) then
		isHarmful = data.isHarmful
	end
	button.isDebuff = isHarmful
	-- WoW 12.0.0: Store data for tooltips
	button.isHarmful = isHarmful
	button.auraInstanceID = data.auraInstanceID
	-- WoW 12.0.0: dispelName can be secret
	local debuffType = not issecretvalue(data.dispelName) and data.dispelName or nil
	-- Setup secure click to cancel buff/debuff (only out of combat)
	if data.name and not InCombatLockdown() and not issecretvalue(data.name) then
		button:SetAttribute("spell", data.name)
		button:SetAttribute("index", position)
	end
	-- Border Coloring
	local color
	if (isHarmful and element.showDebuffType) or (not isHarmful and element.showBuffType) or (element.showType) then
		color = (debuffType and Colors.debuff[debuffType]) or Colors.debuff.none
	else
		color = isHarmful and Colors.debuff.none or Colors.xp
	end
	if (color) then
		button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
		button.Bar:SetStatusBarColor(color[1], color[2], color[3])
	end
	-- Icon Coloring - always show player auras colored
	button.Icon:SetDesaturated(false)
	button.Icon:SetVertexColor(1, 1, 1)
end

ns.AuraStyles.TargetPostUpdateButton = function(self, button, unit, data, position)
	local element = self
	-- WoW 12.0.0: isHarmful can be secret in combat, use isHarmfulAura as fallback
	local isHarmful = data.isHarmfulAura or false
	if not issecretvalue(data.isHarmful) then
		isHarmful = data.isHarmful
	end
	button.isDebuff = isHarmful
	-- WoW 12.0.0: Store data for tooltips (used in Shared/AuraStyles.lua UpdateTooltip)
	button.isHarmful = isHarmful
	button.auraInstanceID = data.auraInstanceID
	-- WoW 12.0.0: dispelName can be secret
	local debuffType = not issecretvalue(data.dispelName) and data.dispelName or nil
	-- Setup secure click to cancel buff/debuff (only out of combat)
	if data.name and not InCombatLockdown() and not issecretvalue(data.name) then
		button:SetAttribute("spell", data.name)
		button:SetAttribute("index", position)
	end
	-- WoW 12.0.0: isStealable can be secret in combat - check before using
	local isStealable = not issecretvalue(data.isStealable) and data.isStealable or false
	if(not isHarmful and isStealable and element.showStealableBuffs and not UnitIsUnit("player", unit)) then
	end
	local color
	if (isHarmful and element.showDebuffType) or (not isHarmful and element.showBuffType) or (element.showType) then
		color = (debuffType and Colors.debuff[debuffType]) or Colors.debuff.none
	else
		color = Colors.verydarkgray
	end
	if (color) then
		button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
	end
	-- WoW 12.0.0: isPlayerAura can be secret in combat
	local isPlayerAura = not issecretvalue(data.isPlayerAura) and data.isPlayerAura or false
	if (isPlayerAura) then
		button.Icon:SetDesaturated(false)
		button.Icon:SetVertexColor(1, 1, 1)
	else
		button.Icon:SetDesaturated(true)
		button.Icon:SetVertexColor(.6, .6, .6)
	end
	-- WoW 12.0.0: Update stack counter using combat-safe API
	if button.Count and data.auraInstanceID then
		local countText = ""
		-- Try combat-safe API first (returns string like "2" or "" for 1 stack)
		if C_UnitAuras.GetAuraApplicationDisplayCount then
			local displayCount = C_UnitAuras.GetAuraApplicationDisplayCount(unit, data.auraInstanceID, 2, 1000)
			-- Check secret FIRST, then type, then empty
			if displayCount and not issecretvalue(displayCount) and type(displayCount) == "string" and displayCount ~= "" then
				countText = displayCount
			end
		end
		-- Fallback: use applications directly if not secret
		if countText == "" and data.applications and not issecretvalue(data.applications) and data.applications > 1 then
			countText = tostring(data.applications)
		end
		button.Count:SetText(countText)
	end
end

ns.AuraStyles.NameplatePostUpdateButton = function(self, button, unit, data, position)
	local element = self
	button.isDebuff = data.isHarmful
	local debuffType = data.dispelName

	-- Setup secure click to cancel buff/debuff
	if data.name then
		button:SetAttribute("spell", data.name)
		button:SetAttribute("index", position)
	end

	if(not button.isDebuff and data.isStealable and element.showStealableBuffs and not UnitIsUnit("player", unit)) then
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
