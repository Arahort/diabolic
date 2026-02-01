local Addon, ns = ...
-- This file is only loaded in Classic (NOT in Retail)
if (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) then
	return
end
ns.AuraFilters = ns.AuraFilters or {}

ns.AuraFilters.PlayerBuffFilter = function(element, unit, button, name, texture,
	count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
	canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)

	--button.unitIsCaster = unit and caster and UnitIsUnit(unit, caster)
	button.spell = name
	button.timeLeft = expiration and (expiration - GetTime())
	button.expiration = expiration
	button.duration = duration
	button.noDuration = (not duration or duration == 0)
	button.isPlayer = caster == "player" or caster == "vehicle"

	if (isBossDebuff) then
		return true
	end

	return (not button.noDuration and duration < 301) or (button.timeLeft and button.timeLeft > 0 and button.timeLeft < 31) or (count > 1)
end

ns.AuraFilters.PlayerDebuffFilter = function(element, unit, button, name, texture,
	count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
	canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)

	--button.unitIsCaster = unit and caster and UnitIsUnit(unit, caster)
	button.spell = name
	button.timeLeft = expiration and (expiration - GetTime())
	button.expiration = expiration
	button.duration = duration
	button.noDuration = (not duration or duration == 0)
	button.isPlayer = caster == "player" or caster == "vehicle"

	if (isBossDebuff) then
		return true
	end

	return true
end

ns.AuraFilters.TargetAuraFilter = function(element, unit, button, name, texture,
	count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
	canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)

	--button.unitIsCaster = unit and caster and UnitIsUnit(unit, caster)
	button.spell = name
	button.timeLeft = expiration and (expiration - GetTime())
	button.expiration = expiration
	button.duration = duration
	button.noDuration = (not duration or duration == 0)
	button.isPlayer = caster == "player" or caster == "vehicle"

	if (isBossDebuff) then
		return true
	end

	return (not button.noDuration and duration < 301) or (count > 1)
end

ns.AuraFilters.NameplateAuraFilter = function(element, unit, button, name, texture,
	count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
	canApply, isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod, effect1, effect2, effect3)

	button.spell = name
	button.timeLeft = expiration and (expiration - GetTime())
	button.expiration = expiration
	button.duration = duration
	button.noDuration = (not duration or duration == 0)
	button.isPlayer = caster == "player" or caster == "vehicle"

	if (isBossDebuff) then
		return true
	elseif (isStealable) then
		return true
	elseif (caster == "player" or caster == "pet" or caster == "vehicle") then
		if (button.isDebuff) then
			return (not button.noDuration and duration < 301) -- Faerie Fire is 5 mins
		else
			return (not button.noDuration and duration < 31) -- show short buffs, like HoTs
		end
	end
end
