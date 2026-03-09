local Addon, ns = ...
local Auras = ns:NewModule("Auras", "LibMoreEvents-1.0", "AceTimer-3.0", "AceHook-3.0", "AceConsole-3.0", "LibSmoothBar-1.0")

-- Lua API
local math_ceil = math.ceil
local math_max = math.max
local pairs = pairs
local select = select
local string_format = string.format
local string_lower = string.lower
local table_insert = table.insert
local tonumber = tonumber

-- WoW API
local CreateFrame = CreateFrame
local GetInventoryItemTexture = GetInventoryItemTexture
local GetTime = GetTime
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local InCombatLockdown = InCombatLockdown

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local RegisterCooldown = ns.Widgets.RegisterCooldown
local SetObjectScale = ns.API.SetObjectScale

-- Aura Template
--------------------------------------------
local Aura = {}

Aura.Style = function(self)
	-- Apply dynamic icon size from settings
	local db = ns.db.global.auras
	local iconSize = db.iconSize or 36
	self:SetSize(iconSize, iconSize)
	local icon = self:CreateTexture(nil, "BACKGROUND", nil, 1)
	icon:SetAllPoints()
	icon:SetMask(GetMedia("actionbutton-mask-square"))
	icon:SetVertexColor(.75, .75, .75)
	self.icon = icon

	local border = CreateFrame("Frame", nil, self, ns.BackdropTemplate)
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 12 })
	border:SetBackdropBorderColor(Colors.verydarkgray[1], Colors.verydarkgray[2], Colors.verydarkgray[3])
	border:SetPoint("TOPLEFT", -6, 6)
	border:SetPoint("BOTTOMRIGHT", 6, -6)
	border:SetFrameLevel(self:GetFrameLevel() + 2)
	self.border = border

	local count = self.border:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(GetFont(12,true))
	count:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	count:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -2, 3)
	self.count = count

	local time = self.border:CreateFontString(nil, "OVERLAY")
	time:Hide()
	time:SetFontObject(GetFont(18,true))
	time:SetTextColor(Colors.red[1], Colors.red[2], Colors.red[3])
	time:SetPoint("CENTER")
	time:SetIgnoreParentAlpha(true)
	time:SetAlpha(.85)
	--hooksecurefunc(time, "SetFormattedText", function(self)
	--	if (self:GetParent():GetParent():GetParent():GetAlpha() > .1) then
	--		self:SetAlpha(.85)
	--	else
	--		self:SetAlpha(0)
	--	end
	--end)
	self.time = time

	-- WoW 12.0.1: Disabled bar under aura icons for now
	-- local bar = Auras:CreateSmoothBar(nil, self)
	-- bar:SetPoint("TOP", self, "BOTTOM", 0, 0)
	-- bar:SetPoint("LEFT", self, "LEFT", 1, 0)
	-- bar:SetPoint("RIGHT", self, "RIGHT", -1, 0)
	-- bar:SetHeight(4)
	-- bar:SetStatusBarTexture(GetMedia("bar-small"))
	-- bar:SetStatusBarColor(Colors.xp[1], Colors.xp[2], Colors.xp[3])
	-- bar.bg = bar:CreateTexture(nil, "BACKGROUND", nil, -7)
	-- bar.bg:SetPoint("TOPLEFT", -1, 1)
	-- bar.bg:SetPoint("BOTTOMRIGHT", 1, -1)
	-- bar.bg:SetColorTexture(.05, .05, .05, .85)
	-- self.bar = bar

	local fadeAnimation = self:CreateAnimationGroup()
	fadeAnimation:SetLooping("BOUNCE")

	local fade = fadeAnimation:CreateAnimation("Alpha")
	fade:SetFromAlpha(1)
	fade:SetToAlpha(.5)
	fade:SetDuration(.6)
	fade:SetSmoothing("IN_OUT")

	self.fadeAnimation = fadeAnimation

	-- WoW 12.0.0: Create real CooldownFrame for SetCooldownFromDurationObject support
	local cd = CreateFrame("Cooldown", nil, self, "CooldownFrameTemplate")
	cd:SetAllPoints()
	cd:SetDrawEdge(false)
	cd:SetDrawSwipe(false)
	cd:SetHideCountdownNumbers(false)
	-- Set countdown font - use custom Morpheus font for compact display
	-- Font is created in AuraStyles.lua
	if cd.SetCountdownFont then
		cd:SetCountdownFont("DiabolicAuraCooldownFont")
	end
	self.cd = cd

	-- Hook cooldown to update bar (disabled - bar is disabled)
	-- RegisterCooldown(cd, bar)

end

Aura.Update = function(self, index)
	-- WoW 12.0.0: issecretvalue may not exist in older versions
	local issecretvalue = issecretvalue or function() return false end

	-- Use index parameter - it's the correct buff index from SecureAuraHeaderTemplate
	local unit = self:GetParent():GetAttribute("unit") or "player"
	-- print("|cFF00FFFF[Update]|r", self:GetName(), "index:", index, "unit:", unit, "filter:", self.filter)
	local auraData = C_UnitAuras.GetAuraDataByIndex(unit, index, self.filter)

	if (auraData) then
		-- WoW 12.0.0: Store auraInstanceID for non-secure updates during combat
		self.auraInstanceID = auraData.auraInstanceID
		-- print("|cFF00FF00  Got aura:|r", auraData.name, "icon:", auraData.icon)
		local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod = auraData.name, auraData.icon, auraData.applications, auraData.dispelName, auraData.duration, auraData.expirationTime, auraData.sourceUnit, auraData.isStealable, auraData.nameplateShowPersonal, auraData.spellId, auraData.canApplyAura, auraData.isBossAura, auraData.isFromPlayerOrPlayerPet, auraData.nameplateShowAll, auraData.timeMod

		-- DON'T set index here - SecureAuraHeaderTemplate already sets it automatically!
		-- Setting it here would overwrite the secure attribute and break cancelaura

		-- macrotext2 is now set by secure _onattributechanged handler in XML template
		-- This ensures it's set from SECURE code, not insecure Lua

		self:SetAlpha(1)
		self.icon:SetTexture(icon)
		-- WoW 12.0.0: Prefer GetAuraApplicationDisplayCount (works in combat!)
		local countText = ""
		if (C_UnitAuras.GetAuraApplicationDisplayCount and auraData.auraInstanceID) then
			local displayCount = C_UnitAuras.GetAuraApplicationDisplayCount(unit, auraData.auraInstanceID, 2, 1000)
			if (displayCount and not issecretvalue(displayCount) and displayCount ~= "") then
				countText = displayCount
			end
		elseif (count and not issecretvalue(count) and count > 1) then
			countText = tostring(count)
		end
		self.count:SetText(countText)

		-- WoW 12.0.0: duration and expirationTime can be secret values
		if (duration and expirationTime) then
			-- If values are secret, use GetAuraDuration API
			if issecretvalue(duration) or issecretvalue(expirationTime) then
				if C_UnitAuras and C_UnitAuras.GetAuraDuration and auraData.auraInstanceID then
					local durationSecret = C_UnitAuras.GetAuraDuration(unit, auraData.auraInstanceID)
					if durationSecret and self.cd.SetCooldownFromDurationObject then
						self.cd:SetCooldownFromDurationObject(durationSecret)
						self.cd:Show()
					else
						self.cd:Hide()
					end
				else
					self.cd:Hide()
				end
				-- Cannot calculate timeLeft with secret values
				self.time:Hide()
				if (self.fadeAnimation:IsPlaying()) then
					self.fadeAnimation:Stop()
				end
				self:SetScript("OnUpdate", nil)
				self.timeLeft = nil
			-- Not secret, use traditional method
			elseif (duration > 0) then
				self.cd:SetCooldown(expirationTime - duration, duration)
				self.cd:Show()

				local timeLeft = expirationTime - GetTime()
				self.timeLeft = timeLeft
				self:SetScript("OnUpdate", self.OnUpdate)

				-- Fade short duration auras in and out
				if (timeLeft < 10) then
					if (not self.fadeAnimation:IsPlaying()) then
						self.fadeAnimation:Play()
					end
					self.time:Show()
				else
					if (self.fadeAnimation:IsPlaying()) then
						self.fadeAnimation:Stop()
					end
					self.time:Hide()
				end
			else
				self.cd:Hide()
				self.time:Hide()
				if (self.fadeAnimation:IsPlaying()) then
					self.fadeAnimation:Stop()
				end
				self:SetScript("OnUpdate", nil)
				self.timeLeft = nil
			end
		else
			self.cd:Hide()
			self.time:Hide()
			if (self.fadeAnimation:IsPlaying()) then
				self.fadeAnimation:Stop()
			end
			self:SetScript("OnUpdate", nil)
			self.timeLeft = nil
		end
	else
		-- WoW 12.0.0: Clear auraInstanceID when no aura
		self.auraInstanceID = nil
		self.icon:SetTexture(nil)
		self.count:SetText("")
		self.cd:Hide()
		self.time:Hide()
		if (self.fadeAnimation:IsPlaying()) then
			self.fadeAnimation:Stop()
		end
		self:SetScript("OnUpdate", nil)
		self.timeLeft = nil
	end

end

Aura.UpdateTempEnchant = function(self, slot)
	local enchant = (slot == 16 and 2) or 6
	local expiration = select(enchant, GetWeaponEnchantInfo())
	local icon = GetInventoryItemTexture("player", slot)

	if (icon) then
		self:SetAlpha(1)
		self.icon:SetTexture(icon)
	else
		-- sometimes empty temp enchants are shown
		-- this is a bug in the secure aura headers
		self:SetAlpha(0)
		self.icon:SetTexture(nil)
	end

	if (expiration) then
		self.enchant = enchant
		self.cd:SetCooldown(GetTime(), expiration / 1e3)
		self.cd:Show()
		self:SetScript("OnUpdate", self.OnUpdate)
	else
		self.cd:Hide()
		self.enchant = nil
		self.timeLeft = nil
		self:SetScript("OnUpdate", nil)
	end

	self.count:SetText("")

end

Aura.UpdateTooltip = function(self)
	if (GameTooltip:IsForbidden()) then return end
	-- WoW 12.0.0: Wrap tooltip operations in pcall to prevent taint errors
	pcall(function()
		local unit = self:GetParent():GetAttribute("unit") or "player"
		local index = self:GetAttribute("index")
		-- WoW 12.0.0: Validate index before calling SetUnitAura
		if (not index) or (type(index) ~= "number") or (index < 1) then
			return
		end
		GameTooltip:SetUnitAura(unit, index, self.filter)
	end)
end

Aura.OnUpdate = function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if (self.elapsed < 0.033) then -- ~30 fps for smooth aura timers
		return
	end
	local totalElapsed = self.elapsed
	self.elapsed = 0

	-- WoW 12.0.0: Update counter from cache (works in combat!)
	if (self.auraInstanceID) then
		local header = self:GetParent()
		if (header and header.auraDataCache) then
			local cached = header.auraDataCache[self.auraInstanceID]
			if (cached and cached.applicationsString and self.count) then
				self.count:SetText(cached.applicationsString)
			end
		end
	end

	local timeLeft
	if (self.enchant) then
		local expiration = select(self.enchant, GetWeaponEnchantInfo())
		timeLeft = expiration and (expiration / 1e3) or 0
	else
		timeLeft = self.timeLeft - totalElapsed
	end
	self.timeLeft = timeLeft

	if (timeLeft > 0) then
		if (timeLeft < 10) then
			if (not self.fadeAnimation:IsPlaying()) then
				self.fadeAnimation:Play()
			end
			self.time:Show()
		else
			if (self.fadeAnimation:IsPlaying()) then
				self.fadeAnimation:Stop()
			end
			self.time:Hide()
		end
	else
		self.timeLeft = nil
		self:SetScript("OnUpdate", nil)
	end

end

Aura.OnEnter = function(self)
	if (not self:IsVisible()) then return end
	if (GameTooltip:IsForbidden()) then return end
	-- WoW 12.0.0: Wrap tooltip operations in pcall to prevent taint errors
	pcall(function()
		local p = self:GetParent()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		GameTooltip:SetPoint(p.tooltipPoint, self, p.tooltipAnchor, p.tooltipOffsetX, p.tooltipOffsetY)
		self:UpdateTooltip()
	end)
end

Aura.OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end
	-- WoW 12.0.0: Wrap tooltip operations in pcall to prevent taint errors
	pcall(function()
		GameTooltip:Hide()
	end)
end

Aura.OnAttributeChanged = function(self, attribute, value)
	if (attribute == "index") then
		return self:Update(value)
	elseif(attribute == "target-slot") then
		return self:UpdateTempEnchant(value)
	end
end

Aura.OnInitialize = function(self)
	self:Style()
	self.filter = self:GetParent():GetAttribute("filter")
	self.UpdateTooltip = self.UpdateTooltip

	-- MINIMAL initialization - let SecureAuraHeaderTemplate handle everything!
	-- Only hook tooltips, don't touch secure attributes at all
	self:HookScript("OnEnter", self.OnEnter)
	self:HookScript("OnLeave", self.OnLeave)

	-- Set filter for cancelaura to work (must match parent)
	if (not InCombatLockdown() and self.filter) then
		self:SetAttribute("filter", self.filter)
	end

	-- Hook OnAttributeChanged to update visuals when SecureAuraHeaderTemplate changes index
	-- Using HookScript (not SetScript) to preserve any secure handlers
	self:HookScript("OnAttributeChanged", self.OnAttributeChanged)

	-- DON'T set any other secure attributes here!
	-- SecureAuraHeaderTemplate manages: unit, index automatically
	-- Setting them in Lua may break the secure system!
end

-- Module API
--------------------------------------------
-- Embed the aura template methods
-- into an existing aura frame.
Auras.Embed = function(self, aura)
	for method,func in pairs(Aura) do
		aura[method] = func
	end
end

-- Run a member method on all auras.
Auras.ForAll = function(self, method, ...)
	local buffs = self.buffs
	if (not buffs) then
		return
	end
	local child = buffs:GetAttribute("child1")
	local i = 1
	while (child) do
		local func = child[method]
		if (func) then
			func(child, child:GetID(), ...)
		end
		i = i + 1
		child = buffs:GetAttribute("child" .. i)
	end
end

-- Updates
--------------------------------------------
Auras.UpdateAlpha = function(self)
	local buffs = self.buffs
	if (not buffs) then
		return
	end

	local consolidateDuration = tonumber(buffs:GetAttribute("consolidateDuration")) or 30
	local consolidateThreshold = tonumber(buffs:GetAttribute("consolidateThreshold")) or 10
	local consolidateFraction = tonumber(buffs:GetAttribute("consolidateFraction")) or 0.1
	local unit, filter = buffs:GetAttribute("unit"), buffs:GetAttribute("filter")
	local slot, consolidated, time = 1, 0, GetTime()
	local name, duration, expires, caster, shouldConsolidate, _

	repeat
		-- Sourced from FrameXML\SecureGroupHeaders.lua
		local auraData = C_UnitAuras.GetAuraDataByIndex(unit, slot, filter)
		if auraData then
			name, duration, expires, caster, shouldConsolidate = auraData.name, auraData.duration, auraData.expirationTime, auraData.sourceUnit, auraData.shouldConsolidate
		else
			name = nil
		end
		if (name and shouldConsolidate) then
			if (not expires or duration > consolidateDuration or (expires - time >= math_max(consolidateThreshold, duration * consolidateFraction)) ) then
				consolidated = consolidated + 1
			end
		end
		slot = slot + 1
	until (not name)

	-- Update count and counter.
	buffs.numConsolidated = consolidated
	buffs.proxy.count:SetText(buffs.numConsolidated > 0 and buffs.numConsolidated or "")

	-- If there are currently consolidated buffs and both
	-- the proxy button and the consolidation frame are shown,
	-- reduce the alpha of the buff window.
	if (buffs.numConsolidated > 0 and buffs.proxy:IsShown() and buffs.consolidation:IsShown()) then
		buffs:SetAlpha(.5)
	else
		buffs:SetAlpha(1)
	end

end

Auras.UpdatePosition = function(self)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end
	local buffs = self.buffs
	if (not buffs) then
		return
	end
	local db = ns.db.global.auras
	buffs:ClearAllPoints()
	buffs:SetPoint("TOPRIGHT", db.positionX or -380, db.positionY or -66)
end
Auras.UpdateIconSize = function(self)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end
	local buffs = self.buffs
	if (not buffs) then
		return
	end
	local db = ns.db.global.auras
	local charDb = ns.db.char.auras
	local iconSize = db.iconSize or 36
	local growUpward = charDb and charDb.growUpward
	local wrapYOffset = growUpward and (iconSize + 12) or -(iconSize + 12)
	-- Update header attributes
	buffs:SetSize(iconSize, iconSize)
	buffs:SetAttribute("minHeight", iconSize)
	buffs:SetAttribute("minWidth", iconSize)
	buffs:SetAttribute("xOffset", -(iconSize + 6))
	buffs:SetAttribute("wrapYOffset", wrapYOffset)
	-- Update proxy
	if buffs.proxy then
		buffs.proxy:SetSize(iconSize, iconSize)
	end
	-- Update consolidation
	if buffs.consolidation then
		buffs.consolidation:SetSize(iconSize, iconSize)
		buffs.consolidation:SetAttribute("xOffset", -(iconSize + 6))
		buffs.consolidation:SetAttribute("wrapYOffset", wrapYOffset)
	end
	-- Update existing aura buttons
	for i = 1, 40 do
		local button = buffs:GetAttribute("child" .. i)
		if button then
			button:SetSize(iconSize, iconSize)
		else
			break
		end
	end
end
Auras.UpdateSettings = function(self)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end
	local visibility = self.visibility
	if (not visibility) then
		return
	end
	local db = ns.db.char.auras
	if (db.alwaysHideAuras) then
		visibility:SetAttribute("auraMode", -1)
		if (BuffFrame) then
			BuffFrame:SetParent(UIParent)
			BuffFrame:RegisterEvent("UNIT_AURA")
			BuffFrame:SetScript("OnEvent", BuffFrame.OnEvent)
			BuffFrame:SetScript("OnUpdate", BuffFrame.OnUpdate)
		end
		if (DebuffFrame) then
			DebuffFrame:SetParent(UIParent)
			DebuffFrame:RegisterEvent("UNIT_AURA")
			DebuffFrame:SetScript("OnEvent", DebuffFrame.OnEvent)
			DebuffFrame:SetScript("OnUpdate", DebuffFrame.OnUpdate)
		end
	elseif (db.alwaysShowAuras) then
		visibility:SetAttribute("auraMode", 1)
		if (BuffFrame) then
			BuffFrame:SetParent(ns.Hider)
			BuffFrame:UnregisterAllEvents()
		end
		if (DebuffFrame) then
			DebuffFrame:SetParent(ns.Hider)
			DebuffFrame:UnregisterAllEvents()
		end
	else
		visibility:SetAttribute("auraMode", 0)
		if (BuffFrame) then
			BuffFrame:SetParent(ns.Hider)
			BuffFrame:UnregisterAllEvents()
		end
		if (DebuffFrame) then
			DebuffFrame:SetParent(ns.Hider)
			DebuffFrame:UnregisterAllEvents()
		end
	end
	visibility:Execute([[ self:RunAttribute("UpdateDriver"); ]])
	-- Also update icon size
	self:UpdateIconSize()
end

-- Initialization & Events
--------------------------------------------
Auras.SpawnAuras = function(self)
	if (not self.buffs) then

		-----------------------------------------
		-- Header
		-----------------------------------------
		-- The primary buff window.
		local buffs = CreateFrame("Frame", ns.Prefix.."BuffHeader", UIParent, "SecureAuraHeaderTemplate")
		buffs:SetFrameLevel(10)
		local db = ns.db.global.auras
		local iconSize = db.iconSize or 36
		buffs:SetSize(iconSize, iconSize)
		buffs:SetPoint("TOPRIGHT", db.positionX or -380, db.positionY or -66)
		SetObjectScale(buffs)
		buffs:SetAttribute("weaponTemplate", "DiabolicAuraTemplate")
		buffs:SetAttribute("template", "DiabolicAuraTemplate")
		buffs:SetAttribute("minHeight", iconSize)
		buffs:SetAttribute("minWidth", iconSize)
		buffs:SetAttribute("point", "TOPRIGHT")
		buffs:SetAttribute("xOffset", -(iconSize + 6))
		buffs:SetAttribute("yOffset", 0)
		buffs:SetAttribute("wrapAfter", 6)
		buffs:SetAttribute("wrapXOffset", 0)
		-- Grow upward: positive wrapYOffset makes new rows appear above
		local charDb = ns.db.char.auras
		local growUpward = charDb and charDb.growUpward
		local wrapYOffset = growUpward and (iconSize + 12) or -(iconSize + 12)
		buffs:SetAttribute("wrapYOffset", wrapYOffset)
		buffs:SetAttribute("filter", "HELPFUL")
		buffs:SetAttribute("includeWeapons", 1)
		buffs:SetAttribute("sortMethod", "TIME")
		buffs:SetAttribute("sortDirection", "-")

		buffs.UpdateAlpha = function() Auras:UpdateAlpha() end
		buffs.tooltipPoint = "TOPRIGHT"
		buffs.tooltipAnchor = "BOTTOMLEFT"
		buffs.tooltipOffsetX = -10
		buffs.tooltipOffsetY = -10

		-- Aura slot index where the
		-- consolidation button will appear.
		buffs:SetAttribute("consolidateTo", -1)

		-- Auras with less remaining duration than
		-- this many seconds should not be consolidated.
		buffs:SetAttribute("consolidateThreshold", 10) -- default 10

		-- The minimum total duration an aura should
		-- have to be considered for consolidation.
		buffs:SetAttribute("consolidateDuration", 10) -- default 30

		-- The fraction of remaining duration a buff
		-- should still have to be eligible for consolidation.
		buffs:SetAttribute("consolidateFraction", .1) -- default .10

		-- Add a vehicle switcher
		RegisterAttributeDriver(buffs, "unit", "[vehicleui] vehicle; player")

		-- WoW 12.0.0: Initialize aura data cache for combat updates
		buffs.auraDataCache = {}

		self.buffs = buffs

		-----------------------------------------
		-- Consolidation
		-----------------------------------------
		-- The proxybutton appearing in the aura listing
		-- representing the existence of consolidated auras.
		local proxy = CreateFrame("Button", buffs:GetName().."ProxyButton", buffs, "SecureUnitButtonTemplate, SecureHandlerEnterLeaveTemplate")
		proxy:Hide()
		proxy:SetSize(iconSize, iconSize)
		proxy:SetIgnoreParentAlpha(true)
		buffs.proxy = proxy

		local texture = proxy:CreateTexture(nil, "BACKGROUND")
		texture:SetSize(64,64)
		texture:SetPoint("CENTER")
		texture:SetTexture(GetMedia("chatbutton-maximize"))
		proxy.texture = texture

		local count = proxy:CreateFontString(nil, "OVERLAY")
		count:SetFontObject(GetFont(12,true))
		count:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
		count:SetPoint("BOTTOMRIGHT", -2, 3)
		proxy.count = count

		buffs:SetAttribute("consolidateProxy", proxy)

		-- The other updates aren't called when it is hidden,
		-- so to have the correct count when toggling through chat commands,
		-- we need to have this extra update on each show.
		self:SecureHookScript(proxy, "OnShow", "UpdateAlpha")
		self:SecureHookScript(proxy, "OnHide", "UpdateAlpha")

		-- Consolidation frame where the consolidated auras appear.
		local consolidation = CreateFrame("Frame", buffs:GetName().."Consolidation", buffs.proxy, "SecureFrameTemplate")
		consolidation:Hide()
		consolidation:SetIgnoreParentAlpha(true)
		consolidation:SetSize(iconSize, iconSize)
		consolidation:SetPoint("TOPLEFT", proxy, "TOPRIGHT", 6, 0)
		consolidation:SetAttribute("minHeight", nil)
		consolidation:SetAttribute("minWidth", nil)
		consolidation:SetAttribute("point", "TOPRIGHT")
		consolidation:SetAttribute("template", buffs:GetAttribute("template"))
		consolidation:SetAttribute("weaponTemplate", buffs:GetAttribute("weaponTemplate"))
		consolidation:SetAttribute("xOffset", buffs:GetAttribute("xOffset"))
		consolidation:SetAttribute("yOffset", buffs:GetAttribute("yOffset"))
		consolidation:SetAttribute("wrapAfter", buffs:GetAttribute("wrapAfter"))
		consolidation:SetAttribute("wrapYOffset", buffs:GetAttribute("wrapYOffset"))

		consolidation.tooltipPoint = buffs.tooltipPoint
		consolidation.tooltipAnchor = buffs.tooltipAnchor
		consolidation.tooltipOffsetX = buffs.tooltipOffsetX
		consolidation.tooltipOffsetY = buffs.tooltipOffsetY

		buffs:SetAttribute("consolidateHeader", consolidation)

		-- Add a vehicle switcher
		RegisterAttributeDriver(consolidation, "unit", "[vehicleui] vehicle; player")

		buffs.consolidation = consolidation

		-- Clickbutton to toggle the consolidation window.
		local button = CreateFrame("Button", proxy:GetName().."ClickButton", proxy, "SecureHandlerClickTemplate")
		button:SetAllPoints()
		button:SetFrameRef("buffs", buffs)
		button:SetFrameRef("consolidation", consolidation)
		button:RegisterForClicks("AnyUp")
		button:SetAttribute("_onclick", [[
			local consolidation = self:GetFrameRef("consolidation")
			local buffs = self:GetFrameRef("buffs")
			if consolidation:IsShown() then
				consolidation:Hide()
				buffs:CallMethod("UpdateAlpha")
			else
				consolidation:Show()
				buffs:CallMethod("UpdateAlpha")
			end
		]])

		proxy.button = button

		-----------------------------------------
		-- Visibility
		-----------------------------------------
		-- The visibility driver used when
		-- visibility mode is set to auto.
		local visdriver = "[petbattle]hide;"

		-- In Wrath we still buff people before pulling,
		-- so this seems like a reasonable compromise.
		if (ns.IsWrath) then
			visdriver = visdriver .. "[group,nocombat]show;"
		end

		visdriver = visdriver .. "[mod:ctrl/shift]show;"
		visdriver = visdriver .. "hide"

		local visibility = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
		visibility:SetFrameRef("buffs", buffs)
		visibility:SetAttribute("_onstate-vis", [[ self:RunAttribute("UpdateVisibility"); ]])
		visibility:SetAttribute("UpdateVisibility", [[
			local visdriver = self:GetAttribute("visdriver");
			if (not visdriver) then
				return
			end
			local buffs = self:GetFrameRef("buffs");
			local shouldhide = SecureCmdOptionParse(visdriver) == "hide";
			local isshown = buffs:IsShown();
			if (shouldhide and isshown) then
				buffs:Hide();
			elseif (not shouldhide and not isshown) then
				buffs:Show();
			end
		]])

		visibility:SetAttribute("UpdateDriver", string_format([[
			local visdriver;
			local buffs = self:GetFrameRef("buffs");
			local auraMode = self:GetAttribute("auraMode");
			if (auraMode == -1) then
				visdriver = "hide";
			elseif (auraMode == 1) then
				visdriver = "[petbattle]hide;show";
			else
				visdriver = "%s";
			end
			self:SetAttribute("visdriver", visdriver);
			UnregisterStateDriver(self, "vis");
			RegisterStateDriver(self, "vis", visdriver);
		]], visdriver))

		self.visibility = visibility
	end
end

-- WoW 12.0.0: Update aura data cache from refreshData
-- This allows counter updates during combat (non-secure code)
Auras.UpdateAuraData = function(self, unit, refreshData)
	-- WoW 12.0.0: issecretvalue may not exist in older versions
	local issecretvalue = issecretvalue or function() return false end

	-- Get aura header cache
	local buffs = self.buffs
	if (not buffs or not buffs.auraDataCache) then
		return
	end
	local cache = buffs.auraDataCache

	-- Full update - rebuild cache
	if (refreshData.isFullUpdate) then
		buffs.auraDataCache = {}
		cache = buffs.auraDataCache
		-- SecureAuraHeaderTemplate will handle full refresh
		return
	end

	-- Process added auras
	if (refreshData.addedAuras) then
		for _, aura in ipairs(refreshData.addedAuras) do
			if (aura.auraInstanceID) then
				-- Get counter display string (works in combat!)
				aura.applicationsString = ""
				if (C_UnitAuras.GetAuraApplicationDisplayCount) then
					local count = C_UnitAuras.GetAuraApplicationDisplayCount(unit, aura.auraInstanceID, 2, 1000)
					if (count and not issecretvalue(count)) then
						aura.applicationsString = count
					end
				elseif (aura.applications and not issecretvalue(aura.applications) and aura.applications > 1) then
					aura.applicationsString = tostring(aura.applications)
				end

				-- Get duration (may be secret!)
				if (C_UnitAuras.GetAuraDuration) then
					aura.durationSecret = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
				end

				cache[aura.auraInstanceID] = aura
			end
		end
	end

	-- Process updated auras
	if (refreshData.updatedAuraInstanceIDs) then
		for _, auraInstanceID in ipairs(refreshData.updatedAuraInstanceIDs) do
			local stored = cache[auraInstanceID]
			if (stored) then
				-- Refresh aura data
				local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
				if (aura) then
					-- Update counter (this is the key for combat updates!)
					aura.applicationsString = ""
					if (C_UnitAuras.GetAuraApplicationDisplayCount) then
						local count = C_UnitAuras.GetAuraApplicationDisplayCount(unit, auraInstanceID, 2, 1000)
						if (count and not issecretvalue(count)) then
							aura.applicationsString = count
						end
					elseif (aura.applications and not issecretvalue(aura.applications) and aura.applications > 1) then
						aura.applicationsString = tostring(aura.applications)
					end

					-- Update duration
					if (C_UnitAuras.GetAuraDuration) then
						aura.durationSecret = C_UnitAuras.GetAuraDuration(unit, auraInstanceID)
					end

					cache[auraInstanceID] = aura
					-- Note: Button will update from cache via OnUpdate script
				end
			end
		end
	end

	-- Process removed auras
	if (refreshData.removedAuraInstanceIDs) then
		for _, auraInstanceID in ipairs(refreshData.removedAuraInstanceIDs) do
			cache[auraInstanceID] = nil
		end
	end
end

Auras.OnChatCommand = function(self, input)
	if (InCombatLockdown()) then
		return
	end

	local arg1, arg2 = self:GetArgs(string_lower(input))
	local db = ns.db.char.auras

	if (arg1 == "show") then
		db.alwaysShowAuras = true
		db.alwaysHideAuras = false
	elseif (arg1 == "hide") then
		db.alwaysShowAuras = false
		db.alwaysHideAuras = true
	elseif (arg1 == "auto") then
		db.alwaysShowAuras = false
		db.alwaysHideAuras = false
	end

	self:UpdateSettings()
end

-- WoW 12.0.0: New UNIT_AURA handler with refreshData support
-- This allows aura counters to update during combat (non-secure code)
Auras.OnUnitAura = function(self, event, unit, refreshData)
	if (unit ~= "player" and unit ~= "vehicle") then
		return
	end

	-- Store or update aura data for later use
	if (refreshData) then
		-- WoW 12.0.0: refreshData contains addedAuras, updatedAuraInstanceIDs, removedAuraInstanceIDs
		-- Update our aura data cache for non-secure updates during combat
		self:UpdateAuraData(unit, refreshData)
	end

	-- Always update alpha (this was the original behavior)
	self:UpdateAlpha()
end

Auras.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		local isInitialLogin, isReloadingUi = ...
		if (isInitialLogin or isReloadingUi) then
			-- Initialize aura data cache in header
			if (self.buffs) then
				self.buffs.auraDataCache = self.buffs.auraDataCache or {}
			end
		end
		self:ForAll("Update")
		self:UpdateAlpha()

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (not InCombatLockdown()) then
			self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
			self:UpdateSettings()
		end
	end
end

Auras.OnInitialize = function(self)
	self:SpawnAuras()
	self:RegisterChatCommand("auras", "OnChatCommand")
	-- EditMode integration
	local LibEditMode = ns.LibEditMode
	if (LibEditMode and LibEditMode.AddFrame) then
		local L = ns.L
		local buffs = self.buffs
		buffs.editModeName = "Diabolic: Buffs"
		LibEditMode:AddFrame(buffs, function(frame, layoutName, point, x, y)
			if (InCombatLockdown()) then return end
			local db = ns.db.global.auras
			db.positionX = x
			db.positionY = y
		end, {point = "TOPRIGHT", x = -380, y = -66})
		LibEditMode:AddFrameSettings(buffs, {
			{
				kind = LibEditMode.SettingType.Slider,
				name = L["AurasIconSize"],
				desc = L["AurasIconSizeDesc"],
				default = 36,
				minValue = 20,
				maxValue = 64,
				valueStep = 1,
				formatter = function(value) return tostring(math.floor(value)) end,
				get = function() return ns.db.global.auras.iconSize or 36 end,
				set = function(layoutName, value)
					ns.db.global.auras.iconSize = value
					Auras:UpdateIconSize()
				end,
			}
		})
	end
end

Auras.OnEnable = function(self)
	-- Switch to EditMode-compatible scaling (UIParent:GetScale() is valid by PLAYER_LOGIN)
	if (self.buffs) then
		ns.API.SetEditModeObjectScale(self.buffs)
	end
	if ns.RegisterCallback then
		ns.RegisterCallback(self, "Auras_Position_Updated", "UpdatePosition")
		ns.RegisterCallback(self, "Aura_Settings_Updated", "UpdateSettings")
	end
	self:UpdateSettings()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	-- WoW 12.0.0: Use OnUnitAura instead of UpdateAlpha to handle refreshData
	self:RegisterUnitEvent("UNIT_AURA", "OnUnitAura", "player", "vehicle")
end
