# Gather Map

**A self-learning resource map overlay for World of Warcraft 1.12**

**Creator:** Babuni.dev  
**Addon version:** 0.4.3 · **Interface:** 11200 · **SavedVariables:** `GatherMapDB`  
**Implementation:** [`GatherMap.lua`](GatherMap.lua), [`GatherMap.toc`](GatherMap.toc)  
**Documentation audit:** 2026-10-26 — verified against source and Git history; **no new in-game tests performed**.

Gather Map remembers **where you successfully gathered resources** and shows those discoveries on both the minimap and zone world map. It started as a herbalism tool and grew into a broader record of herbs, minerals, custom Survival trees, skinned loot, lockpicking chests and ordinary treasure chests. The map learns as you play: **it does not import an authoritative catalog of currently available spawns**.

Instead of opaque dots, the overlay uses **four small difficulty-colored corner markers**. The world map also shows the associated resource icon. Markers re-evaluate against the *current character's* skill or level, while discoveries remain available across the account.

![Saved herbs on the Tanaris world map](Screenshots/world-map-tanaris.png)

## What is recorded

| Resource kind | How it is learned | How color is determined | When it is visible |
| --- | --- | --- | --- |
| **Herbs** | Gather completion or recognized loot after Interact | Herbalism requirement | Current character has Herbalism |
| **Minerals** | Mining success, with some loot-to-node fallback | Mining requirement | Current character has Mining |
| **Survival trees** | Successful Woodcutting/recognized tree loot | Survival requirement | Current character has Survival |
| **Skinning** | Looted hide/leather/scale/item after skinning; saved as an approximate hunting spot | Requirement inferred from creature level | Current character has Skinning |
| **Lockpicking chests** | Recognized locked chest interaction | Lockpicking requirement | Current character has Lockpicking |
| **Ordinary chests** | Recognized world chest interaction | Known chest tier compared with character level | All characters |

The code associates a resource with a zone, subzone, map position, type, requirement where known, icon where available, and occurrence count. The main database is **account-wide**, but profession filtering and colors adapt to each character. **Skinning markers indicate places where a creature was skinned, not guaranteed stationary spawns.**

Custom resource tooltips can supply requirements; unknown requirements produce **purple** corners instead of an invented difficulty. A few known loot-to-node mappings are deliberately cautious: Thorium Ore alone cannot reveal a small versus rich Thorium vein.

## Two map presentations


### Minimap — subtle four-corner markers

Saved locations currently in range appear as four colored corners, with a hover label. The minimap visualization uses coordinates, zoom state, estimated scaling and custom-zone dimensions to position markers.

![Minimap marker and tooltip](Screenshots/minimap-tooltip.png)

### World map — resource icons plus corners

When you open a specific **zone** on the world map, saved locations appear with their matching resource icon and corner dots. The **Gather Map** checkbox near the upper-left of the map toggles this overlay separately from the minimap. It remembers that setting.

![Merged resource markers](Screenshots/world-map-merged-markers.png)

Nearby markers for the **same resource kind and name** merge if their marker bounds overlap. Their four corner dots expand to the outside of the combined rectangle. Different resources do **not** merge. The rendering code caps each map at **300 displayed marker groups**; this is a display cap, **not a cap on saved discoveries**.

### Difficulty colors

| Color | Profession requirement compared with current skill |
| --- | --- |
| Red | Skill below the requirement |
| Orange | Skill meets the requirement, up to 24 points above |
| Yellow | 25–49 above |
| Green | 50–99 above |
| Gray | 100+ above |
| Purple | Requirement unknown |

For ordinary treasure, the algorithm compares the **chest tier to player level**, not profession skill: red at 6+ levels above; orange 3–5 above; yellow from 2 below through 2 above; green 3–9 below; gray 10+ below; unknown purple. Gray has **85% opacity**, the other categories 100%.

## Commands

| Command | Behavior |
| --- | --- |
| `/gathermap`, `/gathermap count`, `/gathermap status` | Show saved counts by type, profession skills and current zone support |
| `/gmap` | Alias for the same slash command family |
| `/gathermap on` or `show` | Show **minimap** markers |
| `/gathermap off` or `hide` | Hide **minimap** markers but continue recording discoveries |
| World-map **Gather Map** checkbox | Independently show/hide the **world-map** overlay |

The two visibility choices live in `GatherMapDB.enabled` and `GatherMapDB.worldMapEnabled`. Turning off minimap pins does **not** stop gathering or necessarily hide world-map pins.

## Install

1. Copy the project folder to `World of Warcraft/Interface/AddOns/GatherMap/`. Place `GatherMap.lua`, `GatherMap.toc` and `Icons/` inside that folder together.
2. Restart WoW, enable **Gather Map**, and use **Load out of date AddOns** if your particular 1.12-compatible client requires it.
3. Gather a recognized resource successfully, then run `/gmap count` and check the minimap/world map for the learned point.
4. Optionally install [Interact](https://github.com/lookino/Interact) for its hotkey behavior; Gather Map does **not require** it.

**Compatibility:** The TOC declares interface **11200**. The source includes additional outdoor/event map sizes for named custom zones; that is not proof every third-party 1.12 client has been verified. Several event strings, profession names, resource names and tooltip patterns are in English; **full localized-client support has not been demonstrated**.

## Supported custom maps

The current `customZoneSize` table contains **15** names: Hyjal, Scarlet Enclave, Lapidis Isle, Gillijim's Isle, Tel'Abim, Alah'Thalas, Gilneas, Icepoint Rock, Blackstone Island, Thalassian Highlands, Winter Veil Vale, Grim Reaches, Balor, Northwind and Moonwhisper Coast. The source has aliases including “Mount Hyjal” and “Island of Lapidis.” Subareas belonging to an existing Vanilla map may reuse their parent map's scaling.

A zone's presence in the table only establishes a **configured dimension**, not confirmed correct minimap alignment on every custom client.

![Markers in the custom Grim Reaches zone](Screenshots/world-map-grim-reaches.png)

## Upgrade if you used the old name

This project was originally named **Octo Gather**. Renaming the folder and saved-variable name does **not automatically migrate** old `OctoGatherDB` data into `GatherMapDB`.

With WoW **fully closed**, install `GatherMap` beside the old addon, open PowerShell in the new addon folder, and run the supplied migration helper with paths you supply:

```powershell
.\Upgrade-SavedData.ps1 -ClientPath "C:\Games\World of Warcraft" -PreviousAddonName "OctoGather"
```

The helper reads the old/new TOC declarations, scans saved-variable files, backs up sources in `AddonUpgradeBackups`, copies converted files to the new name, refuses existing destination files, and **does not execute saved Lua**. It leaves the original files in place. Disable the old addon, check the migrated data and retain the backups. The helper's contents were reviewed, but **it was not executed in this session**.

For non-Windows setups the older README includes a manual migration approach: back up your WTF SavedVariables first; copy old named SavedVariables files to the new name and change **only the top-level declaration** from the old TOC variable to `GatherMapDB`. Do not do this with WoW running.

For ordinary updates **without a folder/name change**, standard WoW SavedVariables persistence applies.

## How reliable is the data?

This is a **personal discovery record**, not a live-world sensing system. WoW's existing tracking dots may show a resource is currently spawned; Gather Map records places previously encountered. A failed cast should not create a node, but correctness depends on game event text, loot timing, tooltip availability and position APIs. The source contains debouncing and pending-state handling to reduce duplicates; these need client-level verification.

The current code polls map updates at approximately **0.10 seconds**, merges markers, and uses an upper display limit of 300 groups per map. Large saved databases, many custom zones, localized clients and interaction-hook load orders merit performance and compatibility tests.

The repo includes two regression-test scripts, **not an all-encompassing automated test suite**:
- `tests/test_interact_hook.py`: tests recursive Interact-hook behavior with **lupa / Lua 5.1** fixture code, not a live Vanilla client.
- `tests/test_upgrade.ps1`: tests migration from a synthetic previous addon name using temporary fixture directories.

Neither was executed during the 2026-10-26 documentation pass.

## Attribution and third-party source materials

The project **credits its creator Babuni.dev**. It also explicitly acknowledges:
- [Gatherer (Vanilla)](https://github.com/jsb/Gatherer) for coordinate scaling and bundled herb art.
- [MetaHunt](https://github.com/DuvelCorp/MetaHunt) for Grim Reaches map dimensions.
- [Interact](https://github.com/lookino/Interact) as an **optional** interoperability target, not a required embedded dependency.

These contributions must stay credited. The current repository tree has **no LICENSE file**. Public GitHub visibility and upstream asset credits do not by themselves establish permission to reuse all code or art; resolve licensing/provenance before packaging or redistributing third-party files.

## Project-development documentation

- [Concept](CONCEPT.md) · [Roadmap](ROADMAP.md) · [Changelog](CHANGELOG.md)
- [Architecture](docs/ARCHITECTURE.md) · [Interaction design](docs/DESIGN.md) · [Content and asset structure](docs/CONTENT.md)
- [Design decisions](docs/DECISIONS.md) · [Narrative development journal](docs/DEVLOG.md)
- [Human–AI collaboration](docs/AI_COLLABORATION.md) · [Developer/AI instructions](AGENTS.md)
