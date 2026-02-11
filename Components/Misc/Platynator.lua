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
-- Custom textures path (use TGA files with underscores)
local CUSTOM_TEXTURES = {
	powerCrystal = [[Interface\AddOns\DiabolicUI3\Assets\power_crystal_back.tga]],
	powerCrystalFront = [[Interface\AddOns\DiabolicUI3\Assets\power_crystal_front.tga]],
}
-- Debug mode
local DEBUG = true
-- Get size settings from db (with fallbacks)
local function GetFrameWidthMult()
	local db = ns.db
	return db and db.global and db.global.experiments and db.global.experiments.platynatorFrameWidthMult or 0.35
end
local function GetFrameHeightMult()
	local db = ns.db
	return db and db.global and db.global.experiments and db.global.experiments.platynatorFrameHeightMult or 0.35
end
local function GetFrameWidthExtra()
	local db = ns.db
	return db and db.global and db.global.experiments and db.global.experiments.platynatorFrameWidthExtra or 3
end
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
-- Deep scan helper - prints all keys on a frame
local function DumpFrameKeys(frame, prefix)
	prefix = prefix or ""
	local keys = {}
	for k, v in pairs(frame) do
		local vtype = type(v)
		if vtype == "table" then
			table.insert(keys, prefix .. tostring(k) .. " = [table]")
		elseif vtype == "function" then
			-- skip functions
		elseif vtype == "userdata" then
			table.insert(keys, prefix .. tostring(k) .. " = [userdata/frame]")
		else
			table.insert(keys, prefix .. tostring(k) .. " = " .. tostring(v))
		end
	end
	return keys
end
-- Find Platynator's custom frame for a unit
-- Tries multiple methods to find Platynator frames
Platynator.FindPlatynatorFrame = function(self, nameplate, unit)
	if not nameplate then return nil end
	-- First check if we've already cached this frame
	if self.displayFrames[unit] then
		return self.displayFrames[unit]
	end
	Debug("=== DEEP SCAN for", unit, "===")
	-- Method 1: Check nameplate children for Platynator frames
	Debug("Method 1: Scanning nameplate children...")
	local children = { nameplate:GetChildren() }
	Debug("  Found", #children, "children")
	local platynatorFrame = nil
	for i, child in ipairs(children) do
		local childName = child:GetName() or "unnamed"
		local childType = child:GetObjectType()
		Debug("  Child", i, ":", childType, childName)
		-- Check if this is a Blizzard frame (has Blizzard-specific fields)
		local isBlizzardFrame = child.HealthBarsContainer or child.classificationIndicator or child.RaidTargetFrame
		if isBlizzardFrame then
			Debug("    ^ This is a BLIZZARD frame, skipping")
		else
			-- Dump interesting keys for non-Blizzard frames
			local keys = DumpFrameKeys(child, "    ")
			for _, key in ipairs(keys) do
				Debug(key)
			end
			-- Check for widgets (Platynator structure)
			if child.widgets then
				Debug("  >>> FOUND Platynator frame with widgets!")
				platynatorFrame = child
				self.displayFrames[unit] = child
				return child, "widgets"
			end
			-- Check for healthBar on non-Blizzard frame
			if child.healthBar and not isBlizzardFrame then
				Debug("  >>> FOUND healthBar on non-Blizzard frame!")
				platynatorFrame = child
			end
		end
	end
	-- If we found a non-Blizzard healthBar frame, use it
	if platynatorFrame then
		self.displayFrames[unit] = platynatorFrame
		return platynatorFrame, "healthBar"
	end
	-- Method 2: Check UIParent children (old Platynator structure)
	Debug("Method 2: Scanning UIParent children...")
	local uiChildren = { UIParent:GetChildren() }
	local platynatorFrames = 0
	for _, child in pairs(uiChildren) do
		-- Look for Platynator-specific fields
		if child.widgets and child.kind then
			platynatorFrames = platynatorFrames + 1
			if child.unit == unit then
				Debug("  >>> FOUND via UIParent! unit match:", unit)
				self.displayFrames[unit] = child
				return child, "widgets-uiparent"
			end
		end
	end
	Debug("  Found", platynatorFrames, "Platynator-style frames in UIParent")
	-- Method 3: Check if Platynator global has any useful methods
	Debug("Method 3: Checking Platynator global API...")
	local PlatynatorAddon = _G.Platynator
	if PlatynatorAddon then
		-- Check for GetDisplay or similar method
		if PlatynatorAddon.GetDisplay then
			Debug("  Found GetDisplay method!")
			local display = PlatynatorAddon:GetDisplay(unit)
			if display then
				Debug("  >>> Got display from API!")
				self.displayFrames[unit] = display
				return display, "api"
			end
		end
		if PlatynatorAddon.displays then
			Debug("  Found displays table!")
			local display = PlatynatorAddon.displays[unit]
			if display then
				Debug("  >>> Got display from displays table!")
				self.displayFrames[unit] = display
				return display, "displays-table"
			end
		end
		-- Dump Platynator global keys
		Debug("  Platynator global keys:")
		local keys = DumpFrameKeys(PlatynatorAddon, "    ")
		for _, key in ipairs(keys) do
			Debug(key)
		end
	end
	Debug("=== END DEEP SCAN - NOT FOUND ===")
	return nil
end
-- Modify the health bar texture of a Platynator nameplate
-- Supports multiple structures:
-- 1. New: display.healthBar (StatusBar)
-- 2. Old: display.widgets[].statusBar with details.kind == "health"
Platynator.CustomizeHealthBar = function(self, display, structureType)
	if not display then
		return false
	end
	Debug("CustomizeHealthBar called, structureType:", structureType or "unknown")
	-- Try to find the health bar based on structure type
	local healthBar
	local widget -- for old structure
	-- New structure: direct healthBar
	if display.healthBar then
		healthBar = display.healthBar
		Debug("Using direct healthBar")
	-- Old structure: widgets table
	elseif display.widgets then
		Debug("Looking in widgets table...")
		for _, w in pairs(display.widgets) do
			if w.statusBar and w.details and w.details.kind == "health" then
				healthBar = w.statusBar
				widget = w
				Debug("Found health widget with statusBar")
				break
			elseif w.statusBar and w.background then
				-- Alternative: has statusBar and background
				healthBar = w.statusBar
				widget = w
				Debug("Found widget with statusBar and background")
				break
			end
		end
	end
	if not healthBar then
		Debug("No healthBar found on display!")
		-- Dump display structure for debugging
		Debug("Display keys:")
		local keys = DumpFrameKeys(display, "  ")
		for _, key in ipairs(keys) do
			Debug(key)
		end
		return false
	end
	Debug("Found healthBar!")
	local origWidth, origHeight = healthBar:GetSize()
	Debug("  HealthBar size:", origWidth, "x", origHeight)
	-- For old widget structure, hide background and border
	if widget then
		if widget.background then
			widget.background:SetAlpha(0)
			Debug("  Hidden widget.background")
		end
		if widget.border then
			widget.border:SetAlpha(0)
			Debug("  Hidden widget.border")
		end
	end
	-- Mark as customized
	display.diabolicCustomized = true
	-- Hook SetSize on healthBar to update frame when size changes (combat scaling)
	if not display.diabolicHooked then
		display.diabolicHooked = true
		local originalSetSize = healthBar.SetSize
		healthBar.SetSize = function(bar, w, h)
			originalSetSize(bar, w + GetFrameWidthExtra(), h)
			if display.diabolicFrame then
				local frameWidth = w * GetFrameWidthMult() + GetFrameWidthExtra()
				local frameHeight = h * GetFrameHeightMult()
				display.diabolicFrame:SetSize(frameWidth, frameHeight)
			end
		end
		Debug("  Hooked SetSize!")
		-- Also hook SetWidth and SetHeight
		local originalSetWidth = healthBar.SetWidth
		healthBar.SetWidth = function(bar, w)
			originalSetWidth(bar, w + GetFrameWidthExtra())
			if display.diabolicFrame then
				local frameWidth = w * GetFrameWidthMult() + GetFrameWidthExtra()
				display.diabolicFrame:SetWidth(frameWidth)
			end
		end
		local originalSetHeight = healthBar.SetHeight
		healthBar.SetHeight = function(bar, h)
			originalSetHeight(bar, h)
			if display.diabolicFrame then
				local frameHeight = h * GetFrameHeightMult()
				display.diabolicFrame:SetHeight(frameHeight)
			end
		end
		Debug("  Hooked SetWidth/SetHeight!")
	end
	-- Hook SetStatusBarTexture to prevent Platynator from overwriting our texture
	if not display.diabolicTextureHooked then
		display.diabolicTextureHooked = true
		-- Hook the StatusBar method
		local originalSetStatusBarTexture = healthBar.SetStatusBarTexture
		healthBar.SetStatusBarTexture = function(bar, tex, ...)
			-- Always use our custom texture instead
			originalSetStatusBarTexture(bar, CUSTOM_TEXTURES.powerCrystalFront, ...)
			Debug("  Intercepted SetStatusBarTexture, using our texture instead")
		end
		Debug("  Hooked SetStatusBarTexture!")
		-- Also hook the texture object directly (Platynator might use tex:SetTexture())
		local statusBarTex = healthBar:GetStatusBarTexture()
		if statusBarTex then
			local originalTexSetTexture = statusBarTex.SetTexture
			statusBarTex.SetTexture = function(self, tex, ...)
				-- Always use our custom texture instead
				originalTexSetTexture(self, CUSTOM_TEXTURES.powerCrystalFront, ...)
				Debug("  Intercepted texture:SetTexture, using our texture instead")
			end
			Debug("  Hooked texture:SetTexture!")
		end
	end
	-- Apply our custom texture directly to the texture object (most reliable)
	local statusBarTex = healthBar:GetStatusBarTexture()
	if statusBarTex then
		-- Use raw SetTexture if available, or go through our hook
		statusBarTex:SetTexture(CUSTOM_TEXTURES.powerCrystalFront)
		print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r Texture after set:", statusBarTex:GetTexture())
	else
		-- Fallback: use SetStatusBarTexture
		healthBar:SetStatusBarTexture(CUSTOM_TEXTURES.powerCrystalFront)
	end
	Debug("  Applied custom texture to healthBar!")
	-- Store original size and expand healthBar width
	if not display.diabolicOrigSize then
		display.diabolicOrigSize = { width = origWidth, height = origHeight }
		healthBar:SetSize(origWidth + GetFrameWidthExtra(), origHeight)
	end
	-- Create DiabolicUI power crystal frame overlay
	-- For widget structure, create on widget; otherwise on display
	local overlayParent = widget or display
	if not overlayParent.diabolicFrame then
		Debug("  Creating DiabolicUI power-crystal frame overlay on", widget and "widget" or "display")
		overlayParent.diabolicFrame = overlayParent:CreateTexture(nil, "OVERLAY")
		overlayParent.diabolicFrame:SetTexture(CUSTOM_TEXTURES.powerCrystal)
		overlayParent.diabolicFrame:SetVertexColor(1, 1, 1, 1)
		local frameWidth = origWidth * GetFrameWidthMult() + GetFrameWidthExtra()
		local frameHeight = origHeight * GetFrameHeightMult()
		overlayParent.diabolicFrame:SetSize(frameWidth, frameHeight)
		overlayParent.diabolicFrame:SetPoint("CENTER", healthBar, "CENTER", 0, 0)
		Debug("  Frame size:", frameWidth, "x", frameHeight)
	end
	overlayParent.diabolicFrame:Show()
	-- Store reference on display for UpdateAllFrames
	display.diabolicFrame = overlayParent.diabolicFrame
	Debug("  Customization complete!")
	return true
end
-- Try to customize a nameplate with retries
Platynator.TryCustomize = function(self, nameplate, unit, attempt)
	attempt = attempt or 1
	local maxAttempts = 5
	local display, structureType = self:FindPlatynatorFrame(nameplate, unit)
	if display then
		Debug("Found Platynator display for", unit, "- kind:", display.kind, "structureType:", structureType, "attempt:", attempt)
		if self:CustomizeHealthBar(display, structureType) then
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
	print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r OnInitialize called")
	-- Check if experiment is enabled
	local db = ns.db
	if not db then
		print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r ERROR: ns.db is nil!")
		return self:Disable()
	end
	if not db.global then
		print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r ERROR: db.global is nil!")
		return self:Disable()
	end
	if not db.global.experiments then
		print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r ERROR: db.global.experiments is nil!")
		return self:Disable()
	end
	local settingValue = db.global.experiments.customizePlatynator
	print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r customizePlatynator =", tostring(settingValue))
	if not settingValue then
		print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r Experiment disabled, stopping")
		return self:Disable()
	end
	print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r Experiment ENABLED!")
	-- Check if Platynator addon is already loaded
	local isPlatynatorLoaded = IsAddOnLoaded("Platynator")
	print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r IsAddOnLoaded('Platynator') =", tostring(isPlatynatorLoaded))
	if isPlatynatorLoaded then
		print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r Platynator already loaded, setting up...")
		self:SetupPlatynator()
	else
		-- Check if it exists but not loaded yet
		local platynatorExists = C_AddOns and C_AddOns.DoesAddOnExist and C_AddOns.DoesAddOnExist("Platynator")
		print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r DoesAddOnExist('Platynator') =", tostring(platynatorExists))
		if platynatorExists then
			print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r Waiting for ADDON_LOADED...")
			self:RegisterEvent("ADDON_LOADED", "OnAddonLoaded")
		else
			print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r Platynator NOT FOUND, disabling")
			return self:Disable()
		end
	end
end
-- Update all existing frames with new size multipliers
Platynator.UpdateAllFrames = function(self)
	local widthMult = GetFrameWidthMult()
	local heightMult = GetFrameHeightMult()
	local widthExtra = GetFrameWidthExtra()
	-- Iterate through cached display frames
	for unit, display in pairs(self.displayFrames) do
		if display.diabolicFrame and display.diabolicOrigSize then
			local origWidth = display.diabolicOrigSize.width
			local origHeight = display.diabolicOrigSize.height
			-- Update frame size
			local frameWidth = origWidth * widthMult + widthExtra
			local frameHeight = origHeight * heightMult
			display.diabolicFrame:SetSize(frameWidth, frameHeight)
			-- Also update healthBar width
			if display.healthBar then
				display.healthBar:SetSize(origWidth + widthExtra, origHeight)
			end
		end
	end
	Debug("Updated all frames: widthMult=" .. widthMult .. " heightMult=" .. heightMult .. " extra=" .. widthExtra)
end
Platynator.OnEnable = function(self)
	-- Listen for size setting changes
	if ns.callbacks and ns.callbacks.RegisterCallback then
		ns.callbacks:RegisterCallback("Platynator_Size_Updated", "UpdateAllFrames", self)
	end
	-- Slash commands disabled for now
	-- SLASH_PLATYNATOR1 = "/platynator"
	-- SLASH_PLATYNATOR2 = "/platy"
	-- SlashCmdList["PLATYNATOR"] = function(msg)
	-- 	local cmd, value = msg:match("^(%S+)%s*(.*)$")
	-- 	if cmd == "w" or cmd == "width" then  -- frame width
	-- 		local num = tonumber(value)
	-- 		if num and num > 0 and num < 3 then
	-- 			GetFrameWidthMult() = num
	-- 			self:UpdateAllFrames()
	-- 		else
	-- 			print("Usage: /platy w 0.75")
	-- 		end
	-- 	elseif cmd == "h" or cmd == "height" then  -- frame height
	-- 		local num = tonumber(value)
	-- 		if num and num > 0 and num < 5 then
	-- 			GetFrameHeightMult() = num
	-- 			self:UpdateAllFrames()
	-- 		else
	-- 			print("Usage: /platy h 1.5")
	-- 		end
	-- 	else
	-- 		print("|cff00ff00DiabolicUI3|r |cffff9900[Platynator]|r Commands:")
	-- 		print("  /platy w <num> - frame width (current: " .. GetFrameWidthMult() .. ")")
	-- 		print("  /platy h <num> - frame height (current: " .. GetFrameHeightMult() .. ")")
	-- 	end
	-- end
end
Platynator.OnDisable = function(self)
	-- Cleanup event frame if it exists
	if self.eventFrame then
		self.eventFrame:UnregisterAllEvents()
		self.eventFrame = nil
	end
	self.processedNameplates = {}
end
