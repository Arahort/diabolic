# DiabolicUI3 Changelog

## [1.9.7-alpha1] - 2026-01-25
### Added
- Added "Show Buffs Near Health Orb" setting (default: enabled) to toggle player buffs display
- Added "Disable DiabolicUI Minimap" setting (default: disabled) to completely disable custom minimap
- Added custom Arial Narrow font for aura cooldown timers (size 9 with outline)
- Added full localization for new settings (12 languages: en, de, es, fr, it, ko, pt, ru, zh)
- Added localization guidelines to project documentation

### Changed
- Reduced aura cooldown timer font size for better text fitting (45 мин now fits properly)
- Changed "Class Color for Power Orb" setting from global to per-character
- Each character can now have different power orb color preference
- Aura timer font changed to Arial Narrow for Cyrillic support

### Fixed
- Fixed Buffs frame nil error when showPlayerBuffs setting is disabled
- Fixed Cyrillic characters displaying as squares in aura timers

### Development
- Added .psd files in Assets folder to .gitignore
- Removed tracked .psd file from repository (kept on disk for local use)

## [1.9.6] - 2026-01-25
### Fixed
- Fixed player unit frame buffs/debuffs not updating count in combat
- Fixed action buttons becoming grayed out in combat
- Fixed aura filters using incorrect field (expiration instead of expirationTime)
- Fixed arithmetic on secret value errors when calculating aura time remaining
- Fixed target/nameplate auras not showing in combat

### Changed
- Player buffs/debuffs now use non-secure buttons to allow combat updates
- Target/Focus/Nameplate auras remain secure (updates deferred until combat ends)
- All aura filters now use data.expirationTime with secret value protection
- Removed stack count condition from player buff filter
- In combat, auras show if expirationTime exists (temporary auras only)

### Known Issues
- Target frame auras do not update count during combat (secure button limitation)
- Some permanent buffs may show in combat if their values become secret

## [1.9.6-alpha3] - 2026-01-25
### Fixed
- Fixed action buttons becoming grayed out after entering combat caused by taint propagation
- Prevented C_UnitAuras.GetAuraDuration calls during combat to avoid tainting action buttons

### Changed
- Secret value aura cooldowns now only update outside of combat to prevent taint
- Regular (non-secret) aura cooldowns continue to work normally in and out of combat

### Known Issues
- Auras with secret values (duration/expiration) will not show cooldown spirals during combat
- Cooldown display will resume after leaving combat

## [1.9.6-alpha2] - 2026-01-25
### Fixed
- Fixed aura cooldowns not displaying in combat for unit frames (near orbs)
- Fixed aura cooldowns not displaying in combat for standalone auras (near minimap)
- Implemented proper secret values handling for aura duration and expirationTime
- Added missing EnableThird locale translations for third action bar option

### Changed
- Updated aura system to use C_UnitAuras.GetAuraDuration() for secret values
- Updated aura buttons to use SetCooldownFromDurationObject() method
- Added countdown numbers display on aura cooldowns

## [1.9.5-RC1] - 2026-01-24
### Fixed
- Fixed action bar cooldowns not working in combat for WoW 12.0.0 Midnight
- Fixed cooldown spiral animation not showing in combat
- Fixed cooldown countdown numbers not displaying in combat
- Fixed action bars not updating when dismounting in combat
- Implemented support for WoW 12.0.0 secret values system in LibActionButton-1.0-GE

### Changed
- Switched to Blizzard's built-in cooldown countdown (native WoW API)
- Updated LibActionButton to use ActionButton_ApplyCooldown when available
- Updated LibActionButton to use C_ActionBar.GetActionCooldown API for WoW 12.0+
- Added fallback support for older WoW versions without C_ActionBar API
- Dropped support for WoW 11.x (The War Within) - addon now requires WoW 12.x Midnight

### Known Issues
- Buffs and debuffs may not display correctly in combat due to WoW 12.0 secret values system
- Unit auras require additional work to handle secret values properly

## [1.9.4] - 2026-01-17
### Changed
- Updated Interface version to 120001 for WoW 12.0.1 compatibility
- Changed addon description from "WoW 11.x" to "WoW 12.x"

### Fixed
- Fixed pet bar tooltips not showing on hover
- Preserved original PetActionButtonTemplate tooltip handlers to maintain proper tooltip functionality

## [1.9.3] - 2026-01-06
### Changed
- Renamed "Hide Target Name on Cast" setting to "Show Target Castbar?" in all 12 locales
- Inverted setting logic: checkbox enabled = show castbar overlay and replace name with spell name
- Default changed to disabled (false) - castbar overlay now hidden by default

### Fixed
- Fixed spell name remaining visible after cast completion
- Fixed castbar progress overlay showing when setting is disabled
- Fixed cast time "0.0" remaining visible after cast completion

### Removed
- Removed unused Settings_Modern.lua file (603 lines of dead code)

## [1.9.2] - 2026-01-06
### Added
- Added full localization support for all WoW-supported languages:
  - German (deDE)
  - Spanish EU (esES)
  - Spanish Mexico (esMX)
  - French (frFR)
  - Italian (itIT)
  - Portuguese Brazil (ptBR)
  - Portuguese Portugal (ptPT)
  - Korean (koKR)
  - Chinese Simplified (zhCN)
  - Chinese Traditional (zhTW)
- All 110+ settings strings now translated for each locale

### Changed
- Action bar settings are now per-character instead of shared across all characters
- Disabled AceDB profile system to ensure independent action bar configuration for each character
- Hidden stance bar settings from UI (settings remain in code for future use)
- Stance bar now disabled by default

### Fixed
- Fixed issue where enabling secondary/third action bars on one character would enable them on all characters
- Fixed action bar count being shared via "Default" profile across all characters

## [1.9.1] - 2026-01-06
### Fixed
- Fixed empty buff/debuff slots appearing during combat (alpha not properly restored)
- Fixed buff/debuff position jumping when mounting/dismounting vehicles or quest mounts (preserves normal offset during temporary bars)
- Fixed PetBar and StanceBar positioning to use action bar settings instead of visibility state
- Fixed PetBar appearing above second bar instead of third when 3 bars are enabled (removed db.positionY override)
- Adjusted PetBar vertical position (lowered by 15 pixels when 3 bars enabled, no offset for 2 bars)

### Performance
- Optimized ActionButton usability updates: reduced from 100+ to 2 updates per second (50-150x improvement)
- Optimized StatusBars overlay animation: reduced from 60 to ~3 updates per second (20x improvement)
- Optimized cooldown timer updates with adaptive throttling based on remaining time:
  - Short cooldowns (<5s): 10 updates/sec for accuracy
  - Medium cooldowns (5-30s): 5 updates/sec
  - Long cooldowns (>30s): 2 updates/sec
- Overall UI performance improvement: 10-30x reduction in CPU usage during combat

## [1.9.0] - 2026-01-05
### Fixed
- Fixed buff/debuff icon duplication and texture mask exhaustion during combat
- Fixed empty buff/debuff icons appearing during combat
- Fixed incorrect buff/debuff positioning after exiting combat (second row starting mid-way)
- Optimized texture updates to only call SetTexture() when icon fileID actually changes
- Improved combat lockdown handling for aura buttons - new buttons are positioned immediately, existing buttons repositioned when safe

### Changed
- Minor player buff/debuff horizontal position adjustment for better alignment (-320→-316, 320→316)

## [1.8.2] - 2026-01-02
### Fixed
- Fixed ADDON_ACTION_BLOCKED when EditMode tries to reposition frames during combat (blizzard.lua)
- Fixed ADDON_ACTION_BLOCKED when making protected frames movable during combat (QualityOfLife.lua)
- Added InCombatLockdown() checks in resetParent function and MakeFrameMovable function

## [1.8.1] - 2026-01-02
### Fixed
- Fixed ADDON_ACTION_BLOCKED errors when hiding buff and debuff buttons during combat
- Added InCombatLockdown() checks in auras.lua for both buffs (line 746) and debuffs (line 879)

## [1.8.0] - 2025-12-25
### Changed
- Hidden Blizzard's default minimap zone name background and text
- Updated default minimap position to (-20, -20) for better screen alignment
- Minimap now displays only DiabolicUI's custom zone text without Blizzard overlay

## [1.7.7] - 2025-12-24
### Fixed
- Fixed ADDON_ACTION_BLOCKED errors in aura positioning during combat
- Fixed nil comparison error in target health prediction
- Improved combat lockdown handling for protected frames

## [1.7.6] - 2025-12-22
### Changed
- Removed archive files from repository

## [1.7.5] - 2025-12-22
### Changed
- Cleaned repository structure
- Updated gitignore patterns

## [1.7.4] - 2025-12-22
### Changed
- Cleaned commit history for consistency
- Repository history rewritten

## [1.7.3] - 2025-12-22
### Changed
- Updated version number to match release tags for better version tracking

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
