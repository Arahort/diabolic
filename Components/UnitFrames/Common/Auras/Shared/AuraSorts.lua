local Addon, ns = ...
ns.AuraSorts = ns.AuraSorts or {}

-- WoW 12.1: aura data is secret, so auras can no longer be sorted by a Lua comparator.
-- Sorting is picked from the methods the AuraContainer implements internally.
--
-- The old comparator put player cast auras first and then ordered by remaining time.
-- The first half is now expressed by group order (a PLAYER filtered group is added
-- before the rest), the second half maps onto the expiration sort below.
ns.AuraSorts.Default = AuraContainerSortMethod.Expiration
ns.AuraSorts.DefaultDirection = AuraContainerSortDirection.Normal

-- Ordering for debuffs on unit frames: boss and dispellable auras bubble up first.
ns.AuraSorts.UnitFrameDebuff = AuraContainerSortMethod.UnitFrameDebuff
