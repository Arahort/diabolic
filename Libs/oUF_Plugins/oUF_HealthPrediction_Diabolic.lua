--[[
Custom Health Prediction element for DiabolicUI3
Maintains compatibility with old oUF PostUpdate signature while using new 12.0.0 APIs

Based on oUF HealthPrediction element but adapted for DiabolicUI3's custom texture-based prediction display.
This version uses the new Calculator API from WoW 12.0.0 which handles secret values properly.

Author: Arahort
]]--

local _, ns = ...
local oUF = ns.oUF or oUF
if not oUF then return end

-- This override replaces the standard oUF HealthPrediction.Override function
-- It maintains the old PostUpdate signature that DiabolicUI3 expects
local function Update(self, event, unit)
	if(self.unit ~= unit) then return end

	local element = self.HealthPrediction
	if not element then return end

	--[[ Callback: HealthPrediction:PreUpdate(unit)
	Called before the element has been updated.
	]]--
	if(element.PreUpdate) then
		element:PreUpdate(unit)
	end

	local health = UnitHealth(unit)
	local maxHealth = UnitHealthMax(unit)

	-- Initialize calculator if it doesn't exist yet
	if not element.calculator then
		element.calculator = CreateUnitHealPredictionCalculator()
	end

	-- Update calculator with current unit data
	-- This handles secret values internally and returns safe values
	UnitGetDetailedHealPrediction(unit, 'player', element.calculator)

	-- Get prediction values from calculator
	-- These are NOT secret values - safe to use in calculations
	local allIncomingHeal, myIncomingHeal, otherIncomingHeal = element.calculator:GetIncomingHeals()
	local absorb = element.calculator:GetDamageAbsorbs()
	local healAbsorb, hasOverHealAbsorb = element.calculator:GetHealAbsorbs()

	-- Provide defaults if values are nil
	myIncomingHeal = myIncomingHeal or 0
	otherIncomingHeal = otherIncomingHeal or 0
	allIncomingHeal = allIncomingHeal or 0
	absorb = absorb or 0
	healAbsorb = healAbsorb or 0

	-- Calculate hasOverAbsorb (not provided by calculator)
	local hasOverAbsorb = false
	if absorb > 0 and health and maxHealth then
		-- Check if absorb would exceed max health
		-- We can do this calculation because calculator returns non-secret values
		if health + allIncomingHeal + absorb >= maxHealth then
			hasOverAbsorb = true
		end
	end

	--[[ Callback: HealthPrediction:PostUpdate(unit, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, hasOverAbsorb, hasOverHealAbsorb, curHealth, maxHealth)
	Called after the element has been updated.

	DiabolicUI3 custom signature includes curHealth and maxHealth at the end.

	* self              - the HealthPrediction element
	* unit              - the unit for which the update has been triggered (string)
	* myIncomingHeal    - the amount of incoming healing done by the player (number)
	* otherIncomingHeal - the amount of incoming healing done by others (number)
	* absorb            - the amount of damage the unit can absorb without losing health (number)
	* healAbsorb        - the amount of healing the unit can absorb without gaining health (number)
	* hasOverAbsorb     - indicates if the amount of damage absorb is higher than the unit's missing health (boolean)
	* hasOverHealAbsorb - indicates if the amount of heal absorb is higher than the unit's current health (boolean)
	* curHealth         - current health value (may be secret value!)
	* maxHealth         - maximum health value (may be secret value!)
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(unit, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, hasOverAbsorb, hasOverHealAbsorb, health, maxHealth)
	end
end

-- Export the Update function so it can be used as an Override
ns.HealthPrediction_Update_Diabolic = Update
