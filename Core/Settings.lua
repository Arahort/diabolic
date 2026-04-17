--[[
	DiabolicUI3 Settings Panel
	Adds settings to Interface Options -> AddOns
	Based on Blizzard Settings API (11.x+)
--]]
local Addon, ns = ...
local SettingsModule = ns:NewModule("Settings", "AceEvent-3.0")
local L = ns.L
local categoryID
local settingsMap = {}
local function OnSettingChanged(_, setting, value)
	local variable = setting:GetVariable()
	local map = settingsMap[variable]
	if map then
		local current = ns.db
		for i = 1, #map.segments do
			current = current[map.segments[i]]
		end
		current[map.key] = value
	end
	if variable:match("^char_actionbars_") then
		ns.callbacks:Fire("ActionBar_Settings_Updated")
	elseif variable:match("^char_auras_") then
		ns.callbacks:Fire("Aura_Settings_Updated")
	elseif variable:match("^char_tooltips_") then
		ns.callbacks:Fire("Tooltips_Settings_Updated")
	elseif variable:match("^char_qol_") then
		ns.callbacks:Fire("QoL_Settings_Updated")
	elseif variable:match("^char_unitframes_") then
		ns.callbacks:Fire("UnitFrames_Settings_Updated")
	elseif variable:match("^global_core_") then
		if variable:match("relativeScale$") then
			ns:SetScale(tostring(value))
		elseif variable:match("unitframesRelativeScale$") then
			ns:SetUnitFramesScale(tostring(value))
		end
		ns.callbacks:Fire("Core_Settings_Updated")
	elseif variable:match("^global_minimap_") then
		ns.callbacks:Fire("Minimap_Settings_Updated")
	elseif variable:match("^global_auras_") then
		ns.callbacks:Fire("Auras_Position_Updated")
		ns.callbacks:Fire("Aura_Settings_Updated")
	elseif variable:match("^global_castbar_") then
		ns.callbacks:Fire("Castbar_Settings_Updated")
	elseif variable:match("^global_unitframes_") then
		ns.callbacks:Fire("UnitFrames_Settings_Updated")
	elseif variable:match("^char_target_") then
		ns.callbacks:Fire("Target_Position_Updated")
	elseif variable:match("^char_classpower_") then
		ns.callbacks:Fire("ClassPower_Position_Updated")
	elseif variable:match("^char_petbar_") then
		ns.callbacks:Fire("PetBar_Position_Updated")
	elseif variable:match("^global_stancebar_") then
		ns.callbacks:Fire("StanceBar_Position_Updated")
	elseif variable:match("^global_micromenu_") then
		ns.callbacks:Fire("MicroMenu_Settings_Updated")
	elseif variable:match("^global_bagbutton_") then
		ns.callbacks:Fire("BagButton_Settings_Updated")
	elseif variable:match("^global_experiments_") then
		ns.callbacks:Fire("Experiments_Settings_Updated")
	end
end
local function RegisterSetting(category, key, path, name, defaultValue, tooltip)
	local variable = path:gsub("%.", "_") .. "_" .. key
	local db = ns.db
	if not db then return end
	local segments = {}
	for segment in path:gmatch("[^.]+") do
		table.insert(segments, segment)
	end
	settingsMap[variable] = {
		segments = segments,
		key = key
	}
	local current = db
	for i = 1, #segments do
		current = current[segments[i]]
	end
	if current[key] == nil then
		current[key] = defaultValue
	end
	-- Use RegisterProxySetting for real-time updates
	local function GetValue()
		return current[key]
	end
	local function SetValue(value)
		current[key] = value
	end
	local setting = Settings.RegisterProxySetting(
		category,
		variable,
		type(defaultValue),
		name,
		defaultValue,
		GetValue,
		SetValue
	)
	if setting then
		-- Wrap callback to match expected signature
		setting:SetValueChangedCallback(function(s, val)
			OnSettingChanged(nil, s, val)
		end)
	end
	return setting
end
SettingsModule.OnInitialize = function(self)
	local db = ns.db
	if not db then return end
	C_AddOns.LoadAddOn("Blizzard_Settings")
	EventUtil.ContinueOnAddOnLoaded("Blizzard_Settings", function()
		local CreateCheckbox = Settings.CreateCheckbox or Settings.CreateCheckBox
		local function AddApplyButton(layout)
			local initializer = CreateSettingsButtonInitializer(
				L["ReloadButton"],
				"Apply",
				function() ReloadUI() end,
				L["ReloadButtonDesc"],
				true
			)
			layout:AddInitializer(initializer)
		end
		--------------------------------------------
		-- Root Category: Diabolic UI (Scale only)
		--------------------------------------------
		local category, layout = Settings.RegisterVerticalLayoutCategory("|TInterface\\AddOns\\DiabolicUI3\\Assets\\diabolic-lettermark:16:16:0:0|t  Diabolic UI")
		categoryID = category.ID
		ns.SettingsCategoryID = categoryID
		AddApplyButton(layout)
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["ScaleHeader"]))
		do
			local setting = RegisterSetting(
				category,
				"relativeScale",
				"global.core",
				L["UIScale"],
				1,
				L["UIScaleDesc"]
			)
			local options = Settings.CreateSliderOptions(0.75, 1.25, 0.05)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%.2f", value)
			end)
			Settings.CreateSlider(category, setting, options, L["UIScaleDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"unitframesRelativeScale",
				"global.core",
				L["UnitFramesScale"],
				1,
				L["UnitFramesScaleDesc"]
			)
			local options = Settings.CreateSliderOptions(0.75, 1.25, 0.05)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%.2f", value)
			end)
			Settings.CreateSlider(category, setting, options, L["UnitFramesScaleDesc"])
		end
		-- Target frame scale slider removed — now available in Edit Mode (LibEditMode)
		--------------------------------------------
		-- Subcategory: Orbs (Сферы)
		--------------------------------------------
		local catOrbs, layoutOrbs = Settings.RegisterVerticalLayoutSubcategory(category, "|T5094560:14:14|t  " .. L["OrbsHeader"])
		AddApplyButton(layoutOrbs)
		do
			local setting = RegisterSetting(
				catOrbs,
				"useD2RStyle",
				"global.orbs",
				L["UseD2ROrbStyle"],
				true,
				L["UseD2ROrbStyleDesc"]
			)
			local OnOrbStyleChanged = function()
				StaticPopup_Show("DIABOLICUI3_RELOAD_UI")
			end
			Settings.SetOnValueChangedCallback("global_orbs_useD2RStyle", OnOrbStyleChanged)
			CreateCheckbox(catOrbs, setting, L["UseD2ROrbStyleDesc"])
		end
		do
			local setting = RegisterSetting(
				catOrbs,
				"useCustomColors",
				"char.orbs",
				L["UseCustomOrbColors"],
				false,
				L["UseCustomOrbColorsDesc"]
			)
			local OnCustomColorsChanged = function()
				ns.callbacks:Fire("OrbColors_Updated")
			end
			Settings.SetOnValueChangedCallback("char_orbs_useCustomColors", OnCustomColorsChanged)
			CreateCheckbox(catOrbs, setting, L["UseCustomOrbColorsDesc"])
		end
		do
			local setting = RegisterSetting(
				catOrbs,
				"eyeGlowD2R",
				"global.orbs",
				L["EyeGlowD2R"],
				false,
				L["EyeGlowD2RDesc"]
			)
			local OnEyeGlowChanged = function()
				ns.callbacks:Fire("OrbEyeGlow_Updated")
			end
			Settings.SetOnValueChangedCallback("global_orbs_eyeGlowD2R", OnEyeGlowChanged)
			CreateCheckbox(catOrbs, setting, L["EyeGlowD2RDesc"])
		end
		do
			local setting = RegisterSetting(
				catOrbs,
				"actionBarsGlow",
				"global.orbs",
				L["ActionBarsGlow"],
				true,
				L["ActionBarsGlowDesc"]
			)
			Settings.SetOnValueChangedCallback("global_orbs_actionBarsGlow", function()
				ns.callbacks:Fire("ActionBarsGlow_Updated")
			end)
			CreateCheckbox(catOrbs, setting, L["ActionBarsGlowDesc"])
		end
		do
			local function CreateColorSwatch(key, labelKey, descKey, defaultColor)
				local initializer = Settings.CreateSettingInitializer("DiabolicColorSwatchSettingTemplate", {
					name = L[labelKey],
					tooltip = L[descKey],
					getColor = function() return ns.db.char.orbs[key] or defaultColor end,
					setColor = function(r, g, b)
						ns.db.char.orbs[key] = {r = r, g = g, b = b}
						ns.callbacks:Fire("OrbColors_Updated")
					end,
				})
				layoutOrbs:AddInitializer(initializer)
			end
			CreateColorSwatch("healthColor", "CustomHealthOrbColor", "CustomHealthOrbColorDesc", {r = 1, g = 0, b = 0})
			CreateColorSwatch("powerColor", "CustomPowerOrbColor", "CustomPowerOrbColorDesc", {r = 0, g = 0, b = 1})
		end
		--------------------------------------------
		-- Subcategory: Action Bars (Панели действий)
		--------------------------------------------
		local catBars, layoutBars = Settings.RegisterVerticalLayoutSubcategory(category, "|T6718291:14:14|t  " .. L["ActionBarsHeader"])
		AddApplyButton(layoutBars)
		do
			local setting = RegisterSetting(
				catBars,
				"enableSecondary",
				"char.actionbars",
				L["EnableSecondary"],
				true,
				L["EnableSecondaryDesc"]
			)
			CreateCheckbox(catBars, setting, L["EnableSecondaryDesc"])
		end
		do
			local setting = RegisterSetting(
				catBars,
				"enableThird",
				"char.actionbars",
				L["EnableThird"] or "Enable Third ActionBar",
				false,
				L["EnableThirdDesc"] or "Toggle the third action bar"
			)
			CreateCheckbox(catBars, setting, L["EnableThirdDesc"] or "Toggle the third action bar")
		end
		do
			local setting = RegisterSetting(
				catBars,
				"showPetBar",
				"char.actionbars",
				L["ShowPetBar"],
				true,
				L["ShowPetBarDesc"]
			)
			CreateCheckbox(catBars, setting, L["ShowPetBarDesc"])
		end
		-- Pet bar position sliders removed — positioning is now handled via Edit Mode (LibEditMode)
		do
			local setting = RegisterSetting(
				catBars,
				"useOrbStyle",
				"char.pet",
				L["UsePetOrbStyle"],
				true,
				L["UsePetOrbStyleDesc"]
			)
			Settings.CreateCheckbox(catBars, setting, L["UsePetOrbStyleDesc"])
		end
		do
			local setting = RegisterSetting(
				catBars,
				"useExtendedBars",
				"char.actionbars",
				L["UseExtendedBars"],
				false,
				L["UseExtendedBarsDesc"]
			)
			CreateCheckbox(catBars, setting, L["UseExtendedBarsDesc"])
		end
		do
			local setting = RegisterSetting(
				catBars,
				"disableSidePanelAutoHide",
				"char.actionbars",
				L["DisableSidePanelAutoHide"],
				false,
				L["DisableSidePanelAutoHideDesc"]
			)
			CreateCheckbox(catBars, setting, L["DisableSidePanelAutoHideDesc"])
		end
		do
			local setting = RegisterSetting(
				catBars,
				"sidePanelToggleAlpha",
				"global.actionbars",
				L["SidePanelToggleAlpha"],
				0.1,
				L["SidePanelToggleAlphaDesc"]
			)
			local options = Settings.CreateSliderOptions(0, 1, 0.1)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%.1f", value)
			end)
			Settings.CreateSlider(catBars, setting, options, L["SidePanelToggleAlphaDesc"])
		end
		do
			local setting = RegisterSetting(
				catBars,
				"hideHotkeys",
				"char.actionbars",
				L["HideHotkeys"],
				false,
				L["HideHotkeysDesc"]
			)
			local OnHideHotkeysToggle = function()
				StaticPopup_Show("DIABOLICUI3_RELOAD_UI")
			end
			Settings.SetOnValueChangedCallback("char_actionbars_hideHotkeys", OnHideHotkeysToggle)
			CreateCheckbox(catBars, setting, L["HideHotkeysDesc"])
		end
		--------------------------------------------
		-- Subcategory: Auras (Ауры)
		--------------------------------------------
		local catAuras, layoutAuras = Settings.RegisterVerticalLayoutSubcategory(category, "|T135893:14:14|t  " .. L["AurasHeader"])
		AddApplyButton(layoutAuras)
		local alwaysShowSetting, alwaysHideSetting
		do
			alwaysShowSetting = RegisterSetting(
				catAuras,
				"alwaysShowAuras",
				"char.auras",
				L["AlwaysShowAuras"],
				true,
				L["AlwaysShowAurasDesc"]
			)
			local function OnAlwaysShowChanged(_, setting, value)
				if value == true and ns.db.char.auras.alwaysHideAuras then
					ns.db.char.auras.alwaysHideAuras = false
					if alwaysHideSetting then
						alwaysHideSetting:SetValue(false)
					end
				end
				ns.callbacks:Fire("Aura_Settings_Updated")
			end
			Settings.SetOnValueChangedCallback("char_auras_alwaysShowAuras", OnAlwaysShowChanged)
			CreateCheckbox(catAuras, alwaysShowSetting, L["AlwaysShowAurasDesc"])
		end
		do
			alwaysHideSetting = RegisterSetting(
				catAuras,
				"alwaysHideAuras",
				"char.auras",
				L["AlwaysHideAuras"],
				false,
				L["AlwaysHideAurasDesc"]
			)
			local function OnAlwaysHideChanged(_, setting, value)
				if value == true and ns.db.char.auras.alwaysShowAuras then
					ns.db.char.auras.alwaysShowAuras = false
					if alwaysShowSetting then
						alwaysShowSetting:SetValue(false)
					end
				end
				ns.callbacks:Fire("Aura_Settings_Updated")
			end
			Settings.SetOnValueChangedCallback("char_auras_alwaysHideAuras", OnAlwaysHideChanged)
			CreateCheckbox(catAuras, alwaysHideSetting, L["AlwaysHideAurasDesc"])
		end
		-- Auras position sliders removed — positioning is now handled via Edit Mode (LibEditMode)
		do
			local setting = RegisterSetting(
				catAuras,
				"iconSize",
				"global.auras",
				L["AurasIconSize"],
				36,
				L["AurasIconSizeDesc"]
			)
			local options = Settings.CreateSliderOptions(20, 64, 1)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catAuras, setting, options, L["AurasIconSizeDesc"])
		end
		do
			local setting = RegisterSetting(
				catAuras,
				"twoRowsTargetAuras",
				"global.auras",
				L["TwoRowsTargetAuras"],
				false,
				L["TwoRowsTargetAurasDesc"]
			)
			local OnTwoRowsChanged = function()
				StaticPopup_Show("DIABOLICUI3_RELOAD_UI")
			end
			Settings.SetOnValueChangedCallback("global_auras_twoRowsTargetAuras", OnTwoRowsChanged)
			CreateCheckbox(catAuras, setting, L["TwoRowsTargetAurasDesc"])
		end
		do
			local setting = RegisterSetting(
				catAuras,
				"hideTargetAuras",
				"global.auras",
				L["HideTargetAuras"],
				false,
				L["HideTargetAurasDesc"]
			)
			Settings.SetOnValueChangedCallback("global_auras_hideTargetAuras", function()
				ns.callbacks:Fire("TargetAuras_Visibility_Updated")
			end)
			CreateCheckbox(catAuras, setting, L["HideTargetAurasDesc"])
		end
		do
			local setting = RegisterSetting(
				catAuras,
				"growUpward",
				"char.auras",
				L["AurasGrowUpward"],
				false,
				L["AurasGrowUpwardDesc"]
			)
			local OnGrowUpwardChanged = function()
				StaticPopup_Show("DIABOLICUI3_RELOAD_UI")
			end
			Settings.SetOnValueChangedCallback("char_auras_growUpward", OnGrowUpwardChanged)
			CreateCheckbox(catAuras, setting, L["AurasGrowUpwardDesc"])
		end
		--------------------------------------------
		-- Subcategory: Unit Frames (Рамки юнитов)
		--------------------------------------------
		local catUF, layoutUF = Settings.RegisterVerticalLayoutSubcategory(category, "|T341221:14:14|t  " .. L["UnitFramesHeader"])
		AddApplyButton(layoutUF)
		do
			local setting = RegisterSetting(
				catUF,
				"useClassColorForPower",
				"char.unitframes",
				L["UseClassColorForPower"],
				false,
				L["UseClassColorForPowerDesc"]
			)
			CreateCheckbox(catUF, setting, L["UseClassColorForPowerDesc"])
		end
		do
			local setting = RegisterSetting(
				catUF,
				"showPlayerBuffs",
				"global.unitframes",
				L["ShowPlayerBuffs"],
				false,
				L["ShowPlayerBuffsDesc"]
			)
			CreateCheckbox(catUF, setting, L["ShowPlayerBuffsDesc"])
		end
		do
			local setting = RegisterSetting(
				catUF,
				"showPlayerInToT",
				"global.unitframes",
				L["ShowPlayerInToT"],
				true,
				L["ShowPlayerInToTDesc"]
			)
			CreateCheckbox(catUF, setting, L["ShowPlayerInToTDesc"])
		end
		do
			local setting = RegisterSetting(
				catUF,
				"showOnlyMyDebuffs",
				"char.unitframes",
				L["ShowOnlyMyDebuffs"],
				true,
				L["ShowOnlyMyDebuffsDesc"]
			)
			CreateCheckbox(catUF, setting, L["ShowOnlyMyDebuffsDesc"])
		end
			-- Target position sliders removed — positioning is now handled via Edit Mode (LibEditMode)
		-- Class Power / Runes sliders removed — positioning is now handled via Edit Mode (LibEditMode)
		--------------------------------------------
		-- Subcategory: Map and Minimap (Карта и миникарта)
		--------------------------------------------
		local catMap, layoutMap = Settings.RegisterVerticalLayoutSubcategory(category, "|TInterface\\Icons\\INV_Misc_Map_01:14:14|t  " .. L["MapHeader"])
		AddApplyButton(layoutMap)
		do
			local setting = RegisterSetting(
				catMap,
				"disabled",
				"global.minimap",
				L["DisableMinimap"],
				false,
				L["DisableMinimapDesc"]
			)
			CreateCheckbox(catMap, setting, L["DisableMinimapDesc"])
		end
		do
			local setting = RegisterSetting(
				catMap,
				"useServerTime",
				"global.minimap",
				L["UseServerTime"],
				false,
				L["UseServerTimeDesc"]
			)
			CreateCheckbox(catMap, setting, L["UseServerTimeDesc"])
		end
		do
			local setting = RegisterSetting(
				catMap,
				"useHalfClock",
				"global.minimap",
				L["UseHalfClock"],
				true,
				L["UseHalfClockDesc"]
			)
			CreateCheckbox(catMap, setting, L["UseHalfClockDesc"])
		end
		-- Minimap position sliders removed — positioning is now handled via Edit Mode (LibEditMode)
		-- LFG Eye Scale removed — now handled via Edit Mode (LibEditMode)
		do
			local setting = RegisterSetting(
				catMap,
				"worldmapCursor",
				"char.mapcoords",
				L["WorldMapCursor"],
				true,
				L["WorldMapCursorDesc"]
			)
			CreateCheckbox(catMap, setting, L["WorldMapCursorDesc"])
		end
		do
			local setting = RegisterSetting(
				catMap,
				"worldmapPlayer",
				"char.mapcoords",
				L["WorldMapPlayer"],
				true,
				L["WorldMapPlayerDesc"]
			)
			CreateCheckbox(catMap, setting, L["WorldMapPlayerDesc"])
		end
		do
			local setting = RegisterSetting(
				catMap,
				"minimap",
				"char.mapcoords",
				L["MinimapCoords"],
				true,
				L["MinimapCoordsDesc"]
			)
			CreateCheckbox(catMap, setting, L["MinimapCoordsDesc"])
		end
		do
			local setting = RegisterSetting(
				catMap,
				"decimals",
				"char.mapcoords",
				L["UseDecimals"],
				false,
				L["UseDecimalsDesc"]
			)
			CreateCheckbox(catMap, setting, L["UseDecimalsDesc"])
		end
		do
			local setting = RegisterSetting(
				catMap,
				"enabled",
				"char.minimapbuttons",
				L["EnableMinimapButtons"],
				true,
				L["EnableMinimapButtonsDesc"]
			)
			local OnEnabledChanged = function()
				if ns.callbacks then
					ns.callbacks:Fire("MinimapButtons_Settings_Updated")
				end
			end
			Settings.SetOnValueChangedCallback("char_minimapbuttons_enabled", OnEnabledChanged)
			CreateCheckbox(catMap, setting, L["EnableMinimapButtonsDesc"])
		end
		do
			local setting = RegisterSetting(
				catMap,
				"mainButtonSize",
				"char.minimapbuttons",
				L["MainButtonSize"],
				40,
				L["MainButtonSizeDesc"]
			)
			local options = Settings.CreateSliderOptions(24, 64, 2)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%d px", value)
			end)
			local OnMainButtonSizeChanged = function()
				if ns.callbacks then
					ns.callbacks:Fire("MinimapButtons_MainButtonSize_Updated")
				end
			end
			Settings.SetOnValueChangedCallback("char_minimapbuttons_mainButtonSize", OnMainButtonSizeChanged)
			Settings.CreateSlider(catMap, setting, options, L["MainButtonSizeDesc"])
		end
		do
			local setting = RegisterSetting(
				catMap,
				"buttonsPerRow",
				"char.minimapbuttons",
				L["ButtonsPerRow"],
				5,
				L["ButtonsPerRowDesc"]
			)
			local options = Settings.CreateSliderOptions(3, 10, 1)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catMap, setting, options, L["ButtonsPerRowDesc"])
		end
		do
			local setting = RegisterSetting(
				catMap,
				"autohide",
				"char.minimapbuttons",
				L["AutoHideDelay"],
				2,
				L["AutoHideDelayDesc"]
			)
			local options = Settings.CreateSliderOptions(0, 10, 1)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catMap, setting, options, L["AutoHideDelayDesc"])
		end
		do
			local setting = RegisterSetting(
				catMap,
				"buttonScale",
				"char.minimapbuttons",
				L["CollectedButtonScale"],
				0.9,
				L["CollectedButtonScaleDesc"]
			)
			local options = Settings.CreateSliderOptions(0.5, 1.5, 0.05)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%.2f", value)
			end)
			Settings.CreateSlider(catMap, setting, options, L["CollectedButtonScaleDesc"])
		end
		--------------------------------------------
		-- Subcategory: Other (Прочее)
		-- Includes: Tooltips, Other
		--------------------------------------------
		local catOther, layoutOther = Settings.RegisterVerticalLayoutSubcategory(category, "|TInterface\\Icons\\trade_engineering:14:14|t  " .. L["OtherHeader"])
		AddApplyButton(layoutOther)
		layoutOther:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["TooltipsHeader"]))
		do
			local setting = RegisterSetting(
				catOther,
				"x",
				"char.tooltips",
				L["TooltipOffsetX"],
				32,
				L["TooltipOffsetXDesc"]
			)
			local options = Settings.CreateSliderOptions(-5000, 5000, 1)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catOther, setting, options, L["TooltipOffsetXDesc"])
		end
		do
			local setting = RegisterSetting(
				catOther,
				"y",
				"char.tooltips",
				L["TooltipOffsetY"],
				-32,
				L["TooltipOffsetYDesc"]
			)
			local options = Settings.CreateSliderOptions(-5000, 5000, 1)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catOther, setting, options, L["TooltipOffsetYDesc"])
		end
		layoutOther:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["OtherHeader"]))
		do
			local setting = RegisterSetting(
				catOther,
				"movableFrames",
				"char.qol",
				L["MovableFrames"],
				true,
				L["MovableFramesDesc"]
			)
			CreateCheckbox(catOther, setting, L["MovableFramesDesc"])
		end
		do
			local setting = RegisterSetting(
				catOther,
				"enableMicroMenu",
				"global.micromenu",
				L["EnableMicroMenu"],
				true,
				L["EnableMicroMenuDesc"]
			)
			local OnMicroMenuToggle = function()
				StaticPopup_Show("DIABOLICUI3_RELOAD_UI")
			end
			Settings.SetOnValueChangedCallback("global_micromenu_enableMicroMenu", OnMicroMenuToggle)
			CreateCheckbox(catOther, setting, L["EnableMicroMenuDesc"])
		end
		-- MicroMenu buttonSize, toggleAlpha and position sliders removed — now handled via Edit Mode (LibEditMode)
		-- BagButton
		do
			local setting = RegisterSetting(
				catOther,
				"hideBagButton",
				"global.bagbutton",
				L["HideBagButton"],
				false,
				L["HideBagButtonDesc"]
			)
			local OnBagButtonToggle = function()
				StaticPopup_Show("DIABOLICUI3_RELOAD_UI")
			end
			Settings.SetOnValueChangedCallback("global_bagbutton_hideBagButton", OnBagButtonToggle)
			CreateCheckbox(catOther, setting, L["HideBagButtonDesc"])
		end
		--------------------------------------------
		-- Subcategory: Experimental (Экспериментальный)
		--------------------------------------------
		local catExp, layoutExp = Settings.RegisterVerticalLayoutSubcategory(category, "|TInterface\\Icons\\Trade_Alchemy:14:14|t  " .. L["ExperimentsHeader"])
		AddApplyButton(layoutExp)
		-- Hide Raid Manager Panel
		do
			local setting = RegisterSetting(
				catExp,
				"hideRaidManager",
				"global.experiments",
				L["HideRaidManager"],
				false,
				L["HideRaidManagerDesc"]
			)
			local OnHideRaidManagerToggle = function()
				StaticPopup_Show("DIABOLICUI3_RELOAD_UI")
			end
			Settings.SetOnValueChangedCallback("global_experiments_hideRaidManager", OnHideRaidManagerToggle)
			CreateCheckbox(catExp, setting, L["HideRaidManagerDesc"])
		end
		do
			local setting = RegisterSetting(
				catExp,
				"customizeRaidFrames",
				"global.experiments",
				L["CustomizeRaidFrames"],
				false,
				L["CustomizeRaidFramesDesc"]
			)
			local OnRaidFramesToggle = function()
				StaticPopup_Show("DIABOLICUI3_RELOAD_UI")
			end
			Settings.SetOnValueChangedCallback("global_experiments_customizeRaidFrames", OnRaidFramesToggle)
			CreateCheckbox(catExp, setting, L["CustomizeRaidFramesDesc"])
			-- Raid Frames sliders (only shown when customizeRaidFrames is enabled)
			local OnRaidFramesSettingChanged = function()
				ns:Fire("RaidFrames_Settings_Updated")
			end
			-- Border Size
			local settingBorderSize = RegisterSetting(
				catExp,
				"raidFramesBorderSize",
				"global.experiments",
				L["RaidFramesBorderSize"],
				15,
				L["RaidFramesBorderSizeDesc"]
			)
			Settings.SetOnValueChangedCallback("global_experiments_raidFramesBorderSize", OnRaidFramesSettingChanged)
			local optionsBorderSize = Settings.CreateSliderOptions(5, 30, 1)
			optionsBorderSize:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%d", value)
			end)
			Settings.CreateSlider(catExp, settingBorderSize, optionsBorderSize, L["RaidFramesBorderSizeDesc"])
			-- Border Top
			local settingBorderTop = RegisterSetting(
				catExp,
				"raidFramesBorderTop",
				"global.experiments",
				L["RaidFramesBorderTop"],
				6,
				L["RaidFramesBorderTopDesc"]
			)
			Settings.SetOnValueChangedCallback("global_experiments_raidFramesBorderTop", OnRaidFramesSettingChanged)
			local optionsBorderTop = Settings.CreateSliderOptions(-10, 20, 1)
			optionsBorderTop:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%d", value)
			end)
			Settings.CreateSlider(catExp, settingBorderTop, optionsBorderTop, L["RaidFramesBorderTopDesc"])
			-- Border Bottom
			local settingBorderBottom = RegisterSetting(
				catExp,
				"raidFramesBorderBottom",
				"global.experiments",
				L["RaidFramesBorderBottom"],
				8,
				L["RaidFramesBorderBottomDesc"]
			)
			Settings.SetOnValueChangedCallback("global_experiments_raidFramesBorderBottom", OnRaidFramesSettingChanged)
			local optionsBorderBottom = Settings.CreateSliderOptions(-10, 20, 1)
			optionsBorderBottom:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%d", value)
			end)
			Settings.CreateSlider(catExp, settingBorderBottom, optionsBorderBottom, L["RaidFramesBorderBottomDesc"])
			-- Border Left
			local settingBorderLeft = RegisterSetting(
				catExp,
				"raidFramesBorderLeft",
				"global.experiments",
				L["RaidFramesBorderLeft"],
				2,
				L["RaidFramesBorderLeftDesc"]
			)
			Settings.SetOnValueChangedCallback("global_experiments_raidFramesBorderLeft", OnRaidFramesSettingChanged)
			local optionsBorderLeft = Settings.CreateSliderOptions(-10, 20, 1)
			optionsBorderLeft:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%d", value)
			end)
			Settings.CreateSlider(catExp, settingBorderLeft, optionsBorderLeft, L["RaidFramesBorderLeftDesc"])
			-- Border Right
			local settingBorderRight = RegisterSetting(
				catExp,
				"raidFramesBorderRight",
				"global.experiments",
				L["RaidFramesBorderRight"],
				2,
				L["RaidFramesBorderRightDesc"]
			)
			Settings.SetOnValueChangedCallback("global_experiments_raidFramesBorderRight", OnRaidFramesSettingChanged)
			local optionsBorderRight = Settings.CreateSliderOptions(-10, 20, 1)
			optionsBorderRight:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%d", value)
			end)
			Settings.CreateSlider(catExp, settingBorderRight, optionsBorderRight, L["RaidFramesBorderRightDesc"])
			-- Role Icon X Offset
			local settingRoleOffsetX = RegisterSetting(
				catExp,
				"raidFramesRoleOffsetX",
				"global.experiments",
				L["RaidFramesRoleOffsetX"],
				5,
				L["RaidFramesRoleOffsetXDesc"]
			)
			Settings.SetOnValueChangedCallback("global_experiments_raidFramesRoleOffsetX", OnRaidFramesSettingChanged)
			local optionsRoleOffsetX = Settings.CreateSliderOptions(-10, 20, 1)
			optionsRoleOffsetX:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%d", value)
			end)
			Settings.CreateSlider(catExp, settingRoleOffsetX, optionsRoleOffsetX, L["RaidFramesRoleOffsetXDesc"])
			-- Role Icon Y Offset
			local settingRoleOffsetY = RegisterSetting(
				catExp,
				"raidFramesRoleOffsetY",
				"global.experiments",
				L["RaidFramesRoleOffsetY"],
				5,
				L["RaidFramesRoleOffsetYDesc"]
			)
			Settings.SetOnValueChangedCallback("global_experiments_raidFramesRoleOffsetY", OnRaidFramesSettingChanged)
			local optionsRoleOffsetY = Settings.CreateSliderOptions(-10, 20, 1)
			optionsRoleOffsetY:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%d", value)
			end)
			Settings.CreateSlider(catExp, settingRoleOffsetY, optionsRoleOffsetY, L["RaidFramesRoleOffsetYDesc"])
		end
		-- AzeriteUI style Group Frames
		do
			local setting = RegisterSetting(
				catExp,
				"azeriteGroupFrames",
				"char.experiments",
				L["AzeriteGroupFrames"],
				false,
				L["AzeriteGroupFramesDesc"]
			)
			local OnAzeriteGroupFramesToggle = function()
				StaticPopup_Show("DIABOLICUI3_RELOAD_UI")
			end
			Settings.SetOnValueChangedCallback("char_experiments_azeriteGroupFrames", OnAzeriteGroupFramesToggle)
			CreateCheckbox(catExp, setting, L["AzeriteGroupFramesDesc"])
		end
		--[[ useAzeriteClassPower (hidden, always enabled)
		do
			local setting = RegisterSetting(
				catExp,
				"useAzeriteClassPower",
				"char.experiments",
				L["UseAzeriteClassPower"],
				false,
				L["UseAzeriteClassPowerDesc"]
			)
			local OnAzeriteClassPowerToggle = function()
				StaticPopup_Show("DIABOLICUI3_RELOAD_UI")
			end
			Settings.SetOnValueChangedCallback("char_experiments_useAzeriteClassPower", OnAzeriteClassPowerToggle)
			CreateCheckbox(catExp, setting, L["UseAzeriteClassPowerDesc"])
		end
		--]]
		-- Reload UI popup
		StaticPopupDialogs["DIABOLICUI3_RELOAD_UI"] = {
			text = L["OrbStyleReloadConfirmation"] or "Changing orb style requires a UI reload. Reload now?",
			button1 = YES,
			button2 = NO,
			OnAccept = function()
				ReloadUI()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
		--------------------------------------------
		-- About subcategory (canvas layout)
		--------------------------------------------
		do
			StaticPopupDialogs["DIABOLICUI3_URL"] = {
				text = "Copy link:",
				button1 = OKAY,
				hasEditBox = true,
				editBoxWidth = 320,
				OnShow = function(self, data)
					local editBox = self.editBox or self.EditBox
					if editBox then
						editBox:SetText(data or "")
						editBox:SetFocus()
						editBox:HighlightText()
					end
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
			}
			local canvas = CreateFrame("ScrollFrame")
			local content = CreateFrame("Frame", nil, canvas)
			content:SetHeight(900)
			canvas:SetScrollChild(content)
			canvas:EnableMouseWheel(true)
			canvas:SetScript("OnMouseWheel", function(self, delta)
				local current = self:GetVerticalScroll()
				local max = self:GetVerticalScrollRange()
				self:SetVerticalScroll(math.max(0, math.min(max, current - delta * 30)))
			end)
			canvas:SetScript("OnSizeChanged", function(sf, w, h)
				content:SetWidth(w)
			end)
			local prev = nil
			local function Line(text, font, gap)
				local fs = content:CreateFontString(nil, "ARTWORK", font or "GameFontNormal")
				fs:SetTextColor(1, 1, 1)
				if prev then
					fs:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -(gap or 4))
				else
					fs:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -16)
				end
				fs:SetPoint("RIGHT", content, "RIGHT", -16, 0)
				fs:SetJustifyH("LEFT")
				fs:SetNonSpaceWrap(true)
				fs:SetText(text)
				prev = fs
			end
			local function Header(text)
				Line("|cffffcc00" .. text .. "|r", "GameFontNormalLarge", 16)
			end
			local function Label(text)
				Line("|cffcccccc" .. text .. "|r", "GameFontNormal", 8)
			end
			local function Gap()
				Line("", "GameFontNormal", 2)
			end
			local function LinkButton(label, url, gap)
				local btn = CreateFrame("Button", nil, content)
				btn:SetHeight(22)
				btn:SetWidth(200)
				if prev then
					btn:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -(gap or 6))
				else
					btn:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -16)
				end
				local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				fs:SetPoint("LEFT")
				fs:SetText("|cff66aaff" .. label .. "|r")
				fs:SetJustifyH("LEFT")
				btn:SetFontString(fs)
				btn:SetScript("OnEnter", function() fs:SetText("|cffffffff" .. label .. "|r") end)
				btn:SetScript("OnLeave", function() fs:SetText("|cff66aaff" .. label .. "|r") end)
				btn:SetScript("OnClick", function()
					StaticPopup_Show("DIABOLICUI3_URL", nil, nil, url)
				end)
				prev = btn
			end
			Header("About")
			local version = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)("DiabolicUI3", "Version") or "?"
			local wowVersion = select(1, GetBuildInfo()) or "?"
			Line("|cffaaaaaa" .. "Version: " .. version .. "    |cff888888WoW: " .. wowVersion .. "|r", "GameFontNormal", 2)
			Line("This is a community-maintained fork of the original Diabolic UI")
			Line("by Lars \"Goldpaw\" Norberg.", nil, 2)
			Gap()
			Label("Original Project Credits")
			Line("Code & Artwork: Lars \"Goldpaw\" Norberg")
			Gap()
			Label("This Fork")
			Line("Updated for WoW 11.x and 12.x by: Alex Arahort")
			Line("Artwork: Alex Arahort and Karina Kisenkova", nil, 2)
			Header("Support")
			Gap()
			LinkButton("Patreon", "https://www.patreon.com/c/Arahort")
			LinkButton("Boosty", "https://boosty.to/alex_arahort")
			LinkButton("GitHub", "https://github.com/Arahort/diabolic")
			LinkButton("Discord", "https://discord.com/channels/407765646634385408/1478671797695025272")
			Gap()
			Label("Crypto")
			Line("USDT TRC20: TShMCz6xGiLvtES8JquqhavrMvFnLM4UQ4")
			Line("USDT TON: UQAKgkYbTk9qWICUn4O249X4F_hqPUHUpCEXNONLbHVfUjcc", nil, 2)
			Line("BTC: bc1q89d70zz5v0f0x00pulrdggmmfav35c0nm99ua3", nil, 2)
			Header("Platynator")
			Label("By SaiyaRatt and Arahort")
			Line("1. Install addon SharedMedia")
			Line("2. Read SharedMedia/INSTRUCTIONS, create MyMedia.txt, run MyMedia.bat", nil, 2)
			Line("3. Copy .tga files from DiabolicUI3/Assets/statusbar/", nil, 2)
			Line("   to SharedMedia_MyMedia/statusbar", nil, 2)
			Line("4. Use platynator_profile.txt to import the preset", nil, 2)
			Header("UI Preset")
			Line("DiabolicUI/Assets/statusbar/ui_profile.txt")
			Header("Thanks")
			Line("Here will be a list of players who supported the development of the addon.")
			Gap()
			Line("Anlorian - The first and largest sponsor of the project.")
			Line("JuNNeZ - help with testing and some bug fixes.")
			Line("Goldpaw - For continuing the great work.")
			Line("SaiyaRatt - Profile for Platynator.")
			Line("YOU can be HERE.", nil, 2)
			Settings.RegisterCanvasLayoutSubcategory(category, canvas, "|T1529344:14:14|t  About")
		end
		Settings.RegisterAddOnCategory(category)
	end)
end
function DiabolicUI3_OnAddonCompartmentClick(addonName, buttonName)
	if buttonName == "RightButton" then
		Settings.OpenToCategory(categoryID)
	end
end
function DiabolicUI3_OnAddonCompartmentEnter(addonName, menuButtonFrame)
	GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
	GameTooltip:SetText("Diabolic UI", 1, 1, 1)
	GameTooltip:AddLine("Left Click: Not implemented yet", nil, 1, nil, true)
	GameTooltip:AddLine("Right Click: Open Settings", nil, 1, nil, true)
	GameTooltip:Show()
end
function DiabolicUI3_OnAddonCompartmentLeave(addonName, menuButtonFrame)
	GameTooltip:Hide()
end
