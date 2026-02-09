--[[
	DiabolicUI3 Platynator Integration
	Custom styling for Platynator addon nameplates

	Since Platynator's Assets table is local and not exposed globally,
	we hook into the nameplate frames directly and modify textures after creation.
--]]
local Addon, ns = ...
local Platynator = ns:NewModule("Platynator", "LibMoreEvents-1.0", "AceHook-3.0")
-- Lua API
local pairs = pairs
local print = print
local select = select
local type = type
-- WoW API
local C_AddOns = C_AddOns
local C_NamePlate = C_NamePlate
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local IsAddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
-- Custom textures path
local CUSTOM_TEXTURES = {
	powerCrystal = [[Interface\AddOns\DiabolicUI3\Assets\power-crystal.png]],
	powerCrystalFront = [[Interface\AddOns\DiabolicUI3\Assets\power-crystal-front.png]],
}
-- Debug mode
local DEBUG = false
-- Adjustable sizes (can be changed via /platynator command)
local FRAME_WIDTH_MULT = 0.35
local FRAME_HEIGHT_MULT = 0.35
-- Debug helper
local Debug = function(...)
	if DEBUG then
		print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r", ...)
	end
end
-- Store processed nameplates to avoid re-processing
Platynator.processedNameplates = {}
-- Cache for Platynator display frames (they're parented to UIParent, not nameplate)
Platynator.displayFrames = {}
-- Find Platynator's custom frame for a unit
-- Platynator frames are NOT children of nameplates - they're parented to UIParent
-- and positioned over the nameplate via SetPoint("CENTER", nameplate)
Platynator.FindPlatynatorFrame = function(self, nameplate, unit)
	if not nameplate then return nil end
	-- First check if we've already cached this frame
	if self.displayFrames[unit] then
		return self.displayFrames[unit]
	end
	-- Platynator frames are children of UIParent with widgets and kind fields
	-- We need to find frames that are anchored to this nameplate
	local children = { UIParent:GetChildren() }
	for _, child in pairs(children) do
		-- Platynator display frames have 'widgets' table, 'kind' field, and 'unit' field
		if child.widgets and child.kind and child.unit then
			-- Check if this display is for our unit
			if child.unit == unit then
				Debug("Found Platynator display via UIParent scan!")
				self.displayFrames[unit] = child
				return child
			end
		end
	end
	-- Alternative: check if frame is positioned at nameplate's center
	for _, child in pairs(children) do
		if child.widgets and child.kind then
			-- Use pcall to avoid taint errors on protected frames
			local ok, point, relativeTo = pcall(child.GetPoint, child, 1)
			if ok and relativeTo == nameplate then
				Debug("Found Platynator display via anchor check!")
				self.displayFrames[unit] = child
				return child
			end
		end
	end
	return nil
end
-- Modify the health bar texture of a Platynator nameplate
Platynator.CustomizeHealthBar = function(self, display)
	if not display or not display.widgets then
		return false
	end
	local customized = false
	for _, widget in pairs(display.widgets) do
		-- Health bars have statusBar and background elements
		if widget.statusBar and widget.background and widget.details and widget.details.kind == "health" then
			Debug("Found health bar widget!")
			widget.diabolicCustomized = true
			local origWidth, origHeight = widget.statusBar:GetSize()
			Debug("  StatusBar size:", origWidth, "x", origHeight)
			-- Hook SetColor and SetSize to reapply texture and update frame size
			if not widget.diabolicHooked then
				widget.diabolicHooked = true
				-- Hook SetColor
				local originalSetColor = widget.SetColor
				if originalSetColor then
					widget.SetColor = function(self, ...)
						originalSetColor(self, ...)
						if self.diabolicCustomized then
							self.statusBar:SetStatusBarTexture(CUSTOM_TEXTURES.powerCrystalFront)
						end
					end
					Debug("  Hooked SetColor!")
				end
				-- Hook SetSize on statusBar to update frame when size changes (combat scaling)
				local originalSetSize = widget.statusBar.SetSize
				widget.statusBar.SetSize = function(bar, w, h)
					originalSetSize(bar, w, h)
					if widget.diabolicFrame then
						local frameWidth = w * FRAME_WIDTH_MULT
						local frameHeight = h * FRAME_HEIGHT_MULT
						widget.diabolicFrame:SetSize(frameWidth, frameHeight)
					end
				end
				Debug("  Hooked SetSize!")
			end
			-- Use DiabolicUI power crystal textures
			widget.statusBar:SetStatusBarTexture(CUSTOM_TEXTURES.powerCrystalFront)
			-- Store original size
			if not widget.diabolicOrigSize then
				widget.diabolicOrigSize = { width = origWidth, height = origHeight }
			end
			-- Hide Platynator's background and border
			widget.background:SetAlpha(0)
			if widget.border then
				widget.border:SetAlpha(0)
			end
			-- Create DiabolicUI power crystal frame overlay
			if not widget.diabolicFrame then
				Debug("  Creating DiabolicUI power-crystal frame overlay...")
				widget.diabolicFrame = widget:CreateTexture(nil, "OVERLAY")
				widget.diabolicFrame:SetTexture(CUSTOM_TEXTURES.powerCrystal)
				widget.diabolicFrame:SetVertexColor(1, 1, 1, 1)
				-- StatusBar ~358x47, adjust frame to fit
				local frameWidth = origWidth * FRAME_WIDTH_MULT
				local frameHeight = origHeight * FRAME_HEIGHT_MULT
				widget.diabolicFrame:SetSize(frameWidth, frameHeight)
				widget.diabolicFrame:SetPoint("CENTER", widget.statusBar, "CENTER", 0, 0)
				Debug("  Frame size:", frameWidth, "x", frameHeight)
			end
			widget.diabolicFrame:Show()
			Debug("  Textures applied!")
			customized = true
		end
	end
	return customized
end
-- Try to customize a nameplate with retries
Platynator.TryCustomize = function(self, nameplate, unit, attempt)
	attempt = attempt or 1
	local maxAttempts = 5
	local display = self:FindPlatynatorFrame(nameplate, unit)
	if display then
		Debug("Found Platynator display for", unit, "- kind:", display.kind, "attempt:", attempt)
		if self:CustomizeHealthBar(display) then
			Debug("Customized health bar for", unit)
			self.processedNameplates[nameplate] = true
		end
	elseif attempt < maxAttempts then
		-- Retry after a short delay
		C_Timer.After(0.2, function()
			-- Check if nameplate still exists
			if C_NamePlate.GetNamePlateForUnit(unit) then
				self:TryCustomize(nameplate, unit, attempt + 1)
			end
		end)
	else
		Debug("Failed to find Platynator frame for", unit, "after", maxAttempts, "attempts")
	end
end
-- Called when a nameplate is added
Platynator.OnNamePlateAdded = function(self, unit)
	if not unit then
		Debug("OnNamePlateAdded: unit is nil!")
		return
	end
	local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	if not nameplate then
		Debug("OnNamePlateAdded: nameplate not found for", unit)
		return
	end
	-- Skip if already processed this nameplate instance
	if self.processedNameplates[nameplate] then
		Debug("OnNamePlateAdded: already processed", unit)
		return
	end
	Debug("OnNamePlateAdded: processing", unit)
	-- Wait a bit for Platynator to set up its frame, then try with retries
	C_Timer.After(0.2, function()
		self:TryCustomize(nameplate, unit, 1)
	end)
end
-- Called when a nameplate is removed
Platynator.OnNamePlateRemoved = function(self, unit)
	if not unit then return end
	local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	if nameplate then
		self.processedNameplates[nameplate] = nil
	end
	-- Clear cached display frame
	if self.displayFrames[unit] then
		self.displayFrames[unit] = nil
	end
end
-- Setup hooks for nameplate events
Platynator.SetupHooks = function(self)
	Debug("Setting up nameplate hooks...")
	-- Create event frame for nameplate events
	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	eventFrame:SetScript("OnEvent", function(_, event, unit)
		if event == "NAME_PLATE_UNIT_ADDED" then
			Debug("Event: NAME_PLATE_UNIT_ADDED for", unit)
			self:OnNamePlateAdded(unit)
		elseif event == "NAME_PLATE_UNIT_REMOVED" then
			self:OnNamePlateRemoved(unit)
		end
	end)
	self.eventFrame = eventFrame
	-- Process any existing nameplates with a delay to let Platynator set up
	Debug("Checking for existing nameplates...")
	C_Timer.After(0.5, function()
		Debug("Scanning existing nameplates...")
		local found = 0
		for i = 1, 40 do
			local unit = "nameplate" .. i
			local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
			if nameplate then
				found = found + 1
				Debug("Found existing nameplate:", unit)
				self:OnNamePlateAdded(unit)
			end
		end
		Debug("Scan complete. Found", found, "existing nameplates")
	end)
	Debug("Hooks set up successfully!")
end
-- Called when Platynator is ready
Platynator.SetupPlatynator = function(self)
	Debug("Platynator is now loaded! Starting integration...")
	-- Get Platynator's global table to verify it's loaded
	local PlatynatorAddon = _G.Platynator
	if not PlatynatorAddon then
		Debug("ERROR: Platynator global table not found!")
		return
	end
	Debug("Found Platynator global table!")
	-- Check what's available in the global API
	if PlatynatorAddon.API then
		Debug("Platynator.API is available")
		for k, v in pairs(PlatynatorAddon.API) do
			Debug("  API." .. tostring(k), "=", type(v))
		end
	end
	-- Note: Platynator's Assets table is LOCAL and not accessible from outside
	-- We need to hook into the frames directly
	Debug("Note: Assets table is local to Platynator, using frame hooks instead")
	-- Setup hooks for nameplate customization
	self:SetupHooks()
end
-- Event handler for ADDON_LOADED
Platynator.OnAddonLoaded = function(self, event, addonName)
	if addonName == "Platynator" then
		Debug("ADDON_LOADED: Platynator!")
		self:UnregisterEvent("ADDON_LOADED", "OnAddonLoaded")
		self:SetupPlatynator()
	end
end
Platynator.OnInitialize = function(self)
	-- Check if experiment is enabled
	local db = ns.db
	if not db or not db.global or not db.global.experiments then
		Debug("Settings not available, disabling module")
		return self:Disable()
	end
	if not db.global.experiments.customizePlatynator then
		-- Silent disable when experiment is off
		return self:Disable()
	end
	Debug("Experiment enabled, checking for Platynator addon...")
	-- Check if Platynator addon is already loaded
	local isPlatynatorLoaded = IsAddOnLoaded("Platynator")
	if isPlatynatorLoaded then
		Debug("Platynator addon already loaded!")
		self:SetupPlatynator()
	else
		-- Check if it exists but not loaded yet
		local platynatorExists = C_AddOns and C_AddOns.DoesAddOnExist and C_AddOns.DoesAddOnExist("Platynator")
		if platynatorExists then
			Debug("Platynator addon exists, waiting for ADDON_LOADED...")
			self:RegisterEvent("ADDON_LOADED", "OnAddonLoaded")
		else
			Debug("Platynator addon NOT FOUND in AddOns folder")
			return self:Disable()
		end
	end
end
-- Update all existing frames with new size multipliers
Platynator.UpdateAllFrames = function(self)
	local children = { UIParent:GetChildren() }
	for _, child in pairs(children) do
		if child.widgets and child.kind then
			for _, widget in pairs(child.widgets) do
				if widget.diabolicFrame and widget.diabolicOrigSize then
					local origWidth = widget.diabolicOrigSize.width
					local origHeight = widget.diabolicOrigSize.height
					-- Update frame size
					local frameWidth = origWidth * FRAME_WIDTH_MULT
					local frameHeight = origHeight * FRAME_HEIGHT_MULT
					widget.diabolicFrame:SetSize(frameWidth, frameHeight)
				end
			end
		end
	end
	print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r Updated: frame=" .. FRAME_WIDTH_MULT .. "x" .. FRAME_HEIGHT_MULT)
end
Platynator.OnEnable = function(self)
	-- Register slash command
	SLASH_PLATYNATOR1 = "/platynator"
	SLASH_PLATYNATOR2 = "/platy"
	SlashCmdList["PLATYNATOR"] = function(msg)
		local cmd, value = msg:match("^(%S+)%s*(.*)$")
		if cmd == "w" or cmd == "width" then  -- frame width
			local num = tonumber(value)
			if num and num > 0 and num < 3 then
				FRAME_WIDTH_MULT = num
				self:UpdateAllFrames()
			else
				print("Usage: /platy w 0.75")
			end
		elseif cmd == "h" or cmd == "height" then  -- frame height
			local num = tonumber(value)
			if num and num > 0 and num < 5 then
				FRAME_HEIGHT_MULT = num
				self:UpdateAllFrames()
			else
				print("Usage: /platy h 1.5")
			end
		else
			print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r Commands:")
			print("  /platy w <num> - frame width (current: " .. FRAME_WIDTH_MULT .. ")")
			print("  /platy h <num> - frame height (current: " .. FRAME_HEIGHT_MULT .. ")")
		end
	end
end
Platynator.OnDisable = function(self)
	-- Cleanup event frame if it exists
	if self.eventFrame then
		self.eventFrame:UnregisterAllEvents()
		self.eventFrame = nil
	end
	self.processedNameplates = {}
end
