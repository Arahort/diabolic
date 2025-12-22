# DiabolicUI3 Changelog

## [1.7.2] - 2025-12-22
### Added
- **NamePlates Toggle Setting** - Optional setting to enable/disable DiabolicUI nameplates
  - New "Enable DiabolicUI NamePlates" checkbox in Unit Frames settings
  - Default: disabled (uses standard Blizzard nameplates)
  - Allows users to choose between custom and standard nameplates
  - English and Russian localization

## [1.7.1] - 2025-12-21
### Fixed
- Fixed action bar page navigation buttons visibility

## [1.7.0] - 2025-12-21
### Added
- **MinimapButtons Module** - Collect addon minimap buttons into single container
  - Automatically gathers all addon buttons around minimap
  - Styled container matching DiabolicUI aesthetic
  - Toggle visibility with minimap button
  - Reduces minimap clutter

## [1.6.0] - 2025-12-21
### Added
- **MapCoords Module** - Display coordinates on map and minimap
  - Player coordinates on world map
  - Cursor coordinates on hover
  - Minimap coordinates display
  - Styled to match DiabolicUI design

## [1.5.0] - 2025-01-20
### Added
- **Movable Interface Frames** - Hold SHIFT and drag to move Blizzard interface windows
  - Supports: Character, Bags, Map, Friends, Settings, Merchant, Professions, Talents, Spellbook
  - Automatically disabled if BlizzMove addon is detected
  - New Quality of Life settings section
  - Feature enabled by default

### Technical
- Created MakeFrameMovable() function with SHIFT+drag requirement
- Added EnableMovableFrames() with standard and dynamic frame lists
- Added defaults for tooltips and qol sections in Core.lua
- Added QoL settings callback handling
- Added English and Russian localization

## [1.4.3] - 2025-01-20
### Removed
- Removed all Wrath Classic support files (DiabolicUI3_Wrath.toc, Libs_Wrath.xml, oUF.old)
- Cleaned up 10,763 lines of unused code
- CurseForge no longer shows incorrect Wrath 3.4.0 compatibility

## [1.4.2] - 2025-01-20
### Changed
- Updated README with complete addon description from CurseForge
- Added comprehensive list of features and improvements
- Added Quality of Life features section
- Added .pkgmeta for CurseForge automatic packaging
- Updated .gitignore to exclude DiabolicUI3_Wrath.toc

## [1.4.1] - 2025-01-19
### Added
- GitHub Actions workflow for automated releases
- Automatic DiabolicUI3.zip archive creation on tag push
- Archive always contains DiabolicUI3 folder regardless of tag name

### Fixed
- Fixed GitHub Actions permissions for release creation

## [1.4.0] - 2025-01-19
### Added
- **Auto-Fill Delete Confirmation** - No need to type "DELETE" manually when destroying items
  - Automatically fills confirmation text
  - Works with all localizations (uses Blizzard's DELETE_ITEM_CONFIRM_STRING)
  - Created new QualityOfLife module

## [1.3.0] - 2025-01-19
### Added
- **Tooltips Follow Mouse Cursor** - Integrated TTOM functionality
  - Adjustable X and Y offset settings (-100 to 100 pixels)
  - Feature enabled by default
  - All DiabolicUI3 visual styles preserved
  - Settings in Tooltips section

## [1.2.0] - 2025-01-18
### Fixed
- **Action Bar Switching in Quests** - Properly switches when entering vehicles/dragons
- **Buff Cancellation** - Right-click buffs to cancel them (works on player and target frames)
- Quest abilities display properly
- Secondary bar automatically hides when vehicle/override/possess modes activate

### Technical
- Added handling for UPDATE_VEHICLE_ACTIONBAR, UPDATE_OVERRIDE_ACTIONBAR, UPDATE_POSSESS_BAR events
- Switched to CancelUnitBuff() API for buff cancellation
- Optimized state driver switching logic

## [1.0.0] - 2025-01-17
### Added
- **Threat Indicator Setting** - Toggle threat-based HP coloring on/off
- **Improved "Hide target name on cast"** - Now hides cast bar, cast time, and spell text
- **Settings Export/Import** - Share configurations or backup settings
- **Target Frame Scale Control** - Adjust target frame size independently (0.5x - 1.5x)

### Fixed
- **EditMode Position Saving** - Minimap, TalkingHead, ExtraButtons properly save positions
- **Pet Bar Duplication** - Reworked Blizzard pet bar hiding using safe methods
- **Multiple ADDON_ACTION_BLOCKED Errors** - Added InCombatLockdown() protection
- **Action Bar Toggle** - Works as proper toggle (left click shows/hides all 3 extra bars)
- **HealPredict Nil Comparison** - Added nil checks
- **Addon Metadata** - Added icon, updated author info, removed outdated links

### Technical
- Disabled Blizzard frames hiding for party/boss/arena (compatibility)
- Removed all taint-causing methods
- Added RegisterAttributeDriver for safe pet bar hiding
- Improved combat lockdown protection across all components

## [Alpha 2] - 2025-01-16
### Initial Release
- Complete API migration to WoW 11.x standards
- Migrated to C_AddOns namespace
- Updated Aura system to use C_UnitAuras API
- Updated Reputation system to use C_Reputation API
- Fixed MainMenuBar → MainActionBar transition
- Replaced LibActionButton-1.0 with LibActionButton-1.0-GE
- Updated oUF to version 12.1.0
- Settings panel in Interface Options
- Addon Compartment support
