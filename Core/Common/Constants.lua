local Addon, ns = ...

-- Addon version
------------------------------------------------------
-- Keyword substitution requires the packager,
-- and does not affect direct GitHub repo pulls.
local version = "3.0.0"
if (version:find("project%-version")) then
	version = "Development"
end
ns.Private.Version = version
ns.Private.IsDevelopment = version == "Development"
ns.Private.IsAlpha = string.find(version, "%-Alpha$")
ns.Private.IsBeta = string.find(version, "%-Beta$")
ns.Private.IsRC = string.find(version, "%-RC$")
ns.Private.IsRelease = string.find(version, "%-Release$")

-- WoW client version
------------------------------------------------------
local patch, build, date, version = GetBuildInfo()
local major, minor = string.split(".", patch)

ns.Private.ClientVersion = version
ns.Private.ClientDate = date
ns.Private.ClientPatch = patch
ns.Private.ClientMajor = tonumber(major)
ns.Private.ClientMinor = tonumber(minor)
ns.Private.ClientBuild = tonumber(build)

-- Simple flags for client version checks
ns.IsRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
ns.Private.IsClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
ns.Private.IsTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
ns.Private.IsWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
ns.Private.WoW10 = version >= 100000

-- Prefix for frame names
------------------------------------------------------
ns.Private.Prefix = string.gsub(Addon, "UI(%d*)", "")

-- Player constants
------------------------------------------------------
local _,playerClass = UnitClass("player")
ns.Private.PlayerClass = playerClass
ns.Private.PlayerRealm = GetRealmName()
ns.Private.PlayerName = UnitNameUnmodified("player")

-- Scaling Constants
------------------------------------------------------
ns.UIScale = 0.6
ns.Private.UIDefaultScale = 0.6

-- Create aliases for backward compatibility
------------------------------------------------------
-- Use rawset to bypass metatable protection
rawset(ns, "IsRetail", ns.Private.IsRetail)
rawset(ns, "IsClassic", ns.Private.IsClassic)
rawset(ns, "IsTBC", ns.Private.IsTBC)
rawset(ns, "IsWrath", ns.Private.IsWrath)
rawset(ns, "WoW10", ns.Private.WoW10)
rawset(ns, "Prefix", ns.Private.Prefix)
rawset(ns, "PlayerClass", ns.Private.PlayerClass)
rawset(ns, "PlayerRealm", ns.Private.PlayerRealm)
rawset(ns, "PlayerName", ns.Private.PlayerName)
