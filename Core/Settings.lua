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
	elseif variable:match("^global_castbar_") then
		ns.callbacks:Fire("Castbar_Settings_Updated")
	elseif variable:match("^global_unitframes_") then
		if variable:match("targetPosition") or variable:match("targetRelativeScale") then
			ns.callbacks:Fire("Target_Position_Updated")
		end
		ns.callbacks:Fire("UnitFrames_Settings_Updated")
	elseif variable:match("^global_petbar_") then
		ns.callbacks:Fire("PetBar_Position_Updated")
	elseif variable:match("^global_stancebar_") then
		ns.callbacks:Fire("StanceBar_Position_Updated")
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
	local setting = Settings.RegisterAddOnSetting(
		category,
		variable,
		key,
		current,
		type(defaultValue),
		name,
		defaultValue
	)
	if setting then
		setting:SetValue(current[key])
		Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
	end
	return setting
end
SettingsModule.OnInitialize = function(self)
	local db = ns.db
	if not db then return end
	EventUtil.ContinueOnAddOnLoaded("Blizzard_Settings", function()
		local CreateCheckbox = Settings.CreateCheckbox or Settings.CreateCheckBox
		local category, layout = Settings.RegisterVerticalLayoutCategory("Diabolic UI")
		categoryID = category.ID
		ns.SettingsCategoryID = categoryID
		-- Apply Button
		do
			local function OnReloadClick()
				ReloadUI()
			end
			local initializer = CreateSettingsButtonInitializer(
				L["ReloadButton"],
				"Apply",
				OnReloadClick,
				L["ReloadButtonDesc"],
				true
			)
			layout:AddInitializer(initializer)
		end
		--------------------------------------------
		-- Scale Section
		--------------------------------------------
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
		-- Orbs Section
		--------------------------------------------
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["OrbsHeader"]))
		do
			local setting = RegisterSetting(
				category,
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
			CreateCheckbox(category, setting, L["UseD2ROrbStyleDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
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
			CreateCheckbox(category, setting, L["UseCustomOrbColorsDesc"])
		end
		do
			local function CreateColorButton(key, labelKey, descKey, defaultColor, buttonLabel)
				local function OnColorClick()
					local color = ns.db.char.orbs[key] or defaultColor
					local originalColor = {r = color.r, g = color.g, b = color.b}
					local info = {
						r = color.r,
						g = color.g,
						b = color.b,
						hasOpacity = false,
						swatchFunc = function()
							local r, g, b = ColorPickerFrame:GetColorRGB()
							ns.db.char.orbs[key] = {r = r, g = g, b = b}
							ns.callbacks:Fire("OrbColors_Updated")
						end,
						cancelFunc = function()
							ns.db.char.orbs[key] = originalColor
							ns.callbacks:Fire("OrbColors_Updated")
						end
					}
					ColorPickerFrame:SetupColorPickerAndShow(info)
				end
				local initializer = CreateSettingsButtonInitializer(
					L[labelKey],
					buttonLabel,
					OnColorClick,
					L[descKey],
					false
				)
				layout:AddInitializer(initializer)
			end
			CreateColorButton("healthColor", "CustomHealthOrbColor", "CustomHealthOrbColorDesc", {r = 1, g = 0, b = 0}, "Health")
			CreateColorButton("powerColor", "CustomPowerOrbColor", "CustomPowerOrbColorDesc", {r = 0, g = 0, b = 1}, "Power")
		end
		--------------------------------------------
		-- Action Bars Section
		--------------------------------------------
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["ActionBarsHeader"]))
		do
			local setting = RegisterSetting(
				category,
				"enableSecondary",
				"char.actionbars",
				L["EnableSecondary"],
				true,
				L["EnableSecondaryDesc"]
			)
			CreateCheckbox(category, setting, L["EnableSecondaryDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"enableThird",
				"char.actionbars",
				L["EnableThird"] or "Enable Third ActionBar",
				false,
				L["EnableThirdDesc"] or "Toggle the third action bar"
			)
			CreateCheckbox(category, setting, L["EnableThirdDesc"] or "Toggle the third action bar")
		end
		do
			local setting = RegisterSetting(
				category,
				"showPetBar",
				"char.actionbars",
				L["ShowPetBar"],
				true,
				L["ShowPetBarDesc"]
			)
			CreateCheckbox(category, setting, L["ShowPetBarDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"positionX",
				"global.petbar",
				L["PetBarPosX"],
				4,
				L["PetBarPosXDesc"]
			)
			local options = Settings.CreateSliderOptions(-2000, 2000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["PetBarPosXDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"positionY",
				"global.petbar",
				L["PetBarPosY"],
				84,
				L["PetBarPosYDesc"]
			)
			local options = Settings.CreateSliderOptions(-2000, 2000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["PetBarPosYDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"useOrbStyle",
				"char.pet",
				L["UsePetOrbStyle"],
				true,
				L["UsePetOrbStyleDesc"]
			)
			Settings.CreateCheckbox(category, setting, L["UsePetOrbStyleDesc"])
		end
		--------------------------------------------
		-- Auras Section
		--------------------------------------------
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["AurasHeader"]))
		local alwaysShowSetting, alwaysHideSetting
		do
			alwaysShowSetting = RegisterSetting(
				category,
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
			CreateCheckbox(category, alwaysShowSetting, L["AlwaysShowAurasDesc"])
		end
		do
			alwaysHideSetting = RegisterSetting(
				category,
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
			CreateCheckbox(category, alwaysHideSetting, L["AlwaysHideAurasDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"positionX",
				"global.auras",
				L["AurasPosX"],
				-380,
				L["AurasPosXDesc"]
			)
			local options = Settings.CreateSliderOptions(-2000, 2000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["AurasPosXDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"positionY",
				"global.auras",
				L["AurasPosY"],
				-66,
				L["AurasPosYDesc"]
			)
			local options = Settings.CreateSliderOptions(-2000, 2000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["AurasPosYDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
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
			Settings.CreateSlider(category, setting, options, L["AurasIconSizeDesc"])
		end
		--------------------------------------------
		-- Map and Minimap Section
		--------------------------------------------
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["MapHeader"]))
		do
			local setting = RegisterSetting(
				category,
				"disabled",
				"global.minimap",
				L["DisableMinimap"],
				false,
				L["DisableMinimapDesc"]
			)
			CreateCheckbox(category, setting, L["DisableMinimapDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"useServerTime",
				"global.minimap",
				L["UseServerTime"],
				false,
				L["UseServerTimeDesc"]
			)
			CreateCheckbox(category, setting, L["UseServerTimeDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"useHalfClock",
				"global.minimap",
				L["UseHalfClock"],
				true,
				L["UseHalfClockDesc"]
			)
			CreateCheckbox(category, setting, L["UseHalfClockDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"positionX",
				"global.minimap",
				L["MinimapPosX"],
				-60,
				L["MinimapPosXDesc"]
			)
			local options = Settings.CreateSliderOptions(-2000, 2000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["MinimapPosXDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"positionY",
				"global.minimap",
				L["MinimapPosY"],
				-60,
				L["MinimapPosYDesc"]
			)
			local options = Settings.CreateSliderOptions(-2000, 2000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["MinimapPosYDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"worldmapCursor",
				"char.mapcoords",
				L["WorldMapCursor"],
				true,
				L["WorldMapCursorDesc"]
			)
			CreateCheckbox(category, setting, L["WorldMapCursorDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"worldmapPlayer",
				"char.mapcoords",
				L["WorldMapPlayer"],
				true,
				L["WorldMapPlayerDesc"]
			)
			CreateCheckbox(category, setting, L["WorldMapPlayerDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"minimap",
				"char.mapcoords",
				L["MinimapCoords"],
				true,
				L["MinimapCoordsDesc"]
			)
			CreateCheckbox(category, setting, L["MinimapCoordsDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"decimals",
				"char.mapcoords",
				L["UseDecimals"],
				false,
				L["UseDecimalsDesc"]
			)
			CreateCheckbox(category, setting, L["UseDecimalsDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
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
			CreateCheckbox(category, setting, L["EnableMinimapButtonsDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
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
			Settings.CreateSlider(category, setting, options, L["MainButtonSizeDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
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
			Settings.CreateSlider(category, setting, options, L["ButtonsPerRowDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
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
			Settings.CreateSlider(category, setting, options, L["AutoHideDelayDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
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
			Settings.CreateSlider(category, setting, options, L["CollectedButtonScaleDesc"])
		end
		--------------------------------------------
		-- Unit Frames Section
		--------------------------------------------
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["UnitFramesHeader"]))
		do
			local setting = RegisterSetting(
				category,
				"useClassColorForPower",
				"char.unitframes",
				L["UseClassColorForPower"],
				false,
				L["UseClassColorForPowerDesc"]
			)
			CreateCheckbox(category, setting, L["UseClassColorForPowerDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"showPlayerBuffs",
				"global.unitframes",
				L["ShowPlayerBuffs"],
				true,
				L["ShowPlayerBuffsDesc"]
			)
			CreateCheckbox(category, setting, L["ShowPlayerBuffsDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"showPlayerInToT",
				"global.unitframes",
				L["ShowPlayerInToT"],
				true,
				L["ShowPlayerInToTDesc"]
			)
			CreateCheckbox(category, setting, L["ShowPlayerInToTDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"showOnlyMyDebuffs",
				"char.unitframes",
				L["ShowOnlyMyDebuffs"],
				true,
				L["ShowOnlyMyDebuffsDesc"]
			)
			CreateCheckbox(category, setting, L["ShowOnlyMyDebuffsDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"targetPositionX",
				"global.unitframes",
				L["TargetPosX"],
				0,
				L["TargetPosXDesc"]
			)
			local options = Settings.CreateSliderOptions(-2000, 2000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["TargetPosXDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"targetPositionY",
				"global.unitframes",
				L["TargetPosY"],
				-40,
				L["TargetPosYDesc"]
			)
			local options = Settings.CreateSliderOptions(-2000, 2000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["TargetPosYDesc"])
		end
		--[[
		-- TargetRelativeScale disabled - not functional
		do
			local setting = RegisterSetting(
				category,
				"targetRelativeScale",
				"global.unitframes",
				L["TargetRelativeScale"],
				1,
				L["TargetRelativeScaleDesc"]
			)
			local options = Settings.CreateSliderOptions(0.5, 1.5, 0.05)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%.2f", value)
			end)
			Settings.CreateSlider(category, setting, options, L["TargetRelativeScaleDesc"])
		end
		--]]
		--------------------------------------------
		-- Tooltips Section
		--------------------------------------------
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["TooltipsHeader"]))
		do
			local setting = RegisterSetting(
				category,
				"x",
				"char.tooltips",
				L["TooltipOffsetX"],
				32,
				L["TooltipOffsetXDesc"]
			)
			local options = Settings.CreateSliderOptions(-100, 100, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["TooltipOffsetXDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"y",
				"char.tooltips",
				L["TooltipOffsetY"],
				-32,
				L["TooltipOffsetYDesc"]
			)
			local options = Settings.CreateSliderOptions(-100, 100, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["TooltipOffsetYDesc"])
		end
		--------------------------------------------
		-- Other Section
		--------------------------------------------
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["OtherHeader"]))
		do
			local setting = RegisterSetting(
				category,
				"movableFrames",
				"char.qol",
				L["MovableFrames"],
				true,
				L["MovableFramesDesc"]
			)
			CreateCheckbox(category, setting, L["MovableFramesDesc"])
		end
		--[[
		-- Castbar position disabled
		do
			local setting = RegisterSetting(
				category,
				"positionX",
				"global.castbar",
				L["CastbarPosX"],
				0,
				L["CastbarPosXDesc"]
			)
			local options = Settings.CreateSliderOptions(-2000, 2000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["CastbarPosXDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"positionY",
				"global.castbar",
				L["CastbarPosY"],
				-150,
				L["CastbarPosYDesc"]
			)
			local options = Settings.CreateSliderOptions(-2000, 2000, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["CastbarPosYDesc"])
		end
		--]]
		-- Reload UI popup for orb style changes
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
