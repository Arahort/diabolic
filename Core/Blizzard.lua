local Addon, ns = ...
local BlizzKill = ns:NewModule("BlizzKill", "LibMoreEvents-1.0", "AceHook-3.0")

-- Lua API
local ipairs = ipairs
local pairs = pairs
local string_format = string.format

-- WoW API
local C_Timer_After = C_Timer.After
local GetCVarDefault = GetCVarDefault
local GetCVarInfo = GetCVarInfo
local hooksecurefunc = hooksecurefunc
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local SetActionBarToggles = SetActionBarToggles

-- WoW Globals
local CHAT_FRAMES = CHAT_FRAMES

-- Global hider frame
local UIHider = ns.Hider

-- Utility
---------------------------------------------------------
local SetCVar = function(name, value)
	local info = C_CVar.GetCVarInfo(name)
	if not info then return end
	local oldValue = info.value
	if (oldValue == nil) or (oldValue == value) then
		return
	end
	if (value == nil) then
		_G.SetCVar(name, info.default or "")
	else
		_G.SetCVar(name, value)
	end
end

local purgeKey = function(t, k)
	t[k] = nil
	local c = 42
	repeat
		if t[c] == nil then
			t[c] = nil
		end
		c = c + 1
	until issecurevariable(t, k)
end

-- Dragonflight
local hideActionBarFrame = function(frame, clearEvents)
	if frame then
		if clearEvents then
			frame:UnregisterAllEvents()
		end

		-- remove some EditMode hooks
		if frame.system then
			-- DISABLED: purgeKey creates execution taint in WoW 11.x with TaintLess loaded
			-- TaintLess already handles taint cleanup, purgeKey conflicts with EditMode
			-- purgeKey(frame, "isShownExternal")

			-- Instead just set to nil directly without purging
			frame.isShownExternal = nil
		end

		-- EditMode overrides the Hide function, avoid calling it as it can taint
		if frame.HideBase then
			frame:HideBase()
		else
			frame:Hide()
		end
		frame:SetParent(UIHider)
	end
end

-- Dragonflight
local hideActionButton = function(button)
	if not button then return end

	button:Hide()
	button:UnregisterAllEvents()
	button:SetAttribute("statehidden", true)
	button:EnableMouse(false)

	-- WoW 12.0: Explicitly hide NormalTexture (the border that appears after /reload)
	if button.NormalTexture then
		button.NormalTexture:SetAlpha(0)
		button.NormalTexture:Hide()
	end
	-- Also try legacy naming convention
	local normalTex = _G[button:GetName() and (button:GetName() .. "NormalTexture")]
	if normalTex then
		normalTex:SetAlpha(0)
		normalTex:Hide()
	end
end

-- Wrath, Classic
local hideActionBar = function(frame, clearEvents, reanchor, noAnchorChanges)
	if (frame) then
		if (clearEvents) then
			frame:UnregisterAllEvents()
		end
		frame:Hide()
		frame:SetParent(UIHider)

		-- Setup faux anchors so the frame position data returns valid
		if (reanchor) and (not noAnchorChanges) then
			local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
			frame:ClearAllPoints()
			if (left) and (right) and (top) and (bottom) then
				frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
				frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", right, bottom)
			else
				frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 10, 10)
				frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", 20, 20)
			end
		elseif (not noAnchorChanges) then
			frame:ClearAllPoints()
		end
	end
end

-- All
local hideFrame = function(frame)
	if (not frame) then
		return
	end
	if (frame) then
		frame:UnregisterAllEvents()
		frame:SetParent(UIHider)
	else
		frame.Show = frame.Hide
	end
	frame:Hide()
end

BlizzKill.NPE_LoadUI = function(self)
	if not (Tutorials and Tutorials.AddSpellToActionBar) then return end

	-- Action Bar drag tutorials
	Tutorials.AddSpellToActionBar:Disable()
	Tutorials.AddClassSpellToActionBar:Disable()

	-- these tutorials rely on finding valid action bar buttons, and error otherwise
	Tutorials.Intro_CombatTactics:Disable()

	-- enable spell pushing because the drag tutorial is turned off
	Tutorials.AutoPushSpellWatcher:Complete()
end

BlizzKill.KillActionBars = function(self)

	-- Dragonflight
	if (ns.IsRetail) then

		hideActionBarFrame(MainMenuBar, false)
		hideActionBarFrame(MultiBarBottomLeft, true)
		hideActionBarFrame(MultiBarBottomRight, true)
		hideActionBarFrame(MultiBarLeft, true)
		hideActionBarFrame(MultiBarRight, true)
		-- Additional Blizzard bars controlled by settings
		if not ns.db.char.actionbars.showBlizzardBar5 then
			hideActionBarFrame(MultiBar5, true)
		end
		if not ns.db.char.actionbars.showBlizzardBar6 then
			hideActionBarFrame(MultiBar6, true)
		end
		if not ns.db.char.actionbars.showBlizzardBar7 then
			hideActionBarFrame(MultiBar7, true)
		end

		-- Hide MultiBar Buttons, but keep the bars alive
		-- NOTE: Скрываем ActionButton'ы и отключаем у них мышь (EnableMouse=false)
		for i=1,12 do
			hideActionButton(_G["ActionButton" .. i])
			hideActionButton(_G["MultiBarBottomLeftButton" .. i])
			hideActionButton(_G["MultiBarBottomRightButton" .. i])
			hideActionButton(_G["MultiBarRightButton" .. i])
			hideActionButton(_G["MultiBarLeftButton" .. i])
			-- Additional bar buttons controlled by settings
			if not ns.db.char.actionbars.showBlizzardBar5 then
				hideActionButton(_G["MultiBar5Button" .. i])
			end
			if not ns.db.char.actionbars.showBlizzardBar6 then
				hideActionButton(_G["MultiBar6Button" .. i])
			end
			if not ns.db.char.actionbars.showBlizzardBar7 then
				hideActionButton(_G["MultiBar7Button" .. i])
			end
			-- WoW 12.0: New PTR action bars (if they exist)
			hideActionButton(_G["PTR4ActionBarButton" .. i])
			hideActionButton(_G["PTR5ActionBarButton" .. i])
			hideActionButton(_G["PTR6ActionBarButton" .. i])
		end

		hideActionBarFrame(MicroButtonAndBagsBar, false)
		hideActionBarFrame(StanceBar, true)
		hideActionBarFrame(PossessActionBar, true)
		hideActionBarFrame(MultiCastActionBarFrame, false)
		hideActionBarFrame(PetActionBar, true)
		hideActionBarFrame(PetActionBarFrame, true)
		hideActionBarFrame(StatusTrackingBarManager, false)

		if PetActionBar then
			PetActionBar.ignoreFramePositionManager = true
		end
		if PetActionBarFrame then
			PetActionBarFrame.ignoreFramePositionManager = true
		RegisterAttributeDriver(PetActionBarFrame, "state-visibility", "hide")
		PetActionBarFrame:SetAttribute("statehidden", true)
		end

		-- Hide individual pet action buttons
		for i = 1, NUM_PET_ACTION_SLOTS do
			hideActionButton(_G["PetActionButton" .. i])
		end

		-- these events drive visibility, we want the MainActionBar to remain invisible
		if MainActionBar then
			MainActionBar:UnregisterEvent("PLAYER_REGEN_ENABLED")
			MainActionBar:UnregisterEvent("PLAYER_REGEN_DISABLED")
			MainActionBar:UnregisterEvent("ACTIONBAR_SHOWGRID")
			MainActionBar:UnregisterEvent("ACTIONBAR_HIDEGRID")
		end

		if IsAddOnLoaded("Blizzard_NewPlayerExperience") then
			self:NPE_LoadUI()
		elseif NPE_LoadUI ~= nil then
			self:SecureHook("NPE_LoadUI")
		end
	end

	-- Wrath, Vanilla
	if (not ns.IsRetail) then

		MultiBarBottomLeft:SetParent(UIHider)
		MultiBarBottomRight:SetParent(UIHider)
		MultiBarLeft:SetParent(UIHider)
		MultiBarRight:SetParent(UIHider)

		-- Hide MultiBar Buttons, but keep the bars alive
		for i=1,12 do
			_G["ActionButton" .. i]:Hide()
			_G["ActionButton" .. i]:UnregisterAllEvents()
			_G["ActionButton" .. i]:SetAttribute("statehidden", true)

			_G["MultiBarBottomLeftButton" .. i]:Hide()
			_G["MultiBarBottomLeftButton" .. i]:UnregisterAllEvents()
			_G["MultiBarBottomLeftButton" .. i]:SetAttribute("statehidden", true)

			_G["MultiBarBottomRightButton" .. i]:Hide()
			_G["MultiBarBottomRightButton" .. i]:UnregisterAllEvents()
			_G["MultiBarBottomRightButton" .. i]:SetAttribute("statehidden", true)

			_G["MultiBarRightButton" .. i]:Hide()
			_G["MultiBarRightButton" .. i]:UnregisterAllEvents()
			_G["MultiBarRightButton" .. i]:SetAttribute("statehidden", true)

			_G["MultiBarLeftButton" .. i]:Hide()
			_G["MultiBarLeftButton" .. i]:UnregisterAllEvents()
			_G["MultiBarLeftButton" .. i]:SetAttribute("statehidden", true)
		end

		if UIPARENT_MANAGED_FRAME_POSITIONS then
			UIPARENT_MANAGED_FRAME_POSITIONS["MainMenuBar"] = nil
			UIPARENT_MANAGED_FRAME_POSITIONS["StanceBarFrame"] = nil
			UIPARENT_MANAGED_FRAME_POSITIONS["PossessBarFrame"] = nil
			UIPARENT_MANAGED_FRAME_POSITIONS["MultiCastActionBarFrame"] = nil
			UIPARENT_MANAGED_FRAME_POSITIONS["PETACTIONBAR_YPOS"] = nil
			UIPARENT_MANAGED_FRAME_POSITIONS["ExtraAbilityContainer"] = nil
		end

		if MainActionBar then
			MainActionBar:EnableMouse(false)
			MainActionBar:UnregisterEvent("DISPLAY_SIZE_CHANGED")
			MainActionBar:UnregisterEvent("UI_SCALE_CHANGED")

			if MainActionBar.slideOut then
				local animations = {MainActionBar.slideOut:GetAnimations()}
				if animations[1] then
					animations[1]:SetOffset(0,0)
				end
			end
		end

		if (OverrideActionBar) then -- classic doesn't have this
			animations = {OverrideActionBar.slideOut:GetAnimations()}
			animations[1]:SetOffset(0,0)
		end

		hideActionBar(MainMenuBarArtFrame, false, true)
		hideActionBar(MainMenuBarArtFrameBackground)
		hideActionBar(MicroButtonAndBagsBar, false, false, true)

		if StatusTrackingBarManager then
			StatusTrackingBarManager:Hide()
		end

		hideActionBar(StanceBarFrame, true, true)
		hideActionBar(PossessBarFrame, false, true)
		hideActionBar(MultiCastActionBarFrame, false, false, true)
		hideActionBar(PetActionBarFrame, true, true)
		hideActionBar(OverrideActionBar, true)

		-- Additional pet bar hiding for WoW 11.x
		if PetBar then
			hideActionBar(PetBar, true, true)
			PetBar.ignoreFramePositionManager = true
		end

		ShowPetActionBar = function() end
		if PetBar and PetBar.Show then
			PetBar.Show = function() end
		end

		-- Prevent layout manager from repositioning pet bars
		if PetActionBarFrame then
			PetActionBarFrame.ignoreFramePositionManager = true
		RegisterAttributeDriver(PetActionBarFrame, "state-visibility", "hide")
		PetActionBarFrame:SetAttribute("statehidden", true)
		end

		if PetActionBar then
			PetActionBar.ignoreFramePositionManager = true
		RegisterAttributeDriver(PetActionBar, "state-visibility", "hide")
		PetActionBar:SetAttribute("statehidden", true)
		end


		if (not ns.IsClassic) then
			if (PlayerTalentFrame) then
				PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
			else
				hooksecurefunc("TalentFrame_LoadUI", function() PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED") end)
			end
		end

		hideActionBar(MainMenuBarVehicleLeaveButton, true)
		hideActionBar(MainMenuBarPerformanceBarFrame, false, false, true)
		hideActionBar(MainMenuExpBar, false, false, true)
		hideActionBar(ReputationWatchBar, false, false, true)
		hideActionBar(MainMenuBarMaxLevelBar, false, false, true)

		if (IsAddOnLoaded("Blizzard_NewPlayerExperience")) then
			self:NPE_LoadUI()
		elseif (NPE_LoadUI ~= nil) then
			self:SecureHook("NPE_LoadUI")
		end

	end

	-- Attempt to hook the bag bar to the bags
	-- Retrieve the first slot button and the backpack
	local backpack = ContainerFrame1
	local firstSlot = CharacterBag0Slot
	local reagentSlot = CharacterReagentBag0Slot

	-- Try to avoid the potential error with Shadowlands anima deposit animations.
	-- Just give it a simplified version of the default position it is given,
	-- it will be replaced by UpdateContainerFrameAnchors() later on anyway.
	if (backpack and not backpack:GetPoint()) then
		backpack:SetPoint("BOTTOMRIGHT", backpack:GetParent(), "BOTTOMRIGHT", -14, 93 )
	end

	-- These should always exist, but Blizz do have a way of changing things,
	-- and I prefer having functionality not be applied in a future update
	-- rather than having the UI break from nil bugs.
	if (firstSlot and backpack) then
		firstSlot:ClearAllPoints()
		firstSlot:SetPoint("TOPRIGHT", backpack, "BOTTOMRIGHT", -6, 0)

		local strata = backpack:GetFrameStrata()
		local level = backpack:GetFrameLevel()

		-- Rearrange slots
		-- *Dragonflight features a reagent bag slot
		local slotSize = reagentSlot and 24 or 30
		local previous
		for _,slotName in ipairs({
			"CharacterBag0Slot",
			"CharacterBag1Slot",
			"CharacterBag2Slot",
			"CharacterBag3Slot",
			"CharacterReagentBag0Slot"
		}) do

			-- Always check for existence,
			-- because nothing is ever guaranteed.
			local slot = _G[slotName]
			if (slot) then
				slot:SetParent(backpack)
				slot:SetSize(slotSize,slotSize)
				slot:SetFrameStrata(strata)
				slot:SetFrameLevel(level)

				-- Remove that fugly outer border
				local tex = _G[slotName.."NormalTexture"]
				if (tex) then
					tex:SetTexture("")
					tex:SetAlpha(0)
				end

				-- Re-anchor the slots to remove space
				if (not previous) then
					slot:ClearAllPoints()
					slot:SetPoint("TOPRIGHT", backpack, "BOTTOMRIGHT", -6, 4)
				else
					slot:ClearAllPoints()
					slot:SetPoint("RIGHT", previous, "LEFT", 0, 0)
				end

				previous = slot
			end
		end

		local keyring = KeyRingButton
		if (keyring) then
			keyring:SetParent(backpack)
			keyring:SetHeight(slotSize)
			keyring:SetFrameStrata(strata)
			keyring:SetFrameLevel(level)
			keyring:ClearAllPoints()
			keyring:SetPoint("RIGHT", previous, "LEFT", 0, 0)
			previous = keyring
		end
	end

	-- Disable annoying yellow popup alerts.
	if (MainMenuMicroButton_ShowAlert) then
		local HideAlerts = function()
			if (HelpTip) then
				HelpTip:HideAllSystem("MicroButtons")
			end
		end
		hooksecurefunc("MainMenuMicroButton_ShowAlert", HideAlerts)
	end

	-- Скрываем MainActionBar (грифоны и панель Blizzard)
	-- Используем SetParent вместо Hide() чтобы не создавать taint
	if MainActionBar then
		if MainActionBar.EndCaps then
			MainActionBar.EndCaps:SetParent(UIHider)
		end
		if MainActionBar.BorderArt then
			MainActionBar.BorderArt:SetParent(UIHider)
		end
		if MainActionBar.ActionBarPageNumber then
			MainActionBar.ActionBarPageNumber:SetParent(UIHider)
		end
	end

end

BlizzKill.KillFloaters = function(self)

	-- AlertFrame disabled - allows achievements, loot toasts, bonus rolls to show
	--if (AlertFrame) then
	--	AlertFrame:UnregisterAllEvents()
	--	AlertFrame:SetScript("OnEvent", nil)
	--	AlertFrame:SetParent(UIHider)
	--end

	-- Regular minimap buffs and debuffs.
	if (BuffFrame) then
		BuffFrame:SetScript("OnLoad", nil)
		BuffFrame:SetScript("OnUpdate", nil)
		BuffFrame:SetScript("OnEvent", nil)
		BuffFrame:SetParent(UIHider)
		BuffFrame:UnregisterAllEvents()

		if (TemporaryEnchantFrame) then
			TemporaryEnchantFrame:SetScript("OnUpdate", nil)
			TemporaryEnchantFrame:SetParent(UIHider)
		end

		if (DebuffFrame) then
			DebuffFrame:SetScript("OnLoad", nil)
			DebuffFrame:SetScript("OnUpdate", nil)
			DebuffFrame:SetScript("OnEvent", nil)
			DebuffFrame:SetParent(UIHider)
			DebuffFrame:UnregisterAllEvents()
		end
	end

	-- Some shadowlands crap, possibly BfA.
	if (PlayerBuffTimerManager) then
		PlayerBuffTimerManager:SetParent(UIHider)
		PlayerBuffTimerManager:SetScript("OnEvent", nil)
		PlayerBuffTimerManager:UnregisterAllEvents()
	end

	-- Player's castbar
	--if (CastingBarFrame) then
	--	CastingBarFrame:SetScript("OnEvent", nil)
	--	CastingBarFrame:SetScript("OnUpdate", nil)
	--	CastingBarFrame:SetParent(UIHider)
	--	CastingBarFrame:UnregisterAllEvents()
	--end

	-- Player's pet's castbar
	--if (PetCastingBarFrame) then
	--	PetCastingBarFrame:SetScript("OnEvent", nil)
	--	PetCastingBarFrame:SetScript("OnUpdate", nil)
	--	PetCastingBarFrame:SetParent(UIHider)
	--	PetCastingBarFrame:UnregisterAllEvents()
	--end

	if (DurabilityFrame) then
		DurabilityFrame:UnregisterAllEvents()
		DurabilityFrame:SetScript("OnShow", nil)
		DurabilityFrame:SetScript("OnHide", nil)

		-- Prevent the durability frame size affecting other anchors
		DurabilityFrame:SetParent(UIHider)
		DurabilityFrame:Hide()
		-- FIX: Instead of overriding IsShown() (which creates taint in WoW 11.x),
		-- use ignoreFramePositionManager flag to prevent layout interference
		DurabilityFrame.ignoreFramePositionManager = true
	end

	if (LevelUpDisplay) then
		LevelUpDisplay:SetScript("OnEvent", nil)
		LevelUpDisplay:UnregisterAllEvents()
		LevelUpDisplay:StopBanner()
		LevelUpDisplay:SetParent(UIHider)
	end

	if (BossBanner) then
		if (BossBanner_Stop) then
			BossBanner_Stop(BossBanner)
		end
		--BossBanner.PlayBanner = nil
		--BossBanner.StopBanner = nil
		BossBanner:UnregisterAllEvents()
		BossBanner:SetScript("OnEvent", nil)
		BossBanner:SetScript("OnUpdate", nil)
		BossBanner:SetParent(UIHider)
	end

	if (PlayerPowerBarAlt) then
		--hideManagedFrame(PlayerPowerBarAlt)
		PlayerPowerBarAlt:UnregisterEvent("UNIT_POWER_BAR_SHOW")
		PlayerPowerBarAlt:UnregisterEvent("UNIT_POWER_BAR_HIDE")
		PlayerPowerBarAlt:UnregisterEvent("PLAYER_ENTERING_WORLD")
		--PlayerPowerBarAlt.ignoreFramePositionManager = true
		--PlayerPowerBarAlt:UnregisterAllEvents()
		--PlayerPowerBarAlt:SetParent(UIHider)
	end

	if (QuestTimerFrame) then
		QuestTimerFrame:SetScript("OnLoad", nil)
		QuestTimerFrame:SetScript("OnEvent", nil)
		QuestTimerFrame:SetScript("OnUpdate", nil)
		QuestTimerFrame:SetScript("OnShow", nil)
		QuestTimerFrame:SetScript("OnHide", nil)
		QuestTimerFrame:SetParent(UIHider)
		QuestTimerFrame:Hide()
		QuestTimerFrame.numTimers = 0
		QuestTimerFrame.updating = nil
		for i = 1,MAX_QUESTS do
			_G["QuestTimer"..i]:Hide()
		end
	end

	--if (RaidBossEmoteFrame) then
	--	RaidBossEmoteFrame:SetParent(UIHider)
	--	RaidBossEmoteFrame:Hide()
	--end

	--if (RaidWarningFrame) then
	--	RaidWarningFrame:SetParent(UIHider)
	--	RaidWarningFrame:Hide()
	--end

	if (TotemFrame) then
		TotemFrame:UnregisterAllEvents()
		TotemFrame:SetScript("OnEvent", nil)
		TotemFrame:SetScript("OnShow", nil)
		TotemFrame:SetScript("OnHide", nil)
	end

	--if (TutorialFrame) then
	--	TutorialFrame:UnregisterAllEvents()
	--	TutorialFrame:Hide()
	--	TutorialFrame.Show = TutorialFrame.Hide
	--end

	if (ZoneTextFrame) then
		ZoneTextFrame:SetParent(UIHider)
		ZoneTextFrame:UnregisterAllEvents()
		ZoneTextFrame:SetScript("OnUpdate", nil)
		-- ZoneTextFrame:Hide()
	end

	if (SubZoneTextFrame) then
		SubZoneTextFrame:SetParent(UIHider)
		SubZoneTextFrame:UnregisterAllEvents()
		SubZoneTextFrame:SetScript("OnUpdate", nil)
		-- SubZoneTextFrame:Hide()
	end

	if (AutoFollowStatus) then
		AutoFollowStatus:SetParent(UIHider)
		AutoFollowStatus:UnregisterAllEvents()
		AutoFollowStatus:SetScript("OnUpdate", nil)
	end

end

BlizzKill.KillTimerBars = function(self, event, ...)
	local UIHider = UIHider
	if (event == "ADDON_LOADED") then
		local addon = ...
		if (addon == "Blizzard_UIWidgets") then
			self:UnregisterEvent("ADDON_LOADED", "KillTimerBars")
			UIWidgetPowerBarContainerFrame:SetParent(UIHider)
		end
		return
	end

	local numTimers = MIRRORTIMER_NUMTIMERS or 3
	for i = 1,numTimers do
		local timer = _G["MirrorTimer"..i]
		if (timer) then
			timer:SetScript("OnEvent", nil)
			timer:SetScript("OnUpdate", nil)
			timer:SetParent(UIHider)
			timer:UnregisterAllEvents()
		end
	end

	if (TimerTracker) then
		TimerTracker:SetScript("OnEvent", nil)
		TimerTracker:SetScript("OnUpdate", nil)
		TimerTracker:UnregisterAllEvents()
		if (TimerTracker.timerList) then
			for _, bar in pairs(TimerTracker.timerList) do
				if (bar) then
					bar:SetScript("OnEvent", nil)
					bar:SetScript("OnUpdate", nil)
					bar:SetParent(UIHider)
					bar:UnregisterAllEvents()
				end
			end
		end
	end

	if (ns.IsRetail) then
		local bar = UIWidgetPowerBarContainerFrame
		if (bar) then
			bar:SetParent(UIHider)
		else
			return self:RegisterEvent("ADDON_LOADED", "KillTimerBars")
		end
	end
end

BlizzKill.KillTimeManager = function(self, event, ...)
	local TM = _G.TimeManagerClockButton
	if (TM) then
		if (event) then
			self:UnregisterEvent(event, "KillTimeManager")
		end
		if (TM) then
			TM:SetParent(UIHider)
			TM:UnregisterAllEvents()
		end
	else
		self:RegisterEvent("ADDON_LOADED", "KillTimeManager")
	end
end

BlizzKill.KillTutorials = function(self, event, ...)
	if (not event) then
		SetCVar("showTutorials", "0")
		self:RegisterEvent("VARIABLES_LOADED", "KillTutorials")
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "KillTutorials")
		return
	else
		if (event == "VARIABLES_LOADED") then
			self:UnregisterEvent(event, "KillTutorials")
			SetCVar("showTutorials", "0")
		elseif (event == "PLAYER_ENTERING_WORLD") then
			SetCVar("showTutorials", "0")
		end
	end
end

BlizzKill.KillNPE = function(self, event, ...)
	local NPE = _G.NewPlayerExperience
	if (NPE) then
		if (event) then
			self:UnregisterEvent(event, "KillNPE")
		end
		if (NPE.GetIsActive and NPE:GetIsActive()) then
			if (NPE.Shutdown) then
				NPE:Shutdown()
			end
		end
	else
		self:RegisterEvent("ADDON_LOADED", "KillNPE")
	end
end

BlizzKill.KillHelpTip = function(self)
	local HelpTip = _G.HelpTip
	if (HelpTip) then
		local AcknowledgeTips = function()
			if (_G.HelpTip.framePool and _G.HelpTip.framePool.EnumerateActive) then
				for frame in _G.HelpTip.framePool:EnumerateActive() do
					if (frame.Acknowledge) then
						frame:Acknowledge()
					end
				end
			end
		end
		hooksecurefunc(_G.HelpTip, "Show", AcknowledgeTips)
		C_Timer_After(1, AcknowledgeTips)
	end
end

-- WoW 12.0: Delayed re-hide for buttons that Blizzard shows after /reload
BlizzKill.ReHideActionButtons = function(self)
	if not ns.IsRetail then return end

	for i=1,12 do
		hideActionButton(_G["ActionButton" .. i])
		hideActionButton(_G["MultiBarBottomLeftButton" .. i])
		hideActionButton(_G["MultiBarBottomRightButton" .. i])
		hideActionButton(_G["MultiBarRightButton" .. i])
		hideActionButton(_G["MultiBarLeftButton" .. i])
		hideActionButton(_G["PTR4ActionBarButton" .. i])
		hideActionButton(_G["PTR5ActionBarButton" .. i])
		hideActionButton(_G["PTR6ActionBarButton" .. i])
	end
end

BlizzKill.OnInitialize = function(self)
	self:KillActionBars()
	self:KillFloaters()
	self:KillTimerBars()
	self:KillTimeManager()
	self:KillTutorials()
	self:KillNPE()
	self:KillHelpTip()

	-- WoW 12.0: Delayed re-hide to catch buttons shown after /reload
	C_Timer_After(0.5, function() self:ReHideActionButtons() end)
end
