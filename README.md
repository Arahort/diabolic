# Diabolic UI 3.0 - Arahort Edition

Orb-based graphical user interface replacement for World of Warcraft.

## About This Fork

This is a **community-maintained fork** of the original [Diabolic UI 2.0](https://www.curseforge.com/wow/addons/diabolicui) by Lars Norberg and Daniel Troko.

**Important:** The original Diabolic UI 2.0 is **no longer functional** in modern World of Warcraft (11.2.7+). This fork has been completely rebuilt to work with current game versions.

### Original Project Credits

- **Original Addon:** [Diabolic UI 2.0](https://www.curseforge.com/wow/addons/diabolicui)
- **Original Code:** Lars Norberg
- **Original Artwork:** Daniel Troko and Lars Norberg
- **Original License:** Custom License (All Rights Reserved)

### This Fork

- **Updated for WoW 11.x by:** Alex Arahort
- **Status:** Fully functional for The War Within (11.2.7+)
- **License:** Community Fork - respecting original authors' work

---

## What's Different From the Original

The original Diabolic UI 2.0 **stopped working completely** after Blizzard's API changes in WoW 11.x. This edition includes:

### Core Fixes (Making it Work Again)

- ✅ Complete API migration to WoW 11.x standards
- ✅ Migrated to `C_AddOns` namespace (old AddOn API deprecated)
- ✅ Updated Aura system to use `C_UnitAuras` API
- ✅ Updated Reputation system to use `C_Reputation` API
- ✅ Fixed `MainMenuBar` → `MainActionBar` transition
- ✅ Fixed `ObjectiveTracker` hooks for new API
- ✅ Fixed hundreds of deprecated function calls
- ✅ Replaced LibActionButton-1.0 with LibActionButton-1.0-GE for WoW 11.x compatibility
- ✅ Fixed action button click registration (EnableMouse propagation)
- ✅ Fixed taint issues with secure templates
- ✅ Updated oUF (unit frames library) to version 12.1.0

### Settings & Customization

- ✅ Settings panel in Interface Options → AddOns
- ✅ Addon Compartment support for quick settings access
- ✅ Export/Import settings - share configurations or backup your setup with version control
- ✅ Target Frame Scale Control - adjust target frame size independently (0.5x - 1.5x)
- ✅ Threat Indicator setting - toggle threat-based HP coloring (green/yellow/red)
- ✅ Improved "Hide target name on cast" - now also hides cast bar, cast time, and spell text
- ✅ Tooltip offset customization - adjust X/Y position relative to cursor

### UI Improvements

- ✅ Better default scaling for modern displays
- ✅ Secondary action bar enabled by default
- ✅ Improved power orb for hybrid classes (shows primary resource)
- ✅ Optimized default positions for all UI elements
- ✅ EditMode position saving - Minimap, TalkingHead, and ExtraButtons properly save positions

### Quality of Life Features

- ✅ **Movable interface windows** - hold SHIFT and drag to move Character, Bags, Map, Friends, Settings, and more
- ✅ **Tooltips follow mouse cursor** - integrated TTOM functionality with customizable offset
- ✅ **Auto-fill delete confirmation** - no need to type "DELETE" manually when destroying items
- ✅ **Fixed buff cancellation** - right-click buffs to cancel them (works on player and target frames)
- ✅ **Action bars switching in quests** - properly switches when entering vehicles/dragons
- ✅ **Pet bar duplication fixed** - reworked Blizzard pet bar hiding using safe methods
- ✅ **Combat lockdown protection** - added InCombatLockdown() checks to prevent taint errors
- ✅ **Action bar toggle improved** - left click shows/hides all 3 extra bars
- ✅ **Map coordinates display** - player and cursor coordinates on world map and minimap
- ✅ **Minimap buttons container** - collects addon buttons into single organized container
- ✅ **NamePlates toggle** - optional setting to enable/disable custom nameplates

---

## Requirements

- World of Warcraft **Retail 11.2.7** or later (The War Within)

## Installation

1. Download the addon
2. Extract to `World of Warcraft\_retail_\Interface\AddOns`
3. Restart WoW or type `/reload` in-game

---

## Support

This is a community-maintained fork. For issues or feature requests, please visit:

- **GitHub:** https://github.com/Arahort/diabolic
- **CurseForge:** https://www.curseforge.com/wow/addons/diabolicui-arahort-edition

### Support the Developer

- **Patreon:** https://www.patreon.com/c/Arahort
- **Boosty:** https://boosty.to/alex_arahort

#### Crypto:

- USDT TRC20: `TShMCz6xGiLvtES8JquqhavrMvFnLM4UQ4`
- USDT TON: `UQAKgkYbTk9qWICUn4O249X4F_hqPUHUpCEXNONLbHVfUjcc`
- BTC: `bc1q89d70zz5v0f0x00pulrdggmmfav35c0nm99ua3`

---

## List of Add-ons Present in the Video

- DiabolicUI Arahort Edition
- Scrap
- DBM
- Rematch
- Talent Tree Tweaks
- DragonRider
- AllTheThings
- Auctinator
- Baganator
- Syndicator
- Chattynator
- Better Fishing
- Almost Completed Achievements
- BugGrabber
- BugSack
- Details!
- Dialogue UI
- MapCoords
- Plumber
- Postal
- TomTom
- WIM
- World Quest Tracker
- MinimapButtonButton
