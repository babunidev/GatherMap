# GatherMap — technical architecture

**Source audited:** `GatherMap.lua` (1,237 lines), `GatherMap.toc`, saved-data helper and tests, October 26, 2026. **Static code review, not client execution.**

## Lifecycle, events and state

```text
ADDON_LOADED (GatherMap / optional Interact)
    -> InitializeDatabase()
    -> InstallInteractHook()

PLAYER_ENTERING_WORLD
    -> InitializeDatabase(), UpdatePins(), UpdateWorldMapPins()

SPELLCAST_START / CHAT_MSG_SPELL_SELF_BUFF / SPELLCAST_STOP
    -> BeginResourceAction() / recorded successful resource text
    -> RecordNodeOnce() if valid
SPELLCAST_FAILED / SPELLCAST_INTERRUPTED
    -> ClearPending()
CHAT_MSG_LOOT
    -> classify item and capture mining/herb/wood or skinning loot
SKILL_LINES_CHANGED / MINIMAP_UPDATE_ZOOM / ZONE_CHANGED_NEW_AREA
    -> refresh minimap and world-map markers
WORLD_MAP_UPDATE
    -> refresh world-map markers

OnUpdate approximately every 0.10 seconds
    -> expire pending loot
    -> InstallInteractHook() if global changed
    -> refresh pins, world pins and hovered labels
```

The source uses Vanilla 1.12's implicit `event`, `arg1`, `this` callback conventions and Lua 5.0 compatible syntax. The TOC loads one Lua file, optional-depends on `Interact`, and initializes account-wide `GatherMapDB`.

## Categories and gathering state machine

The current `actionKinds` table maps:
- `Herb Gathering` → herb
- `Mining` → mineral
- `Skinning` → skin
- `Woodcutting` → wood
- `Opening` → treasure
- `Pick Lock` → lock

`BeginResourceAction` reads the object tooltip or target context, storing **pendingNode**, **pendingRequirement**, **pendingKind**, **pendingTexture**, pending flag, and a time window for loot arriving after an interaction. A successful self-buff/action phrase such as `You perform ... on ...` may directly name a resource; `SPELLCAST_STOP` can commit a pending node if identified. Failures clear state. Skinning awaits loot so the record can name the **actual item** received.

`InstallInteractHook` watches the optional global `Interact`, records a last-interact timestamp, and delegates to the function that existed when the wrapper was created. On later replacement it can wrap again with a **new locally captured predecessor**; a shared predecessor previously produced recursive chains. The dedicated Python/Lua fixture tries to reproduce the old recursion and exercise the current wrapper. Interact itself is not bundled.

The **Interact loot fallback** can infer herbs, ore deposits or wood through recognized looted item names. Some names are inherently ambiguous (e.g. Thorium Ore can come from different vein types), so the source uses a generic node/unknown requirement instead of falsely choosing a specific deposit.

**Locale caution:** Several action names, English chat patterns, profession strings, chest keywords and resource names are literal English. This limits assertions of universal localization support.

## Data model and deduplication

```text
GatherMapDB
├── version = 3
├── enabled = true/false         # minimap overlay only
├── worldMapEnabled = true/false # independent world map
└── nodes
    └── "<continent>:<zone>" = [
          {
            name, kind, x, y, required?,
            texture?, count, zoneName, areaName
          }, ...
       ]
```

A resource's position is read from the player's current zone map, stored as normalized map coordinates. `RecordNode` rejects absent names/positions, finds same-type+name nodes within **0.004** in both X and Y, then updates their **weighted average position and count**. Otherwise it appends a new entry. `RecordNodeOnce` also suppresses same-kind+name events within **2 seconds**. These two mechanisms differ: the first groups repeated visits spatially, the second filters repeated event emissions temporally.

The key `"<continent>:<zone>"` uses the map indices in the **currently loaded client**. Added custom maps can change indices and zone mapping; migrating SavedVariables across clients with different zone indices needs special testing. `zoneName` and `areaName` are saved alongside positions, but the current primary lookup is still the numeric key.

On init, **old database version 1** entries missing `kind` become `herb`; old **version 2** skin points retain their location but have stale `required` cleared due to earlier low-level formula error. The current version is **3**.

## Current-skill presentation

The source reads skill lines named Herbalism, Mining, Skinning, Lockpicking and Survival. `ShouldShowNode` hides profession-based markers if the current character lacks the respective skill (rank 0); treasure always shows.

Profession colors compare requirement to current rank:
- unknown → purple;
- skill below required → red;
- skill required to required+24 → orange;
- +25..+49 → yellow;
- +50..+99 → green;
- +100 and above → gray.

Treasure uses player level instead of profession: required tier minus player level ≥6 red, ≥3 orange, ≥-2 yellow, ≥-9 green, otherwise gray.

Skinning requirement inversely calculates Vanilla's level/skill rule: creature level up to 10 yields 1; levels 11–20 use `(level - 10)*10`; above 20 use `level*5`. Saved skinning points name the **looted item**, not necessarily the creature name.

## Coordinate conversion and custom maps

`GetPosition` finds the current main map zone by normalized **zone name** (`GetRealZoneText` checked against `GetMapZones`), then uses `GetPlayerMapPosition`. It may call `SetMapZoom` to resolve (0,0) position when map not visible.

`zoneScale` maps normal zone names to classic Gatherer-derived factors; `continentScale` and `minimapZoomYards` convert zoom into minimap offsets. **15** `customZoneSize` width/height pairs enable extra event/custom maps. `zoneAliases` handles spelling variants such as Mount Hyjal → Hyjal. A custom map's configured dimensions are **not automatically a live-tested compatibility guarantee**.

## Rendering and interaction

- `UpdatePins` computes minimap offsets relative to player, applies visibility and a circular minimap radius. The minimap shows **four 3px colored corner dots** per grouped hit area, with hover labels.
- `UpdateWorldMapPins` requires an open specifically selected zone, not a continent overview. It converts normalized X/Y to the `WorldMapButton` dimensions, adds game/bundled resource icon textures and four corner dots.
- `AddMarkerGroup` merges overlapping rectangles **only for identical kind + name**, and rechecks after expansion for transitive overlap. The **highest difficulty priority** wins within a merged group; different resources can overlap without merging.
- A reusable pool of frames cuts repeated creation, and `MAX_PINS=300` limits groups **rendered** on each map, not database size.
- A separate custom cursor tooltip avoids dependence on fragile old tooltip templates while the game tooltip is used for gathering recognition.
- `GatherMapDB.enabled` controls minimap only; the world-map checkbox saves `worldMapEnabled` independently. Recording continues when markers are hidden.
- Gray groups have 85% alpha; other groups full alpha. The refresh loop triggers around **10 times per second**, which may be expensive on dense maps.

## Dependencies and migration helper

`GatherMap.toc` declares `OptionalDeps: Interact`; `Interact` is not required. Bundled `Icons/Herb*.tga` (29 files) are credited to [Gatherer](https://github.com/jsb/Gatherer) alongside minimap scaling. Grim Reaches map data is credited to [MetaHunt](https://github.com/DuvelCorp/MetaHunt).

`Upgrade-SavedData.ps1` supports renaming SavedVariables after the transition from **OctoGatherDB** to **GatherMapDB**. It checks that WoW is closed, limits addon-name input, reads old/new TOCs, backs up discovered SavedVariables, refuses overwrites and rewrites only top-level assignments in the copied text without executing Lua. This is separate from in-addon schema migration.

Two fixture tests are committed. `tests/test_interact_hook.py` requires **lupa/Lua 5.1**; `tests/test_upgrade.ps1` runs on PowerShell. Neither is evidence of client correctness absent execution logs.

**No actual game testing or helper execution occurred in this documentation-only review.**
