local Addon, ns = ...
local API = ns.API or {}
ns.API = API

local PLAYER_NAME = UnitName("player")

local GetAddOnInfo = function(index)
	local name, title, notes, loadable, reason, security, newVersion = C_AddOns.GetAddOnInfo(index)
	local enabled = not(C_AddOns.GetAddOnEnableState(index, PLAYER_NAME) == 0) 
	return name, title, notes, enabled, loadable, reason, security
end

-- Check if an addon exists	in the addon listing
local IsAddOnAvailable = function(target)
	local target = string.lower(target)
	for i = 1, C_AddOns.GetNumAddOns() do
		local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(i)
		if (string.lower(name) == target) then
			return true
		end
	end
end

-- Check if an addon is enabled	in the addon listing
-- *Making this available as a generic library method.
local IsAddOnEnabled = function(target)
	local target = string.lower(target)
	for i = 1, C_AddOns.GetNumAddOns() do
		local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(i)
		if (string.lower(name) == target) then
			if (enabled and loadable) then
				return true
			end
		end
	end
end

-- Check if an addon exists in the addon listing and loadable on demand
local IsAddOnLoadable = function(target, ignoreLoD)
	local target = string.lower(target)
	for i = 1, C_AddOns.GetNumAddOns() do
		local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(i)
		if (string.lower(name) == target) then
			if (loadable or ignoreLoD) then
				return true
			end
		end
	end
end

-- Global API
---------------------------------------------------------
API.GetAddOnInfo = GetAddOnInfo
API.IsAddOnLoadable = IsAddOnLoadable
API.IsAddOnEnabled = IsAddOnEnabled
API.IsAddOnAvailable = IsAddOnAvailable
