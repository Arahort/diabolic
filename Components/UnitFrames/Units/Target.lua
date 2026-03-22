local Addon, ns = ...
local UnitStyles = ns.UnitStyles
if (not UnitStyles) then
	return
end

-- Lua API
local math_huge = math.huge
local table_sort = table.sort
local unpack = unpack

-- WoW API
local CreateFrame = CreateFrame
local UnitBattlePetLevel = UnitBattlePetLevel
local UnitClass = UnitClass
local UnitClassification = UnitClassification
local UnitIsBattlePetCompanion = UnitIsBattlePetCompanion
local UnitIsWildBattlePet = UnitIsWildBattlePet
local UnitLevel = UnitEffectiveLevel or UnitLevel

-- Addon API
local AbbreviateTime = ns.API.AbbreviateTimeShort
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

-- Callbacks
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
	-- WoW 12.0.0: oUF now passes ColorMixin objects instead of r,g,b numbers
	if type(r) == "table" and r.GetRGB then
		r, g, b = r:GetRGB()
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

	if not curHealth or not maxHealth then return end
	local allIncomingHeal = myIncomingHeal + otherIncomingHeal
	local allNegativeHeals = healAbsorb
	local showPrediction, change
	if ((allIncomingHeal > 0) or (allNegativeHeals > 0)) and (maxHealth > 0) then
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
		local growth = preview:GetGrowth()
		local min,max = preview:GetMinMaxValues()
		local value = preview:GetValue() / max
		local previewTexture = preview:GetStatusBarTexture()
		local previewWidth, previewHeight = preview:GetSize()
		local left, right, top, bottom = preview:GetTexCoord()

		if (growth == "RIGHT") then

			local texValue, texChange = value, change
			local rangeH, rangeV

			rangeH = right - left
			rangeV = bottom - top
			texChange = change*value
			texValue = left + value*rangeH

			if (change > 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMLEFT", previewTexture, "BOTTOMRIGHT", 0, 0)
				element:SetSize(change*previewWidth, previewHeight)
				element:SetTexCoord(texValue, texValue + texChange, top, bottom)
				element:SetVertexColor(0, .7, 0, .25)
				element:Show()

			elseif (change < 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMRIGHT", previewTexture, "BOTTOMRIGHT", 0, 0)
				element:SetSize(-change*previewWidth, previewHeight)
				element:SetTexCoord(texValue + texChange, texValue, top, bottom)
				element:SetVertexColor(.25, 0, 0, .75)
				element:Show()

			else
				element:Hide()
			end

		elseif (growth == "LEFT") then
			local texValue, texChange = value, change
			local rangeH, rangeV
			rangeH = right - left
			rangeV = bottom - top
			texChange = change*value
			texValue = left + value*rangeH

			if (change > 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMRIGHT", previewTexture, "BOTTOMLEFT", 0, 0)
				element:SetSize(change*previewWidth, previewHeight)
				element:SetTexCoord(texValue + texChange, texValue, top, bottom)
				element:SetVertexColor(0, .7, 0, .25)
				element:Show()

			elseif (change < 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMLEFT", previewTexture, "BOTTOMLEFT", 0, 0)
				element:SetSize(-change*previewWidth, previewHeight)
				element:SetTexCoord(texValue, texValue + texChange, top, bottom)
				element:SetVertexColor(.5, 0, 0, .75)
				element:Show()

			else
				element:Hide()
			end
		end
	else
		element:Hide()
	end

end

local Cast_CustomDelayText = function(element, duration)
	-- WoW 12.0.1: duration may be a timer object, extract number
	if type(duration) == "table" and duration.GetRemainingDuration then
		duration = duration:GetRemainingDuration() or 0
	end
	if (element.casting) and element.max then
		duration = element.max - duration
	end
	local delay = element.delay or 0
	if type(duration) == "number" then
		element.Time:SetFormattedText("%.1f |cffff0000%s%.2f|r", duration, element.casting and "+" or "-", delay)
	end
end

local Cast_CustomTimeText = function(element, duration)
	-- WoW 12.0.1: duration may be a timer object, extract number
	if type(duration) == "table" and duration.GetRemainingDuration then
		duration = duration:GetRemainingDuration() or 0
	end
	if (element.casting) and element.max then
		duration = element.max - duration
	end
	if type(duration) == "number" then
		element.Time:SetFormattedText("%.1f", duration)
	end
end

local Cast_PostCastStart = function(element, unit)
	local self = element.__owner
	local db = ns.db
	local showCastbar = db and db.global and db.global.unitframes and db.global.unitframes.showTargetCastbar

	if showCastbar then
		self.Name:Hide()
		self.Health.Value:Hide()
		element.Text:Show()
		element.Time:Show()
		element:SetAlpha(1)
		element:Show()
		local _,class = UnitClass(unit)
		if (class == "PRIEST") then
			element:SetStatusBarColor(.3, .3, .3, .25)
		else
			element:SetStatusBarColor(1, 1, 1, .25)
		end
	else
		element.Text:Hide()
		element.Time:Hide()
		element:SetAlpha(0)
	end
end

local Cast_PostCastStop = function(element, unit, spellID)
	local self = element.__owner
	self.Name:Show()
	self.Health.Value:Show()
	self.Health.Value:UpdateTag()
	element.Text:Hide()
	element.Time:Hide()
	element:SetAlpha(1)
	element:Show()
end

local Cast_PostCastFail = function(element, unit, spellID)
	local self = element.__owner
	self.Name:Show()
	self.Health.Value:Show()
	element:Show()
	self.Health.Value:UpdateTag()

	local r, g, b = self.colors.normal[1], self.colors.normal[2], self.colors.normal[3]
	element.Text:SetTextColor(r, g, b)
	element.Text:Hide()
	element.Time:Hide()
	element:SetAlpha(1)
	element:SetValue(0)
end

-- Update health color setting based on user preference.
local UpdateHealthColor = function(self)
	if (not self.Health) then return end
	local db = ns.db
	if db and db.global and db.global.unitframes then
		self.Health.colorHealth = db.global.unitframes.useHealthColorForTarget
		if (self.unit) then
			self.Health:ForceUpdate()
		end
	end
end

-- Update artwork based on unit classification.
local UpdateArtwork = function(self)
	local unit = self.unit
	if (not unit) then
		return
	end
	local l = UnitLevel(unit)
	if (not ns.IsWrath) then
		if (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
			l = UnitBattlePetLevel(unit)
		end
	end
	local c = UnitClassification(unit)
	if (c == "worldboss" or (l and l < 1) or c == "elite" or c == "rareelite" or c == "rare") then
		self.Backdrop:SetTexture(GetMedia("target-elite-diabolic"))
		self.Health:SetStatusBarTexture(GetMedia("target-bar-elite-diabolic"))
	else
		self.Backdrop:SetTexture(GetMedia("target-normal-diabolic"))
		self.Health:SetStatusBarTexture(GetMedia("target-bar-normal-diabolic"))
	end
end

UnitStyles["Target"] = function(self, unit, id)

	self:SetSize(350,75)

	local backdrop = self:CreateTexture(self:GetName().."Backdrop", "BACKGROUND", nil, -1)
	backdrop:SetSize(512,128)
	backdrop:SetPoint("CENTER")

	self.Backdrop = backdrop

	-- Health
	--------------------------------------------
	local health = self:CreateBar(self:GetName().."HealthBar")
	health:SetFrameLevel(health:GetFrameLevel() + 2)
	health:SetSize(291,43)
	health:SetPoint("CENTER")
	health:SetStatusBarTexture(GetMedia("target-bar-normal-diabolic"))
	health:GetStatusBarTexture():SetTexCoord(221/1024, 803/1024, 85/256, 171/256)
	health:SetSparkTexture(GetMedia("blank"))
	health.colorDisconnected = true
	health.colorTapping = true
	health.colorClass = true
	health.colorReaction = true
	local db = ns.db
	health.colorThreat = true
	health.colorHealth = true
	if db and db.global and db.global.unitframes then
		health.colorHealth = db.global.unitframes.useHealthColorForTarget
		if db.global.unitframes.showThreatOnTarget ~= nil then
			health.colorThreat = db.global.unitframes.showThreatOnTarget
		end
	end

	self.Health = health
	self.Health.Override = ns.API.UpdateHealth
	self.Health.PostUpdate = Health_PostUpdate
	self.Health.PostUpdateColor = Health_PostUpdateColor

	-- Health Preview
	--------------------------------------------
	local preview = self:CreateBar(health:GetName().."Preview", health)
	preview:SetFrameLevel(health:GetFrameLevel() - 1)
	preview:SetSize(291,43)
	preview:SetPoint("CENTER")
	preview:SetStatusBarTexture(GetMedia("target-bar-normal-diabolic"))
	preview:GetStatusBarTexture():SetTexCoord(221/1024, 803/1024, 85/256, 171/256)
	preview:SetSparkTexture(GetMedia("blank"))
	preview:SetAlpha(.5)
	preview:DisableSmoothing(true)

	self.Health.Preview = preview

	-- Health Prediction
	--------------------------------------------
	local healPredictFrame = CreateFrame("Frame", nil, health)
	healPredictFrame:SetFrameLevel(health:GetFrameLevel() + 2)
	healPredictFrame:SetAllPoints()

	local healPredict = healPredictFrame:CreateTexture(health:GetName().."Prediction", "OVERLAY")
	healPredict:SetTexture(GetMedia("target-bar-normal-diabolic"))
	healPredict.health = health
	healPredict.preview = preview
	healPredict.maxOverflow = 1

	self.HealthPrediction = healPredict
	self.HealthPrediction.PostUpdate = HealPredict_PostUpdate

	-- Health Value
	--------------------------------------------
	local healthValue = health:CreateFontString(nil, "OVERLAY", nil, 0)
	healthValue:SetFontObject(GetFont(16,true))
	healthValue:SetTextColor(unpack(self.colors.offwhite))
	healthValue:SetPoint("CENTER", 0, 0)

	self:Tag(healthValue, "["..ns.Prefix..":Health]")

	self.Health.Value = healthValue

	-- Unit Name
	--------------------------------------------
	local name = self:CreateFontString(nil, "OVERLAY", nil, 0)
	name:SetJustifyH("CENTER")
	name:SetFontObject(GetFont(16,true))
	name:SetTextColor(unpack(self.colors.offwhite))
	name:SetAlpha(.85)
	name:SetPoint("BOTTOM", self, "TOP", 0, 0)

	self:Tag(name, "["..ns.Prefix..":Level:Prefix][name]["..ns.Prefix..":Rare:Suffix]")

	self.Name = name

	-- CombatFeedback
	--------------------------------------------
	local feedbackText = self:CreateFontString(nil, "OVERLAY")
	feedbackText.maxAlpha = .8
	feedbackText.feedbackFont = GetFont(20, true)
	feedbackText.feedbackFontLarge = GetFont(24, true)
	feedbackText.feedbackFontSmall = GetFont(18, true)
	feedbackText:SetFontObject(feedbackText.feedbackFont)
	feedbackText:SetPoint("RIGHT", self, "LEFT", -4, 2)

	self.CombatFeedback = feedbackText

	-- Cast Bar (temporarily disabled for testing gray overlay on health bar)
	--------------------------------------------
	--[[
	local cast = self:CreateBar(self:GetName())
	cast:SetFrameLevel(health:GetFrameLevel() + 3)
	cast:SetSize(291,43)
	cast:SetPoint("CENTER")
	cast:SetStatusBarTexture(GetMedia("target-bar-normal-diabolic"))
	cast:GetStatusBarTexture():SetTexCoord(221/1024, 803/1024, 85/256, 171/256)
	cast:SetStatusBarColor(1, 1, 1, .25)
	cast:SetSparkTexture(GetMedia("blank"))
	cast:DisableSmoothing(true)
	cast.timeToHold = 0.5

	local castTime = cast:CreateFontString(nil, "OVERLAY", nil, 0)
	castTime:SetFontObject(GetFont(16,true))
	castTime:SetTextColor(unpack(self.colors.offwhite))
	castTime:SetPoint("CENTER", 0, 0)
	cast.Time = castTime

	local castText = cast:CreateFontString(nil, "OVERLAY", nil, 0)
	castText:SetFontObject(GetFont(16,true))
	castText:SetTextColor(unpack(self.colors.offwhite))
	castText:SetAlpha(.85)
	castText:SetPoint("BOTTOM", self, "TOP", 0, 0)
	cast.Text = castText

	cast.CustomDelayText = Cast_CustomDelayText
	cast.CustomTimeText = Cast_CustomTimeText
	cast.PostCastFail = Cast_PostCastFail
	cast.PostCastStop = Cast_PostCastStop
	cast.PostCastStart = Cast_PostCastStart
	cast:SetScript("OnHide", Cast_PostCastStop)

	self.Castbar = cast
	--]]

	-- Auras
	--------------------------------------------
	local auras = CreateFrame("Frame", nil, self)
	local twoRows = ns.db and ns.db.global and ns.db.global.auras and ns.db.global.auras.twoRowsTargetAuras
	if twoRows then
		auras:SetSize(40*7-4, 36*2+4)  -- 2 rows: height for 2 aura rows + spacing
		auras.numTotal = 14
	else
		auras:SetSize(40*7-4, 36)  -- 1 row
		auras.numTotal = 7
	end
	auras:SetPoint("TOP", self, "BOTTOM", 0, -12)
	auras.size = 36
	auras.spacing = 4
	auras.disableMouse = false
	auras.disableCooldown = false
	auras.onlyShowPlayer = false
	auras.showStealableBuffs = false
	auras.initialAnchor = "TOPLEFT"
	auras["spacing-x"] = 4
	auras["spacing-y"] = 4
	auras["growth-x"] = "RIGHT"
	auras["growth-y"] = "DOWN"
	auras.tooltipAnchor = "ANCHOR_BOTTOMRIGHT"
	auras.reanchorIfVisibleChanged = true
	auras.CreateButton = ns.AuraStyles.CreateButton_NonSecure
	auras.PostUpdateButton = ns.AuraStyles.TargetPostUpdateButton
	auras.FilterAura = ns.AuraFilters.TargetAuraFilter
	auras.SortAuras = ns.AuraSorts.DefaultFunction

	self.Auras = auras

	self.PostUpdate = UpdateArtwork
	self:RegisterEvent("PLAYER_TARGET_CHANGED", UpdateArtwork, true)
	self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", UpdateArtwork, true)

	self.UpdateHealthColor = UpdateHealthColor

	self.UpdateTargetAurasVisibility = function(self)
		local hide = ns.db and ns.db.global and ns.db.global.auras and ns.db.global.auras.hideTargetAuras
		if hide then
			self.Auras.Show = function() end  -- prevent oUF/any code from showing it back
			self.Auras:Hide()
		else
			self.Auras.Show = nil  -- restore default Show
			self.Auras:Show()
		end
	end
	self:UpdateTargetAurasVisibility()
	ns.RegisterCallback(self, "TargetAuras_Visibility_Updated", "UpdateTargetAurasVisibility")

end