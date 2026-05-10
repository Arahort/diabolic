local Addon, ns = ...
ns = LibStub("AceAddon-3.0"):NewAddon(ns, Addon, "AceConsole-3.0", "LibMoreEvents-1.0")
ns.L = LibStub("AceLocale-3.0"):GetLocale(Addon) -- Addon localization
ns.callbacks = LibStub("CallbackHandler-1.0"):New(ns, nil, nil, false) -- Addon callback handler
ns.Hider = CreateFrame("Frame"); ns.Hider:Hide()
ns.Noop = function() end
_G[Addon] = ns

ns.PetHider = CreateFrame("Frame", Addon.."_PetBattleFrameHider", UIParent, "SecureHandlerStateTemplate")
ns.PetHider:SetAllPoints()
ns.PetHider:SetFrameStrata("LOW")
RegisterStateDriver(ns.PetHider, "visibility", "[petbattle] hide; show")

-- Default settings
-- *don't modify these as they only
--  affect clean installs or new characters,
--  and the modules expect these defaults.
local defaults = {
	char = {
		actionbars = {
			enableSecondary = true,
			showPetBar = true,
			showStanceBar = false,
			showBlizzardBar5 = false,
			showBlizzardBar6 = false,
			showBlizzardBar7 = false,
			hideHotkeys = false,
			useExtendedBars = true,
			disableSidePanelAutoHide = false
		},
		auras = {
			alwaysHideAuras = false,
			alwaysShowAuras = true,
			growUpward = false,
			positionPoint = "TOPRIGHT",
			positionX = -290,
			positionY = -5
		},
		minimap = {
			positionPoint = "TOPRIGHT",
			positionX = -30,
			positionY = -40,
			minimapScale = 0.9
		},
		micromenu = {
			positionPoint = "BOTTOMRIGHT",
			positionX = -11,
			positionY = 11
		},
		tooltips = {
			enabled = true,
			x = 32,
			y = -32,
			anchor = "TOPLEFT"
		},
		qol = {
			movableFrames = true
		},
		unitframes = {
			useClassColorForPower = false,
			showOnlyMyDebuffs = true
		},
		orbs = {
			useCustomColors = false,
			healthColor = {r = 1, g = 0, b = 0},
			powerColor = {r = 0, g = 0, b = 1}
		},
		mapcoords = {
			worldmapCursor = true,
			worldmapPlayer = true,
			minimap = true,
			decimals = true
		},
		minimapbuttons = {
			enabled = true,
			collectMailAndTracking = false,
			direction = "leftdown",
			buttonsPerRow = 5,
			autohide = 2,
			mainButtonSize = 30,
			buttonScale = 0.9,
			blacklist = {}
		},
		pet = {
			useOrbStyle = true,
			orbPoint = nil,        -- nil => use auto-calculated position (near player orb)
			orbRelPoint = nil,
			orbPositionX = nil,
			orbPositionY = nil,
			orbSize = 100
		},
		petbar = {
			positionPoint = "BOTTOM",
			positionX = 4,
			positionY = 163,
			scale = 0.8
		},
		classpower = {
			positionPoint = "BOTTOM",
			positionX = 0,
			positionY = 300,
			scale = 1.0
		},
		target = {
			positionPoint = "TOP",
			positionX = 0,
			positionY = -95,
			scale = 1.0
		},
		experiments = {
			useAzeriteClassPower = true,
			azeriteGroupFrames = true
		},
		groupFrames = {
			partyPoint = "TOPLEFT",
			partyX = 50,
			partyY = -42,
			focusPoint = "TOPLEFT",
			focusX = 200,
			focusY = -42,
			focusTargetPoint = "TOPLEFT",
			focusTargetX = 350,
			focusTargetY = -42,
			showPercent = true,
			healthFontSize = 17,
			nameFontSize = 16,
			healthBarHeight = 16,
			powerBarHeight = 10,
			scale = 1
		}
	},
	global = {
		actionbars = {
			sidePanelToggleAlpha = 0.1
		},
		core = {
			relativeScale = 1.1,
			unitframesRelativeScale = 0.85
		},
		orbs = {
			useD2RStyle = true,
			eyeGlowD2R = true,
			actionBarsGlow = true
		},
		chatbubbles = {
			enableChatBubbles = true,
			visibility = {
				world = true,
				worldcombat = true,
				instance = true,
				instancecombat = false
			}
		},
		chatframes = {
			enableChatFrames = false
		},
		castbar = {
			enableCastbar = false,
			positionX = 0,
			positionY = -290
		},
		unitframes = {
			enableNamePlates = false,
			showTargetCastbar = false,
			useHealthColorForTarget = false,
			showThreatOnTarget = false,
			targetRelativeScale = 1.2
		},
		micromenu = {
			enableMicroMenu = true,
			buttonSize = 34,
			toggleAlpha = 0.3
		},
		minimap = {
			useServerTime = false,
			useHalfClock = false,
			lfgEyeScale = 1.0
		},
		talkinghead = {
			positionX = 0,
			positionY = -454.54
		},
		extrabuttons = {
			extraPoint = "BOTTOM",
			extraRelPoint = "BOTTOM",
			extraPositionX = -546,
			extraPositionY = 156,
			extraSize = 60,
			zonePoint = "BOTTOM",
			zoneRelPoint = "BOTTOM",
			zonePositionX = 558,
			zonePositionY = 162,
			zoneSize = 60
		},
		fonts = {
			customEnabled = false,
			fontName = "Default (game)",
			fontPath = nil
		},
		auras = {
			iconSize = 36,
			twoRowsTargetAuras = false,
			hideTargetAuras = false
		},
		playerDebuffs = {
			positionPoint = "BOTTOMRIGHT",
			positionRelPoint = "BOTTOM",
			positionX = 316,
			positionY = 100,
			iconSize = 40,
			growthX = "LEFT",   -- "LEFT" or "RIGHT"
			growthY = "UP",     -- "UP" or "DOWN"
			spacingX = 4,
			spacingY = 11
		},
		stancebar = {
			positionX = 380,
			positionY = 84
		},
		bagbutton = {
			hideBagButton = false
		},
		experiments = {
			customizePlatynator = false,
			platynatorFrameWidthMult = 0.35,
			platynatorFrameHeightMult = 0.35,
			platynatorFrameWidthExtra = 3,
			customizeRaidFrames = false,
			raidFramesBorderSize = 15,
			raidFramesBorderTop = 5,
			raidFramesBorderBottom = 7,
			raidFramesBorderLeft = 1,
			raidFramesBorderRight = 1,
			raidFramesRoleOffsetX = 5,
			raidFramesRoleOffsetY = 5,
			hideRaidManager = false
		}
	}
}

-- Lua API
local ipairs = ipairs
local math_max = math.max
local math_min = math.min
local next = next
local string_lower = string.lower
local tonumber = tonumber

-- WoW API
local EnableAddOn = C_AddOns.EnableAddOn
local DisableAddOn = C_AddOns.DisableAddOn
local InCombatLockdown = InCombatLockdown
local LoadAddOn = C_AddOns.LoadAddOn
local ReloadUI = ReloadUI

-- Private API
local IsAddOnAvailable = ns.API.IsAddOnAvailable
local SetRelativeScale = ns.API.SetRelativeScale
local SetMinimapRelativeScale = ns.API.SetMinimapRelativeScale
local SetUnitFramesRelativeScale = ns.API.SetUnitFramesRelativeScale
local UpdateObjectScales = ns.API.UpdateObjectScales

-- Purge deprecated settings,
-- translate to new where applicable,
-- make sure important ones are within bounds.
local SanitizeSettings = function(db)
	if (not db) then
		return
	end
	db.char.actionbars.enablePetBar = nil
	db.char.actionbars.enableStanceBar = nil
	db.char.actionbars.preferPetOrStanceBar = nil
	db.char.actionbars.restorePetOrStanceBar = nil
	local numBars = db.char.actionbars.numBars
	if (numBars) then
		db.char.actionbars.numBars = nil
		if (numBars > 1) then
			db.char.actionbars.enableSecondary = true
		else
			db.char.actionbars.enableSecondary = false
		end
	end
	local hideTargetNameOnCast = db.global.unitframes and db.global.unitframes.hideTargetNameOnCast
	if (hideTargetNameOnCast ~= nil) then
		db.global.unitframes.showTargetCastbar = hideTargetNameOnCast
		db.global.unitframes.hideTargetNameOnCast = nil
	end
	local scale = db.global.core.relativeScale
	if (scale) then
		scale = math_min(1.25, math_max(.75, scale))
		db.global.core.relativeScale = scale
	end
	return db
end

-- Proxy method to avoid modules using the callback object directly
ns.Fire = function(self, name, ...)
	ns.callbacks:Fire(name, ...)
end

ns.ResetScale = function(self)
	if (InCombatLockdown()) then
		return
	end
	local db = self.db
	local scale = db.global.core.relativeScale
	local defaultScale = defaults.global.core.relativeScale
	if (scale and scale ~= defaultScale) then
		db.global.core.relativeScale = defaultScale -- Store the saved setting
		SetRelativeScale(defaultScale) -- Store it in the addon namespace
		UpdateObjectScales() -- Apply it to existing objects
		-- Fire callbacks to submodules.
		ns.callbacks:Fire("Relative_Scale_Updated", db.global.core.relativeScale)
	end
end

ns.SetScale = function(self, input)
	if (InCombatLockdown()) then
		return
	end
	local scale = tonumber((self:GetArgs(string_lower(input))))
	if (scale) then
		local db = self.db
		local oldScale = db.global.core.relativeScale
		-- Sanitize it, don't want crazy values
		scale = math_min(1.25, math_max(.75, scale))
		if (oldScale ~= scale) then
			-- Store and apply new relative user scale
			db.global.core.relativeScale = scale -- Store the saved setting
			SetRelativeScale(scale) -- Store it in the addon namespace
			UpdateObjectScales() -- Apply it to existing objects
			-- Fire callbacks to submodules.
			ns.callbacks:Fire("Relative_Scale_Updated", db.global.core.relativeScale)
		end
	end
end

ns.SetMinimapScale = function(self, input)
	if (InCombatLockdown()) then
		return
	end
	local scale = tonumber(type(input) == "string" and (self:GetArgs(string_lower(input))) or input)
	if (scale) then
		local db = self.db
		local oldScale = db.char.minimap.minimapScale
		scale = math_min(1.25, math_max(.75, scale))
		if (oldScale ~= scale) then
			db.char.minimap.minimapScale = scale
			SetMinimapRelativeScale(scale)
			UpdateObjectScales()
			ns.callbacks:Fire("Minimap_Scale_Updated", scale)
		end
	end
end

ns.SetUnitFramesScale = function(self, input)
	if (InCombatLockdown()) then
		return
	end
	local scale = tonumber((self:GetArgs(string_lower(input))))
	if (scale) then
		local db = self.db
		local oldScale = db.global.core.unitframesRelativeScale
		scale = math_min(1.25, math_max(.75, scale))
		if (oldScale ~= scale) then
			db.global.core.unitframesRelativeScale = scale
			SetUnitFramesRelativeScale(scale)
			UpdateObjectScales()
			ns.callbacks:Fire("UnitFrames_Scale_Updated", db.global.core.unitframesRelativeScale)
		end
	end
end

ns.UpdateTargetFrameScale = function()
	if (InCombatLockdown()) then
		return
	end
	local targetFrame = ns.UnitFramesByName and ns.UnitFramesByName["Target"]
	if (targetFrame) then
		local db = ns.db
		if (db and db.char and db.char.target) then
			local targetScale = db.char.target.scale or 1
			ns.API.SetTargetFrameObjectScale(targetFrame, targetScale)
		end
	end
end

ns.ToggleChat = function(self, input)
	local db = self.db
	local arg = input and self:GetArgs(string_lower(input))
	local newValue
	if (arg == "0" or arg == "off" or arg == "false") then
		newValue = false
	elseif (arg == "1" or arg == "on" or arg == "true") then
		newValue = true
	else
		newValue = not db.global.chatframes.enableChatFrames
	end
	db.global.chatframes.enableChatFrames = newValue
	print("|cff00ff00DiabolicUI3:|r Кастомные чаты " .. (newValue and "|cff00ff00включены|r" or "|cffff0000отключены|r") .. ". Требуется /reload для применения.")
end

ns.SwitchUI = function(self, input)
	if (not self._ui_list) then
		-- Create a list of currently installed UIs.
		self._ui_list = {}
		for ui,cmds in next,{
			["AzeriteUI"] 	= { "azerite", "azui" },
			["DiabolicUI3"] = { "diabolic", "diablo", "dui" },
			["GoldpawUI"] 	= { "goldpaw", "gui" },
			["JourneyUI"] 	= { "journey", "jui" }
		} do
			-- Only include existing UIs that can be switched to.
			if (ui ~= Addon) and (IsAddOnAvailable(ui)) then
				for _,cmd in next,cmds do
					self._ui_list[cmd] = ui
				end
			end
		end
	end
	local arg = self:GetArgs(string_lower(input))
	local target = arg and self._ui_list[arg]
	if (target) then
		EnableAddOn(target) -- Enable the desired UI
		for cmd,ui in next,self._ui_list do
			if (ui and ui ~= target) then -- Don't disable target UI
				DisableAddOn(ui) -- Disable all other UIs
			end
		end
		DisableAddOn(Addon) -- Disable the current UI
		ReloadUI() -- Reload interface to the selected UI
	end
end

ns.UpdateSettings = function(self, event, ...)
	print(event, ...)

	-- Fire callbacks to submodules.
	ns.callbacks:Fire("Saved_Settings_Updated")
end

-- Allow other modules and addons to use this.
ns.GetSettings = function(self)
	return self.db or SanitizeSettings(LibStub("AceDB-3.0"):New(Addon.."_DB", defaults))
end

ns.OnInitialize = function(self)

	self.db = self:GetSettings()
	-- Profile callbacks removed - profiles disabled for per-character settings
	-- self.db.RegisterCallback(self, "OnProfileChanged", "UpdateSettings")
	-- self.db.RegisterCallback(self, "OnProfileCopied", "UpdateSettings")
	-- self.db.RegisterCallback(self, "OnProfileReset", "UpdateSettings")

	-- Apply user scale to all elements
	if (self.db.global.core.relativeScale) then
		SetRelativeScale(self.db.global.core.relativeScale)
	end
	if (self.db.char.minimap.minimapScale) then
		SetMinimapRelativeScale(self.db.char.minimap.minimapScale)
	end
	if (self.db.global.core.unitframesRelativeScale) then
		SetUnitFramesRelativeScale(self.db.global.core.unitframesRelativeScale)
	end

	-- Add a command to clear all chat frames.
	-- I mainly use this to remove clutter before taking screenshots.
	-- You could theoretically put this in a macro and clear chat then screenshot.
	self:RegisterChatCommand("clear", function()
		for _,frameName in pairs(_G.CHAT_FRAMES) do
			local frame = _G[frameName]
			if (frame and frame:IsShown()) then
				frame:Clear()
			end
		end
	end)

	-- Our UI switcher. Because I have many. And use them all.
	self:RegisterChatCommand("go", "SwitchUI")
	self:RegisterChatCommand("switchto", "SwitchUI")

	-- Fully experimental
	self:RegisterChatCommand("setscale", "SetScale")
	self:RegisterChatCommand("resetscale", "ResetScale")
	self:RegisterChatCommand("setminimapscale", "SetMinimapScale")
	self:RegisterChatCommand("setunitframesscale", "SetUnitFramesScale")

	-- Toggle custom chat frames
	self:RegisterChatCommand("togglechat", "ToggleChat")
	self:RegisterChatCommand("disablechat", function() self:ToggleChat("0") end)
	self:RegisterChatCommand("enablechat", function() self:ToggleChat("1") end)


	-- In case some other jokers have disabled these, we add them back to avoid a World of Bugs.
	-- RothUI used to remove the two first, and a lot of people missed his documentation on how to get them back.
	-- I personally removed the objective's tracker for a while in DiabolicUI, which led to pain. Lots of pain.
	for _,v in ipairs({ "Blizzard_CUFProfiles", "Blizzard_CompactRaidFrames", "Blizzard_ObjectiveTracker" }) do
		EnableAddOn(v)
		LoadAddOn(v)
	end

end
