local Addon, ns = ...
-- This file is only loaded in Retail (see TOC)
if (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE) then
	return
end
ns.AuraFilters = ns.AuraFilters or {}
-- WoW 12.0.0: issecretvalue may not exist in older versions
local issecretvalue = issecretvalue or function() return false end

ns.AuraFilters.PlayerBuffFilter = function(element, unit, data)
	local button = {}
	--button.unitIsCaster = unit and caster and UnitIsUnit(unit, caster)
	button.spell = data.name
	-- WoW 12.0.0: Use expirationTime and protect from secret values
	button.timeLeft = data.expirationTime and not issecretvalue(data.expirationTime) and (data.expirationTime - GetTime()) or nil
	button.expiration = data.expirationTime
	button.duration = data.duration
	-- WoW 12.0.0: Skip comparison if duration is secret value
	button.noDuration = (not data.duration or (not issecretvalue(data.duration) and data.duration == 0))
	button.isPlayer = data.isPlayerAura

	if (data.isBossDebuff) then
		return true
	end

	-- WoW 12.0.0: Original filter but without stack count condition
	-- Show buffs with duration < 301 seconds OR short remaining time
	-- Removed: or (data.applications > 1) - don't show stackable buffs without timer
	if issecretvalue(data.duration) then
		-- In combat - can't check exact duration
		-- Show if it has expiration (temporary buff with timer)
		return data.expirationTime ~= nil
	end

	-- Out of combat - original filter without stack count
	return (not button.noDuration and data.duration < 301) or (button.timeLeft and button.timeLeft > 0 and button.timeLeft < 31)
end

ns.AuraFilters.PlayerDebuffFilter = function(element, unit, data)
	return true
end

ns.AuraFilters.TargetAuraFilter = function(element, unit, data)
	-- WoW 12.0.0: isHarmful - use isHarmfulAura as safe fallback (always available)
	local isHarmful = data.isHarmfulAura or false
	if not issecretvalue(data.isHarmful) and data.isHarmful then
		isHarmful = data.isHarmful
	end
	-- Filter: Show only my debuffs on target (if enabled)
	if isHarmful then
		local db = ns.db
		if db and db.char and db.char.unitframes and db.char.unitframes.showOnlyMyDebuffs then
			-- Use C_UnitAuras.IsAuraFilteredOutByInstanceID - works in combat!
			-- Returns true if aura would be filtered out by "HARMFUL|PLAYER"
			if C_UnitAuras.IsAuraFilteredOutByInstanceID and data.auraInstanceID then
				local isFilteredOut = C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, data.auraInstanceID, "HARMFUL|PLAYER")
				if isFilteredOut then
					return false -- Not from player
				end
			end
		end
	end
	-- Show all auras
	return true
end

ns.AuraFilters.NameplateAuraFilter = function(element, unit, data)
	local button = {}
	button.spell = data.name
	-- WoW 12.0.0: Use expirationTime and protect from secret values
	button.timeLeft = data.expirationTime and not issecretvalue(data.expirationTime) and (data.expirationTime - GetTime()) or nil
	button.expiration = data.expirationTime
	button.duration = data.duration
	-- WoW 12.0.0: Skip comparison if duration is secret value
	button.noDuration = (not data.duration or (not issecretvalue(data.duration) and data.duration == 0))
	button.isPlayer = data.isPlayerAura
	button.isDebuff = data.isHarmful

	if (data.isBossDebuff) then
		return true
	elseif (data.isStealable) then
		return true
	elseif (data.nameplateShowAll) then
		return true
	elseif (data.nameplateShowSelf and button.isPlayer) then
		return true
	elseif (button.isPlayer) then
		-- WoW 12.0.0: In combat, duration/applications may be secret
		if issecretvalue(data.duration) or issecretvalue(data.applications) then
			-- Can't check exact values, but can show if it has expiration (temporary aura)
			return data.expirationTime ~= nil
		end
		if (button.isDebuff) then
			return (not button.noDuration and data.duration < 61) or (data.applications > 1)
		else
			return (not button.noDuration and data.duration < 31) or (data.applications > 1)
		end
	end
end
