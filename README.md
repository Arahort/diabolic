# Diabolic UI - Arahort Edition

Orb-based graphical user interface replacement for World of Warcraft, inspired by Diablo series.

## About This Fork

This is a **community-maintained fork** of the original [Diabolic UI 2.0](https://www.curseforge.com/wow/addons/diabolicui) by Lars Norberg and Daniel Troko.

**Important:** The original Diabolic UI is **no longer functional** in modern World of Warcraft. This fork has been completely rebuilt to work with current game versions.

### Original Project Credits

- **Original Addon:** [Diabolic UI](https://www.curseforge.com/wow/addons/diabolicui)
- **Original Code:** Lars Norberg
- **Original Artwork:** Daniel Troko and Lars Norberg
- **Original License:** Custom License (All Rights Reserved)

### This Fork

- **Updated for WoW 12.x by:** Alex Arahort
- **Artwork:** Alex Arahort and Karina Kisenkova
- **Status:** Fully functional for Midnight (12.0+)
- **License:** Community Fork

---

## Features

### Orb Styles

- **Diablo 2 Resurrected Style** (default) - New orb textures inspired by D2R
- **Classic Diablo 3 Style** - Original DiabolicUI orb textures
- **Custom Orb Colors** - Per-character color picker for Health and Power orbs

### Action Bars

- **6 Action Bars** - Primary, Secondary, Third bars + 2 side panels + Pet bar
- **Extended Mode** - 12 buttons per bar (6x2 layout) using action bar page 7
- **Pet Orb Style** - Show pet health as a sphere instead of portrait frame
- **Single-Button Assistant Support** - Dynamic icon updates during combat
- **Stance/Form Bar** - Automatic display for classes with stances

### Unit Frames

- **Health & Power Orbs** - Diablo-style resource spheres
- **Target Frame** - Independent scaling (0.5x - 2.0x)
- **Target of Target** - Optional display when target attacks you
- **Castbar Borders** - ToT-style border for player and pet castbars
- **Debuff Filtering** - Show only your debuffs on target (boss debuffs always visible)

### Minimap

- **Repositioned Elements** - Mail (left), Tracking (right), LFG eye (bottom)
- **LFG Queue Animation** - Pulsing glow when in dungeon/raid queue
- **Coordinates Display** - Player and cursor coordinates on minimap and world map
- **Button Collector** - All addon minimap buttons in single organized container
- **Clean Look** - Hidden zoom buttons, AddonCompartment, EditMode clutter

### Auras (Buffs/Debuffs)

- **Near Minimap** - Configurable position and icon size (20-64px)
- **Near Health Orb** - Optional display for player buffs
- **Right-click to Cancel** - Cancel buffs on player and target frames

### Performance Optimizations

- Removed SetCooldown hooks (major CPU savings in combat)
- Throttled OnUpdate for tooltips and auras (~30 fps)
- Combat-only checks for dynamic features

### Quality of Life

- **Movable Windows** - Hold SHIFT and drag Character, Bags, Map, etc.
- **Tooltips Follow Cursor** - Customizable X/Y offset
- **Auto-fill DELETE** - No need to type "DELETE" when destroying items
- **Server/Local Time** - Toggle between server and local time display
- **12/24 Hour Clock** - Choose your preferred time format

---

## Requirements

- World of Warcraft **Retail 12.0** or later (Midnight)

## Installation

### From CurseForge (Recommended)

Install via CurseForge client for automatic updates.

### Manual Installation

1. Download the latest release
2. Extract to `World of Warcraft\_retail_\Interface\AddOns`
3. Restart WoW or type `/reload` in-game

---

## Support

This is a community-maintained fork. For issues or feature requests:

- **GitHub:** https://github.com/Arahort/diabolic
- **CurseForge:** https://www.curseforge.com/wow/addons/diabolicui-arahort-edition

### Support the Developer

- **Patreon:** https://www.patreon.com/c/Arahort
- **Boosty:** https://boosty.to/alex_arahort

#### Crypto

- USDT TRC20: `TShMCz6xGiLvtES8JquqhavrMvFnLM4UQ4`
- USDT TON: `UQAKgkYbTk9qWICUn4O249X4F_hqPUHUpCEXNONLbHVfUjcc`
- BTC: `bc1q89d70zz5v0f0x00pulrdggmmfav35c0nm99ua3`

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for full version history.

### Version 2.0.0 Highlights

- Diablo 2 Resurrected orb style (enabled by default)
- Custom orb colors with per-character settings
- Independent target frame scaling
- Extended hidden bars option (12 buttons per bar)
- Pet orb style display
- Single-Button Assistant dynamic icon updates
- Performance optimizations (removed SetCooldown hooks, OnUpdate throttling)
- Minimap improvements (repositioned elements, LFG animation)
- Full localization (12 languages)
