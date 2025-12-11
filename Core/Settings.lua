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
	elseif variable:match("^global_core_") then
		if variable:match("relativeScale$") then
			ns:SetScale(tostring(value))
		elseif variable:match("minimapRelativeScale$") then
			ns:SetMinimapScale(tostring(value))
		elseif variable:match("unitframesRelativeScale$") then
			ns:SetUnitFramesScale(tostring(value))
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
		do
			local function OnReloadClick()
				ReloadUI()
			end
			local initializer = CreateSettingsButtonInitializer(
				L["ReloadButton"],
				"Reload",
				OnReloadClick,
				L["ReloadButtonDesc"],
				true
			)
			layout:AddInitializer(initializer)
		end
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["CoreHeader"]))
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
				"showStanceBar",
				"char.actionbars",
				L["ShowStanceBar"],
				true,
				L["ShowStanceBarDesc"]
			)
			CreateCheckbox(category, setting, L["ShowStanceBarDesc"])
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
			local options = Settings.CreateSliderOptions(-500, 500, 5)
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
			local options = Settings.CreateSliderOptions(0, 200, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["PetBarPosYDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"positionX",
				"global.stancebar",
				L["StanceBarPosX"],
				380,
				L["StanceBarPosXDesc"]
			)
			local options = Settings.CreateSliderOptions(-500, 500, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["StanceBarPosXDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"positionY",
				"global.stancebar",
				L["StanceBarPosY"],
				84,
				L["StanceBarPosYDesc"]
			)
			local options = Settings.CreateSliderOptions(0, 200, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["StanceBarPosYDesc"])
		end
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
			local options = Settings.CreateSliderOptions(-1000, 0, 5)
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
			local options = Settings.CreateSliderOptions(-500, 0, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["AurasPosYDesc"])
		end
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["MinimapHeader"]))
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
			local options = Settings.CreateSliderOptions(-500, 0, 5)
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
			local options = Settings.CreateSliderOptions(-500, 0, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["MinimapPosYDesc"])
		end
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["CastbarHeader"]))
		do
			local setting = RegisterSetting(
				category,
				"enableCastbar",
				"global.castbar",
				L["EnableCastbar"],
				true,
				L["EnableCastbarDesc"]
			)
			CreateCheckbox(category, setting, L["EnableCastbarDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"positionX",
				"global.castbar",
				L["CastbarPosX"],
				0,
				L["CastbarPosXDesc"]
			)
			local options = Settings.CreateSliderOptions(-1000, 1000, 5)
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
			local options = Settings.CreateSliderOptions(-500, 500, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["CastbarPosYDesc"])
		end
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["UnitFramesHeader"]))
		do
			local setting = RegisterSetting(
				category,
				"useClassColorForPower",
				"global.unitframes",
				L["UseClassColorForPower"],
				false,
				L["UseClassColorForPowerDesc"]
			)
			CreateCheckbox(category, setting, L["UseClassColorForPowerDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"hideTargetNameOnCast",
				"global.unitframes",
				L["HideTargetNameOnCast"],
				true,
				L["HideTargetNameOnCastDesc"]
			)
			CreateCheckbox(category, setting, L["HideTargetNameOnCastDesc"])
		end
		do
			local setting = RegisterSetting(
				category,
				"useHealthColorForTarget",
				"global.unitframes",
				L["UseHealthColorForTarget"],
				false,
				L["UseHealthColorForTargetDesc"]
			)
			CreateCheckbox(category, setting, L["UseHealthColorForTargetDesc"])
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
			local options = Settings.CreateSliderOptions(-1000, 1000, 5)
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
			local options = Settings.CreateSliderOptions(-500, 500, 5)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return tostring(value)
			end)
			Settings.CreateSlider(category, setting, options, L["TargetPosYDesc"])
		end
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
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["ResetHeader"]))
		do
			local function OnButtonClick()
				StaticPopup_Show("DIABOLICUI3_RESET_SETTINGS")
			end
			local initializer = CreateSettingsButtonInitializer(
				L["ResetButton"],
				"Reset",
				OnButtonClick,
				L["ResetButtonDesc"],
				true
			)
			layout:AddInitializer(initializer)
		end
		do
			local function OnExportClick()
				local importExport = ns:GetModule("ImportExport")
				if importExport then
					importExport:ExportSettings()
				end
			end
			local initializer = CreateSettingsButtonInitializer(
				L["ExportButton"],
				"Export",
				OnExportClick,
				L["ExportButtonDesc"],
				true
			)
			layout:AddInitializer(initializer)
		end
		do
			local function OnImportClick()
				local importExport = ns:GetModule("ImportExport")
				if importExport then
					importExport:ImportSettings()
				end
			end
			local initializer = CreateSettingsButtonInitializer(
				L["ImportSettingsButton"],
				"Import",
				OnImportClick,
				L["ImportSettingsButtonDesc"],
				true
			)
			layout:AddInitializer(initializer)
		end
		Settings.RegisterAddOnCategory(category)
		StaticPopupDialogs["DIABOLICUI3_RESET_SETTINGS"] = {
			text = L["ResetConfirmation"],
			button1 = YES,
			button2 = NO,
			OnAccept = function()
				ns.db:ResetDB()
				ReloadUI()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
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
