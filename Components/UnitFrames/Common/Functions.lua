local Addon, ns = ...
local oUF = ns.oUF
local API = ns.API

-- WoW API
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitGUID = UnitGUID
local UnitIsConnected = UnitIsConnected
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

-- Simple UpdateHealth - direct API for all units
API.UpdateHealth = function(self, event, unit)
	if (not unit or self.__unit ~= unit) then return end
	local element = self.Health
	if (element.PreUpdate) then
		element:PreUpdate(unit)
	end
	-- Direct API - let's see real error
	local cur = UnitHealth(unit)
	local max = UnitHealthMax(unit)
	local connected = UnitIsConnected(unit)
	-- Different GUID means a different player or NPC,
	-- so we want updates to be instant, not smoothed.
	local forced = (event == "ForceUpdate") or (event == "RefreshUnit") or (event == "GROUP_ROSTER_UPDATE")
	if (not forced) then
		local guid = UnitGUID(unit)
		-- WoW 12.0: Use pcall for guid comparison to handle secret/tainted values
		local guidChanged = false
		if guid then
			local success, result = pcall(function() return guid ~= element.guid end)
			guidChanged = success and result
		end
		if guidChanged or (guid and not element.guid) then
			forced = true
			element.guid = guid
		end
	end
	element:SetMinMaxValues(0, max, forced)
	if (connected) then
		element:SetValue(cur, forced)
	else
		element:SetValue(max, true)
	end
	element.cur = cur
	element.max = max
	local preview = element.Preview
	if (preview) then
		preview:SetMinMaxValues(0, max, true)
		if connected then
			preview:SetValue(cur, true)
		else
			preview:SetValue(max, true)
		end
	end
	if (element.PostUpdate) then
		element:PostUpdate(unit, cur, max)
	end
end

-- WoW 12.0.1: Power update - native StatusBar handles secret values
API.UpdatePower = function(self, event, unit)
	if(self.__unit ~= unit) then return end
	local element = self.Power
	if (element.PreUpdate) then
		element:PreUpdate(unit)
	end
	local guid = UnitGUID(unit)
	-- WoW 12.0: Use pcall for guid comparison to handle secret/tainted values
	local guidChanged = false
	if guid then
		local success, result = pcall(function() return guid ~= element.guid end)
		guidChanged = success and result
	end
	local forced = guidChanged or (guid and not element.guid) or (UnitIsDeadOrGhost(unit))
	element.guid = guid
	local displayType, min = nil, 0
	local cur, max = UnitPower(unit), UnitPowerMax(unit)
	element:SetMinMaxValues(0, max)
	if (UnitIsConnected(unit)) then
		element:SetValue(cur, forced)
	else
		element:SetValue(max, forced)
	end
	element.cur = cur
	element.min = min
	element.max = max
	element.displayType = displayType
	if (element.PostUpdate) then
		element:PostUpdate(unit, cur, min, max)
	end
end
