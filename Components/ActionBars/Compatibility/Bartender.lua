local Addon, ns = ...
if (not ns.API.IsAddOnEnabled("Bartender4")) then return end

local ActionBars = ns:GetModule("ActionBars")
local Bartender = ActionBars:NewModule("Bartender", "LibMoreEvents-1.0")

-- WoW API
local InCombatLockdown = InCombatLockdown
local UnregisterStateDriver = UnregisterStateDriver

-- Addon API
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local UIHider = ns.Hider
local noop = ns.Noop

-- Disable and unhook Bartender's micro menu module
-- as this directly conflicts with our own.
Bartender.HandleMicroMenu = function(self)
	local MicroMenuMod = Bartender4:GetModule("MicroMenu")
	if (not MicroMenuMod) then
		return
	end
	MicroMenuMod:Disable()
	MicroMenuMod:UnhookAll()
end

-- Prevent Bartender from transferring keybinds
-- to the blizzard default bars when entering petbattle,
-- as we're doing this already.
Bartender.HandlePetBattles = function(self)
	if (Bartender4.petBattleController) then
		UnregisterStateDriver(Bartender4.petBattleController, "petbattle")
		Bartender4.petBattleController:Execute([[ self:ClearBindings(); ]])
	end
	Bartender4.RegisterPetBattleDriver = noop
end

-- Prevent Bartender from transferring keybinds
-- to the blizzard default bars when entering vehicles,
-- as this will prevent our own bars from functioning.
Bartender.HandleVehicle = function(self)
	if (Bartender4.vehicleController) then
		OverrideActionBar:UnregisterAllEvents()
		OverrideActionBar:Hide()
		OverrideActionBar:SetParent(UIHider)
		UnregisterStateDriver(Bartender4.vehicleController, "vehicle")
		Bartender4.vehicleController:Execute([[ self:ClearBindings(); ]])
	end
	Bartender4.UpdateBlizzardVehicle = noop
end

Bartender.HandleBartender = function(self, event, addon)
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "HandleBartender")

	elseif (event == "ADDON_LOADED") then
		if (addon ~= "Bartender4") then return end
		self:UnregisterEvent("ADDON_LOADED", "HandleBartender")

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (InCombatLockdown()) then return end
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "HandleBartender")
	end

	self:HandleMicroMenu()
	self:HandlePetBattles()
	self:HandleVehicle()

	ns.BartenderHandled = true
	ns:Fire("Bartender_Handled")
end

Bartender.OnInitialize = function(self)
	if (IsAddOnLoaded("Bartender4")) then
		self:HandleBartender()
	else
		self:RegisterEvent("ADDON_LOADED", "HandleBartender")
	end
end
