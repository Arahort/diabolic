--[[

	The MIT License (MIT)

	Copyright (c) 2022 Lars Norberg

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

--]]
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
	local button = {}
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

	-- WoW 12.0.0: In combat, duration/applications may be secret
	if issecretvalue(data.duration) or issecretvalue(data.applications) then
		-- Can't check exact values, but can show if it has expiration (temporary aura)
		-- NOTE: Target uses secure buttons, so updates will be deferred until combat ends
		return data.expirationTime ~= nil
	end

	-- Out of combat - show: (duration < 301) OR (stacks > 1)
	return (not button.noDuration and data.duration < 301) or (data.applications > 1)
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
