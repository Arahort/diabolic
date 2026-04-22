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
	else
		local absorb = UnitGetTotalAbsorbs(unit) or 0
		-- WoW 12.0.0: Skip operations if absorb is secret value
		if not issecretvalue(absorb) then
			if (absorb > 0) then
				return c_gray.." ("..r..c_normal..absorb..r..c_gray..")"..r
			end
		end
	end
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

Events[ns.Prefix..":Health"] = "UNIT_HEALTH UNIT_MAXHEALTH"
Methods[ns.Prefix..":Health"] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return L_DEAD
	else
		local health = UnitHealth(unit)
		-- WoW 12.0.0: Can't compare secret values, but can pass to functions
		if issecretvalue(health) then
			return health -- Return secret value directly, SetText can display it
		end
		if (health and health > 0) then
			return AbbreviateNumber(health)
		end
	end
end

Events[ns.Prefix..":Health:Full"] = "UNIT_HEALTH UNIT_MAXHEALTH"
Methods[ns.Prefix..":Health:Full"] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return
	else
		local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
		-- WoW 12.0.0: Can't concatenate secret values, return as is
		if issecretvalue(health) or issecretvalue(maxHealth) then
			return health -- Return current health, can't format with secret values
		end
		if (maxHealth and maxHealth > 0) then
			return health..c_gray.."/"..r..maxHealth
		end
	end
end

Events[ns.Prefix..":Health:Smart"] = "UNIT_HEALTH UNIT_MAXHEALTH"
Methods[ns.Prefix..":Health:Smart"] = function(unit)
	if (UnitIsDeadOrGhost(unit)) then
		return L_DEAD
	else
		local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
		-- WoW 12.0.0: Can't do math with secret values, return as is
		if issecretvalue(health) or issecretvalue(maxHealth) then
			return health -- Return current health, can't calculate percentage
		end
		if (maxHealth and maxHealth > 0) then
			if (health == maxHealth) then
				return AbbreviateNumber(health)
			else
				local displayValue = health / maxHealth * 100 + .5
				return displayValue - displayValue%1
			end
		end
	end
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
	-- Midnight API path: UnitHealthPercent + ScaleTo100 + RoundToNearestString
	if (UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100
			and C_StringUtil and C_StringUtil.RoundToNearestString) then
		local ok, pct = pcall(UnitHealthPercent, unit, true, CurveConstants.ScaleTo100)
		if (ok and pct) then
			return C_StringUtil.RoundToNearestString(pct) .. "%"
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
	else
		local current, total = UnitPower(unit), UnitPowerMax(unit)
		-- WoW 12.0.0: Can't concatenate secret values, return as is
		if issecretvalue(current) or issecretvalue(total) then
			return current -- Return current power, can't format with secret values
		end
		if (total and total > 0) then
			return current..c_gray.."/"..r..total
		end
	end
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
