# GatherMap

**World of Warcraft Forever only — unreleased development port.** GatherMap remembers resources a character has actually gathered and displays personal discoveries as small, difficulty-colored **four-corner markers** on the minimap and world map. Discoveries are shared between characters on the account; profession skills and marker colors are calculated for the current character. GatherMap is not a live-spawn radar or an imported resource catalog.

**Creative direction:** Babuni. **Target:** Forever 1.60.1, Interface `16001` (verify the actual installed build). **Development version:** `0.5.0-alpha`. **SavedVariables:** `GatherMapDB`. **Development branch:** [`feat/forever-port`](https://github.com/babunidev/GatherMap/tree/feat/forever-port). **Published release:** historical `v0.4.3` only; no public Forever release has been authorized.

> **Verification status:** Lua 5.1/5.4 compilation, static checks, mocked API/UI behavior, large-node stress tests and backup fixtures pass in GitHub Actions. No gathering, map placement, migration, actual performance or addon coexistence has been verified **inside the Forever client**. Recording remains **disabled by default**.

## Install the development build — not for public distribution

1. Find the actual Forever client's `Interface/AddOns/` folder. The beta used `_classic_beta_`; current public guides report `_forever_` for the launch client, but **use the folder belonging to the client you actually launch**, especially on Linux/Wine. Close Forever before installing new addon files.
2. From the `feat/forever-port` source checkout, run `python3 tools/check_forever_package.py` to audit the manifest and runtime dependencies. Optionally create a **local development-only ZIP** with `python3 tools/check_forever_package.py --output /tmp/GatherMap-forever-dev.zip`.
3. Extract the generated ZIP into the client's `Interface/AddOns/`. The resulting folder must be exactly `Interface/AddOns/GatherMap/` with `GatherMap_Camelot.toc`, the Lua/XML files listed by that manifest, and `Icons/`. **Do not** install a second nested `GatherMap/GatherMap` folder.
4. Start Forever with GatherMap enabled in the AddOns list. Check `/dump GetBuildInfo()`, enable error reporting with `/console scriptErrors 1`, then run `/gmap status`.
5. Preserve an external backup of `WTF` before testing saved data. The local ZIP is only a reproducible development artifact; artwork redistribution/first-party licensing is **not fully resolved** and it must not be uploaded as a public release.

The historical `GatherMap.toc` (`Interface: 11200`) and `GatherMap.lua` remain in Git for provenance. They are **not** part of the Forever package and are never loaded by its Camelot manifest. See [legacy instructions](docs/LEGACY_0_4_3.md).

## Implemented in source

- **Discovery:** Experimental confirmation of herbs, ore, skinning materials/hunting locations, normal treasure and lockpicking using recognized cast success plus matching loot sources. Forever-specific gathering spell IDs `1235236` (Herb Gathering) and `1235230` (Mining) are explicitly recognized alongside legacy IDs, and confirmed loot can be retried on `LOOT_OPENED` when not ready on `LOOT_READY`. Interrupted, unrelated and duplicate actions are rejected. Survival/Woodcutting history is retained, but no current Forever recording mechanic has been established.
- **Display:** Four 3px colored corners, world-map resource icons and passive hover labels. Markers merge transitively only for matching resource type and name. Display is limited to 300 **groups**, not 300 saved nodes.
- **Difficulty:** Red, orange, yellow, green, gray and unknown purple. Documented Forever-specific thresholds exist for 28 herbs and 9 ore nodes; missing thresholds remain purple. Effective profession skill includes bonuses; ordinary chest difficulty uses player level. Shared records produce different colors for different characters.
- **Performance:** Event-aware redraws, reusable minimap frames, grouped world-map pins and a spatial index for larger saved zone databases.
- **Historical data:** Raw schema-v1/v2/v3 and old `continent:zone` entries are preserved. An opt-in importer supports explicit mapping, preview, two real-world coordinate anchors, before/after snapshots and guarded rollback; no automatic historical zone conversion occurs.

## Map settings button

Open the world map and click **GatherMap** in the upper-left map area. A small panel opens with independent switches for **Minimap markers**, **World-map markers**, **Record discoveries**, and **Diagnostic chat**. The old checkbox has been removed. Recording remains **OFF by default**, even when both marker displays are visible. Switch it on explicitly before gathering; saved discoveries do not depend on the panel remaining open.

The last capture result appears at the bottom of the panel. For more detailed rejection counts, use `/gmap capture debug`; opt-in diagnostic messages can be enabled from the panel or `/gmap capture debug on`. Disable them afterward to avoid chat noise.

## Commands

| Command | Purpose |
| --- | --- |
| `/gmap status` | Current skills, saved-data status and recording policy |
| `/gmap on` / `/gmap off` | Enable/disable **minimap** markers only |
| `/gmap world on` / `/gmap world off` | Enable/disable **world-map** markers only; world-map settings are also available through the GatherMap button |
| `/gmap testpin` / `/gmap clear` | Show/remove a temporary unsaved test marker |
| `/gmap menu` | Open or close the same settings panel while the world map is visible |
| `/gmap capture status` | Show recording policy |
| `/gmap capture on` / `/gmap capture off` | Explicitly enable/disable **experimental** recording |
| `/gmap capture debug` | Show cast/loot/source-match/save/refusal counters and last outcome |
| `/gmap capture debug on` / `off` | Enable/disable opt-in diagnostic chat |
| `/gmap migrate status` | Inspect historical zone counts |
| `/gmap migrate link <old-key>` | Link a historical zone to the **current** Forever zone only when labels agree |
| `/gmap migrate anchor <old-key> <node-index>` | Check one historical point against the character's **actual current** Forever location |
| `/gmap migrate preview <old-key>` | Dry-run counts and coordinate evidence; **does not copy** |
| `/gmap migrate apply <old-key> confirm` | Copy only after two distant anchors on the same build, a preview and a physical backup |
| `/gmap migrate rollback <old-key>` | Restore a snapshot only when no later discovery would be lost |

**Migration is intentionally conservative:** A matching zone name is insufficient. Two historical anchor locations, each within 1.5% on both normalized axes and separated by at least 10% of the map, are required on the same client build before applying. The requirement is necessary but does **not** prove every spot in that zone aligns.

## Testing, safety and project history

- [Reproducible in-game test plan](docs/TEST_PLAN.md) — expected outcomes, error diagnostics, backup/reload, multiple characters and other addons.
- [Current development roadmap](ROADMAP.md) — remaining tasks, with all live-client tests in a separate category.
- [Forever API verification](docs/FOREVER_API_AUDIT.md) — source-confirmed methods/events versus unverified game behavior.
- [Architecture and migration design](docs/FOREVER_PORT.md).
- [Attribution and asset rights](docs/THIRD_PARTY_ASSETS.md) — 29 inherited icons match historical Gatherer files; licensing still requires review.
- [Concept](CONCEPT.md), [Changelog](CHANGELOG.md) and [Development journal](docs/DEVLOG.md).

The project originates in Babuni's creative direction. Historical Gatherer/MapNotes and MetaHunt contributions retain attribution. Source portability, API declarations, synthetic performance and static CI are **not** evidence of successful Forever gameplay. Do not distribute a public package or publish a tag until the applicable rights, release settings and in-game verification are confirmed and a specific public version is approved.
