# DiabolicUI3 Changelog

## [2.4.3] - 2026-02-15

### 🎨 Visual Improvements
- **Castbar Progress Texture**: Custom overlay texture for player and pet castbars
  - Uses Heath-Bar texture with proper fill animation via SetTexCoord
  - Blue color tint for visual distinction

---

## [2.4.2] - 2026-02-15

### 🎨 Visual Improvements
- **Castbar Border**: New custom border texture for player and pet castbars
  - Uses Health-Bar-Border2 texture for better visual consistency

---

## [2.4.1] - 2026-02-15

### 🐛 Bug Fixes
- **Tooltip Taint Fix**: Fixed taint error when hovering over POI/quests on world map
  - Blizzard_SharedXML/Backdrop.lua no longer throws "secret number value" errors
  - Map-related tooltips (MapCanvas, WorldMap, AreaPOI) now skip custom positioning
- **Minimap Ping Taint Fix**: Fixed ADDON_ACTION_FORBIDDEN when left-clicking minimap to ping
  - Changed from SetScript to HookScript for OnMouseUp handler
  - Blizzard's ping handler now works without taint
- **Mail Icon Border Visibility**: Border and shade now hide when no mail (was showing empty frame)

### 🔧 Changes
- Added statusbar profile files for UI and Platynator customization

---

## [2.4.0] - 2026-02-14

### ✨ New Features
- **Aura Growth Direction**: New per-character option to grow buff rows upward instead of downward
  - Checkbox in Settings → Auras section
  - Requires UI reload to apply
- **Minimap Icon Borders**: Added circular borders to Mail (9 o'clock) and Tracking (3 o'clock) icons
  - Matches the bag button border style for visual consistency
- **Expansion Landing Button**: ExpansionLandingPageMinimapButton (Dragonflight/War Within) now collected into minimap buttons container
- **Settings Panel Icon**: Added DiabolicUI icon next to addon name in Interface Options addon list

### 🌍 Localization
- Full translations for aura growth direction setting in all 12 supported languages

---

## [2.3.0] - 2026-02-10

### ✨ New Features
- **Platynator Integration**: Custom DiabolicUI styling for Platynator addon nameplates
  - Replaces Platynator health bars with power-crystal textures
  - Automatic frame sizing with combat scaling support
  - Experimental feature - enable in Settings → Experiments
- **Two Rows Target Auras**: New option to show 14 auras in 2 rows under target frame (instead of 7)
  - New checkbox in Settings → Auras section
  - Requires UI reload to apply
- **StanceBar Styling**: Custom DiabolicUI styling for stance/shapeshifting buttons
  - Power-crystal frame overlay matching action bar style
  - Proper border textures and consistent visual design

### 🎨 UI Improvements
- Extended all position slider ranges to -2000/2000 for more flexibility
- Improved Platynator frame width to properly cover health bar edges
- MicroMenu now has proper icon styling

### 🌍 Localization
- Full translations for all new settings in 12 supported languages
- Updated slider descriptions to show extended -2000 to 2000 range

### 🔧 Technical
- Added FRAME_WIDTH_EXTRA constant for Platynator health bar edge coverage
- Platynator slash commands disabled (internal testing only)
- Added twoRowsTargetAuras setting to global.auras database

---

## [2.1.0] - 2026-02-04

### ✨ New Features
- **MicroMenu Panel**: New vertical popup menu with all game micro buttons (Character, Spellbook, Talents, etc.), accessible via a toggle button in the bottom-right corner
- **MicroMenu Settings**: Enable/disable toggle, button size slider (20-50px), and position sliders (X/Y) in the Settings panel under "Other"
- **Auto-Hide**: MicroMenu automatically hides after 3 seconds when the mouse leaves the panel
- **Combat Safe**: Menu opens/closes freely in combat via secure frame handlers

### 🎨 UI Improvements
- Clean icon-only display: stripped Blizzard button backgrounds and borders for a minimal look
- Semi-transparent dark backdrop with tooltip-style border
- Toggle button with plus/minus texture, fades to 30% opacity when idle
- Hidden during pet battles and vehicle UI

### 🌍 Localization
- Full translations for MicroMenu settings in all 12 supported languages

## [2.0.1] - 2026-02-03

### 🐛 Bug Fixes
- **Cooldown Edge Fix**: Fixed yellow-orange cooldown edge line appearing on hidden side panel action bar buttons. WoW 12.0 C++ `ActionButton_ApplyCooldown` was enabling edge rendering internally, bypassing Lua hooks.

## [2.0.0] - 2026-02-01

### ✨ New Features
- **Diablo 2 Resurrected Orb Style**: New orb textures inspired by D2R (enabled by default)
- **Custom Orb Colors**: Per-character color picker for Health and Power orbs
- **Independent Target Frame Scale**: Separate scaling slider (0.5-2.0) for target frame
- **Extended Hidden Bars**: Option for 12 buttons per bar (6x2 layout) using action bar page 7
- **Pet Orb Style**: Show pet health as a sphere instead of portrait frame
- **Single-Button Assistant Support**: Dynamic icon updates during combat
- **Castbar Border**: ToT-style border texture for player and pet castbars
- **LFG Eye Animation**: Pulsing glow when in dungeon/raid queue

### 🎨 UI Improvements
- **Minimap Rework**: Repositioned Mail (left), Tracking (right), LFG eye (bottom) with custom textures
- **Settings Panel Reorganization**: Better organized with proper section headers
- **Renamed "Orbs" to "Spheres"**: Consistent terminology across all settings and localization
- **D2R Positions for Extra Buttons**: ZoneAbility and ExtraAction buttons positioned near orbs when D2R style is enabled
- **Hidden Minimap Clutter**: Removed zoom buttons, AddonCompartment, EditMode empty frame

### ⚡ Performance Optimizations
- Removed SetCooldown hooks from ActionBars, PetBar, StanceBar (major optimization)
- Added OnUpdate throttle for Tooltip (~30 fps instead of every frame)
- Added OnUpdate throttle for Auras (~30 fps for timer updates)
- Single-Button Assistant icon check runs only in combat (0.1s interval)

### 🐛 Bug Fixes
- Fixed ADDON_ACTION_BLOCKED errors when hiding auras, changing EditMode, moving frames in combat
- Fixed achievement toasts, loot popups, and bonus rolls not showing
- Fixed border appearing on action bar 2-3 after /reload
- Fixed SmallActionBar page conflict with ThirdActionBar
- Fixed tracking icon resetting on zone change
- Fixed LFG eye resetting position when talking to NPCs
- Fixed Cyrillic characters displaying as squares in aura timers
- Fixed Single-Button Assistant icon freezing in combat
- Fixed custom orb colors being overridden by PostUpdate functions
- Fixed tooltip taint for world objects

### 🔧 Changes
- Disabled custom nameplates module (use Blizzard default or Plater/Kui/etc.)
- D2R orb style is now enabled by default
- "Class Color for Power Orb" is now per-character setting

### 🌍 Localization
- Full localization support for all new features (12 languages)
- Languages: English, German, Spanish (EU/MX), French, Italian, Korean, Portuguese (BR/PT), Russian, Chinese (Simplified/Traditional)

---

## [2.0.0-alpha12] - 2026-01-31
### Performance
- ActionBars: Removed SetCooldown hook, set alpha once at creation (major optimization)
- PetBar: Same optimization for pet action buttons
- StanceBar: Same optimization for stance buttons

## [2.0.0-alpha11] - 2026-01-31
### Performance
- Tooltip OnUpdate: Added throttle (~30 fps instead of every frame)
- Auras OnUpdate: Reduced from 100 fps to ~30 fps for timer updates

## [2.0.0-alpha10] - 2026-01-31
### Changed
- Disabled custom nameplates (use Blizzard default or Plater/Kui/etc.)

### Maintenance
- Cleaned up TODO.md - removed completed tasks

## [2.0.0-alpha9] - 2026-01-31
### Added
- Castbar: Added ToT-style border texture to PlayerCastingBarFrame and PetCastingBarFrame
- QueueStatus (LFG eye): Added pulsing glow animation when in queue

### Improved
- Tracking icon: Now survives zone changes, NPC interactions, and reloads (hooked SetPoint)
- QueueStatus (LFG eye): Now survives NPC interactions (hooked SetPoint)

### Fixed
- Fixed tracking icon resetting to default position on zone change
- Fixed LFG eye resetting position when talking to NPCs

## [2.0.0-alpha8] - 2026-01-31
### Improved
- ExtraButtons: Added D2R orb style positions for ZoneAbilityFrame (500, 250) and ExtraActionButton (-495, 240)
- These buttons now appear near the orbs when D2R style is enabled

## [2.0.0-alpha7] - 2026-01-31
### Improved
- Minimap: Mail icon repositioned to 9 o'clock (left side)
- Minimap: QueueStatusButton (LFG eye) repositioned to 6 o'clock with custom orange texture
- Minimap: Hidden zoom buttons (+/-)

### Fixed
- Fixed zoom buttons not hiding due to ns.IsRetail being nil in WoW 12.0

## [2.0.0-alpha6] - 2026-01-31
### Improved
- Minimap: Mail icon repositioned to bottom (6 o'clock)
- Minimap: Tracking button repositioned to right side (3 o'clock)
- Minimap: Instance difficulty repositioned to top (12 o'clock)
- Minimap: Hidden AddonCompartmentFrame
- Minimap: Hidden MinimapCluster from EditMode (no more empty frame)
- Minimap: Default position changed to X=-30, Y=-40

### Fixed
- Fixed "attempt to call method 'Layout' (a nil value)" error on UPDATE_PENDING_MAIL
- Added Layout stub to Minimap for Blizzard MailFrame compatibility

## [2.0.0-alpha5] - 2026-01-31
### Fixed
- Fixed border appearing on action bar 2-3 after /reload
- Root cause: bar:Hide() was called before button creation, causing styling issues on reload
- Moved bar:Hide() to after button creation for SecondaryActionBar and ThirdActionBar
- Applied SetNormalTexture/SetHighlightTexture/SetCheckedTexture hooks for all WoW versions (was only Classic)
- Added NormalTexture hiding to OnButtonUpdate callback for extra safety

## [2.0.0-alpha4] - 2026-01-30
### Fixed
- Fixed SmallActionBar1,4 duplicating buttons with ThirdActionBar
- Moved SmallActionBar1,4 from page 5 (BOTTOMRIGHT) to page 2 (free page)
- Side panels now use independent action bar page without conflicts

### Technical
- SmallActionBar1 (left side, bottom) now uses barID 2 instead of BOTTOMRIGHT_ACTIONBAR_PAGE
- SmallActionBar4 (right side, bottom) now uses barID 2 instead of BOTTOMRIGHT_ACTIONBAR_PAGE
- Page 5 is now exclusively used by ThirdActionBar

## [2.0.0-alpha3] - 2026-01-29
### Added
- Added independent target frame scale setting (0.5-2.0, default 1.0)
- Target frame scale now completely independent from "Bottom UI Scale" setting
- New "Target Frame Scale" slider in Core settings section (next to "Bottom UI Scale")
- Real-time target frame scaling without UI reload
- Full localization support for new setting (12 languages)

### Changed
- Target frame moved to separate scaling system (TargetFrameScaled)
- Target frame no longer affected by unitframesRelativeScale changes
- Unified scaling architecture - all scales work through UpdateObjectScales()

### Technical
- Added global.core.targetFrameScale database setting (default: 1.0)
- Created TargetFrameScaled[] cache in Scale.lua for independent target scaling
- Added API.SetTargetFrameObjectScale() method for target frame registration
- Added ns.UpdateTargetFrameScale() for real-time updates
- Target frame uses base UI scale (GetScale()) instead of unitframes scale (GetUnitFramesScale())
- Updated UpdateObjectScales() to handle both UnitFramesScaled and TargetFrameScaled arrays

## [2.0.0-alpha2] - 2026-01-29
### Added
- Added custom orb colors feature with per-character settings
- Color picker for Health orb color (ColorPickerFrame integration)
- Color picker for Power orb color (ColorPickerFrame integration)
- "Use Custom Orb Colors" checkbox (per-character, disabled by default)
- Full localization support for color settings (12 languages)
- Real-time color updates without UI reload

### Fixed
- Fixed custom orb colors being overridden by PostUpdate functions
- Fixed color picker cancelFunc to properly restore colors on cancel
- Fixed custom colors not applying on addon load
- Fixed ForceUpdate() errors when disabling custom colors (method doesn't exist on orbs)
- Fixed Settings API integration (CreateSettingsButtonInitializer)

### Technical
- Added char.orbs.useCustomColors, healthColor, powerColor to database
- Created UpdateOrbColors() callback for real-time updates
- Added early returns in Health_PostUpdateColor and Power_PostUpdate to preserve custom colors
- Used closure pattern in cancelFunc for proper color restoration
- Custom colors override automatic coloring (colorHealth/colorPower flags)

## [2.0.0-alpha1] - 2026-01-29
### Added
- Added Diablo 2 Resurrected orb style setting with full localization (12 languages)
- Added D2R style orb textures (orb-art1-d2r.tga, orb-art2-d2r.tga)
- D2R orb style is now enabled by default (can be disabled in settings)
- Added UI reload confirmation dialog when changing orb style

### Fixed
- Fixed ADDON_ACTION_BLOCKED error when hiding player aura buttons during combat
- Fixed ADDON_ACTION_BLOCKED error when EditMode tries to change frame parent during combat
- Fixed ADDON_ACTION_BLOCKED error when making protected frames movable during combat

### Technical
- Added global.orbs.useD2RStyle setting to database (default: true)
- Added conditional texture loading in Player.lua based on orb style setting
- Added InCombatLockdown checks to prevent taint in three critical locations

## [1.9.7.1] - 2026-01-27
### Fixed
- Fixed achievement toasts, loot popups, and bonus rolls not showing
- Disabled custom AlertFrames positioning module to use Blizzard default behavior
- Alert notifications now appear at default Blizzard position (top center of screen)

### Technical
- Commented out AlertFrames.lua module in Components/Misc/Misc.xml
- Removed conflicts between Core/Blizzard.lua and Components/Misc/AlertFrames.lua

## [1.9.7-RC3] - 2026-01-26
### Added
- Added "Main Button Size" setting for MinimapButtons (24-64 pixels, default: 40)
- Full localization for main button size setting (12 languages)
- Dynamic button size update - changes apply immediately without reload

### Changed
- MinimapButtons main button border now scales proportionally with button size (135% of button size)

### Fixed
- Fixed achievement toasts, loot popups, and bonus roll windows not showing
- Disabled AlertFrame killing to restore Blizzard popup notifications

### Removed
- Removed unused "Main Button Scale" setting that had no effect

## [1.9.7-alpha3] - 2026-01-26
### Fixed
- Fixed achievement toasts, loot popups, and bonus roll windows not showing
- Disabled AlertFrame killing to restore Blizzard popup notifications

## [1.9.7-alpha2] - 2026-01-26
### Added
- Added "Aura Icon Size" setting to control buff icon size near minimap (20-64 pixels, default: 36)
- Added full localization for aura icon size setting (12 languages)

### Changed
- Aura icon size now dynamically adjusts based on settings
- Disabled Reset/Import/Export section in settings (commented out, may be restored later)

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
