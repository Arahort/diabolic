local Addon, ns = ...
-- This file is only loaded in Retail (see TOC)
if (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE) then
	return
end
ns.AuraFilters = ns.AuraFilters or {}

-- WoW 12.1: aura data is secret, so an addon can no longer decide per aura whether
-- to show it. Filtering happens inside the AuraContainer, driven by a filter string
-- and an optional set of candidate filters, both of which are declared up front.
--
-- Filter string components (combine with "|", negate with "!"):
--   HELPFUL, HARMFUL, PLAYER, RAID, CANCELABLE, DISPELLABLE, CROWD_CONTROL,
--   BIG_DEFENSIVE, EXTERNAL_DEFENSIVE, IMPORTANT, RAID_IN_COMBAT,
--   RAID_PLAYER_DISPELLABLE, INCLUDE_NAME_PLATE_ONLY, MAW
--
-- Candidate filter keys the container understands:
--   includeSpellIDs, excludeSpellIDs, includeDispelTypes, excludeDispelTypes,
--   maxDuration, canApplyAura, isBossAura, isBossOrRoleAura, isRoleAura,
--   isPriorityAura, isStealable, isFromPlayerOrPlayerPet, processedAuraType,
--   nameplateShowAll, nameplateShowPersonal

-- Player buffs and debuffs cast by the player, shown in full color.
ns.AuraFilters.PlayerBuffs = "HELPFUL"
ns.AuraFilters.PlayerDebuffs = "HARMFUL"

-- Buffs and debuffs on another unit, split by who cast them. The player's own
-- auras are listed first and stay colored, everything else is dimmed.
ns.AuraFilters.OwnBuffs = "HELPFUL|PLAYER"
ns.AuraFilters.OwnDebuffs = "HARMFUL|PLAYER"
ns.AuraFilters.ForeignBuffs = "HELPFUL|!PLAYER"
ns.AuraFilters.ForeignDebuffs = "HARMFUL|!PLAYER"

-- The old player buff filter kept short lived buffs and hid the permanent ones.
-- maxDuration reproduces it, and permanent auras are implicitly excluded.
ns.AuraFilters.ShortBuffCandidates = { maxDuration = 300 }

-- Nameplates used to show boss auras, stealable buffs and short player auras.
-- Those are three separate groups now, each with its own candidate filter.
ns.AuraFilters.BossAuraCandidates = { isBossOrRoleAura = true }
ns.AuraFilters.StealableCandidates = { isStealable = true }
ns.AuraFilters.ShortDebuffCandidates = { maxDuration = 60 }
