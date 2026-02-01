local Addon, ns = ...
ns.AuraSorts = ns.AuraSorts or {}

-- Lua API
local math_huge = math.huge
local table_sort = table.sort

-- https://wowpedia.fandom.com/wiki/API_C_UnitAuras.GetAuraDataByAuraInstanceID
local Aura_Sort = function(a, b)

	-- Player first, includes procs and zone buffs.
	if (a.isPlayerAura ~= b.isPlayerAura) then
		return a.isPlayerAura
	end

	-- Player first, those we can apply.
	if (a.canApplyAura ~= b.canApplyAura) then
		return a.canApplyAura
	end

	-- No duration last, short times first.
	local aTime = (not a.duration or a.duration == 0) and math_huge or a.expirationTime or -1
	local bTime = (not b.duration or b.duration == 0) and math_huge or b.expirationTime or -1

	if (aTime ~= bTime) then
		return aTime < bTime
	end

	return a.auraInstanceID < b.auraInstanceID
end

local Aura_Sort_Classic = function(a, b)
	if (a and b) then
		if (a.IsShown and b.IsShown and a:IsShown() and b:IsShown()) then

			-- These flags are supplied by the aura filters
			local aPlayer = a.isPlayer or false
			local bPlayer = b.isPlayer or false

			if (aPlayer == bPlayer) then

				local aTime = a.noDuration and math_huge or a.expiration or -1
				local bTime = b.noDuration and math_huge or b.expiration or -1
				if (aTime == bTime) then

					local aName = a.spell or ""
					local bName = b.spell or ""
					if (aName and bName) then
						local sortDirection = a:GetParent().sortDirection
						if (sortDirection == "DESCENDING") then
							return (aName < bName)
						else
							return (aName > bName)
						end
					end

				elseif (aTime and bTime) then
					local sortDirection = a:GetParent().sortDirection
					if (sortDirection == "DESCENDING") then
						return (aTime < bTime)
					else
						return (aTime > bTime)
					end
				else
					return (aTime) and true or false
				end

			else
				local sortDirection = a:GetParent().sortDirection
				if (sortDirection == "DESCENDING") then
					return (not aPlayer and bPlayer)
				else
					return (aPlayer and not bPlayer)
				end
			end
		else
			return (a.IsShown and a:IsShown())
		end
	end
end

ns.AuraSorts.DefaultFunction = ns.IsRetail and Aura_Sort or Aura_Sort_Classic
ns.AuraSorts.Default = function(element, max)
	table_sort(element, ns.AuraSorts.DefaultFunction)
	return 1, #element
end
