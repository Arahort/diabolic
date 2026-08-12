local Addon, ns = ...
local UnitStyles = ns.UnitStyles
if (not UnitStyles) then
	return
end
local oUF = ns.oUF
-- Lua API
local unpack = unpack
-- WoW API
local CreateFrame = CreateFrame
local SetPortraitTexture = SetPortraitTexture
local UnitGUID = UnitGUID
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsUnit = UnitIsUnit
local UnitPowerMax = UnitPowerMax
local issecretvalue = issecretvalue or function() return false end
-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
-- AzeriteUI silver "ui" color
local UI_R, UI_G, UI_B = 192/255, 192/255, 192/255
-- Config
local FRAME_WIDTH = 130
local FRAME_HEIGHT = 170
-- Portrait (pushed up to leave space below for plate)
local PORTRAIT_SIZE_W = 70
local PORTRAIT_SIZE_H = 73
local PORTRAIT_OFFSET_Y = 62
local PORTRAIT_BG_SIZE = 130
local PORTRAIT_BG_OFFSET_Y = 24
local PORTRAIT_SHADE_SIZE = 86
local PORTRAIT_SHADE_OFFSET_Y = 46
local PORTRAIT_BORDER_SIZE = 194
local PORTRAIT_BORDER_OFFSET_Y = -8
-- Backdrop plate (cast_back AzeriteUI texture around HP/Power)
local PLATE_WIDTH = 140
local PLATE_HEIGHT = 90
local PLATE_OFFSET_X = 1
local PLATE_OFFSET_Y = -2
-- Health bar (thicker)
local HEALTH_WIDTH = 100
local HEALTH_HEIGHT = 16
local HEALTH_OFFSET_Y = 28
-- Power bar (thicker, borders touch HP border - no gap)
local POWER_WIDTH = 100
local POWER_HEIGHT = 10
local POWER_OFFSET_Y = 10
-- Border/BG padding relative to bar size
local BAR_BORDER_PAD_X = 10 -- border +10 wider than bar
local BAR_BORDER_PAD_Y = 8  -- border +8 taller than bar
local BAR_BG_PAD_X = 2      -- inner bg +2 wider
local BAR_BG_PAD_Y = 2
-- Shared namespace export (for EditMode runtime updates from UnitFrames.lua)
ns.PartyLayout = ns.PartyLayout or {}
ns.PartyLayout.HEALTH_WIDTH = HEALTH_WIDTH
ns.PartyLayout.POWER_WIDTH = POWER_WIDTH
ns.PartyLayout.POWER_OFFSET_Y = POWER_OFFSET_Y
ns.PartyLayout.BORDER_PAD_X = BAR_BORDER_PAD_X
ns.PartyLayout.BORDER_PAD_Y = BAR_BORDER_PAD_Y
ns.PartyLayout.BG_PAD_X = BAR_BG_PAD_X
ns.PartyLayout.BG_PAD_Y = BAR_BG_PAD_Y
-- Compute HP offset such that HP border touches Power border with no gap
-- HP border bottom = HP_OFFSET_Y - BORDER_PAD_Y/2
-- Power border top = POWER_OFFSET_Y + POWER_HEIGHT + BORDER_PAD_Y/2
-- For contact: HP_OFFSET_Y = POWER_OFFSET_Y + POWER_HEIGHT + BORDER_PAD_Y
ns.PartyLayout.ComputeHpOffset = function(powerHeight)
	return POWER_OFFSET_Y + powerHeight + BAR_BORDER_PAD_Y
end
-- Apply new HP/Power heights to a single party frame at runtime
ns.PartyLayout.ApplyBarHeights = function(frame, hpHeight, powerHeight)
	if (not frame or not frame.Health) then return end
	local hpOffset = ns.PartyLayout.ComputeHpOffset(powerHeight)
	-- Power bar + its decorations
	if (frame.Power) then
		frame.Power:SetHeight(powerHeight)
		frame.Power:ClearAllPoints()
		frame.Power:SetPoint("BOTTOM", 0, POWER_OFFSET_Y)
	end
	if (frame.PowerBackdrop) then
		frame.PowerBackdrop:SetSize(POWER_WIDTH + BAR_BORDER_PAD_X, powerHeight + BAR_BORDER_PAD_Y)
	end
	if (frame.PowerBarBackground) then
		frame.PowerBarBackground:SetSize(POWER_WIDTH + BAR_BG_PAD_X, powerHeight + BAR_BG_PAD_Y)
	end
	-- HP bar + its decorations
	frame.Health:SetHeight(hpHeight)
	frame.Health:ClearAllPoints()
	frame.Health:SetPoint("BOTTOM", 0, hpOffset)
	if (frame.HealthBackdrop) then
		frame.HealthBackdrop:SetSize(HEALTH_WIDTH + BAR_BORDER_PAD_X, hpHeight + BAR_BORDER_PAD_Y)
	end
	if (frame.HealthBarBackground) then
		frame.HealthBarBackground:SetSize(HEALTH_WIDTH + BAR_BG_PAD_X, hpHeight + BAR_BG_PAD_Y)
	end
end
-- Role icon
local ROLE_ICON_SIZE = 34
local ROLE_BACKDROP_SIZE = 77
-- Auras (3 per row, unlimited rows — up to 40 total)
local AURA_SIZE = 30
local AURA_SPACING = 4
local AURA_PER_ROW = 3
local AURA_ROWS = 14
local AURA_TOTAL = 40
-- Health post-update for color
local Health_PostUpdateColor = function(element, unit, r, g, b)
	if type(r) == "table" and r.GetRGB then
		r, g, b = r:GetRGB()
	end
	if r and g and b then
		element:SetStatusBarColor(r, g, b)
	end
end
-- Portrait post-update (handles offline/OOR state)
-- Skip expensive ClearModel+SetUnit when unit GUID hasn't changed (prevents
-- animation restart on units like focustarget that get frequent updates).
local Portrait_PostUpdate = function(element, unit, hasStateChanged)
	-- WoW 12.0: UnitGUID can return secret value for focustarget/targettarget in combat.
	-- Comparing or storing secret values would taint the portrait frame.
	local ok, newGuid = pcall(UnitGUID, unit)
	if (not ok) then newGuid = nil end
	local guidIsSecret = newGuid and issecretvalue(newGuid)
	if (guidIsSecret) then newGuid = nil end
	-- Ensure the 2D fallback texture exists (used when 3D model is unavailable).
	if (not element.fallback2DTexture) then
		element.fallback2DTexture = element:CreateTexture()
		element.fallback2DTexture:SetDrawLayer("ARTWORK")
		element.fallback2DTexture:SetAllPoints()
		element.fallback2DTexture:SetTexCoord(.1, .9, .1, .9)
	end
	-- Offline/OOR: always use 2D fallback.
	if (not element.state) then
		if (element.guid ~= newGuid) then
			element:ClearModel()
			pcall(SetPortraitTexture, element.fallback2DTexture, unit)
			element.guid = newGuid
		end
		element.fallback2DTexture:Show()
		return
	end
	-- Secret unit (typical focustarget on hostile NPC): 3D model can't be loaded safely,
	-- so show a 2D portrait texture instead — prevents an empty frame.
	if (guidIsSecret) then
		element:ClearModel()
		pcall(SetPortraitTexture, element.fallback2DTexture, unit)
		element.fallback2DTexture:Show()
		element.guid = nil
		return
	end
	-- Normal path: 3D unit model.
	if (element.fallback2DTexture) then
		element.fallback2DTexture:Hide()
	end
	if (element.guid == newGuid) then
		return -- same unit — don't restart animation
	end
	element:SetCamDistanceScale(1)
	element:SetPortraitZoom(1)
	element:SetPosition(0, 0, 0)
	element:SetRotation(0)
	element:ClearModel()
	pcall(element.SetUnit, element, unit)
	element.guid = newGuid
end
-- Power post-update (hide when dead/disconnected or no power resource).
-- WoW 12.0: on units like focustarget (hostile NPC) UnitPowerMax can return a
-- secret value or 0 — in that case hide the bar AND its decorative backdrops
-- instead of showing an empty slot.
local Power_PostUpdate = function(element, unit, cur, min, max)
	local parent = element.__owner or element:GetParent()
	local function setVisible(show)
		if (show) then
			element:Show()
			if (parent and parent.PowerBarBackground) then parent.PowerBarBackground:Show() end
			if (parent and parent.PowerBackdrop) then parent.PowerBackdrop:Show() end
		else
			element:Hide()
			if (parent and parent.PowerBarBackground) then parent.PowerBarBackground:Hide() end
			if (parent and parent.PowerBackdrop) then parent.PowerBackdrop:Hide() end
		end
	end
	if (not UnitIsConnected(unit)) or UnitIsDeadOrGhost(unit) then
		setVisible(false)
		return
	end
	-- WoW 12.1: UnitPowerMax is SecretWhenUnitPowerMaxRestricted, and a secret number
	-- cannot be compared, so the old code treated every restricted unit as having no
	-- power at all and hid the bar. Party members and allied NPCs ended up without any
	-- resource bar. The bar is only hidden when the maximum is readable and really zero,
	-- which still covers the mobs this was written for.
	local maxKnown = max and (not issecretvalue(max))
	if (not maxKnown) then
		local okMax, realMax = pcall(UnitPowerMax, unit)
		if (okMax and realMax and not issecretvalue(realMax)) then
			maxKnown, max = true, realMax
		end
	end
	setVisible((not maxKnown) or (max > 0))
end
-- Group role override
local GroupRoleIndicator_Override = function(self, event)
	local element = self.GroupRoleIndicator
	if (not element) then return end
	local unit = self.__unit
	-- The focus and focus target frames borrow this style but are not group members,
	-- so they have no role to show. Asking anyway returns a secret string in 12.1 once
	-- the unit's identity is restricted, and comparing that to "TANK" is not allowed,
	-- which left whatever icon the previous occupant of the frame had.
	if (not unit) or (not unit:match("^party") and not unit:match("^raid")) then
		element:Hide()
		return
	end
	local role = UnitGroupRolesAssigned(unit)
	if (issecretvalue(role)) then
		element:Hide()
		return
	end
	if (role == "TANK" or role == "HEALER" or role == "DAMAGER") then
		element.Icon:SetTexture(element[role])
		element:Show()
	else
		element:Hide()
	end
end
-- Target highlight update: color the portrait border golden when unit is targeted
local TargetHighlight_Update = function(self, event, unit)
	if (unit and unit ~= self.__unit) then return end
	unit = unit or self.__unit
	if (not self.Portrait or not self.Portrait.Border) then return end
	local border = self.Portrait.Border
	if (unit and UnitIsUnit(unit, "target")) then
		-- Golden target color
		border:SetVertexColor(1, .94, .66, 1)
	else
		-- Default silver
		border:SetVertexColor(UI_R, UI_G, UI_B, 1)
	end
end
-- Style function
UnitStyles["Party"] = function(self, unit, id)
	self:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
	-- Tag this frame so ForEachPartyFrame (in UnitFrames.lua) can find it
	-- regardless of unit token (party/player/focus/focustarget/etc.)
	self.__isDiabolicGroupFrame = true
	-- Apply saved scale from char.groupFrames (EditMode slider)
	if (ns.db and ns.db.char and ns.db.char.groupFrames and ns.db.char.groupFrames.scale and ns.API.SetEditModeUFObjectScale) then
		ns.API.SetEditModeUFObjectScale(self, ns.db.char.groupFrames.scale)
	end
	-- Overlay (for text/icons on top)
	local overlay = CreateFrame("Frame", nil, self)
	overlay:SetFrameLevel(self:GetFrameLevel() + 7)
	overlay:SetAllPoints()
	self.Overlay = overlay
	-- Portrait frame (lower than self for background)
	local portraitFrame = CreateFrame("Frame", nil, self)
	portraitFrame:SetFrameLevel(self:GetFrameLevel())
	portraitFrame:SetAllPoints()
	-- Portrait
	local portrait = CreateFrame("PlayerModel", self:GetName().."Portrait", portraitFrame)
	portrait:SetFrameLevel(portraitFrame:GetFrameLevel())
	portrait:SetSize(PORTRAIT_SIZE_W, PORTRAIT_SIZE_H)
	portrait:SetPoint("BOTTOM", 0, PORTRAIT_OFFSET_Y)
	portrait:SetAlpha(.85)
	self.Portrait = portrait
	self.Portrait.PostUpdate = Portrait_PostUpdate
	-- Portrait background
	local portraitBg = portraitFrame:CreateTexture(nil, "BACKGROUND", nil, 0)
	portraitBg:SetSize(PORTRAIT_BG_SIZE, PORTRAIT_BG_SIZE)
	portraitBg:SetPoint("BOTTOM", 0, PORTRAIT_BG_OFFSET_Y)
	portraitBg:SetTexture(GetMedia("UnitFrames/Group/party_portrait_back"))
	portraitBg:SetVertexColor(.5, .5, .5)
	self.Portrait.Bg = portraitBg
	-- Portrait overlay (shade + border)
	local portraitOverlay = CreateFrame("Frame", nil, self)
	portraitOverlay:SetFrameLevel(self:GetFrameLevel() + 1)
	portraitOverlay:SetAllPoints()
	-- Portrait shade
	local portraitShade = portraitOverlay:CreateTexture(nil, "BACKGROUND", nil, -1)
	portraitShade:SetSize(PORTRAIT_SHADE_SIZE, PORTRAIT_SHADE_SIZE)
	portraitShade:SetPoint("BOTTOM", 0, PORTRAIT_SHADE_OFFSET_Y)
	portraitShade:SetTexture(GetMedia("UnitFrames/Group/shade-circle"))
	self.Portrait.Shade = portraitShade
	-- Portrait border
	local portraitBorder = portraitOverlay:CreateTexture(nil, "BACKGROUND", nil, 0)
	portraitBorder:SetSize(PORTRAIT_BORDER_SIZE, PORTRAIT_BORDER_SIZE)
	portraitBorder:SetPoint("BOTTOM", 0, PORTRAIT_BORDER_OFFSET_Y)
	portraitBorder:SetTexture(GetMedia("UnitFrames/Group/party_portrait_border"))
	portraitBorder:SetVertexColor(UI_R, UI_G, UI_B)
	self.Portrait.Border = portraitBorder
	-- Decorative backdrops — separate for HP and Power
	local backdropFrame = CreateFrame("Frame", nil, self)
	backdropFrame:SetFrameLevel(self:GetFrameLevel() + 2)
	backdropFrame:SetAllPoints()
	-- Read HP/Power heights from saved settings (fallback to defaults)
	local initHpHeight = HEALTH_HEIGHT
	local initPowerHeight = POWER_HEIGHT
	if (ns.db and ns.db.char and ns.db.char.groupFrames) then
		initHpHeight = ns.db.char.groupFrames.healthBarHeight or HEALTH_HEIGHT
		initPowerHeight = ns.db.char.groupFrames.powerBarHeight or POWER_HEIGHT
	end
	-- HP bar background fill (Heath-Bar-Back)
	local healthBarBack = backdropFrame:CreateTexture(nil, "ARTWORK", nil, -2)
	healthBarBack:SetSize(HEALTH_WIDTH + BAR_BG_PAD_X, initHpHeight + BAR_BG_PAD_Y)
	healthBarBack:SetTexture(GetMedia("statusbar/Heath-Bar-Back"))
	self.HealthBarBackground = healthBarBack
	-- HP decorative border (Health-Bar-Border2)
	local healthBackdrop = backdropFrame:CreateTexture(nil, "ARTWORK", nil, 2)
	healthBackdrop:SetSize(HEALTH_WIDTH + BAR_BORDER_PAD_X, initHpHeight + BAR_BORDER_PAD_Y)
	healthBackdrop:SetTexture(GetMedia("statusbar/Health-Bar-Border2"))
	self.HealthBackdrop = healthBackdrop
	-- Power bar background fill
	local powerBarBack = backdropFrame:CreateTexture(nil, "ARTWORK", nil, -2)
	powerBarBack:SetSize(POWER_WIDTH + BAR_BG_PAD_X, initPowerHeight + BAR_BG_PAD_Y)
	powerBarBack:SetTexture(GetMedia("statusbar/Heath-Bar-Back"))
	self.PowerBarBackground = powerBarBack
	-- Power decorative border
	local powerBackdrop = backdropFrame:CreateTexture(nil, "ARTWORK", nil, 2)
	powerBackdrop:SetSize(POWER_WIDTH + BAR_BORDER_PAD_X, initPowerHeight + BAR_BORDER_PAD_Y)
	powerBackdrop:SetTexture(GetMedia("statusbar/Health-Bar-Border2"))
	self.PowerBackdrop = powerBackdrop
	-- Health Bar (size/offset from saved settings)
	local initHpOffset = ns.PartyLayout.ComputeHpOffset(initPowerHeight)
	local health = self:CreateBar(self:GetName().."HealthBar")
	health:SetSize(HEALTH_WIDTH, initHpHeight)
	health:SetPoint("BOTTOM", 0, initHpOffset)
	health:SetStatusBarTexture(GetMedia("statusbar/Heath-Bar"))
	health:SetSparkTexture(GetMedia("blank"))
	health:SetFrameLevel(self:GetFrameLevel() + 3)
	-- Position HP border + background around HP bar
	healthBackdrop:SetPoint("CENTER", health, "CENTER", 0, 0)
	healthBarBack:SetPoint("CENTER", health, "CENTER", 0, 0)
	health.colorDisconnected = true
	health.colorTapping = true
	health.colorClass = true
	health.colorClassPet = true
	health.colorReaction = true
	health.colorThreat = true
	health.colorHealth = true
	self.Health = health
	self.Health.Override = ns.API.UpdateHealth
	self.Health.PostUpdateColor = Health_PostUpdateColor
	-- Health Prediction (incoming heals + absorbs + heal-absorbs)
	local healPredFrame = CreateFrame("Frame", nil, health)
	healPredFrame:SetFrameLevel(health:GetFrameLevel() + 1)
	healPredFrame:SetAllPoints()
	local myHealPrediction = healPredFrame:CreateTexture(nil, "OVERLAY", nil, 1)
	myHealPrediction:SetTexture(GetMedia("statusbar/Heath-Bar"))
	myHealPrediction:SetVertexColor(0, .827, 0, .35)
	local otherHealPrediction = healPredFrame:CreateTexture(nil, "OVERLAY", nil, 1)
	otherHealPrediction:SetTexture(GetMedia("statusbar/Heath-Bar"))
	otherHealPrediction:SetVertexColor(0, .631, .557, .35)
	local totalAbsorb = healPredFrame:CreateTexture(nil, "OVERLAY", nil, 2)
	totalAbsorb:SetTexture(GetMedia("statusbar/Heath-Bar"))
	totalAbsorb:SetVertexColor(1, 1, 1, .35)
	local healAbsorb = healPredFrame:CreateTexture(nil, "OVERLAY", nil, 3)
	healAbsorb:SetTexture(GetMedia("statusbar/Heath-Bar"))
	healAbsorb:SetVertexColor(.5, 0, 0, .5)
	self.HealthPrediction = {
		myBar = myHealPrediction,
		otherBar = otherHealPrediction,
		absorbBar = totalAbsorb,
		healAbsorbBar = healAbsorb,
		maxOverflow = 1
	}
	-- HP text (percent or number based on setting) - font size configurable in EditMode
	local healthFontSize = 17
	if (ns.db and ns.db.char and ns.db.char.groupFrames and ns.db.char.groupFrames.healthFontSize) then
		healthFontSize = ns.db.char.groupFrames.healthFontSize
	end
	local healthValue = overlay:CreateFontString(nil, "OVERLAY")
	healthValue:SetPoint("CENTER", health, "CENTER", 0, 0)
	healthValue:SetFontObject(GetFont(healthFontSize, true))
	healthValue:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], 1)
	healthValue:SetJustifyH("CENTER")
	-- Our tags internally handle dead/offline state, don't prefix with [dead][offline]
	local tagPercent = "["..ns.Prefix..":HealthPercent]"
	local tagNumber = "["..ns.Prefix..":Health:Smart]"
	-- TEMP: always percent for testing
	self:Tag(healthValue, tagPercent)
	self.Health.Value = healthValue
	self.Health.TagPercent = tagPercent
	self.Health.TagNumber = tagNumber
	-- Name just above HP bar - font size configurable in EditMode
	local nameFontSize = 16
	if (ns.db and ns.db.char and ns.db.char.groupFrames and ns.db.char.groupFrames.nameFontSize) then
		nameFontSize = ns.db.char.groupFrames.nameFontSize
	end
	local name = overlay:CreateFontString(nil, "OVERLAY")
	name:SetFontObject(GetFont(nameFontSize, true))
	name:SetTextColor(unpack(Colors.offwhite))
	name:SetPoint("BOTTOM", health, "TOP", 0, 3)
	name:SetJustifyH("CENTER")
	self:Tag(name, "["..ns.Prefix..":Name]")
	self.Name = name
	-- Power Bar (thin mana bar below HP inside plate)
	local power = self:CreateBar(self:GetName().."PowerBar")
	power:SetSize(POWER_WIDTH, initPowerHeight)
	power:SetPoint("BOTTOM", 0, POWER_OFFSET_Y)
	power:SetStatusBarTexture(GetMedia("statusbar/Heath-Bar"))
	power:SetSparkTexture(GetMedia("blank"))
	power:SetFrameLevel(health:GetFrameLevel())
	power.frequentUpdates = true
	power.colorPower = true
	self.Power = power
	self.Power.Override = ns.API.UpdatePower
	self.Power.PostUpdate = Power_PostUpdate
	-- Position Power border + background around Power bar
	powerBackdrop:SetPoint("CENTER", power, "CENTER", 0, 0)
	powerBarBack:SetPoint("CENTER", power, "CENTER", 0, 0)
	-- Castbar (shown when unit is casting) - overlays HP bar
	-- Native StatusBar (not LibSmoothBar): the modern oUF Castbar fills via
	-- SetTimerDuration and updates/hides through OnUpdate, neither of which
	-- LibSmoothBar implements (the smooth bar would never fill or disappear).
	local castbar = CreateFrame("StatusBar", self:GetName().."Castbar", self)
	castbar:SetSize(HEALTH_WIDTH, initHpHeight)
	castbar:SetPoint("BOTTOM", 0, initHpOffset)
	castbar:SetStatusBarTexture(GetMedia("statusbar/Heath-Bar"))
	castbar:SetStatusBarColor(1, 1, 1, .25)
	castbar:SetFrameLevel(health:GetFrameLevel() + 2)
	castbar:Hide()
	self.Castbar = castbar
	-- Target highlight via portrait border color (no rectangle texture)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", TargetHighlight_Update, true)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", TargetHighlight_Update, true)
	-- (ThreatIndicator element removed — colorThreat=true on Health already handles aggro coloring)
	-- Group Role Indicator
	local groupRole = CreateFrame("Frame", nil, overlay)
	groupRole:SetSize(ROLE_ICON_SIZE, ROLE_ICON_SIZE)
	groupRole:SetPoint("TOP", 0, 0)
	groupRole.DAMAGER = GetMedia("UnitFrames/Group/grouprole-icons-dps")
	groupRole.HEALER = GetMedia("UnitFrames/Group/grouprole-icons-heal")
	groupRole.TANK = GetMedia("UnitFrames/Group/grouprole-icons-tank")
	local roleBackdrop = groupRole:CreateTexture(nil, "BACKGROUND", nil, 1)
	roleBackdrop:SetSize(ROLE_BACKDROP_SIZE, ROLE_BACKDROP_SIZE)
	roleBackdrop:SetPoint("CENTER")
	roleBackdrop:SetTexture(GetMedia("point_plate"))
	roleBackdrop:SetVertexColor(UI_R, UI_G, UI_B)
	groupRole.Backdrop = roleBackdrop
	local roleIcon = groupRole:CreateTexture(nil, "ARTWORK", nil, 1)
	roleIcon:SetSize(ROLE_ICON_SIZE, ROLE_ICON_SIZE)
	roleIcon:SetPoint("CENTER")
	groupRole.Icon = roleIcon
	self.GroupRoleIndicator = groupRole
	self.GroupRoleIndicator.Override = GroupRoleIndicator_Override
	-- Leader Indicator
	local leader = overlay:CreateTexture(nil, "OVERLAY", nil, 3)
	leader:SetSize(16, 16)
	leader:SetPoint("LEFT", groupRole, "RIGHT", 2, 0)
	self.LeaderIndicator = leader
	-- Raid Target Indicator (skull, star, etc.)
	local raidTarget = overlay:CreateTexture(nil, "OVERLAY", nil, 3)
	raidTarget:SetSize(24, 24)
	raidTarget:SetPoint("RIGHT", groupRole, "LEFT", -2, 0)
	self.RaidTargetIndicator = raidTarget
	-- Phase Indicator
	local phase = overlay:CreateTexture(nil, "OVERLAY", nil, 3)
	phase:SetSize(20, 20)
	phase:SetPoint("RIGHT", self, "LEFT", -2, 0)
	self.PhaseIndicator = phase
	-- Ready Check Indicator
	local readyCheck = overlay:CreateTexture(nil, "OVERLAY", nil, 7)
	readyCheck:SetSize(32, 32)
	readyCheck:SetPoint("CENTER", self, "CENTER", 0, 3)
	readyCheck.readyTexture = [[Interface/RAIDFRAME/ReadyCheck-Ready]]
	readyCheck.notReadyTexture = [[Interface/RAIDFRAME/ReadyCheck-NotReady]]
	readyCheck.waitingTexture = [[Interface/RAIDFRAME/ReadyCheck-Waiting]]
	self.ReadyCheckIndicator = readyCheck
	-- Resurrection Indicator
	local resurrect = overlay:CreateTexture(nil, "OVERLAY", nil, 1)
	resurrect:SetSize(32, 32)
	resurrect:SetPoint("CENTER", self, "CENTER", 0, 3)
	resurrect:SetTexture([[Interface\RaidFrame\Raid-Icon-Rez]])
	self.ResurrectIndicator = resurrect
	-- Range check (fade out-of-range members)
	self.Range = {
		insideAlpha = 1.0,
		outsideAlpha = 0.6
	}
	-- Auras (3x3 grid under character — below name)
	local aurasWidth = AURA_SIZE * AURA_PER_ROW + AURA_SPACING * (AURA_PER_ROW - 1)
	local aurasHeight = AURA_SIZE * AURA_ROWS + AURA_SPACING * (AURA_ROWS - 1)
	-- WoW 12.1: debuffs come from an AuraContainer group. Only harmful auras are
	-- shown here, same as the old numBuffs = 0 setup.
	local auras = self:CreateAuras({
		initialAnchor = "TOPLEFT",
		growthX = "RIGHT",
		growthY = "DOWN",
		layoutLimit = aurasWidth,
	})
	auras:SetSize(aurasWidth, aurasHeight)
	auras:SetPoint("TOP", self, "BOTTOM", 0, -4)
	auras.size = AURA_SIZE
	auras.elementSpacing = AURA_SPACING
	auras.lineSpacing = AURA_SPACING
	auras.disableMouse = false
	auras.sortMethod = ns.AuraSorts.UnitFrameDebuff
	auras.sortDirection = ns.AuraSorts.DefaultDirection
	auras.CreateButton = ns.AuraStyles.CreateButton
	-- Stance-style button-big backdrop behind each icon, in place of the aura border.
	auras.PostCreateButton = function(element, btn)
		if (btn.Border) then
			btn.Border:Hide()
		end
		local backdrop = btn:CreateTexture(nil, "BACKGROUND", nil, -1)
		backdrop:SetSize(AURA_SIZE + 9, AURA_SIZE + 9)
		backdrop:SetPoint("CENTER")
		backdrop:SetTexture(GetMedia("button-big"))
		btn.partyBackdrop = backdrop
	end

	-- The focus and focus target frames share this style but sit on their own, so their
	-- debuff rows are capped at a single row instead of the full group grid.
	local auraLimit = (unit == "focus" or unit == "focustarget") and AURA_PER_ROW * 2 or AURA_TOTAL
	auras.debuffGroup = auras:AddGroup(ns.AuraFilters.PlayerDebuffs, { maxFrameCount = auraLimit })

	self.Auras = auras
	return self
end
--[==[ Test mode: show fake debuff buttons on party frames to verify layout
-- Usage: /dazparty test [N]  (N = 1..9, default 9)
-- Clear: /dazparty clear
local PartyTest = {}
SLASH_DAZPARTY1 = "/dazparty"
SlashCmdList["DAZPARTY"] = function(msg)
	msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	local cmd, arg = msg:match("^(%S+)%s*(.*)$")
	cmd = cmd or "test"
	if (cmd == "clear") then
		for frame, buttons in pairs(PartyTest) do
			for _, btn in ipairs(buttons) do
				btn:Hide()
			end
		end
		print("|cff00ff00DiabolicUI3:|r test debuffs cleared")
		return
	end
	local count = tonumber(arg) or 9
	if (count < 1) then count = 1 end
	if (count > 9) then count = 9 end
	local sampleIcons = {
		[[Interface\Icons\Spell_Shadow_UnholyFrenzy]],
		[[Interface\Icons\Spell_Frost_Frostbolt02]],
		[[Interface\Icons\Spell_Fire_Immolation]],
		[[Interface\Icons\Spell_Nature_Lightning]],
		[[Interface\Icons\Spell_Holy_PowerWordShield]],
		[[Interface\Icons\Ability_Rogue_Deadliness]],
		[[Interface\Icons\Spell_Shadow_DeathCoil]],
		[[Interface\Icons\Spell_Nature_Poison]],
		[[Interface\Icons\Spell_Arcane_Blast]],
	}
	local sampleColors = {
		{1,0,0}, {0,0,1}, {1,.5,0}, {1,1,0},
		{1,1,1}, {.5,0,1}, {0,1,0}, {.5,1,0}, {0,.8,1}
	}
	local partyFrames = {}
	if (oUF and oUF.objects) then
		for _, obj in ipairs(oUF.objects) do
			if (obj.unit and type(obj.unit) == "string" and obj.unit:match("^party%d*$") and obj.Auras) then
				table.insert(partyFrames, obj)
			end
		end
	end
	if (#partyFrames == 0) then
		print("|cffff0000DiabolicUI3:|r no party frames found — are you in a party?")
		return
	end
	local found = 0
	for _, frame in ipairs(partyFrames) do
		found = found + 1
		PartyTest[frame] = PartyTest[frame] or {}
		local buttons = PartyTest[frame]
		for i = 1, 9 do
			local btn = buttons[i]
			if (not btn) then
				btn = CreateFrame("Frame", nil, frame.Auras)
				btn:SetSize(AURA_SIZE, AURA_SIZE)
				-- Stance-style backdrop (button-big) behind icon
				local backdrop = btn:CreateTexture(nil, "BACKGROUND", nil, -1)
				backdrop:SetSize(AURA_SIZE + 9, AURA_SIZE + 9)
				backdrop:SetPoint("CENTER")
				backdrop:SetTexture(GetMedia("button-big"))
				btn.partyBackdrop = backdrop
				local icon = btn:CreateTexture(nil, "ARTWORK")
				icon:SetPoint("TOPLEFT", 2, -2)
				icon:SetPoint("BOTTOMRIGHT", -2, 2)
				icon:SetTexCoord(.08, .92, .08, .92)
				btn.icon = icon
				buttons[i] = btn
			end
			if (i <= count) then
				local col = (i - 1) % AURA_PER_ROW
				local row = math.floor((i - 1) / AURA_PER_ROW)
				btn:ClearAllPoints()
				btn:SetPoint("TOPLEFT", frame.Auras, "TOPLEFT",
					col * (AURA_SIZE + AURA_SPACING),
					-row * (AURA_SIZE + AURA_SPACING))
				btn.icon:SetTexture(sampleIcons[i])
				btn.icon:SetVertexColor(sampleColors[i][1], sampleColors[i][2], sampleColors[i][3])
				btn:Show()
			else
				btn:Hide()
			end
		end
	end
	print(string.format("|cff00ff00DiabolicUI3:|r showing %d test debuffs on %d party frames", count, found))
end
print("|cff00ff00DiabolicUI3:|r /dazparty test [N] or /dazparty clear")
--]==]
