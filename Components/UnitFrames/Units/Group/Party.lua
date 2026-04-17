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
local POWER_HEIGHT = 12
local POWER_OFFSET_Y = 8
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
local Portrait_PostUpdate = function(element, unit, hasStateChanged)
	if (not element.state) then
		element:ClearModel()
		if (not element.fallback2DTexture) then
			element.fallback2DTexture = element:CreateTexture()
			element.fallback2DTexture:SetDrawLayer("ARTWORK")
			element.fallback2DTexture:SetAllPoints()
			element.fallback2DTexture:SetTexCoord(.1, .9, .1, .9)
		end
		SetPortraitTexture(element.fallback2DTexture, unit)
		element.fallback2DTexture:Show()
	else
		if (element.fallback2DTexture) then
			element.fallback2DTexture:Hide()
		end
		element:SetCamDistanceScale(1)
		element:SetPortraitZoom(1)
		element:SetPosition(0, 0, 0)
		element:SetRotation(0)
		element:ClearModel()
		element:SetUnit(unit)
		element.guid = UnitGUID(unit)
	end
end
-- Power post-update (hide when dead/disconnected)
local Power_PostUpdate = function(element, unit, cur, min, max)
	if (UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit)) then
		element:Show()
	else
		element:Hide()
	end
end
-- Group role override
local GroupRoleIndicator_Override = function(self, event)
	local element = self.GroupRoleIndicator
	if (not element) then return end
	local role = UnitGroupRolesAssigned(self.unit)
	if (role == "TANK" or role == "HEALER" or role == "DAMAGER") then
		element.Icon:SetTexture(element[role])
		element:Show()
	else
		element:Hide()
	end
end
-- Target highlight update
local TargetHighlight_Update = function(self, event, unit)
	if (unit and unit ~= self.unit) then return end
	local element = self.TargetHighlight
	if (not element) then return end
	unit = unit or self.unit
	if (unit and UnitIsUnit(unit, "target")) then
		element:SetVertexColor(unpack(element.colorTarget))
		element:Show()
	else
		element:Hide()
	end
end
-- Style function
UnitStyles["Party"] = function(self, unit, id)
	self:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
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
	-- HP bar background fill (Heath-Bar-Back)
	local healthBarBack = backdropFrame:CreateTexture(nil, "ARTWORK", nil, -2)
	healthBarBack:SetSize(HEALTH_WIDTH + 2, HEALTH_HEIGHT + 2)
	healthBarBack:SetTexture(GetMedia("statusbar/Heath-Bar-Back"))
	self.HealthBarBackground = healthBarBack
	-- HP decorative border (Health-Bar-Border2) - tighter fit
	local healthBackdrop = backdropFrame:CreateTexture(nil, "ARTWORK", nil, 2)
	healthBackdrop:SetSize(HEALTH_WIDTH + 10, HEALTH_HEIGHT + 8)
	healthBackdrop:SetTexture(GetMedia("statusbar/Health-Bar-Border2"))
	self.HealthBackdrop = healthBackdrop
	-- Power bar background fill
	local powerBarBack = backdropFrame:CreateTexture(nil, "ARTWORK", nil, -2)
	powerBarBack:SetSize(POWER_WIDTH + 2, POWER_HEIGHT + 2)
	powerBarBack:SetTexture(GetMedia("statusbar/Heath-Bar-Back"))
	self.PowerBarBackground = powerBarBack
	-- Power decorative border
	local powerBackdrop = backdropFrame:CreateTexture(nil, "ARTWORK", nil, 2)
	powerBackdrop:SetSize(POWER_WIDTH + 10, POWER_HEIGHT + 8)
	powerBackdrop:SetTexture(GetMedia("statusbar/Health-Bar-Border2"))
	self.PowerBackdrop = powerBackdrop
	-- Health Bar (wide, thick — inside cast_back frame)
	local health = self:CreateBar(self:GetName().."HealthBar")
	health:SetSize(HEALTH_WIDTH, HEALTH_HEIGHT)
	health:SetPoint("BOTTOM", 0, HEALTH_OFFSET_Y)
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
	-- HP value text (abbreviated) centered in HP bar
	local healthValue = overlay:CreateFontString(nil, "OVERLAY")
	healthValue:SetPoint("CENTER", health, "CENTER", 0, 0)
	healthValue:SetFontObject(GetFont(12, true))
	healthValue:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .9)
	healthValue:SetJustifyH("CENTER")
	self:Tag(healthValue, "[dead][offline]["..ns.Prefix..":Health:Smart]")
	self.Health.Value = healthValue
	-- Name just above HP bar (bigger font)
	local name = overlay:CreateFontString(nil, "OVERLAY")
	name:SetFontObject(GetFont(14, true))
	name:SetTextColor(unpack(Colors.offwhite))
	name:SetPoint("BOTTOM", health, "TOP", 0, 2)
	name:SetJustifyH("CENTER")
	self:Tag(name, "["..ns.Prefix..":Name]")
	self.Name = name
	-- Power Bar (thin mana bar below HP inside plate)
	local power = self:CreateBar(self:GetName().."PowerBar")
	power:SetSize(POWER_WIDTH, POWER_HEIGHT)
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
	local castbar = self:CreateBar(self:GetName().."Castbar")
	castbar:SetSize(HEALTH_WIDTH, HEALTH_HEIGHT)
	castbar:SetPoint("BOTTOM", 0, HEALTH_OFFSET_Y)
	castbar:SetStatusBarTexture(GetMedia("statusbar/Heath-Bar"))
	castbar:SetStatusBarColor(1, 1, 1, .25)
	castbar:SetSparkTexture(GetMedia("blank"))
	castbar:SetFrameLevel(health:GetFrameLevel() + 2)
	castbar:Hide()
	self.Castbar = castbar
	-- Target Highlight (outline when this unit is your target)
	local targetHighlight = overlay:CreateTexture(nil, "OVERLAY", nil, 2)
	targetHighlight:SetSize(PLATE_WIDTH + 6, PLATE_HEIGHT + 4)
	targetHighlight:SetPoint("CENTER", healthBackdrop, "CENTER", 0, 0)
	targetHighlight:SetTexture(GetMedia("UnitFrames/Group/nameplate_outline"))
	targetHighlight:SetVertexColor(1, .94, .66, 1)
	targetHighlight:Hide()
	targetHighlight.colorTarget = { 1, .94, .66, 1 }
	self.TargetHighlight = targetHighlight
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
	local auras = CreateFrame("Frame", self:GetName().."Auras", self)
	auras:SetSize(aurasWidth, aurasHeight)
	auras:SetPoint("TOP", self, "BOTTOM", 0, -4)
	auras.size = AURA_SIZE
	auras.spacing = AURA_SPACING
	auras.numDebuffs = AURA_TOTAL
	auras.numBuffs = 0
	auras.numTotal = AURA_TOTAL
	auras["growth-x"] = "RIGHT"
	auras["growth-y"] = "DOWN"
	auras.initialAnchor = "TOPLEFT"
	auras.disableMouse = false
	auras.showStealableBuffs = false
	auras.onlyShowPlayer = false
	if (ns.AuraStyles and ns.AuraStyles.CreateButton) then
		auras.CreateButton = ns.AuraStyles.CreateButton
	end
	if (ns.AuraStyles and ns.AuraStyles.TargetPostUpdateButton) then
		auras.PostUpdateButton = ns.AuraStyles.TargetPostUpdateButton
	end
	self.Auras = auras
	return self
end
-- Test mode: show fake debuff buttons on party frames to verify layout
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
				local icon = btn:CreateTexture(nil, "ARTWORK")
				icon:SetAllPoints()
				icon:SetTexCoord(.08, .92, .08, .92)
				btn.icon = icon
				local border = btn:CreateTexture(nil, "OVERLAY")
				border:SetPoint("TOPLEFT", -1, 1)
				border:SetPoint("BOTTOMRIGHT", 1, -1)
				border:SetColorTexture(0, 0, 0, 1)
				border:SetDrawLayer("BACKGROUND", -1)
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
