local Addon, ns = ...
local Development = ns:NewModule("Development", "AceConsole-3.0", "LibMoreEvents-1.0")

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetScale = ns.API.GetScale

Development.ToggleDevMode = function(self)
	ns.db.global.core.enableDevelopmentMode = not ns.db.global.core.enableDevelopmentMode
	ReloadUI()
end

Development.OnInitialize = function(self)

	local showVersion = ns.db.global.core.enableDevelopmentMode or ns.IsDevelopment or ns.IsAlpha or ns.IsBeta or ns.IsRC
	if (showVersion) then
		local versionLabel = UIParent:CreateFontString()
		versionLabel:SetIgnoreParentScale(true)
		versionLabel:SetScale(GetScale())
		versionLabel:SetDrawLayer("OVERLAY", 1)
		versionLabel:SetFontObject(GetFont(12,true))
		versionLabel:SetTextColor(unpack(Colors.offwhite))
		versionLabel:SetAlpha(.85)
		versionLabel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 10)
		if (ns.IsDevelopment) then
			versionLabel:SetText("Git Version")
		else
			versionLabel:SetText(ns.Version)
		end
		self.VersionLabel = versionLabel
	end

	if (ns.db.global.core.enableDevelopmentMode) then
		local devLabel = UIParent:CreateFontString()
		devLabel:SetIgnoreParentScale(true)
		devLabel:SetScale(GetScale())
		devLabel:SetDrawLayer("OVERLAY", 1)
		devLabel:SetFontObject(GetFont(12,true))
		devLabel:SetTextColor(unpack(Colors.gray))
		devLabel:SetAlpha(.85)
		devLabel:SetText("Dev Mode")
		if (showVersion) then
			devLabel:SetPoint("BOTTOMLEFT", self.VersionLabel, "TOPLEFT", 0, 4)
		else
			devLabel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 10)
		end
		self.DevLabel = devLabel
	end

	self:RegisterChatCommand("devmode", "ToggleDevMode")
end
