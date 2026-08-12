local Addon, ns = ...
local oUF = ns.oUF
local Events = oUF.Tags.Events
local Methods = oUF.Tags.Methods

-- Lua API
local math_max = math.max
local string_find = string.find

-- WoW API
local UnitBattlePetLevel = UnitBattlePetLevel
local UnitClassification = UnitClassification
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsBattlePetCompanion = UnitIsBattlePetCompanion
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsWildBattlePet = UnitIsWildBattlePet
local UnitLevel = UnitEffectiveLevel or UnitLevel
local UnitName = UnitName
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

-- Addon API
local Colors = ns.Colors
local AbbreviateName = ns.API.AbbreviateName
local AbbreviateNumber = ns.API.AbbreviateNumber
local AbbreviateNumberBalanced = ns.API.AbbreviateNumberBalanced
local GetDifficultyColorByLevel = ns.API.GetDifficultyColorByLevel

-- Colors
local c_gray = Colors.gray.colorCode
local c_normal = Colors.normal.colorCode
local c_rare = Colors.quality.Rare.colorCode
local c_red = Colors.red.colorCode
local r = "|r"

-- WoW 12.0.0: issecretvalue may not exist in older versions
local issecretvalue = issecretvalue or function() return false end

-- WoW 12.1: health and absorb values are secret, which rules out comparing or
-- concatenating them in Lua. These C helpers do both for us: TruncateWhenZero turns a
-- number into text and yields an empty string for zero, and WrapString only glues the
-- prefix and suffix on when the middle part is not empty, so a missing value simply
-- disappears together with its brackets and separators.
local RoundToNearestString = C_StringUtil.RoundToNearestString
local TruncateWhenZero = C_StringUtil.TruncateWhenZero
local WrapString = C_StringUtil.WrapString

-- Strings
local L_DEAD = DEAD
local L_RARE = ITEM_QUALITY3_DESC

-- Textures
local T_BOSS = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:14:14:-2:1|t"

-- Tags
---------------------------------------------------------------------
Events[ns.Prefix..":Absorb"] = "UNIT_ABSORB_AMOUNT_CHANGED"
Methods[ns.Prefix..":Absorb"] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return
	end
	-- UnitGetTotalAbsorbs is flagged SecretReturns, so it is secret at all times and
	-- the old "> 0" test never passed, leaving this tag permanently empty.
	return WrapString(TruncateWhenZero(UnitGetTotalAbsorbs(unit)), c_gray.." ("..r..c_normal, r..c_gray..")"..r)
end

Events[ns.Prefix..":Classification"] = "UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED"
if (oUF.isClassic or oUF.isTBC or oUF.isWrath) then
	Methods[ns.Prefix..":Classification"] = function(unit)
		local l = UnitLevel(unit)
		local c = UnitClassification(unit)
		if (c == "worldboss" or (not l) or (l < 1)) then
			return
		end
		if (c == "elite" or c == "rareelite") then
			return c_red.."+"..r.." "
		end
		return " "
	end
else
	Methods[ns.Prefix..":Classification"] = function(unit)
		local l = UnitLevel(unit)
		if (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
			l = UnitBattlePetLevel(unit)
		end
		local c = UnitClassification(unit)
		if (c == "worldboss" or (not l) or (l < 1)) then
			return
		end
		if (c == "elite" or c == "rareelite") then
			return c_red.."+"..r.." "
		end
		return " "
	end
end

-- Builds "1234567 (73%)" out of two secret numbers. UnitHealth is flagged SecretReturns,
-- so it can never be abbreviated or compared in Lua, and the abbreviated number formatter
-- only works on C driven widgets, not on font strings. The text is assembled in C
-- instead, where WrapString drops a part together with its punctuation if it is empty.
local FormatHealthWithPercent = function(unit)
	local healthText = RoundToNearestString(UnitHealth(unit))
	if (UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100) then
		local ok, pct = pcall(UnitHealthPercent, unit, true, CurveConstants.ScaleTo100)
		if (ok) then
			local percentText = WrapString(RoundToNearestString(pct), c_gray.." ("..r, c_gray.."%)"..r)
			return WrapString(healthText, nil, percentText)
		end
	end
	return healthText
end

Events[ns.Prefix..":Health"] = "UNIT_HEALTH UNIT_MAXHEALTH"
Methods[ns.Prefix..":Health"] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return L_DEAD
	end
	return FormatHealthWithPercent(unit)
end

Events[ns.Prefix..":Health:Full"] = "UNIT_HEALTH UNIT_MAXHEALTH"
Methods[ns.Prefix..":Health:Full"] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return
	end
	-- The old version bailed out to the bare current health, because both values are
	-- secret and could not be concatenated, so the maximum was never shown.
	local maxText = WrapString(RoundToNearestString(UnitHealthMax(unit)), c_gray.."/"..r, nil)
	return WrapString(RoundToNearestString(UnitHealth(unit)), nil, maxText)
end

Events[ns.Prefix..":Health:Smart"] = "UNIT_HEALTH UNIT_MAXHEALTH"
Methods[ns.Prefix..":Health:Smart"] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return L_DEAD
	end
	-- The "number at full health, percentage otherwise" rule needed a comparison
	-- between two secret numbers, which Lua no longer allows, so both are shown.
	return FormatHealthWithPercent(unit)
end

-- WoW 12.0+: UnitHealthPercent + CurveConstants.ScaleTo100 returns scaled 0-100 value.
-- The value may still be secret/curved — must use C_StringUtil.RoundToNearestString
-- (Pattern used by Platynator addon for nameplate HP text in Midnight)
Events[ns.Prefix..":HealthPercent"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_ENTERING_WORLD"
Methods[ns.Prefix..":HealthPercent"] = function(unit)
	if (not unit) then return "" end
	if (not UnitIsConnected(unit)) then
		return PLAYER_OFFLINE or "Offline"
	end
	if (UnitIsDeadOrGhost(unit)) then
		return L_DEAD
	end
	-- Midnight API path: UnitHealthPercent + ScaleTo100 + RoundToNearestString.
	-- UnitHealthPercent is flagged SecretReturns, so the rounded text is a secret
	-- string as well and the percent sign has to be appended in C, not with "..".
	if (UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100) then
		local ok, pct = pcall(UnitHealthPercent, unit, true, CurveConstants.ScaleTo100)
		if (ok) then
			return WrapString(RoundToNearestString(pct), nil, "%")
		end
	end
	-- Fallback: direct calculation if values aren't secret
	local health = UnitHealth(unit)
	local maxHealth = UnitHealthMax(unit)
	if (not issecretvalue(health) and not issecretvalue(maxHealth)
			and maxHealth and maxHealth > 0) then
		local pct = health / maxHealth * 100 + .5
		return (pct - pct % 1) .. "%"
	end
	return ""
end

Events[ns.Prefix..":Level"] = "UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED"
if (oUF.isClassic or oUF.isTBC or oUF.isWrath) then
	Methods[ns.Prefix..":Level"] = function(unit, asPrefix)
		local l = UnitLevel(unit)
		local c = UnitClassification(unit)
		if (c == "worldboss" or (not l) or (l < 1)) then
			return T_BOSS
		end
		local _,_,_,colorCode = GetDifficultyColorByLevel(l)
		if (c == "elite" or c == "rareelite") then
			return colorCode..l..r..c_red.."+"..r
		end
		if (asPrefix) then
			return colorCode..l..r..c_gray..":"..r
		else
			return colorCode..l..r
		end
	end
else
	Methods[ns.Prefix..":Level"] = function(unit, asPrefix)
		local l = UnitLevel(unit)
		if (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
			l = UnitBattlePetLevel(unit)
		end
		local c = UnitClassification(unit)
		if (c == "worldboss" or (not l) or (l < 1)) then
			return T_BOSS
		end
		local _,_,_,colorCode = GetDifficultyColorByLevel(l)
		if (c == "elite" or c == "rareelite") then
			return colorCode..l..r..c_red.."+"..r
		end
		if (asPrefix) then
			return colorCode..l..r..c_gray..":"..r
		else
			return colorCode..l..r
		end
	end
end

Events[ns.Prefix..":Level:Prefix"] = "UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED"
Methods[ns.Prefix..":Level:Prefix"] = function(unit)
	local l = Methods[ns.Prefix..":Level"](unit, true)
	return (l and l ~= T_BOSS) and l.." " or l
end

Events[ns.Prefix..":Name"] = "UNIT_NAME_UPDATE"
Methods[ns.Prefix..":Name"] = function(unit, realUnit)
	-- WoW 12.0: UnitName() returns a secret value for hostile/unseen units in combat
	-- (e.g. focustarget when target is an enemy NPC). string_find on a secret string
	-- raises "attempt to perform string conversion on a secret string value".
	local ok, name = pcall(UnitName, realUnit or unit)
	if (not ok) or (not name) then return end
	-- issecretvalue check: returning a secret string from a tag method would taint the FontString.
	if (issecretvalue and issecretvalue(name)) then return end
	if (string_find(name, "%s")) then
		name = AbbreviateName(name)
	end
	return name
end

Events[ns.Prefix..":Power:Full"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER"
Methods[ns.Prefix..":Power:Full"] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return
	end
	-- Power is secret while restricted, and the old version then fell back to the bare
	-- current value, silently dropping the maximum. Both parts are joined in C instead.
	local maxText = WrapString(RoundToNearestString(UnitPowerMax(unit)), c_gray.."/"..r, nil)
	return WrapString(RoundToNearestString(UnitPower(unit)), nil, maxText)
end

Events[ns.Prefix..":Rare"] = "UNIT_CLASSIFICATION_CHANGED"
Methods[ns.Prefix..":Rare"] = function(unit)
	local classification = UnitClassification(unit)
	local rare = classification == "rare" or classification == "rareelite"
	if (rare) then
		return c_rare.."("..L_RARE..")"..r
	end
end

Events[ns.Prefix..":Rare:Suffix"] = "UNIT_CLASSIFICATION_CHANGED"
Methods[ns.Prefix..":Rare:Suffix"] = function(unit)
	local r = Methods[ns.Prefix..":Rare"](unit)
	return r and " "..r
end
