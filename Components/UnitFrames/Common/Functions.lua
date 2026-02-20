local Addon, ns = ...
local oUF = ns.oUF
local API = ns.API

-- WoW API
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitGUID = UnitGUID
local UnitIsConnected = UnitIsConnected
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitIsUnit = UnitIsUnit

-- WoW 12.0.1: Check for secret values
local issecretvalue = issecretvalue or function() return false end

-- WoW 12.0.1: Custom UpdateHealth using calculator API
-- Note: oUF Enable already creates element.values calculator
API.UpdateHealth = function(self, event, unit)
	if (not unit or self.unit ~= unit) then return end
	local element = self.Health
	if (element.PreUpdate) then
		element:PreUpdate(unit)
	end
	-- WoW 12.0.1: Use calculator created by oUF Enable
	-- Fallback: create one if not exists (shouldn't happen normally)
	local calculator = element.values
	if (not calculator) then
		calculator = CreateUnitHealPredictionCalculator()
		element.values = calculator
	end
	-- Fill calculator with current unit data
	UnitGetDetailedHealPrediction(unit, 'player', calculator)
	-- Get values from calculator (should be regular numbers, not secret)
	local cur = calculator:GetCurrentHealth()
	local max = calculator:GetMaximumHealth()
	-- Safety check: skip if values are somehow still secret
	if issecretvalue(cur) or issecretvalue(max) then
		-- Fallback: show full bar for connected, empty for disconnected
		if UnitIsConnected(unit) then
			element:SetMinMaxValues(0, 1, true)
			element:SetValue(1, true)
		else
			element:SetMinMaxValues(0, 1, true)
			element:SetValue(0, true)
		end
		return
	end
	local connected = UnitIsConnected(unit)
	-- Different GUID means a different player or NPC,
	-- so we want updates to be instant, not smoothed.
	local forced = (event == "ForceUpdate") or (event == "RefreshUnit") or (event == "GROUP_ROSTER_UPDATE")
	if (not forced) then
		local guid = UnitGUID(unit)
		if (guid ~= element.guid) then
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

-- WoW 12.0.1: Power - skip update for units with secret values
API.UpdatePower = function(self, event, unit)
	if(self.unit ~= unit) then return end
	local element = self.Power
	if (element.PreUpdate) then
		element:PreUpdate(unit)
	end
	local guid = UnitGUID(unit)
	local forced = (guid ~= element.guid) or (UnitIsDeadOrGhost(unit))
	element.guid = guid
	local displayType, min = nil, 0
	local cur, max = UnitPower(unit), UnitPowerMax(unit)
	-- WoW 12.0.1: Skip update if values are secret (non-player units)
	if issecretvalue(cur) or issecretvalue(max) then
		return
	end
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
