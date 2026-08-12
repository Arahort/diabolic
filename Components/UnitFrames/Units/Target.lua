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
	ns.API.SetPreviewColor(element.Preview, r, g, b)
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

-- Castbar: remaining time, with the casting delay appended in red.
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

-- Castbar: remaining time only.
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

-- Interruptible casts are red; protected (non-interruptible) casts are tinted
-- blue-grey like Platynator. element.notInterruptible is a *secret boolean* for
-- enemy targets in WoW 12.0, so we must NOT branch on it in Lua (if/and/or/not).
-- Instead we derive each colour channel with the secret-safe C-function
-- C_CurveUtil.EvaluateColorValueFromBoolean(bool, valueIfTrue, valueIfFalse):
-- notInterruptible == true -> protected colour, false -> interruptible (red).
-- The result is fed straight into the C-side SetStatusBarColor — no Lua boolean
-- test ever happens. Comparing to nil is fine, as a secret boolean is never
-- equal to nil (deterministic, leaks nothing).
local CAST_COLOR_PROTECTED = { .51, .75, .76 }

local Cast_UpdateInterruptible = function(element, unit)
	local notInt = element.notInterruptible
	if (notInt == nil) then
		notInt = false
	end
	local ok = Colors.red
	local ev = C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean
	if (ev) then
		element:SetStatusBarColor(
			ev(notInt, CAST_COLOR_PROTECTED[1], ok[1]),
			ev(notInt, CAST_COLOR_PROTECTED[2], ok[2]),
			ev(notInt, CAST_COLOR_PROTECTED[3], ok[3])
		)
	else
		element:SetStatusBarColor(ok[1], ok[2], ok[3])
	end
end

local Cast_PostCastStart = function(element, unit)
	Cast_UpdateInterruptible(element, unit)
end

-- Update health color setting based on user preference.
local UpdateHealthColor = function(self)
	if (not self.Health) then return end
	local db = ns.db
	if db and db.global and db.global.unitframes then
		self.Health.colorHealth = db.global.unitframes.useHealthColorForTarget
		if (self.__unit) then
			self.Health:ForceUpdate()
		end
	end
end

-- Update artwork based on unit classification.
local UpdateArtwork = function(self)
	local unit = self.__unit
	if (not unit) then
		return
	end
	local l = UnitLevel(unit)
	if (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
		l = UnitBattlePetLevel(unit)
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
	-- Start out with the normal artwork. UpdateArtwork swaps in the elite frame from
	-- PostUpdate, and if any element ever throws before that runs, the frame would
	-- otherwise be left without a border at all.
	backdrop:SetTexture(GetMedia("target-normal-diabolic"))

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

	-- Cast Bar
	--------------------------------------------
	-- Parented to the frame so it scales together with the EditMode target scale.
	-- Bar/border/background textures match the Party HP/Power bars for a consistent
	-- look. Visibility is driven by "showTargetCastbar" via the ShouldShow override.
	--
	-- NOTE: this MUST be a native StatusBar, not self:CreateBar (LibSmoothBar).
	-- The modern oUF Castbar fills the bar through StatusBar:SetTimerDuration and
	-- updates/hides it through its OnUpdate; LibSmoothBar stubs out SetTimerDuration
	-- and never runs the OnUpdate, so a smooth bar would never fill or disappear.
	local CAST_WIDTH, CAST_HEIGHT = 240, 20
	local CAST_BORDER_PAD_X, CAST_BORDER_PAD_Y = 10, 8
	local CAST_BACK_PAD_X, CAST_BACK_PAD_Y = 2, 2
	local CAST_ICON_SIZE = CAST_HEIGHT + CAST_BORDER_PAD_Y

	local cast = CreateFrame("StatusBar", self:GetName().."Castbar", self)
	cast:SetSize(CAST_WIDTH, CAST_HEIGHT)
	cast:SetPoint("TOP", self, "BOTTOM", 0, -10)
	cast:SetFrameLevel(health:GetFrameLevel() + 4)
	cast:SetStatusBarTexture(GetMedia("statusbar/Heath-Bar"))
	cast:SetStatusBarColor(unpack(Colors.red))
	cast.timeToHold = 0.5

	-- Bar background behind the fill
	local castBack = cast:CreateTexture(nil, "BACKGROUND", nil, -2)
	castBack:SetSize(CAST_WIDTH + CAST_BACK_PAD_X, CAST_HEIGHT + CAST_BACK_PAD_Y)
	castBack:SetPoint("CENTER", cast, "CENTER", 0, 0)
	castBack:SetTexture(GetMedia("statusbar/Heath-Bar-Back"))
	castBack:SetVertexColor(.15, .15, .15, .85)

	-- Decorative border around the bar
	local castBorder = cast:CreateTexture(nil, "OVERLAY", nil, 0)
	castBorder:SetSize(CAST_WIDTH + CAST_BORDER_PAD_X, CAST_HEIGHT + CAST_BORDER_PAD_Y)
	castBorder:SetPoint("CENTER", cast, "CENTER", 0, 0)
	castBorder:SetTexture(GetMedia("statusbar/Health-Bar-Border2"))

	-- Spell icon to the left of the bar
	local castIcon = cast:CreateTexture(nil, "OVERLAY", nil, 1)
	castIcon:SetSize(CAST_ICON_SIZE, CAST_ICON_SIZE)
	castIcon:SetPoint("RIGHT", cast, "LEFT", -8, 0)
	castIcon:SetTexCoord(5/64, 59/64, 5/64, 59/64) -- trim the default icon border
	cast.Icon = castIcon

	-- Border around the spell icon (same art as the bar border)
	local castIconBorder = cast:CreateTexture(nil, "ARTWORK", nil, 0)
	castIconBorder:SetSize(CAST_ICON_SIZE + CAST_BORDER_PAD_X, CAST_ICON_SIZE + CAST_BORDER_PAD_Y)
	castIconBorder:SetPoint("CENTER", castIcon, "CENTER", 0, 0)
	castIconBorder:SetTexture(GetMedia("statusbar/Health-Bar-Border2"))

	-- "Cannot interrupt" shield (copied from Platynator). oUF shows/hides it
	-- automatically on protected casts via Shield:SetAlphaFromBoolean(notInterruptible).
	local castShield = cast:CreateTexture(nil, "OVERLAY", nil, 3)
	castShield:SetSize(CAST_ICON_SIZE * 1.0, CAST_ICON_SIZE * 1.0 * (165/136))
	castShield:SetPoint("RIGHT", castIcon, "LEFT", -6, 0)
	castShield:SetTexture(GetMedia("target-castbar-shield", "png"))
	cast.Shield = castShield

	-- Spell name
	local castText = cast:CreateFontString(nil, "OVERLAY", nil, 7)
	castText:SetFontObject(GetFont(14, true))
	castText:SetTextColor(unpack(self.colors.offwhite))
	castText:SetJustifyH("LEFT")
	castText:SetWordWrap(false)
	castText:SetPoint("LEFT", cast, "LEFT", 6, 0)
	castText:SetPoint("RIGHT", cast, "RIGHT", -36, 0)
	cast.Text = castText

	-- Remaining cast time
	local castTime = cast:CreateFontString(nil, "OVERLAY", nil, 7)
	castTime:SetFontObject(GetFont(14, true))
	castTime:SetTextColor(unpack(self.colors.offwhite))
	castTime:SetJustifyH("RIGHT")
	castTime:SetPoint("RIGHT", cast, "RIGHT", -6, 0)
	cast.Time = castTime

	cast.CustomDelayText = Cast_CustomDelayText
	cast.CustomTimeText = Cast_CustomTimeText
	cast.PostCastStart = Cast_PostCastStart
	cast.PostCastInterruptible = Cast_UpdateInterruptible

	-- Gate the castbar on the user setting (default on). Returning false here
	-- stops oUF from ever showing the bar while the option is disabled.
	cast.ShouldShow = function(element, unit)
		local show = ns.db and ns.db.global and ns.db.global.unitframes and ns.db.global.unitframes.showTargetCastbar
		if (show == nil) then show = true end
		return show and (element.__owner.__unit == unit)
	end

	self.Castbar = cast

	-- Auras
	--------------------------------------------
	-- WoW 12.1: auras live in an AuraContainer. Filtering happens through filter
	-- strings, so "who cast this" is expressed as separate groups instead of a Lua
	-- filter: the player's own auras come first in full color, foreign ones follow
	-- dimmed, exactly the order the old comparator produced.
	local twoRows = ns.db and ns.db.global and ns.db.global.auras and ns.db.global.auras.twoRowsTargetAuras
	local rows = twoRows and 2 or 1
	local perRow = 7
	local auras = self:CreateAuras({
		initialAnchor = "TOPLEFT",
		growthX = "RIGHT",
		growthY = "DOWN",
		layoutLimit = 40*perRow-4,
	})
	auras:SetSize(40*perRow-4, 36*rows + (rows-1)*4)
	-- Anchor is set by UpdateTargetCastbar (depends on whether the castbar is shown).
	auras.size = 36
	auras.elementSpacing = 4
	auras.lineSpacing = 4
	auras.groupSpacing = 4
	auras.disableMouse = false
	auras.disableCooldown = false
	auras.tooltipAnchor = "ANCHOR_BOTTOMRIGHT"
	auras.sortMethod = ns.AuraSorts.Default
	auras.sortDirection = ns.AuraSorts.DefaultDirection
	auras.CreateButton = ns.AuraStyles.CreateButton

	local maxPerGroup = perRow * rows
	auras:AddGroup(ns.AuraFilters.OwnBuffs, { maxFrameCount = maxPerGroup })
	auras:AddGroup(ns.AuraFilters.OwnDebuffs, { maxFrameCount = maxPerGroup })
	auras.foreignBuffGroup = auras:AddGroup(ns.AuraFilters.ForeignBuffs, {
		maxFrameCount = maxPerGroup,
		PostCreateButton = ns.AuraStyles.PostCreateForeignButton,
	})
	auras.foreignDebuffGroup = auras:AddGroup(ns.AuraFilters.ForeignDebuffs, {
		maxFrameCount = maxPerGroup,
		PostCreateButton = ns.AuraStyles.PostCreateForeignButton,
	})

	self.Auras = auras

	-- "Show only my debuffs" is now a filter swap on the foreign debuff group.
	self.UpdateTargetDebuffFilter = function(self)
		local onlyMine = ns.db and ns.db.char and ns.db.char.unitframes and ns.db.char.unitframes.showOnlyMyDebuffs
		self.Auras:SetAuraGroupMaxFrameCount(self.Auras.foreignDebuffGroup, onlyMine and 0 or maxPerGroup)
	end

	self.PostUpdate = UpdateArtwork
	self:RegisterEvent("PLAYER_TARGET_CHANGED", UpdateArtwork, true)
	self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", UpdateArtwork, true)

	self.UpdateHealthColor = UpdateHealthColor

	self.UpdateTargetAurasVisibility = function(self)
		local hide = ns.db and ns.db.global and ns.db.global.auras and ns.db.global.auras.hideTargetAuras
		-- The container drives its own visibility, so it is switched off at the
		-- source rather than by neutralizing Show().
		self.Auras:SetEnabled(not hide)
		self.Auras:SetShown(not hide)
	end
	self:UpdateTargetAurasVisibility()
	self:UpdateTargetDebuffFilter()
	ns.RegisterCallback(self, "TargetAuras_Visibility_Updated", "UpdateTargetAurasVisibility")
	ns.RegisterCallback(self, "TargetAuras_Filter_Updated", "UpdateTargetDebuffFilter")

	-- React to the "show target castbar" toggle: when on, reserve space and
	-- anchor the auras below the castbar; when off, hide it and pull the auras
	-- back up to the frame. Actual cast visibility is handled by Castbar:ShouldShow.
	-- Position the castbar (above the name or below the frame) and re-anchor the
	-- auras accordingly, based on the two options. Also refreshes the EditMode
	-- preview so toggling the options while EditMode is open updates live.
	self.UpdateTargetCastbar = function(self)
		local uf = ns.db and ns.db.global and ns.db.global.unitframes
		local show = true
		if (uf and uf.showTargetCastbar ~= nil) then show = uf.showTargetCastbar end
		local aboveName = uf and uf.showTargetCastbarAboveName
		local cast = self.Castbar
		cast:ClearAllPoints()
		self.Auras:ClearAllPoints()
		if (show and aboveName) then
			-- WoW 12.1: the unit name is a secret string, so the name font string has
			-- secret anchors, and anything anchored to it inherits that. The cast bar
			-- would then report a secret width, which breaks the empower stage pips.
			-- It hangs off the frame itself instead, cleared by the name's line height.
			local _, nameFontSize = self.Name:GetFont()
			cast:SetPoint("BOTTOM", self, "TOP", 0, 8 + (nameFontSize or 16))
			self.Auras:SetPoint("TOP", self, "BOTTOM", 0, -12)
		elseif (show) then
			cast:SetPoint("TOP", self, "BOTTOM", 0, -10)
			self.Auras:SetPoint("TOP", cast, "BOTTOM", 0, -14)
		else
			cast:SetPoint("TOP", self, "BOTTOM", 0, -10)
			self.Auras:SetPoint("TOP", self, "BOTTOM", 0, -12)
			if (cast:IsShown() and not self.castbarPreviewActive) then
				cast:Hide()
			end
		end
		self:RefreshCastbarPreview()
	end

	-- EditMode preview: while EditMode is open, fill the castbar with a sample cast
	-- (like the debuffs preview) so it can be positioned, but only when the castbar
	-- option is on. The oUF element is disabled during preview, otherwise its
	-- OnUpdate would instantly hide our static sample.
	self.RefreshCastbarPreview = function(self)
		local cast = self.Castbar
		if (not cast) then return end
		local uf = ns.db and ns.db.global and ns.db.global.unitframes
		local show = true
		if (uf and uf.showTargetCastbar ~= nil) then show = uf.showTargetCastbar end
		if (self.inEditMode and show) then
			if (not self.castbarPreviewActive) then
				self:DisableElement("Castbar")
				self.castbarPreviewActive = true
			end
			local previewSpell = 116 -- Frostbolt: localized name + matching icon via C_Spell
			local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(previewSpell)
			local icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(previewSpell)
			if (cast.Icon) then cast.Icon:SetTexture(icon or 134400) end
			if (cast.Text) then cast.Text:SetText(name or "") end
			if (cast.Time) then cast.Time:SetText("1.5") end
			if (cast.Shield) then cast.Shield:SetAlpha(0) end
			cast:SetStatusBarColor(unpack(Colors.red))
			cast:SetMinMaxValues(0, 1)
			cast:SetValue(0.66)
			cast:Show()
		elseif (self.castbarPreviewActive) then
			self.castbarPreviewActive = nil
			self:EnableElement("Castbar")
			cast:Hide()
		end
	end
	self.ShowCastbarPreview = function(self)
		self.inEditMode = true
		self:RefreshCastbarPreview()
	end
	self.HideCastbarPreview = function(self)
		self.inEditMode = nil
		self:RefreshCastbarPreview()
	end
	self:UpdateTargetCastbar()
	ns.RegisterCallback(self, "UnitFrames_Settings_Updated", "UpdateTargetCastbar")

end