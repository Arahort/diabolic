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
		elseif variable:match("minimapRelativeScale$") then
			ns:SetMinimapScale(tostring(value))
		elseif variable:match("unitframesRelativeScale$") then
			ns:SetUnitFramesScale(tostring(value))
		elseif variable:match("targetFrameScale$") then
			ns.UpdateTargetFrameScale()
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
		if variable:match("targetPosition") or variable:match("targetRelativeScale") then
			ns.callbacks:Fire("Target_Position_Updated")
		end
		if variable:match("classpowerPosition") or variable:match("classpowerScale") then
			ns.callbacks:Fire("ClassPower_Position_Updated")
		end
		ns.callbacks:Fire("UnitFrames_Settings_Updated")
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
				"minimapRelativeScale",
				"global.core",
				L["MinimapScale"],
				1,
				L["MinimapScaleDesc"]
			)
			local options = Settings.CreateSliderOptions(0.75, 1.25, 0.05)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%.2f", value)
			end)
			Settings.CreateSlider(category, setting, options, L["MinimapScaleDesc"])
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
		do
			local setting = RegisterSetting(
				category,
				"targetFrameScale",
				"global.core",
				L["TargetFrameScale"],
				1,
				L["TargetFrameScaleDesc"]
			)
			local options = Settings.CreateSliderOptions(0.5, 2.0, 0.05)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%.2f", value)
			end)
			Settings.CreateSlider(category, setting, options, L["TargetFrameScaleDesc"])
		end
		--------------------------------------------
		-- Subcategory: Orbs (Сферы)
		--------------------------------------------
		local catOrbs, layoutOrbs = Settings.RegisterVerticalLayoutSubcategory(category, "|TInterface\\Icons\\spell_arcane_arcane04:14:14|t  " .. L["OrbsHeader"])
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
		local catBars, layoutBars = Settings.RegisterVerticalLayoutSubcategory(category, "|TInterface\\Icons\\ability_warrior_battleshout:14:14|t  " .. L["ActionBarsHeader"])
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
		do
			local setting = RegisterSetting(
				catBars,
				"positionX",
				"char.petbar",
				L["PetBarPosX"],
				4,
				L["PetBarPosXDesc"]
			)
			local options = Settings.CreateSliderOptions(-5000, 5000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catBars, setting, options, L["PetBarPosXDesc"])
		end
		do
			local setting = RegisterSetting(
				catBars,
				"positionY",
				"char.petbar",
				L["PetBarPosY"],
				84,
				L["PetBarPosYDesc"]
			)
			local options = Settings.CreateSliderOptions(-5000, 5000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catBars, setting, options, L["PetBarPosYDesc"])
		end
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
		-- Subcategory: Unit Frames (Рамки юнитов)
		-- Includes: Auras + Unit Frames settings
		--------------------------------------------
		local catUF, layoutUF = Settings.RegisterVerticalLayoutSubcategory(category, "|TInterface\\Icons\\achievement_character01_male:14:14|t  " .. L["UnitFramesHeader"])
		AddApplyButton(layoutUF)
		layoutUF:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["AurasHeader"]))
		local alwaysShowSetting, alwaysHideSetting
		do
			alwaysShowSetting = RegisterSetting(
				catUF,
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
			CreateCheckbox(catUF, alwaysShowSetting, L["AlwaysShowAurasDesc"])
		end
		do
			alwaysHideSetting = RegisterSetting(
				catUF,
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
			CreateCheckbox(catUF, alwaysHideSetting, L["AlwaysHideAurasDesc"])
		end
		do
			local setting = RegisterSetting(
				catUF,
				"positionX",
				"global.auras",
				L["AurasPosX"],
				-380,
				L["AurasPosXDesc"]
			)
			local options = Settings.CreateSliderOptions(-5000, 5000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catUF, setting, options, L["AurasPosXDesc"])
		end
		do
			local setting = RegisterSetting(
				catUF,
				"positionY",
				"global.auras",
				L["AurasPosY"],
				-66,
				L["AurasPosYDesc"]
			)
			local options = Settings.CreateSliderOptions(-5000, 5000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catUF, setting, options, L["AurasPosYDesc"])
		end
		do
			local setting = RegisterSetting(
				catUF,
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
			Settings.CreateSlider(catUF, setting, options, L["AurasIconSizeDesc"])
		end
		do
			local setting = RegisterSetting(
				catUF,
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
			CreateCheckbox(catUF, setting, L["TwoRowsTargetAurasDesc"])
		end
		do
			local setting = RegisterSetting(
				catUF,
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
			CreateCheckbox(catUF, setting, L["AurasGrowUpwardDesc"])
		end
		layoutUF:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["UnitFramesHeader"]))
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
		do
			local setting = RegisterSetting(
				catUF,
				"targetPositionX",
				"global.unitframes",
				L["TargetPosX"],
				0,
				L["TargetPosXDesc"]
			)
			local options = Settings.CreateSliderOptions(-5000, 5000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catUF, setting, options, L["TargetPosXDesc"])
		end
		do
			local setting = RegisterSetting(
				catUF,
				"targetPositionY",
				"global.unitframes",
				L["TargetPosY"],
				-40,
				L["TargetPosYDesc"]
			)
			local options = Settings.CreateSliderOptions(-5000, 5000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catUF, setting, options, L["TargetPosYDesc"])
		end
		-- Class Power / Runes Position
		do
			local setting = RegisterSetting(
				catUF,
				"classpowerPositionX",
				"global.unitframes",
				L["ClassPowerPosX"],
				0,
				L["ClassPowerPosXDesc"]
			)
			local options = Settings.CreateSliderOptions(-5000, 5000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catUF, setting, options, L["ClassPowerPosXDesc"])
		end
		do
			local setting = RegisterSetting(
				catUF,
				"classpowerPositionY",
				"global.unitframes",
				L["ClassPowerPosY"],
				300,
				L["ClassPowerPosYDesc"]
			)
			local options = Settings.CreateSliderOptions(-5000, 5000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catUF, setting, options, L["ClassPowerPosYDesc"])
		end
		do
			local setting = RegisterSetting(
				catUF,
				"classpowerScale",
				"global.unitframes",
				L["ClassPowerScale"],
				1.0,
				L["ClassPowerScaleDesc"]
			)
			local options = Settings.CreateSliderOptions(0.5, 2.0, 0.05)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%.2f", value)
			end)
			Settings.CreateSlider(catUF, setting, options, L["ClassPowerScaleDesc"])
		end
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
		do
			local setting = RegisterSetting(
				catMap,
				"positionX",
				"global.minimap",
				L["MinimapPosX"],
				-60,
				L["MinimapPosXDesc"]
			)
			local options = Settings.CreateSliderOptions(-5000, 5000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catMap, setting, options, L["MinimapPosXDesc"])
		end
		do
			local setting = RegisterSetting(
				catMap,
				"positionY",
				"global.minimap",
				L["MinimapPosY"],
				-60,
				L["MinimapPosYDesc"]
			)
			local options = Settings.CreateSliderOptions(-5000, 5000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catMap, setting, options, L["MinimapPosYDesc"])
		end
		-- LFG Eye Scale
		do
			local setting = RegisterSetting(
				catMap,
				"lfgEyeScale",
				"global.minimap",
				L["LFGEyeScale"],
				1.0,
				L["LFGEyeScaleDesc"]
			)
			local options = Settings.CreateSliderOptions(0.5, 2.0, 0.1)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%.1f", value)
			end)
			Settings.CreateSlider(catMap, setting, options, L["LFGEyeScaleDesc"])
		end
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
		do
			local setting = RegisterSetting(
				catOther,
				"buttonSize",
				"global.micromenu",
				L["MicroMenuButtonSize"],
				34,
				L["MicroMenuButtonSizeDesc"]
			)
			local options = Settings.CreateSliderOptions(20, 50, 2)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%d px", value)
			end)
			Settings.CreateSlider(catOther, setting, options, L["MicroMenuButtonSizeDesc"])
		end
		do
			local setting = RegisterSetting(
				catOther,
				"positionX",
				"global.micromenu",
				L["MicroMenuPosX"],
				-11,
				L["MicroMenuPosXDesc"]
			)
			local options = Settings.CreateSliderOptions(-5000, 5000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catOther, setting, options, L["MicroMenuPosXDesc"])
		end
		do
			local setting = RegisterSetting(
				catOther,
				"positionY",
				"global.micromenu",
				L["MicroMenuPosY"],
				11,
				L["MicroMenuPosYDesc"]
			)
			local options = Settings.CreateSliderOptions(-5000, 5000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(catOther, setting, options, L["MicroMenuPosYDesc"])
		end
		do
			local setting = RegisterSetting(
				catOther,
				"toggleAlpha",
				"global.micromenu",
				L["MicroMenuToggleAlpha"],
				0.3,
				L["MicroMenuToggleAlphaDesc"]
			)
			local options = Settings.CreateSliderOptions(0.1, 1.0, 0.1)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%.1f", value)
			end)
			local OnToggleAlphaChanged = function()
				ns:Fire("MicroMenu_Settings_Updated")
			end
			Settings.SetOnValueChangedCallback("global_micromenu_toggleAlpha", OnToggleAlphaChanged)
			Settings.CreateSlider(catOther, setting, options, L["MicroMenuToggleAlphaDesc"])
		end
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
