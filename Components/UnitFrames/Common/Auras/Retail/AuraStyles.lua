local Addon, ns = ...
if (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE) then
	return
end
ns.AuraStyles = ns.AuraStyles or {}

-- WoW 12.1: the per aura post update hooks that used to live here are gone.
-- They read the aura payload (isHarmful, dispelName, isStealable, isPlayerAura,
-- applications) to recolor the border, dim foreign auras and write the stack text,
-- and none of that data is readable from Lua anymore.
--
-- Each of those jobs now has a home in the container instead:
--   dimming foreign auras - a separate group filtered on "!PLAYER",
--                           see ns.AuraStyles.PostCreateForeignButton
--   stack text            - button:SetApplicationCount()
--   dispel type           - button:AddDispelTypeTexture()
--   border color          - fixed per group through the borderColor option
--
-- See Shared\AuraStyles.lua for the button style and Retail\AuraFilters.lua for
-- the group filters.
