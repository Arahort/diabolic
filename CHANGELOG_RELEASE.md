# DiabolicUI3 - Release Notes

## New Features
- **Threat Indicator setting for Target Frame** - Toggle threat-based HP coloring (green/yellow/red) on/off
- **Improved "Hide target name on cast" setting** - Now also hides cast bar, cast time, and spell text

## Fixes
- **EditMode position saving** - Minimap, TalkingHead, and ExtraButtons now properly save positions when EditMode closes
- **Pet Bar duplication fixed** - Completely reworked Blizzard pet bar hiding system using safe methods
- **Multiple ADDON_ACTION_BLOCKED errors fixed** - Added InCombatLockdown() protection for auras/buffs operations
- **Action bar toggle** - Now works as proper toggle (left click shows/hides all 3 extra bars)
- **HealPredict nil comparison error** - Added nil checks
- **Addon metadata** - Added icon, updated author info, removed outdated links

## Changes
- Disabled Blizzard frames hiding for party/boss/arena (compatibility with other raid frames)
- Removed all taint-causing methods (SetShown hooks, event-based hiding, Update hooks)
- Added RegisterAttributeDriver for safe pet bar hiding


## Compatibility
- World of Warcraft 11.2.7 (Retail)

