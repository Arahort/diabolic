local Addon, ns = ...
local oUF = ns.oUF
local API = ns.API

-- WoW API
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitGUID = UnitGUID
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsConnected = UnitIsConnected
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
-- WoW 12.0.0: New percentage APIs to bypass secret values
local UnitHealthPercent = UnitHealthPercent
local UnitPowerPercent = UnitPowerPercent
local CurveConstants = CurveConstants
local issecretvalue = issecretvalue or function() return false end

API.UpdateHealth = function(self, event, unit)
	if (not unit or self.unit ~= unit) then return end
	local element = self.Health
	--[[ Callback: Health:PreUpdate(unit)
	Called before the element has been updated.

	* self - the Health element
	* unit - the unit for which the update has been triggered (string)
	--]]
	if (element.PreUpdate) then
		element:PreUpdate(unit)
	end

	local absorb
	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	local connected = UnitIsConnected(unit)

	-- Different GUID means a different player or NPC,
	-- so we want updates to be instant, not smoothed.
	local forced = (event == "ForceUpdate") or (event == "RefreshUnit") or (event == "GROUP_ROSTER_UPDATE")
	if (not forced) then
		local guid = UnitGUID(unit)
		-- WoW 12.0.0: GUID can be secret value, skip comparison if secret
		if not issecretvalue(guid) and not issecretvalue(element.guid) then
			if (guid ~= element.guid) then
				forced = true
				element.guid = guid
			end
		end
	end

	-- WoW 12.0.0: Use percentage API to bypass secret values
	-- Fixed 0-100 range instead of dynamic 0-max
	element:SetMinMaxValues(0, 100, forced)
	if (connected) then
		-- Use UnitHealthPercent which returns 0-100 percentage (not secret!)
		local percent = UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)
		element:SetValue(percent, forced)
	else
		element:SetValue(100, true)
	end

	element.cur = cur
	element.max = max

	local preview = element.Preview
	if (preview) then
		preview:SetMinMaxValues(0, 100, true)
		if connected then
			local percent = UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)
			preview:SetValue(percent, true)
		else
			preview:SetValue(100, true)
		end
	end

	--[[ Callback: Health:PostUpdate(unit, cur, max)
	Called after the element has been updated.

	* self - the Health element
	* unit - the unit for which the update has been triggered (string)
	* cur  - the unit's current health value (number)
	* max  - the unit's maximum possible health value (number)
	--]]
	if (element.PostUpdate) then
		element:PostUpdate(unit, cur, max)
	end
end

API.UpdatePower = function(self, event, unit)
	if(self.unit ~= unit) then return end
	local element = self.Power

	--[[ Callback: Power:PreUpdate(unit)
	Called before the element has been updated.

	* self - the Power element
	* unit - the unit for which the update has been triggered (string)
	--]]
	if (element.PreUpdate) then
		element:PreUpdate(unit)
	end

	-- Different GUID means a different player or NPC,
	-- so we want updates to be instant, not smoothed.
	local guid = UnitGUID(unit)
	local forced = (guid ~= element.guid) or (UnitIsDeadOrGhost(unit))
	element.guid = guid

	-- Показываем основной ресурс игрока (для друида - Lunar Power, не мана)
	-- Используем UnitPower без параметра, как в теге Power:Full
	local displayType, min = nil, 0
	local cur, max = UnitPower(unit), UnitPowerMax(unit)
	-- WoW 12.0.0: Use percentage API to bypass secret values
	-- Fixed 0-100 range instead of dynamic 0-max
	element:SetMinMaxValues(0, 100)
	if (UnitIsConnected(unit)) then
		-- Use UnitPowerPercent which returns 0-100 percentage (not secret!)
		local percent = UnitPowerPercent(unit, nil, true, CurveConstants.ScaleTo100)
		element:SetValue(percent, forced)
	else
		element:SetValue(100, forced)
	end

	element.cur = cur
	element.min = min
	element.max = max
	element.displayType = displayType

	--[[ Callback: Power:PostUpdate(unit, cur, min, max)
	Called after the element has been updated.

	* self - the Power element
	* unit - the unit for which the update has been triggered (string)
	* cur  - the unit's current power value (number)
	* min  - the unit's minimum possible power value (number)
	* max  - the unit's maximum possible power value (number)
	--]]
	if (element.PostUpdate) then
		element:PostUpdate(unit, cur, min, max)
	end
end
