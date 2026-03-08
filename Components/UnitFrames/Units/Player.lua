local Addon, ns = ...
local UnitStyles = ns.UnitStyles
if (not UnitStyles) then
	return
end

-- Lua API
local math_pi = math.pi
local next = next
local select = select
local unpack = unpack

-- WoW API
local CreateFrame = CreateFrame

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local IsAddOnEnabled = ns.API.IsAddOnEnabled
local SetObjectScale = ns.API.SetUnitFramesObjectScale
local noop = ns.Noop

-- Constants
local playerClass = ns.PlayerClass
local useAzeriteClassPower = false

-- AzeriteUI-style ClassPower Layout Data
--------------------------------------------
local toRadians = function(d) return d * (math_pi / 180) end
local AzeriteClassPowerLayouts = {
	Stagger = {
		[1] = {
			Position = { "TOPLEFT", 62, -109 },
			Size = { 13, 13 }, BackdropSize = { 60, 60 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = toRadians(5)
		},
		[2] = {
			Position = { "TOPLEFT", 41, -58 },
			Size = { 39, 40 }, BackdropSize = { 80, 80 },
			Texture = GetMedia("point_hearth"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = nil
		},
		[3] = {
			Position = { "TOPLEFT", 64, -36 },
			Size = { 13, 13 }, BackdropSize = { 60, 60 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = nil
		}
	},
	ArcaneCharges = {
		[1] = {
			Position = { "TOPLEFT", 78, -139 },
			Size = { 13, 13 }, BackdropSize = { 58, 58 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = toRadians(6)
		},
		[2] = {
			Position = { "TOPLEFT", 57, -111 },
			Size = { 13, 13 }, BackdropSize = { 60, 60 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = toRadians(5)
		},
		[3] = {
			Position = { "TOPLEFT", 49, -76 },
			Size = { 13, 13 }, BackdropSize = { 60, 60 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = toRadians(4)
		},
		[4] = {
			Position = { "TOPLEFT", 72, -33 },
			Size = { 51, 52 }, BackdropSize = { 104, 104 },
			Texture = GetMedia("point_hearth"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = nil
		}
	},
	ComboPoints = {
		[1] = {
			Position = { "TOPLEFT", 82, -137 },
			Size = { 13, 13 }, BackdropSize = { 58, 58 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = toRadians(6)
		},
		[2] = {
			Position = { "TOPLEFT", 64, -111 },
			Size = { 13, 13 }, BackdropSize = { 60, 60 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = toRadians(5)
		},
		[3] = {
			Position = { "TOPLEFT", 54, -79 },
			Size = { 13, 13 }, BackdropSize = { 60, 60 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = toRadians(4)
		},
		[4] = {
			Position = { "TOPLEFT", 60, -44 },
			Size = { 13, 13 }, BackdropSize = { 60, 60 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = nil
		},
		[5] = {
			Position = { "TOPLEFT", 82, -11 },
			Size = { 14, 21 }, BackdropSize = { 82, 96 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_diamond"),
			PointRotation = toRadians(1)
		}
	},
	Chi = {
		[1] = {
			Position = { "TOPLEFT", 82, -137 },
			Size = { 13, 13 }, BackdropSize = { 58, 58 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = toRadians(6)
		},
		[2] = {
			Position = { "TOPLEFT", 62, -109 },
			Size = { 13, 13 }, BackdropSize = { 60, 60 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = toRadians(5)
		},
		[3] = {
			Position = { "TOPLEFT", 51, -73 },
			Size = { 39, 40 }, BackdropSize = { 80, 80 },
			Texture = GetMedia("point_hearth"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = nil
		},
		[4] = {
			Position = { "TOPLEFT", 64, -36 },
			Size = { 13, 13 }, BackdropSize = { 60, 60 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = nil
		},
		[5] = {
			Position = { "TOPLEFT", 82, -9 },
			Size = { 13, 13 }, BackdropSize = { 60, 60 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = nil
		}
	},
	SoulShards = {
		[1] = {
			Position = { "TOPLEFT", 82, -137 },
			Size = { 12, 12 }, BackdropSize = { 54, 54 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = toRadians(6)
		},
		[2] = {
			Position = { "TOPLEFT", 64, -111 },
			Size = { 13, 13 }, BackdropSize = { 60, 60 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_plate"),
			PointRotation = toRadians(5)
		},
		[3] = {
			Position = { "TOPLEFT", 50, -80 },
			Size = { 11, 15 }, BackdropSize = { 65, 60 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_diamond"),
			PointRotation = toRadians(3)
		},
		[4] = {
			Position = { "TOPLEFT", 58, -44 },
			Size = { 12, 18 }, BackdropSize = { 78, 79 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_diamond"),
			PointRotation = toRadians(3)
		},
		[5] = {
			Position = { "TOPLEFT", 82, -11 },
			Size = { 14, 21 }, BackdropSize = { 82, 96 },
			Texture = GetMedia("point_crystal"), BackdropTexture = GetMedia("point_diamond"),
			PointRotation = toRadians(1)
		}
	},
	Runes = {
		[1] = {
			Position = { "TOPLEFT", 82, -131 },
			Size = { 28, 28 }, BackdropSize = { 58, 58 },
			Texture = GetMedia("point_rune2"), BackdropTexture = GetMedia("point_dk_block"),
			PointRotation = nil
		},
		[2] = {
			Position = { "TOPLEFT", 58, -107 },
			Size = { 28, 28 }, BackdropSize = { 68, 68 },
			Texture = GetMedia("point_rune4"), BackdropTexture = GetMedia("point_dk_block"),
			PointRotation = nil
		},
		[3] = {
			Position = { "TOPLEFT", 32, -83 },
			Size = { 30, 30 }, BackdropSize = { 74, 74 },
			Texture = GetMedia("point_rune1"), BackdropTexture = GetMedia("point_dk_block"),
			PointRotation = nil
		},
		[4] = {
			Position = { "TOPLEFT", 65, -64 },
			Size = { 28, 28 }, BackdropSize = { 68, 68 },
			Texture = GetMedia("point_rune3"), BackdropTexture = GetMedia("point_dk_block"),
			PointRotation = nil
		},
		[5] = {
			Position = { "TOPLEFT", 39, -38 },
			Size = { 32, 32 }, BackdropSize = { 78, 78 },
			Texture = GetMedia("point_rune2"), BackdropTexture = GetMedia("point_dk_block"),
			PointRotation = nil
		},
		[6] = {
			Position = { "TOPLEFT", 79, -10 },
			Size = { 40, 40 }, BackdropSize = { 98, 98 },
			Texture = GetMedia("point_rune1"), BackdropTexture = GetMedia("point_dk_block"),
			PointRotation = nil
		}
	}
}
local AzeriteCaseColor = { 211/255, 200/255, 169/255 }
local AzeriteSlotColor = { 130/255 * .3, 133/255 * .3, 130/255 * .3, 2/3 }
local AzeriteSlotOffset = 1.5
local AzeriteRoundCaseTexture = GetMedia("point_plate")
local AzeriteRoundFillTexture = [[Interface\CHARACTERFRAME\TempPortraitAlphaMask]]
local AzeriteRoundFillScale = 0.125

-- Element Callbacks
--------------------------------------------
-- Forceupdate health prediction on health updates,
-- to assure our smoothed elements are properly aligned.
local Health_PostUpdate = function(element, unit, cur, max)
	local predict = element.__owner.HealthPrediction
	if (predict) then
		predict:ForceUpdate()
	end
end

-- Update the health preview color on health color updates.
local Health_PostUpdateColor = function(element, unit, r, g, b)
	-- Don't override custom colors
	if ns.db.char.orbs and ns.db.char.orbs.useCustomColors then
		return
	end
	-- WoW 12.0.0: oUF now passes ColorMixin objects instead of r,g,b numbers
	if type(r) == "table" and r.GetRGB then
		r, g, b = r:GetRGB()
	end
	-- WoW 12.0.0: Set color for health orb itself (oUF doesn't do it for orbs)
	if r and g and b then
		element:SetStatusBarColor(r, g, b)
	end
	local preview = element.Preview
	if (preview and r and g and b) then
		preview:SetStatusBarColor(r * .7, g * .7, b * .7)
	end
end

-- Align our custom health prediction texture
-- based on the plugin's provided values.
local HealPredict_PostUpdate = function(element, unit, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, hasOverAbsorb, hasOverHealAbsorb, curHealth, maxHealth)

	-- WoW 12.0.0: issecretvalue may not exist in older versions
	local issecretvalue = issecretvalue or function() return false end

	-- WoW 12.0.0: Calculator API may return secret values - convert to 0 if secret
	if issecretvalue(myIncomingHeal) then myIncomingHeal = 0 end
	if issecretvalue(otherIncomingHeal) then otherIncomingHeal = 0 end
	if issecretvalue(absorb) then absorb = 0 end
	if issecretvalue(healAbsorb) then healAbsorb = 0 end
	if issecretvalue(curHealth) then curHealth = 0 end
	if issecretvalue(maxHealth) then maxHealth = 1 end

	-- Provide defaults if values are nil
	myIncomingHeal = myIncomingHeal or 0
	otherIncomingHeal = otherIncomingHeal or 0
	healAbsorb = healAbsorb or 0

	local allIncomingHeal = myIncomingHeal + otherIncomingHeal
	local allNegativeHeals = healAbsorb
	local showPrediction, change

	if curHealth and maxHealth and ((allIncomingHeal > 0) or (allNegativeHeals > 0)) and (maxHealth > 0) then
		local startPoint = curHealth/maxHealth

		-- Dev switch to test absorbs with normal healing
		--allIncomingHeal, allNegativeHeals = allNegativeHeals, allIncomingHeal

		-- Hide predictions if the change is very small, or if the unit is at max health.
		change = (allIncomingHeal - allNegativeHeals)/maxHealth
		if ((curHealth < maxHealth) and (change > (element.health.predictThreshold or .05))) then
			local endPoint = startPoint + change

			-- Crop heal prediction overflows
			if (endPoint > 1) then
				endPoint = 1
				change = endPoint - startPoint
			end

			-- Crop heal absorb overflows
			if (endPoint < 0) then
				endPoint = 0
				change = -startPoint
			end

			-- This shouldn't happen, but let's do it anyway.
			if (startPoint ~= endPoint) then
				showPrediction = true
			end
		end
	end

	if (showPrediction) then

		local preview = element.preview
		local min,max = preview:GetMinMaxValues()
		local anchor = preview:GetValue() / max
		local texture = preview:GetStatusBarTexture()
		local width, height = preview:GetSize()

		if (change > 0) then
			element:ClearAllPoints()
			element:SetPoint("BOTTOM", texture, "BOTTOM", 0, anchor * height)
			element:SetSize(width, change*height)
			element:SetTexCoord(0, 1, 1 - anchor - change, 1 - anchor)
			element:SetVertexColor(0, .7, 0, .25)
			element:Show()

		elseif (change < 0) then
			element:ClearAllPoints()
			element:SetPoint("BOTTOM", texture, "BOTTOM", 0, (anchor - change) * height)
			element:SetSize(width, -change*height)
			element:SetTexCoord(0, 1, 1 - anchor, 1 - anchor - change)
			element:SetVertexColor(.25, 0, 0, .75)
			element:Show()

		else
			element:Hide()
		end
	else
		element:Hide()
	end

end

local Cast_CustomDelayText = function(element, duration)
	if (element.casting) then
		duration = element.max - duration
	end
	--element.Time:SetFormattedText("%.1f |cffff0000%s%.2f|r", duration, element.casting and "+" or "-", element.delay)
	element.Time:SetFormattedText("%.1f", duration)
	element.Delay:SetFormattedText("|cffff0000%s%.2f|r", element.casting and "+" or "-", element.delay)
end

local Cast_CustomTimeText = function(element, duration)
	if (element.casting) then
		duration = element.max - duration
	end
	element.Time:SetFormattedText("%.1f", duration)
	element.Delay:SetText()
end

-- Update cast bar color to indicate protected casts.
local Cast_UpdateInterruptible = function(element, unit)
	if (element.notInterruptible) then
		element:SetStatusBarColor(unpack(Colors.red))
	else
		element:SetStatusBarColor(unpack(Colors.cast))
	end
end

-- Show castbar frame when casting starts
local Cast_PostCastStart = function(element, unit)
	if (element.frame) then
		element.frame:Show()
	end
	Cast_UpdateInterruptible(element, unit)
end

-- Hide castbar frame when casting stops
local Cast_PostCastStop = function(element, unit)
	if (element.frame) then
		element.frame:Hide()
	end
end

-- Hide castbar frame when casting fails
local Cast_PostCastFail = function(element, unit)
	if (element.frame) then
		element.frame:Hide()
	end
end

-- AzeriteUI-style ClassPower Callbacks
--------------------------------------------
local AzeriteApplyPointLayout = function(point, info, parent)
	local rotation = info.PointRotation or 0
	point.case:SetSize(unpack(info.BackdropSize))
	point.case:SetTexture(info.BackdropTexture)
	point.case:SetRotation(rotation)
	if (info.BackdropTexture == AzeriteRoundCaseTexture) then
		local caseW, caseH = info.BackdropSize[1], info.BackdropSize[2]
		local fillSize = math.min(caseW, caseH) * AzeriteRoundFillScale
		local origW, origH = info.Size[1], info.Size[2]
		local centerX = info.Position[2] + origW / 2
		local centerY = info.Position[3] - origH / 2
		point:ClearAllPoints()
		point:SetPoint("CENTER", parent, "TOPLEFT", centerX, centerY)
		point:SetSize(fillSize, fillSize)
		point:SetStatusBarTexture(AzeriteRoundFillTexture)
		point.slot:SetTexture(AzeriteRoundFillTexture)
		point.slot:SetRotation(0)
	else
		point:ClearAllPoints()
		point:SetPoint(unpack(info.Position))
		point:SetSize(unpack(info.Size))
		point:SetStatusBarTexture(info.Texture)
		point:GetStatusBarTexture():SetRotation(rotation)
		point.slot:SetTexture(info.Texture)
		point.slot:SetRotation(rotation)
	end
end
local AzeriteClassPower_CreatePoint = function(self)
	local point = CreateFrame("StatusBar", nil, self)
	point:SetOrientation("VERTICAL")
	point:SetReverseFill(false)
	point:SetStatusBarTexture(GetMedia("point_crystal"))
	point:SetStatusBarColor(1, 1, 1)
	point:SetMinMaxValues(0, 1)
	point:SetValue(1)
	local case = point:CreateTexture(nil, "BACKGROUND", nil, -2)
	case:SetPoint("CENTER")
	case:SetVertexColor(unpack(AzeriteCaseColor))
	point.case = case
	local slot = point:CreateTexture(nil, "BACKGROUND", nil, -1)
	slot:SetPoint("TOPLEFT", -AzeriteSlotOffset, AzeriteSlotOffset)
	slot:SetPoint("BOTTOMRIGHT", AzeriteSlotOffset, -AzeriteSlotOffset)
	slot:SetVertexColor(unpack(AzeriteSlotColor))
	point.slot = slot
	return point
end
local AzeriteClassPower_PostUpdate = function(element, cur, max, hasMaxChanged, powerType)
	local isEditMode = element.inEditMode
	if (not cur or not max) then
		return
	end
	if (type(cur) ~= "number" or cur <= 0) then
		if (not isEditMode) then
			return element:Hide()
		end
	end
	local style
	if (max >= 6) then
		style = "Runes"
	elseif (max == 5) then
		style = playerClass == "MONK" and "Chi" or playerClass == "WARLOCK" and "SoulShards" or "ComboPoints"
	elseif (max == 4) then
		style = "ArcaneCharges"
	elseif (max == 3) then
		style = "Stagger"
	end
	if (not style) then
		if (not isEditMode) then
			return element:Hide()
		end
		return
	end
	if (not element:IsShown()) then
		element:Show()
	end
	if (not isEditMode) then
		for i = 1, #element do
			local point = element[i]
			if (point:IsShown()) then
				local value = point:GetValue()
				local _, pmax = point:GetMinMaxValues()
				if (element.inCombat) then
					point:SetAlpha((cur == max) and 1 or (value < pmax) and .5 or 1)
				else
					point:SetAlpha((cur == max) and 0 or (value < pmax) and .5 or 1)
				end
			end
		end
	end
	if (style ~= element.style) then
		local layoutdb = AzeriteClassPowerLayouts[style]
		if (layoutdb) then
			local id = 0
			for i, info in next, layoutdb do
				local point = element[i]
				if (point) then
					AzeriteApplyPointLayout(point, info, element)
					id = id + 1
				end
			end
			if (not isEditMode) then
				for i = id + 1, #element do
					element[i]:Hide()
				end
			end
		end
		element.style = style
	end
end
local AzeriteClassPower_PostUpdateColor = function(element, r, g, b)
	if type(r) == "table" and r.GetRGB then
		r, g, b = r:GetRGB()
	end
	for i = 1, #element do
		element[i]:SetStatusBarColor(r, g, b)
	end
end
local AzeriteRunes_PostUpdate = function(element, runemap, hasVehicle, allReady)
	if (element.inEditMode) then return end
	for i = 1, #element do
		local rune = element[i]
		if (rune:IsShown()) then
			local value = rune:GetValue()
			local _, max = rune:GetMinMaxValues()
			if (element.inCombat) then
				rune:SetAlpha(allReady and 1 or (value < max) and .5 or 1)
			else
				rune:SetAlpha(allReady and 0 or (value < max) and .5 or 1)
			end
		end
	end
end
local AzeriteRunes_PostUpdateColor = function(element, r, g, b, color, rune)
	if (rune) then
		rune:SetStatusBarColor(r, g, b)
	else
		color = element.__owner.colors.power.RUNES
		r, g, b = color[1], color[2], color[3]
		for i = 1, #element do
			element[i]:SetStatusBarColor(r, g, b)
		end
	end
end
local AzeriteStagger_PostUpdate = function(element, cur, max)
	if (element.inEditMode) then return end
	element[1].min = 0
	element[1].max = max * .3
	element[2].min = element[1].max
	element[2].max = max * .6
	element[3].min = element[2].max
	element[3].max = max
	for i = 1, 3 do
		local point = element[i]
		local value = (cur > point.max) and point.max or (cur < point.min) and point.min or cur
		point:SetMinMaxValues(point.min, point.max)
		point:SetValue(value)
		if (element.inCombat or cur > 0) then
			point:SetAlpha(1)
		else
			point:SetAlpha(0)
		end
	end
end
local AzeriteStagger_SetStatusBarColor = function(element, r, g, b)
	for i = 1, 3 do
		local point = element[i]
		if (point) then
			point:SetStatusBarColor(r, g, b)
			if (point.fg) then
				point.fg:SetVertexColor(r, g, b, .75)
			end
		end
	end
end
local AzeriteStagger_UpdateColor = function(self, event, unit)
	if (unit and unit ~= self.unit) then return end
	local element = self.Stagger
	local colors = self.colors.power["STAGGER"]
	if (not colors) then return end
	for i = 1, 3 do
		local point = element[i]
		local color = colors[i]
		if (point and color) then
			local r, g, b = color:GetRGB()
			point:SetStatusBarColor(r, g, b)
			if (point.slot) then
				point.slot:SetVertexColor(r * .3, g * .3, b * .3, 1)
			end
		end
	end
end

-- Standard ClassPower Callbacks
--------------------------------------------
local ClassPower_OnDisplayValueChanged = function(point)
	local value = point:GetValue()
	local min, max = point:GetMinMaxValues()
	-- Base it all on the bar's current color
	if (point.fg) then
		local r, g, b = point:GetStatusBarColor()
		point.fg:SetVertexColor(r, g, b, .75)
		-- Adjust texcoords of the overlay glow to match the bars
		local c = point.fg.texCoords
		point.fg:SetTexCoord(c[1], c[2], c[4] - (c[4]-c[3]) * ((value-min)/(max-min)), c[4])
	end
end
local ClassPower_PostUpdate = function(element, cur, max, hasMaxChanged, powerType)
	if (element.inEditMode) then return end
	-- Resize the holder frame to keep points centered
	if (hasMaxChanged) then
		element:SetWidth(max * element.pointWidth)
	end
	for i = 1, #element do
		local point = element[i]
		if (point:IsShown()) then
			local value = point:GetValue()
			local pmin, pmax = point:GetMinMaxValues()
			if (element.inCombat) then
				point:SetAlpha((cur == max) and 1 or (value < pmax) and .5 or 1)
			else
				point:SetAlpha((cur == max) and 0 or (value < pmax) and .5 or 1)
			end
		end
	end
end

local ClassPower_PostUpdateColor = function(element, r, g, b)
	-- WoW 12.0.0: oUF now passes ColorMixin objects instead of r,g,b numbers
	if type(r) == "table" and r.GetRGB then
		r, g, b = r:GetRGB()
	end
	if r and g and b then
		for i = 1, #element do
			local bar = element[i]
			bar:SetStatusBarColor(r, g, b)
			local fg = bar.fg
			if (fg) then
				local mu = fg.multiplier or 1
				fg:SetVertexColor(r, g, b)
			end
		end -- End of for loop
	end -- End of if r and g and b
end

local Runes_PostUpdate = function(element, runemap, hasVehicle, allReady)
	if (element.inEditMode) then return end
	for i = 1, #element do
		local rune = element[i]
		if (rune:IsShown()) then
			local value = rune:GetValue()
			local min, max = rune:GetMinMaxValues()
			if (element.inCombat) then
				rune:SetAlpha(allReady and 1 or (value < max) and .5 or 1)
			else
				rune:SetAlpha(allReady and 0 or (value < max) and .5 or 1)
			end
		end
	end
end

local Runes_PostUpdateColor = function(element, r, g, b, color, rune)
	local m = ns.IsWrath and .5 or 1 -- Probably only needed on our current runes
	if (rune) then
		rune:SetStatusBarColor(r * m, g * m, b * m)
		rune.fg:SetVertexColor(r * m, g * m, b * m)
	else
		if (not ns.IsWrath) then
			color = element.__owner.colors.power.RUNES
			r, g, b = color[1] * m, color[2] * m, color[3] * m
		end
		for i = 1, #element do
			local rune = element[i]
			if (ns.IsWrath) then
				color = element.__owner.colors.runes[rune.runeType]
				r, g, b = color[1] * m, color[2] * m, color[3] * m
			end
			rune:SetStatusBarColor(r, g, b)
			rune.fg:SetVertexColor(r, g, b)
		end
	end
end

local Stagger_SetStatusBarColor = function(element, r, g, b)
	for i,point in next,element do
		point:SetStatusBarColor(r, g, b)
	end
end

local Stagger_PostUpdate = function(element, cur, max)
	if (element.inEditMode) then return end
	element[1].min = 0
	element[1].max = max * .3
	element[2].min = element[1].max
	element[2].max = max * .6
	element[3].min = element[2].max
	element[3].max = max

	for i,point in next,element do
		local value = (cur > point.max) and point.max or (cur < point.min) and point.min or cur

		point:SetMinMaxValues(point.min, point.max)
		point:SetValue(value)

		if (element.inCombat) then
			point:SetAlpha((cur == max) and 1 or (value < point.max) and .5 or 1)
		else
			point:SetAlpha((cur == 0) and 0 or (value < point.max) and .5 or 1)
		end
	end
end

-- Script Handlers
--------------------------------------------
local UnitFrame_OnEvent = function(self, event)
	if (event == "PLAYER_REGEN_DISABLED") then
		self:OnMouseOver(event)
		local runes = self.Runes
		if (runes) and (not runes.inCombat) then
			runes.inCombat = true
			if (not useAzeriteClassPower) then runes:Show() end
			runes:ForceUpdate()
		end
		local stagger = self.Stagger
		if (stagger and not stagger.inCombat) then
			stagger.inCombat = true
			if (not useAzeriteClassPower) then stagger:Show() end
			stagger:ForceUpdate()
		end
		local classpower = self.ClassPower
		if (classpower) and (not classpower.inCombat) then
			classpower.inCombat = true
			if (not useAzeriteClassPower) then classpower:Show() end
			classpower:ForceUpdate()
		end
	elseif (event == "PLAYER_REGEN_ENABLED") then
		self:OnMouseOver(event)
		local runes = self.Runes
		if (runes) and (runes.inCombat) then
			runes.inCombat = false
			if (not useAzeriteClassPower) then runes:Hide() end
			runes:ForceUpdate()
		end
		local stagger = self.Stagger
		if (stagger and stagger.inCombat) then
			stagger.inCombat = false
			if (not useAzeriteClassPower) then stagger:Hide() end
			stagger:ForceUpdate()
		end
		local classpower = self.ClassPower
		if (classpower) and (classpower.inCombat) then
			classpower.inCombat = false
			if (not useAzeriteClassPower) then classpower:Hide() end
			classpower:ForceUpdate()
		end
	end
end

local UnitFrame_OnHide = function(self)
	self.inCombat = nil
	self.isMouseOver = nil
	self.Power.isMouseOver = nil
	self:OnMouseOver()
end

local UnitFrame_OnMouseOver = function(self, event)
	if (event == "PLAYER_REGEN_DISABLED") then
		self.inCombat = true
	elseif (event == "PLAYER_REGEN_ENABLED") then
		self.inCombat = nil
	end
	if (self.isMouseOver) or (self.Power.isMouseOver) or (self.inCombat) then
		self.Health.Value:Show()
		self.Power.Value:Show()
		self:UpdateTags()
	else
		self.Health.Value:Hide()
		self.Power.Value:Hide()
	end
end

local Power_OnEnter = function(element)
	local OnEnter = element.__owner:GetScript("OnEnter")
	if (OnEnter) then
		OnEnter(element)
	end
end

local Power_OnLeave = function(element)
	local OnLeave = element.__owner:GetScript("OnLeave")
	if (OnLeave) then
		OnLeave(element)
	end
end

local Power_OnMouseOver = function(element)
	element.__owner:OnMouseOver()
end

local Power_PostUpdate = function(element, unit, cur, min, max)
	-- Don't override custom colors
	if ns.db.char.orbs and ns.db.char.orbs.useCustomColors then
		return
	end
	local db = ns:GetSettings()
	if db.char.unitframes.useClassColorForPower then
		local _, class = UnitClass(unit)
		if class then
			local color = element.__owner.colors.class[class]
			if color then
				element:SetStatusBarColor(color[1], color[2], color[3])
				return
			end
		end
	end
	local r, g, b = 0.3, 0.52, 0.9
	element:SetStatusBarColor(r, g, b)
end

-- Callbacks
--------------------------------------------
-- Update aura positons when visible bars change.
local PostUpdateAuraPositions = function(self, event, ...)

	local ActionBars = ns:GetModule("ActionBars")
	local PetBar = ActionBars:GetModule("PetBar", true)
	local StanceBar = ActionBars:GetModule("StanceBar", true)
	local offset = 0
	local stanceOffset = 0

	-- Check if temporary action bars are active (vehicle, override, temp shapeshift)
	local hasTempBar = HasVehicleActionBar() or HasOverrideActionBar() or HasTempShapeshiftActionBar()

	if hasTempBar then
		-- Use saved normal offset when temp bars are active (don't move buffs)
		offset = self.normalBarOffset or ActionBars:GetBarOffset()
	else
		-- Update and save normal offset when no temp bars
		offset = ActionBars:GetBarOffset()
		self.normalBarOffset = offset
	end

	self.hasStanceBar = StanceBar and StanceBar.Bar and StanceBar.Bar:IsShown()
	self.hasPetBar = PetBar and PetBar.Bar and PetBar.Bar:IsShown()

	if (self.hasPetBar) then
		offset = offset + 40
	elseif (self.hasStanceBar) then
		stanceOffset = 40
	end

	-- Check if buffs frame exists (depends on showPlayerBuffs setting)
	if self.Buffs then
		self.Buffs:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", -316, 100 + offset)
	end
	self.Debuffs:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", 316, 100 + offset + stanceOffset)

	ns:Fire("UnitFrame_Position_Updated", self:GetName())
end

-- Update castbar position when settings change.
local UpdateCastbarPosition = function(self, event, ...)
	if (not self.Castbar) then return end
	local db = ns:GetSettings()
	if (db.global.castbar.enableCastbar) then
		local frame = self.Castbar.frame or self.Castbar
		frame:ClearAllPoints()
		frame:SetPoint("CENTER", UIParent, "CENTER", db.global.castbar.positionX or 0, db.global.castbar.positionY or -150)
	end
end

-- Utility Functions
--------------------------------------------
-- Create the points used for class power, stagger and runes.
local CreatePoint = function(self, i)

	local point = self:CreateBar()
	point:SetSize(70,70)
	point.pointWidth = 70
	point:SetStatusBarTexture(GetMedia("diabolic-runes"))
	point:GetStatusBarTexture():SetTexCoord((i-1)*128/1024, i*128/1024, 128/512, 256/512)
	point:SetSparkTexture(GetMedia("blank"))
	point:DisableSmoothing(true) -- Force disable smoothing, it's too inaccurate for this.
	point:SetOrientation("UP")
	point:SetMinMaxValues(0, 1)
	point:SetValue(1)
	point:SetScript("OnDisplayValueChanged", ClassPower_OnDisplayValueChanged)

	-- Empty slot texture
	local bg = point:CreateTexture()
	bg:SetDrawLayer("BACKGROUND", -1)
	bg:ClearAllPoints()
	bg:SetPoint("BOTTOM", 0, 0)
	bg:SetSize(70,70)
	bg:SetTexture(GetMedia("diabolic-runes"))
	bg:SetTexCoord((i-1)*128/1024, i*128/1024, 0/512, 128/512)
	bg.multiplier = .25
	point.bg = bg

	-- Overlay glow, aligned to the bar texture
	-- This needs post updates to adjust its texcoords based on bar value.
	local fg = point:CreateTexture()
	fg:SetDrawLayer("ARTWORK", 1)
	fg:SetPoint("TOP", point:GetStatusBarTexture(), "TOP", 0, 0)
	fg:SetPoint("BOTTOM", 0, 0)
	fg:SetPoint("LEFT", 0, 0)
	fg:SetPoint("RIGHT", 0, 0)
	fg:SetSize(70,70) -- this is overriden by the points above
	fg:SetBlendMode("ADD")
	fg:SetTexture(GetMedia("diabolic-runes"))
	fg:SetTexCoord((i-1)*128/1024, i*128/1024, 256/512, 384/512)
	fg:SetAlpha(.85)
	fg.texCoords = { (i-1)*128/1024, i*128/1024, 256/512, 384/512 }
	point.fg = fg

	return point
end

UnitStyles["Player"] = function(self, unit, id)
	useAzeriteClassPower = ns.db and ns.db.char and ns.db.char.experiments and ns.db.char.experiments.useAzeriteClassPower or false
	self:SetSize(200,200)
	self:SetFrameLevel(self:GetFrameLevel() + 1)

	-- Holders for always visible elements
	--------------------------------------------
	local artworkHolder = SetObjectScale(CreateFrame("Frame", nil, UIParent))
	artworkHolder:SetAllPoints(self)
	artworkHolder:SetFrameStrata(self:GetFrameStrata())
	artworkHolder:SetFrameLevel(self:GetFrameLevel())

	self.Artwork = artworkHolder

	local artworkOverlay = CreateFrame("Frame", nil, artworkHolder)
	artworkOverlay:SetAllPoints()
	artworkOverlay:SetFrameStrata(self:GetFrameStrata())
	artworkOverlay:SetFrameLevel(self:GetFrameLevel() + 5)

	self.Artwork.Overlay = artworkOverlay

	-- Health Orb
	--------------------------------------------
	local health = self:CreateOrb(self:GetName().."HealthOrb")
	health:SetSize(200,200)
	health:SetPoint("BOTTOM")
	health:SetStatusBarTexture(GetMedia("orb2"), GetMedia("orb2"))
	if ns.db.char.orbs and ns.db.char.orbs.useCustomColors then
		health.colorHealth = false
		local color = ns.db.char.orbs.healthColor or {r = 1, g = 0, b = 0}
		health:SetStatusBarColor(color.r, color.g, color.b)
	else
		health.colorHealth = true
	end

	select(2, health:GetStatusBarTexture()):SetTexCoord(1,0,1,0) -- flip 2nd texture horizontally

	self.Health = health
	self.Health.Override = ns.API.UpdateHealth
	self.Health.PostUpdate = Health_PostUpdate
	self.Health.PostUpdateColor = Health_PostUpdateColor

	local healthBackdrop = artworkHolder:CreateTexture(health:GetName().."Backdrop", "BACKGROUND", nil, -7)
	healthBackdrop:SetSize(330,330)
	healthBackdrop:SetPoint("CENTER", health)
	healthBackdrop:SetTexture(GetMedia("orb-backdrop1"))

	self.Health.Bacdrop = healthBackdrop

	local healthOverlay = CreateFrame("Frame", nil, health)
	healthOverlay:SetFrameLevel(health:GetFrameLevel() + 5)

	self.Health.Overlay = healthOverlay

	local healthShade = artworkOverlay:CreateTexture(nil, "BACKGROUND")
	healthShade:SetAllPoints(health)
	healthShade:SetTexture(GetMedia("shade-circle"))
	healthShade:SetVertexColor(0,0,0,1)

	self.Health.Shade = healthShade

	local healthGlass = artworkOverlay:CreateTexture(health:GetName().."Glass", "BORDER")
	healthGlass:SetAllPoints(healthBackdrop)
	healthGlass:SetTexture(GetMedia("orb-glass"))
	healthGlass:SetAlpha(.6)

	self.Health.Glass = healthGlass

	local healthBorder = artworkOverlay:CreateTexture(health:GetName().."Border", "ARTWORK")
	healthBorder:SetAllPoints(healthBackdrop)
	healthBorder:SetTexture(GetMedia("orb-border"))

	self.Health.Border = healthBorder

	local healthArt = artworkOverlay:CreateTexture(health:GetName().."Artwork", "OVERLAY", nil, 1)
	healthArt:SetSize(healthBackdrop:GetSize())
	healthArt:SetPoint("BOTTOMRIGHT", health, "BOTTOM", 29, -25)
	-- Use D2R style orb art if enabled in settings
	local orbTexture = (ns.db.global.orbs and ns.db.global.orbs.useD2RStyle) and "orb-art1-d2r" or "orb-art1"
	healthArt:SetTexture(GetMedia(orbTexture))

	self.Health.Artwork = healthArt

	-- Health Value Text
	--------------------------------------------
	local healthValue = health:CreateFontString(health:GetName().."ValueText", "OVERLAY", nil, 0)
	healthValue:Hide()
	healthValue:SetFontObject(GetFont(14,true))
	healthValue:SetTextColor(unpack(self.colors.offwhite))
	healthValue:SetAlpha(.85)
	healthValue:SetPoint("BOTTOM", health, "TOP", 0, 16)

	if (ns.IsWrath) then
		self:Tag(healthValue, "["..ns.Prefix..":Health:Full]")
	else
		self:Tag(healthValue, "["..ns.Prefix..":Health:Full]["..ns.Prefix..":Absorb]")
	end

	self.Health.Value = healthValue

	-- Health Preview
	--------------------------------------------
	local layer, level = health:GetStatusBarTexture():GetDrawLayer()
	local preview = self:CreateOrb(health:GetName().."Preview")
	preview:SetFrameLevel(health:GetFrameLevel())
	preview:SetSize(200,200)
	preview:SetPoint("BOTTOM")
	preview:SetStatusBarTexture(GetMedia("minimap-mask-transparent"))
	preview:GetStatusBarTexture():SetDrawLayer(layer, level - 1)
	preview:SetAlpha(.5)
	preview:DisableSmoothing(true)

	self.Health.Preview = preview

	-- Health Prediction
	--------------------------------------------
	local healPredictFrame = CreateFrame("Frame", nil, health)
	healPredictFrame:SetFrameLevel(health:GetFrameLevel() + 2)
	healPredictFrame:SetAllPoints()

	local healPredict = healPredictFrame:CreateTexture(health:GetName().."Prediction", "OVERLAY")
	healPredict.health = health
	healPredict.preview = preview
	healPredict.maxOverflow = 1
	healPredict:SetTexture(GetMedia("minimap-mask-opaque"))

	self.HealthPrediction = healPredict
	self.HealthPrediction.PostUpdate = HealPredict_PostUpdate

	-- CombatFeedback
	--------------------------------------------
	local feedbackText = healthOverlay:CreateFontString(self:GetName().."CombatFeedbackText", "OVERLAY")
	feedbackText.maxAlpha = .8
	feedbackText.feedbackFont = GetFont(24, true)
	feedbackText.feedbackFontLarge = GetFont(24, true)
	feedbackText.feedbackFontSmall = GetFont(18, true)
	feedbackText:SetFontObject(feedbackText.feedbackFont)
	feedbackText:SetPoint("CENTER", health, "CENTER", 2, 2)

	self.CombatFeedback = feedbackText

	-- Power Orb
	--------------------------------------------
	local power = self:CreateOrb(self:GetName().."PowerOrb")
	power:SetSize(200,200)
	power:SetPoint("BOTTOM", 882, 0)
	power:SetStatusBarTexture(GetMedia("orb2"), GetMedia("orb2"))
	if ns.db.char.orbs and ns.db.char.orbs.useCustomColors then
		local color = ns.db.char.orbs.powerColor or {r = 0, g = 0, b = 1}
		power:SetStatusBarColor(color.r, color.g, color.b)
		power.colorPower = false
	elseif ns.db.char.unitframes.useClassColorForPower then
		power.colorPower = true
	else
		power:SetStatusBarColor(0.3, 0.52, 0.9)
		power.colorPower = false
	end
	power:EnableMouse(true)
	power:SetScript("OnEnter", Power_OnEnter)
	power:SetScript("OnLeave", Power_OnLeave)
	power:SetMouseClickEnabled(false)
	power.OnEnter = Power_OnMouseOver
	power.OnLeave = Power_OnMouseOver
	power.frequentUpdates = true
	power.displayAltPower = true
	power.PostUpdate = Power_PostUpdate

	select(2, power:GetStatusBarTexture()):SetTexCoord(1,0,1,0) -- flip 2nd texture horizontally

	self.Power = power
	self.Power.Override = ns.API.UpdatePower

	local powerBackdrop = artworkHolder:CreateTexture(power:GetName().."Backdrop", "BACKGROUND", nil, -7)
	powerBackdrop:SetSize(330,330)
	powerBackdrop:SetPoint("CENTER", power)
	powerBackdrop:SetTexture(GetMedia("orb-backdrop2"))

	self.Power.Backdrop = powerBackdrop

	local powerOverlay = CreateFrame("Frame", nil, power)
	powerOverlay:SetFrameLevel(power:GetFrameLevel() + 5)

	self.Power.Overlay = powerOverlay

	local powerShade = artworkOverlay:CreateTexture(nil, "BACKGROUND")
	powerShade:SetAllPoints(power)
	powerShade:SetTexture(GetMedia("shade-circle"))
	powerShade:SetVertexColor(0,0,0,1)

	self.Power.Shade = powerShade

	local powerGlass = artworkOverlay:CreateTexture(power:GetName().."Glass", "BORDER")
	powerGlass:SetAllPoints(powerBackdrop)
	powerGlass:SetTexture(GetMedia("orb-glass"))
	powerGlass:SetAlpha(.6)

	self.Power.Glass = powerGlass

	local powerBorder = artworkOverlay:CreateTexture(power:GetName().."Border", "ARTWORK")
	powerBorder:SetAllPoints(powerBackdrop)
	powerBorder:SetTexture(GetMedia("orb-border"))

	self.Power.Border = powerBorder

	local powerArt = artworkOverlay:CreateTexture(power:GetName().."Artwork", "OVERLAY", nil, 1)
	powerArt:SetSize(powerBackdrop:GetSize())
	powerArt:SetPoint("BOTTOMLEFT", power, "BOTTOM", -29, -25)
	-- Use D2R style orb art if enabled in settings
	local orbTexture = (ns.db.global.orbs and ns.db.global.orbs.useD2RStyle) and "orb-art2-d2r" or "orb-art2"
	powerArt:SetTexture(GetMedia(orbTexture))

	self.Power.Artwork = powerArt

	-- Eye Glow D2R: Angel (celestial blue) on health, Demon (red) on power
	--------------------------------------------
	local healthEyeGlow = artworkOverlay:CreateTexture(nil, "OVERLAY", nil, 3)
	healthEyeGlow:SetSize(60, 60)
	healthEyeGlow:SetPoint("CENTER", healthArt, "CENTER", 34, 42)
	healthEyeGlow:SetTexture(GetMedia("orb-glass"))
	healthEyeGlow:SetVertexColor(0.5, 0.85, 1.0)
	healthEyeGlow:SetBlendMode("ADD")
	healthEyeGlow:Hide()
	local healthGlowAG = healthEyeGlow:CreateAnimationGroup()
	healthGlowAG:SetLooping("BOUNCE")
	local healthGlowAnim = healthGlowAG:CreateAnimation("Alpha")
	healthGlowAnim:SetFromAlpha(0.4)
	healthGlowAnim:SetToAlpha(0.8)
	healthGlowAnim:SetDuration(2.5)
	healthGlowAnim:SetSmoothing("IN_OUT")
	self.Health.EyeGlow = healthEyeGlow
	self.Health.EyeGlowAG = healthGlowAG
	local powerEyeGlow = artworkOverlay:CreateTexture(nil, "OVERLAY", nil, 3)
	powerEyeGlow:SetSize(60, 60)
	powerEyeGlow:SetPoint("CENTER", powerArt, "CENTER", -50, 15)
	powerEyeGlow:SetTexture(GetMedia("orb-glass"))
	powerEyeGlow:SetVertexColor(1.0, 0.1, 0.05)
	powerEyeGlow:SetBlendMode("ADD")
	powerEyeGlow:Hide()
	local powerGlowAG = powerEyeGlow:CreateAnimationGroup()
	powerGlowAG:SetLooping("BOUNCE")
	local powerGlowAnim = powerGlowAG:CreateAnimation("Alpha")
	powerGlowAnim:SetFromAlpha(0.4)
	powerGlowAnim:SetToAlpha(0.8)
	powerGlowAnim:SetDuration(2.5)
	powerGlowAnim:SetSmoothing("IN_OUT")
	self.Power.EyeGlow = powerEyeGlow
	self.Power.EyeGlowAG = powerGlowAG

	-- Power Value Text
	--------------------------------------------
	local powerValue = powerOverlay:CreateFontString(power:GetName().."ValueText", "OVERLAY", nil, 0)
	powerValue:Hide()
	powerValue:SetFontObject(GetFont(14,true))
	powerValue:SetTextColor(unpack(self.colors.offwhite))
	powerValue:SetAlpha(.85)
	powerValue:SetPoint("BOTTOM", power, "TOP", 0, 16)
	self:Tag(powerValue, "["..ns.Prefix..":Power:Full]")

	self.Power.Value = powerValue

	-- Castbar
	--------------------------------------------
	local db = ns:GetSettings()
	if (not IsAddOnEnabled("Quartz") and db.global.castbar.enableCastbar) then

		local castFrame = CreateFrame("Frame", nil, UIParent)
		castFrame:SetSize(240, 20)
		castFrame:SetPoint("CENTER", UIParent, "CENTER", db.global.castbar.positionX or 0, db.global.castbar.positionY or -150)
		castFrame:Hide()

		local castFrameBackdrop = castFrame:CreateTexture(nil, "BACKGROUND", nil, -2)
		castFrameBackdrop:SetAllPoints()
		castFrameBackdrop:SetTexture(GetMedia("target-bar-normal-diabolic"))
		castFrameBackdrop:SetTexCoord(221/1024, 803/1024, 85/256, 171/256)
		castFrameBackdrop:SetVertexColor(.3, .3, .3, .8)

		local cast = self:CreateBar(nil, castFrame)
		cast:SetFrameStrata("MEDIUM")
		cast:SetSize(220,4)
		cast:SetPoint("CENTER", castFrame, "CENTER", 0, 0)
		cast:SetStatusBarTexture(GetMedia("plain"))
		cast:SetStatusBarColor(unpack(self.colors.cast))
		cast:DisableSmoothing(true)
		cast.timeToHold = .5
		cast.frame = castFrame

		local castSafeZone = cast:CreateTexture(nil, "ARTWORK", nil, 0)
		castSafeZone:SetColorTexture(unpack(self.colors.palered))
		castSafeZone:SetAlpha(.25)
		cast.SafeZone = castSafeZone

		local castText = cast:CreateFontString(nil, "OVERLAY", nil, 0)
		castText:SetFontObject(GetFont(13,true))
		castText:SetTextColor(unpack(self.colors.offwhite))
		castText:SetAlpha(.85)
		castText:SetPoint("BOTTOM", cast, "TOP", 0, 6)
		cast.Text = castText

		local castTime = cast:CreateFontString(nil, "OVERLAY", nil, 0)
		castTime:SetFontObject(GetFont(15,true))
		castTime:SetTextColor(unpack(self.colors.offwhite))
		castTime:SetPoint("LEFT", cast, "RIGHT", 8, 0)
		castTime:SetJustifyV("MIDDLE")
		cast.Time = castTime

		local castDelay = cast:CreateFontString(nil, "OVERLAY", nil, 0)
		castDelay:SetFontObject(GetFont(12,true))
		castDelay:SetTextColor(unpack(self.colors.red))
		castDelay:SetPoint("LEFT", castTime, "RIGHT", 0, 0)
		castDelay:SetJustifyV("MIDDLE")
		cast.Delay = castDelay

		cast.CustomDelayText = Cast_CustomDelayText
		cast.CustomTimeText = Cast_CustomTimeText
		cast.PostCastInterruptible = Cast_UpdateInterruptible
		cast.PostCastStart = Cast_PostCastStart
		cast.PostCastStop = Cast_PostCastStop
		cast.PostCastFail = Cast_PostCastFail

		self.Castbar = cast
	end

	-- Classpowers
	--------------------------------------------
	-- 	Supported class powers:
	-- 	- All     - Combo Points
	-- 	- Mage    - Arcane Charges
	-- 	- Monk    - Chi Orbs
	-- 	- Paladin - Holy Power
	-- 	- Warlock - Soul Shards
	--------------------------------------------
	local SCP = IsAddOnEnabled("SimpleClassPower")
	if (not SCP) then

		local classpower = CreateFrame("Frame", nil, UIParent)
		classpower:SetFrameStrata("MEDIUM")
		classpower:SetFrameLevel(100)
		if (useAzeriteClassPower) then
			classpower:SetSize(124, 168)
			classpower:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 300)
			classpower.PostUpdate = AzeriteClassPower_PostUpdate
			classpower.PostUpdateColor = AzeriteClassPower_PostUpdateColor
			for i = 1, 10 do
				local point = AzeriteClassPower_CreatePoint(self)
				point:SetParent(classpower)
				classpower[i] = point
			end
		else
			classpower:SetSize(560,70) -- 8 points * 70px (resized dynamically by PostUpdate)
			classpower:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 300)
			classpower.pointWidth = 70
			classpower.PostUpdate = ClassPower_PostUpdate
			classpower.PostUpdateColor = ClassPower_PostUpdateColor
			-- Create max 8 points (texture supports 8, future patches may add more)
			for i = 1, 8 do
				local point = CreatePoint(self, i)
				point:SetParent(classpower)
				if (i == 1) then
					point:SetPoint("TOPLEFT", classpower, "TOPLEFT", 0, 0)
				else
					point:SetPoint("TOPLEFT", classpower[i-1], "TOPRIGHT", 0, 0)
				end
				classpower[i] = point
			end
		end
		self.ClassPower = classpower
		if (not useAzeriteClassPower) then
			self.ClassPower:Hide()
		end
	end

	-- Stagger (Monk)
	--------------------------------------------
	if (playerClass == "MONK") and (not SCP) then

		local stagger = CreateFrame("Frame", nil, UIParent)
		stagger:SetFrameStrata("MEDIUM")
		stagger:SetFrameLevel(100)
		stagger.SetValue = noop
		stagger.SetMinMaxValues = noop
		stagger.SetStatusBarColor = useAzeriteClassPower and AzeriteStagger_SetStatusBarColor or Stagger_SetStatusBarColor
		if (useAzeriteClassPower) then
			stagger:SetSize(124, 168)
			stagger:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 300)
			for i = 1, 3 do
				local point = AzeriteClassPower_CreatePoint(self)
				point:SetParent(stagger)
				stagger[i] = point
			end
			-- Pre-apply Stagger layout (static, always 3 points)
			local layoutdb = AzeriteClassPowerLayouts["Stagger"]
			if (layoutdb) then
				for i, info in next, layoutdb do
					local point = stagger[i]
					if (point) then
						AzeriteApplyPointLayout(point, info, stagger)
					end
				end
			end
			self.Stagger = stagger
			self.Stagger.PostUpdate = AzeriteStagger_PostUpdate
			self.Stagger.UpdateColor = AzeriteStagger_UpdateColor
		else
			stagger:SetSize(210,70)
			stagger:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 300)
			for i = 1,3 do
				local point = CreatePoint(self, i)
				point:SetParent(stagger)
				if (i == 1) then
					point:SetPoint("TOPLEFT", stagger, "TOPLEFT", 0, 0)
				else
					point:SetPoint("TOPLEFT", stagger[i-1], "TOPRIGHT", 0, 0)
				end
				stagger[i] = point
			end
			self.Stagger = stagger
			self.Stagger.PostUpdate = Stagger_PostUpdate
		end
		if (not useAzeriteClassPower) then
			self.Stagger:Hide()
		end
	end

	-- Runes (Death Knight)
	--------------------------------------------
	if (playerClass == "DEATHKNIGHT") and ((ns.IsWrath) or (ns.IsRetail and not SCP)) then

		local runes = CreateFrame("Frame", nil, UIParent)
		runes:SetFrameStrata("MEDIUM")
		runes:SetFrameLevel(100)
		runes.sortOrder = "ASC"
		if (useAzeriteClassPower) then
			runes:SetSize(124, 168)
			runes:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 300)
			runes.PostUpdate = AzeriteRunes_PostUpdate
			runes.PostUpdateColor = AzeriteRunes_PostUpdateColor
			for i = 1, 8 do
				local rune = AzeriteClassPower_CreatePoint(self)
				rune:SetParent(runes)
				runes[i] = rune
			end
			-- Pre-apply Runes layout (static, always 6 runes)
			local layoutdb = AzeriteClassPowerLayouts["Runes"]
			if (layoutdb) then
				for i, info in next, layoutdb do
					local rune = runes[i]
					if (rune) then
						AzeriteApplyPointLayout(rune, info, runes)
					end
				end
			end
		else
			runes:SetSize(560,70) -- 8 runes * 70px
			runes:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 300)
			runes.PostUpdate = Runes_PostUpdate
			runes.PostUpdateColor = Runes_PostUpdateColor
			-- Create max 8 runes (texture supports 8, future patches may add more)
			for i = 1, 8 do
				local rune = CreatePoint(self, i)
				rune:SetParent(runes)
				if (i == 1) then
					rune:SetPoint("TOPLEFT", runes, "TOPLEFT", 0, 0)
				else
					rune:SetPoint("TOPLEFT", runes[i-1], "TOPRIGHT", 0, 0)
				end
				runes[i] = rune
			end
		end
		self.Runes = runes
		if (not useAzeriteClassPower) then
			self.Runes:Hide()
		end
	end

	-- Auras
	--------------------------------------------
	-- NOTE: Бафы на player frame скрыты, так как они дублируются
	-- с основным buff header (Components/Auras/Auras.lua)
	-- который отображается в правом верхнем углу
	-- Но фреймы должны существовать для PostUpdateAuraPositions
	-- Check setting to show/hide buffs near health orb
	if ns.db.global.unitframes.showPlayerBuffs then
		local buffs = CreateFrame("Frame", self:GetName().."BuffFrame", self)
		buffs:SetSize(300, 110)
		buffs.num = 40
		buffs.size = 40
		buffs.spacing = 4
		buffs.filter = "HELPFUL"
		buffs.disableMouse = false
		buffs.disableCooldown = false
		buffs.onlyShowPlayer = false
		buffs.showStealableBuffs = false
		buffs.initialAnchor = "BOTTOMLEFT"
		buffs.spacingX = 4
		buffs.spacingY = 11
		buffs.growthX = "RIGHT"
		buffs.growthY = "UP"
		buffs.tooltipAnchor = "ANCHOR_TOPLEFT"
		buffs.sortMethod = "TIME_REMAINING"
		buffs.sortDirection = "ASCENDING"
		buffs.reanchorIfVisibleChanged = true
		-- WoW 12.0.0: Use non-secure buttons for player to avoid ADDON_ACTION_BLOCKED in combat
		buffs.CreateButton = ns.AuraStyles.CreateButtonWithBar_NonSecure
		buffs.allowCombatUpdates = true -- Allow oUF to update non-secure buttons in combat
		buffs.PostUpdateButton = ns.AuraStyles.PlayerPostUpdateButton
		buffs.FilterAura = ns.AuraFilters.PlayerBuffFilter
		buffs.SortAuras = ns.AuraSorts.DefaultFunction

		self.Buffs = buffs
	end

	local debuffs = CreateFrame("Frame", self:GetName().."DebuffFrame", self)
	debuffs:SetSize(300, 110)
	debuffs.num = 40
	debuffs.size = 40
	debuffs.spacing = 4
	debuffs.filter = "HARMFUL"
	debuffs.disableMouse = false
	debuffs.disableCooldown = false
	debuffs.onlyShowPlayer = false
	debuffs.showDebuffType = true
	debuffs.showStealableBuffs = false
	debuffs.initialAnchor = "BOTTOMRIGHT"
	debuffs.spacingX = 4
	debuffs.spacingY = 11
	debuffs.growthX = "LEFT"
	debuffs.growthY = "UP"
	debuffs.tooltipAnchor = "ANCHOR_TOPRIGHT"
	debuffs.reanchorIfVisibleChanged = true
	-- WoW 12.0.0: Use non-secure buttons for player to avoid ADDON_ACTION_BLOCKED in combat
	debuffs.CreateButton = ns.AuraStyles.CreateButtonWithBar_NonSecure
	debuffs.allowCombatUpdates = true -- Allow oUF to update non-secure buttons in combat
	debuffs.PostUpdateButton = ns.AuraStyles.PlayerPostUpdateButton
	debuffs.FilterAura = ns.AuraFilters.PlayerDebuffFilter
	debuffs.SortAuras = ns.AuraSorts.DefaultFunction

	self.Debuffs = debuffs

	-- Scripts & Events
	--------------------------------------------
	self.OnEvent = UnitFrame_OnEvent
	self.OnEnter = UnitFrame_OnMouseOver  -- called by script handler
	self.OnLeave = UnitFrame_OnMouseOver  -- called by script handler
	self.OnHide = UnitFrame_OnHide -- called by script handler
	self.OnMouseOver = UnitFrame_OnMouseOver

	self:RegisterEvent("PLAYER_REGEN_ENABLED", self.OnEvent, true)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", self.OnEvent, true)


	-- SubElement Position Callbacks
	--------------------------------------------
	self.PostUpdateAuraPositions = PostUpdateAuraPositions
	self:PostUpdateAuraPositions()

	ns.RegisterCallback(self, "ActionBars_SecondaryBar_Updated", "PostUpdateAuraPositions")
	ns.RegisterCallback(self, "ActionBars_ThirdBar_Updated", "PostUpdateAuraPositions")
	ns.RegisterCallback(self, "ActionBars_PetBar_Updated", "PostUpdateAuraPositions")
	ns.RegisterCallback(self, "ActionBars_StanceBar_Updated", "PostUpdateAuraPositions")

	self.UpdateCastbarPosition = UpdateCastbarPosition
	ns.RegisterCallback(self, "Castbar_Settings_Updated", "UpdateCastbarPosition")

	self.UpdateOrbColors = function(self)
		local health = self.Health
		local power = self.Power
		if ns.db.char.orbs and ns.db.char.orbs.useCustomColors then
			health.colorHealth = false
			local healthColor = ns.db.char.orbs.healthColor or {r = 1, g = 0, b = 0}
			health:SetStatusBarColor(healthColor.r, healthColor.g, healthColor.b)
			power.colorPower = false
			local powerColor = ns.db.char.orbs.powerColor or {r = 0, g = 0, b = 1}
			power:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)
		else
			health.colorHealth = true
			local r, g, b = health:GetStatusBarColor()
			health:SetStatusBarColor(r, g, b)
			if ns.db.char.unitframes.useClassColorForPower then
				power.colorPower = true
				local _, class = UnitClass("player")
				if class then
					local color = self.colors.class[class]
					if color then
						power:SetStatusBarColor(color[1], color[2], color[3])
					end
				end
			else
				power.colorPower = false
				power:SetStatusBarColor(0.3, 0.52, 0.9)
			end
		end
	end
	ns.RegisterCallback(self, "OrbColors_Updated", "UpdateOrbColors")
	self:UpdateOrbColors()

	self.UpdateEyeGlow = function(self)
		local enabled = ns.db.global.orbs and ns.db.global.orbs.useD2RStyle and ns.db.global.orbs.eyeGlowD2R
		if enabled then
			self.Health.EyeGlow:Show()
			self.Health.EyeGlowAG:Play()
			self.Power.EyeGlow:Show()
			self.Power.EyeGlowAG:Play()
		else
			self.Health.EyeGlowAG:Stop()
			self.Health.EyeGlow:Hide()
			self.Power.EyeGlowAG:Stop()
			self.Power.EyeGlow:Hide()
		end
	end
	ns.RegisterCallback(self, "OrbEyeGlow_Updated", "UpdateEyeGlow")
	self:UpdateEyeGlow()
-- Class Power / Runes Position and Scale
	self.UpdateClassPowerPosition = function(self)
		local db = ns.db.char.classpower
		local posPoint = db.positionPoint or "BOTTOM"
		local posX = db.positionX or 0
		local posY = db.positionY or 300
		local scale = db.scale or 1.0
		-- All three parented to UIParent
		if self.ClassPower then
			self.ClassPower:ClearAllPoints()
			self.ClassPower:SetPoint(posPoint, posX, posY)
			self.ClassPower:SetScale(scale)
		end
		if self.Runes then
			self.Runes:ClearAllPoints()
			self.Runes:SetPoint(posPoint, posX, posY)
			self.Runes:SetScale(scale)
		end
		if self.Stagger then
			self.Stagger:ClearAllPoints()
			self.Stagger:SetPoint(posPoint, posX, posY)
			self.Stagger:SetScale(scale)
		end
	end
	ns.RegisterCallback(self, "ClassPower_Position_Updated", "UpdateClassPowerPosition")
	self:UpdateClassPowerPosition()
	-- Register ClassPower with EditMode (LibEditMode)
	local LibEditMode = ns.LibEditMode
	if LibEditMode and LibEditMode.AddFrame and self.ClassPower then
		local cpDb = ns.db.char.classpower
		self.ClassPower.editModeName = "Diabolic: Class Resources"
		LibEditMode:AddFrame(self.ClassPower, function(frame, layoutName, point, x, y)
			cpDb.positionPoint = point
			cpDb.positionX = x
			cpDb.positionY = y
			self:UpdateClassPowerPosition()
		end, {point = "BOTTOM", x = 0, y = 300})
		LibEditMode:AddFrameSettings(self.ClassPower, {
			{
				kind = LibEditMode.SettingType.Slider,
				name = ns.L["ClassPowerScale"] or "Class Resources Scale",
				desc = ns.L["ClassPowerScaleDesc"] or "Scale of class resources",
				default = 1.0,
				minValue = 0.5,
				maxValue = 2.0,
				valueStep = 0.05,
				formatter = function(value) return string.format("%.2f", value) end,
				get = function(layoutName) return cpDb.scale or 1.0 end,
				set = function(layoutName, value)
					cpDb.scale = value
					self:UpdateClassPowerPosition()
				end,
			}
		})
		-- Force-show ClassPower/Stagger/Runes during EditMode
		-- PostUpdate functions skip hide/alpha when inEditMode but still apply layout
		local cp = self.ClassPower
		local stg = self.Stagger
		local rns = self.Runes
		local editModeElements = {}
		for _, el in next, {cp, stg, rns} do
			if (el) then
				editModeElements[#editModeElements + 1] = el
			end
		end
		EditModeManagerFrame:HookScript("OnShow", function()
			for _, el in next, editModeElements do
				el.inEditMode = true
				-- ForceUpdate triggers PostUpdate which applies Azerite layout
				-- PostUpdate skips hide/alpha when inEditMode
				if (el.ForceUpdate) then el:ForceUpdate() end
				el:Show()
				for i = 1, 10 do
					local pt = el[i]
					if (pt) then
						pt:Show()
						pt:SetAlpha(1)
						if (pt.SetValue) then pt:SetMinMaxValues(0, 1); pt:SetValue(1) end
					end
				end
			end
		end)
		EditModeManagerFrame:HookScript("OnHide", function()
			for _, el in next, editModeElements do
				el.inEditMode = nil
				el:Hide()
			end
		end)
	end

end
