local Addon, ns = ...
local ActionBars = ns:GetModule("ActionBars")
local ExtraButtons = ActionBars:NewModule("ExtraButtons", "LibMoreEvents-1.0", "AceHook-3.0", "AceEvent-3.0")

-- Lua API
local pairs = pairs
local string_find = string.find

-- WoW API
local GetBindingKey = GetBindingKey
local hooksecurefunc = hooksecurefunc

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local SetObjectScale = ns.API.SetUnitFramesObjectScale
local UIHider = ns.Hider
local noop = ns.Noop

ExtraButtons.UpdateButton = function(self, button)

	local name = button:GetName()
	local isExtra = name and string_find(name, "ExtraActionButton%d+")
	if (isExtra) then
		if (not self.ExtraButtons) then
			self.ExtraButtons = {}
		end
		self.ExtraButtons[button] = true
	end

	local db = ns.db.global.extrabuttons
	local size = isExtra and (db.extraSize or 60) or (db.zoneSize or 60)
	button:SetSize(size, size)

	if (button:GetNormalTexture()) then
		button:GetNormalTexture():SetTexture(nil)
	end

	if (button.icon or button.Icon) then (button.icon or button.Icon):SetAlpha(0) end
	if (button.NormalTexture) then button.NormalTexture:SetAlpha(0) end -- Zone
	if (button.Flash) then
		button.Flash:SetTexture(nil)
		if not button.Flash.__GP_FlashHooked then
			button.Flash.__GP_FlashHooked = true
			hooksecurefunc(button.Flash, "Show", function(f) f:SetAlpha(0) end)
		end
	end
	local style = button.style or button.Style
	if style then
		style:SetAlpha(0)
		if not style.__GP_StyleHooked then
			style.__GP_StyleHooked = true
			hooksecurefunc(style, "Show", function(f) f:SetAlpha(0) end)
		end
	end

	local cooldown = button.cooldown or button.Cooldown
	if (cooldown) then
		cooldown:SetSize(size * 0.725, size * 0.725)
		cooldown:ClearAllPoints()
		cooldown:SetPoint("CENTER", 0, 0)
		cooldown:SetSwipeTexture(GetMedia("actionbutton-mask-circular"))
		cooldown:SetSwipeColor(0, 0, 0, .75)
		cooldown:SetDrawSwipe(true)
		cooldown:SetBlingTexture(GetMedia("blank"), 0, 0, 0 , 0)
		cooldown:SetDrawBling(true)
		cooldown:SetHideCountdownNumbers(true)

		-- Attempting to fix the issue with too opaque swipe textures
		if (not cooldown.__GP_Swipe) then
			cooldown.__GP_Swipe = function()
				cooldown:SetSwipeColor(0, 0, 0, .75)
				cooldown:SetDrawSwipe(true)
				cooldown:SetBlingTexture(GetMedia("blank"), 0, 0, 0 , 0)
				cooldown:SetDrawBling(true)
				cooldown:SetHideCountdownNumbers(true)
			end
			cooldown:HookScript("OnShow", cooldown.__GP_Swipe)
		end
	end

	local inset = size * 0.1375
	local count = button.Count
	if (count) then
		count:ClearAllPoints()
		count:SetPoint("BOTTOMRIGHT", -inset, inset)
		count:SetFontObject(GetFont(14, true))
		count:SetJustifyH("RIGHT")
		count:SetJustifyV("BOTTOM")
	end

	local keybind = button.HotKey
	if (keybind) then
		if (ns.db.char.actionbars.hideHotkeys) then
			keybind:SetParent(UIHider)
		end
		keybind:ClearAllPoints()
		keybind:SetPoint("TOPRIGHT", -inset, -inset)
		keybind:SetFontObject(GetFont(12, true))
		keybind:SetJustifyH("CENTER")
		keybind:SetJustifyV("BOTTOM")
		keybind:SetShadowOffset(0, 0)
		keybind:SetShadowColor(0, 0, 0, 1)
		keybind:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75)
		--keybind:SetText(GetBindingKey(button:GetName()))
	end

	if (button.GetCheckedTexture and button:GetCheckedTexture()) then
		button:GetCheckedTexture():SetTexture(nil)
		button:GetCheckedTexture():SetAlpha(0)
	end
	if (button.GetPushedTexture and button:GetPushedTexture()) then
		local pushed = button:GetPushedTexture()
		pushed:SetTexture(nil)
		pushed:SetAlpha(0)
		if not pushed.__GP_PushedHooked then
			pushed.__GP_PushedHooked = true
			hooksecurefunc(pushed, "Show", function(f) f:SetAlpha(0) end)
		end
	end
	if (button:GetObjectType() == "CheckButton") then
		if (not button.__GP_Checked) then
			local checkedTexture = button:CreateTexture()
			checkedTexture:SetAlpha(0)
			hooksecurefunc(checkedTexture, "Show", function(f) f:SetAlpha(0) end)
			button.__GP_Checked = checkedTexture
			button:SetCheckedTexture(checkedTexture)
		end
		if not button.__GP_CTSetHooked then
			button.__GP_CTSetHooked = true
			hooksecurefunc(button, "SetCheckedTexture", function(b, ...)
				local ct = b:GetCheckedTexture()
				if ct and ct ~= b.__GP_Checked then
					ct:SetAlpha(0)
				end
			end)
		end
	end

	-- This crazy stunt is needed to be able
	-- to set a mask at all on the Extra buttons.
	-- I honestly have no idea why. Somebody tell me?
	if (not button.__GP_Icon) then
		local newIcon = button:CreateTexture()
		newIcon:SetPoint("TOPLEFT", button, inset, -inset)
		newIcon:SetPoint("BOTTOMRIGHT", button, -inset, inset)
		newIcon:SetMask(GetMedia("actionbutton-mask-circular"))
		newIcon:SetAlpha(.85)
		button.__GP_Icon = newIcon

		local oldIcon = button.icon or button.Icon

		button.__UpdateGPIcon = function() button.__GP_Icon:SetTexture(oldIcon:GetTexture()) end
		button:__UpdateGPIcon() -- Fix the empty border on reload problem.

		hooksecurefunc(oldIcon, "SetTexture", button.__UpdateGPIcon)
		hooksecurefunc(oldIcon, "Show", button.__UpdateGPIcon)
	end

	if (not button.__GP_Highlight) then
		local highlightTexture = button:CreateTexture()
		highlightTexture:SetDrawLayer("BACKGROUND", 1)
		highlightTexture:SetTexture(GetMedia("actionbutton-mask-circular"))
		highlightTexture:SetAllPoints(button.__GP_Icon)
		highlightTexture:SetVertexColor(1, 1, 1, .1)
		button.__GP_Highlight = highlightTexture

		if (button:GetHighlightTexture()) then
			button:GetHighlightTexture():SetTexture(nil)
		end

		button:SetHighlightTexture(button.__GP_Highlight)
	end

	if (not button.__GP_Border) then
		local border = button:CreateTexture(nil, "BACKGROUND", nil, -7)
		border:SetTexture(GetMedia("button-big-circular"))
		border:SetVertexColor(.8, .76, .72)
		border:SetAllPoints()
		button.__GP_Border = border
	end


end

ExtraButtons.UpdateExtraButtons = function(self)
	local frame = ExtraActionBarFrame
	if (not frame) then
		return
	end
	for i = 1, frame:GetNumChildren() do
		local button = _G["ExtraActionButton"..i]
		if (button) then
			self:UpdateButton(button)
		end
	end
end

ExtraButtons.UpdateZoneButtons = function(self)
	local frame = ZoneAbilityFrame
	if (not frame) then
		return
	end
	if (frame.Style) then
		frame.Style:SetAlpha(0)
	end
	if (frame.SpellButtonContainer) then
		for button in frame.SpellButtonContainer:EnumerateActive() do
			if (button) then
				self:UpdateButton(button)
			end
		end
	end
end

ExtraButtons.UpdateBindings = function(self)
	if (self.ExtraButtons) then
		for button in pairs(self.ExtraButtons) do
			if (button.HotKey) then
				button.HotKey:SetText(GetBindingKey(button:GetName()))
			end
		end
	end
end

ExtraButtons.UpdatePosition = function(self)
	local db = ns.db.global.extrabuttons
	if self.ExtraScaffold then
		self.ExtraScaffold:ClearAllPoints()
		self.ExtraScaffold:SetPoint(
			db.extraPoint or "BOTTOM",
			UIParent,
			db.extraRelPoint or "BOTTOM",
			db.extraPositionX or -546,
			db.extraPositionY or 156
		)
	end
	if self.ZoneScaffold then
		self.ZoneScaffold:ClearAllPoints()
		self.ZoneScaffold:SetPoint(
			db.zonePoint or "BOTTOM",
			UIParent,
			db.zoneRelPoint or "BOTTOM",
			db.zonePositionX or 558,
			db.zonePositionY or 162
		)
	end
end

ExtraButtons.ApplySize = function(self, which)
	local db = ns.db.global.extrabuttons
	if which == "extra" or which == "both" then
		local size = db.extraSize or 60
		if self.ExtraScaffold then
			self.ExtraScaffold:SetSize(size, size)
		end
		self:UpdateExtraButtons()
	end
	if which == "zone" or which == "both" then
		local size = db.zoneSize or 60
		if self.ZoneScaffold then
			self.ZoneScaffold:SetSize(size, size)
		end
		self:UpdateZoneButtons()
	end
end

ExtraButtons.OnInitialize = function(self)
	-- WoW 12.0: Do NOT touch ExtraAbilityContainer (secure frame).
	-- Any modification (SetScale, SetFrameStrata, SetFrameLevel, assigning fields like
	-- ignoreFramePositionManager) taints the frame and causes ADDON_ACTION_BLOCKED
	-- later when Blizzard's code calls Layout()→SetSize() on it.
	-- Work only with ExtraActionBarFrame (its child) which is safe to re-parent.
	local db = ns.db.global.extrabuttons
	-- EditMode scaling: scaffolds use UIParent scale (scale = 1 relative to parent) so that
	-- visual size is fully controlled by the pixel size setting in EditMode, independent of
	-- the "Unit Frames Scale" slider. SetIgnoreParentScale(false) keeps LibEditMode drag math
	-- consistent (coordinates are in UIParent space).
	local EditModeScale = function(object)
		if (object and object.SetScale) then
			object:SetIgnoreParentScale(false)
			object:SetScale(1)
		end
		return object
	end
	-- Don't scale ExtraActionBarFrame separately — it inherits scaffold's scale (1 = UIParent space).
	if (ExtraAbilityContainer and ExtraActionBarFrame) then
		ExtraActionBarFrame:SetIgnoreParentScale(false)
		ExtraActionBarFrame:SetScale(1)
		local extraScaffold = EditModeScale(CreateFrame("Frame", nil, UIParent))
		extraScaffold:SetFrameStrata("LOW")
		extraScaffold:SetFrameLevel(10)
		extraScaffold:SetSize(db.extraSize or 60, db.extraSize or 60)
		ExtraActionBarFrame:SetParent(extraScaffold)
		ExtraActionBarFrame:ClearAllPoints()
		ExtraActionBarFrame:SetAllPoints()
		ExtraActionBarFrame:EnableMouse(false)
		ExtraActionBarFrame.ignoreInLayout = true
		ExtraActionBarFrame.ignoreFramePositionManager = true

		self.ExtraScaffold = extraScaffold
	end

	if (ZoneAbilityFrame) then
		ZoneAbilityFrame:SetIgnoreParentScale(false)
		ZoneAbilityFrame:SetScale(1)
		local zoneScaffold = EditModeScale(CreateFrame("Frame", nil, UIParent))
		zoneScaffold:SetFrameStrata("LOW")
		zoneScaffold:SetFrameLevel(10)
		zoneScaffold:SetSize(db.zoneSize or 60, db.zoneSize or 60)

		ZoneAbilityFrame.SpellButtonContainer.holder = zoneScaffold
		ZoneAbilityFrame.SpellButtonContainer:SetFrameStrata("LOW")
		ZoneAbilityFrame:SetParent(zoneScaffold)
		ZoneAbilityFrame:ClearAllPoints()
		ZoneAbilityFrame:SetAllPoints()
		ZoneAbilityFrame:EnableMouse(false)
		ZoneAbilityFrame.ignoreInLayout = true
		ZoneAbilityFrame.ignoreFramePositionManager = true

		self.ZoneScaffold = zoneScaffold
		self:SecureHook(ZoneAbilityFrame, "UpdateDisplayedZoneAbilities", "UpdateZoneButtons")
	end

	self:UpdatePosition()

	-- EditMode integration (LibEditMode)
	local LibEditMode = ns.LibEditMode
	if (LibEditMode and LibEditMode.AddFrame) then
		local L = ns.L
		-- Helper: create a visible placeholder so the scaffold is draggable in EditMode
		-- even when the actual Blizzard Extra/Zone ability frame is hidden (no active spell).
		local function ensurePreview(scaffold, border, iconTex)
			if (scaffold.__preview) then return scaffold.__preview end
			local preview = scaffold:CreateTexture(nil, "BACKGROUND", nil, -1)
			preview:SetAllPoints()
			preview:SetTexture([[Interface\ICONS\]] .. (iconTex or "INV_Misc_QuestionMark"))
			preview:SetMask(GetMedia("actionbutton-mask-circular"))
			preview:SetAlpha(.85)
			local bord = scaffold:CreateTexture(nil, "BORDER", nil, -7)
			bord:SetTexture(GetMedia("button-big-circular"))
			bord:SetVertexColor(.8, .76, .72)
			bord:SetAllPoints()
			preview:Hide(); bord:Hide()
			scaffold.__preview = preview
			scaffold.__previewBorder = bord
			return preview
		end
		if self.ExtraScaffold then
			ensurePreview(self.ExtraScaffold, true, "INV_Misc_PocketWatch_01")
		end
		if self.ZoneScaffold then
			ensurePreview(self.ZoneScaffold, true, "Spell_Shadow_Teleport")
		end
		LibEditMode:RegisterCallback("enter", function()
			if self.ExtraScaffold and self.ExtraScaffold.__preview then
				self.ExtraScaffold.__preview:Show()
				self.ExtraScaffold.__previewBorder:Show()
			end
			if self.ZoneScaffold and self.ZoneScaffold.__preview then
				self.ZoneScaffold.__preview:Show()
				self.ZoneScaffold.__previewBorder:Show()
			end
		end)
		LibEditMode:RegisterCallback("exit", function()
			if self.ExtraScaffold and self.ExtraScaffold.__preview then
				self.ExtraScaffold.__preview:Hide()
				self.ExtraScaffold.__previewBorder:Hide()
			end
			if self.ZoneScaffold and self.ZoneScaffold.__preview then
				self.ZoneScaffold.__preview:Hide()
				self.ZoneScaffold.__previewBorder:Hide()
			end
		end)
		if self.ExtraScaffold then
			self.ExtraScaffold.editModeName = "Diabolic: Extra Button"
			LibEditMode:AddFrame(self.ExtraScaffold, function(frame, layoutName, point, x, y)
				if (InCombatLockdown()) then return end
				local d = ns.db.global.extrabuttons
				d.extraPoint = point
				d.extraRelPoint = point
				d.extraPositionX = x
				d.extraPositionY = y
			end, {point = db.extraPoint or "BOTTOM", x = db.extraPositionX or -546, y = db.extraPositionY or 156})
			LibEditMode:AddFrameSettings(self.ExtraScaffold, {
				{
					kind = LibEditMode.SettingType.Slider,
					name = L["ExtraButtonSize"],
					desc = L["ExtraButtonSizeDesc"],
					default = 60,
					minValue = 20,
					maxValue = 100,
					valueStep = 1,
					formatter = function(value) return string.format("%dpx", value) end,
					get = function() return ns.db.global.extrabuttons.extraSize or 60 end,
					set = function(layoutName, value)
						ns.db.global.extrabuttons.extraSize = value
						ExtraButtons:ApplySize("extra")
					end,
				}
			})
		end
		if self.ZoneScaffold then
			self.ZoneScaffold.editModeName = "Diabolic: Zone Ability"
			LibEditMode:AddFrame(self.ZoneScaffold, function(frame, layoutName, point, x, y)
				if (InCombatLockdown()) then return end
				local d = ns.db.global.extrabuttons
				d.zonePoint = point
				d.zoneRelPoint = point
				d.zonePositionX = x
				d.zonePositionY = y
			end, {point = db.zonePoint or "BOTTOM", x = db.zonePositionX or 558, y = db.zonePositionY or 162})
			LibEditMode:AddFrameSettings(self.ZoneScaffold, {
				{
					kind = LibEditMode.SettingType.Slider,
					name = L["ZoneAbilitySize"],
					desc = L["ZoneAbilitySizeDesc"],
					default = 60,
					minValue = 20,
					maxValue = 100,
					valueStep = 1,
					formatter = function(value) return string.format("%dpx", value) end,
					get = function() return ns.db.global.extrabuttons.zoneSize or 60 end,
					set = function(layoutName, value)
						ns.db.global.extrabuttons.zoneSize = value
						ExtraButtons:ApplySize("zone")
					end,
				}
			})
		end
	end

	if ns.IsRetail then
		self:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "UpdatePosition")
	end

	if (not self.ExtraScaffold) and (not self.ZoneScaffold) then
		self:Disable()
	end
end

ExtraButtons.OnEnable = function(self)
	if (not self.ExtraScaffold) and (not self.ZoneScaffold) then
		return
	end
	self:UpdateExtraButtons()
	self:UpdateZoneButtons()
	self:UpdateBindings()
	self:RegisterEvent("UPDATE_BINDINGS", "UpdateBindings")
end
