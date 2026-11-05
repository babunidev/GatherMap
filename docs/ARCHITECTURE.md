# GatherMap — technical architecture

**Source audited:** `GatherMap.lua` (1,237 lines), `GatherMap.toc`, saved-data helper and tests, October 26, 2026. **Static code review, not client execution.**

## Status of this architecture

This document describes the **preserved legacy 1.12 implementation** in `GatherMap.lua` and `GatherMap.toc`, version 0.4.3, not a tested Forever runtime. New development targets **Forever only** and must replace the old map, skill and cast/event integrations after independent client/API verification. The current code is the functional specification for intended behavior, not proof of compatibility. See [FOREVER_PORT.md](FOREVER_PORT.md).

## Forever compatibility shell (unreleased, November 4, 2026)

The new `GatherMap_Camelot.toc` loads `GatherMapData.lua` (inherited resource lookup tables and icon references), `GatherMapDifficulty.lua` (modern character-aware thresholds), `GatherMapWorldPins.xml` (virtual native map pin template), then `GatherMapForever.lua` (Forever map runtime). The old `GatherMap.lua` and `GatherMap.toc` remain unchanged for provenance.

- **Map:** `C_Map.GetBestMapForUnit` and `C_Map.GetMapInfo` identify zone `UiMapID`; `C_Map.GetPlayerMapPosition` and `GetWorldPosFromMapPos` provide normalized and world positions. Only `GatherMapDB.nodes["map:" .. UiMapID]` renders; legacy keys are retained without interpretation. Minimap locations use `C_Minimap.GetViewRadius` and player-facing rotation.
- **Skills:** `GatherMapDifficulty.lua` reads `C_SkillInfo` skills and modifiers (with `C_TradeSkillUI` fallback), uses 37 community-documented resource tables, and leaves unknown thresholds purple. No Survival skill is assumed. Live values are unverified.
- **Map UI:** Native `MapCanvasDataProviderMixin` and `MapCanvasPinMixin` create world-map pins; pooled minimap frames draw four 3px colored corners. Same-resource-only transitive merging is retained. The world-map checkbox and `/gmap on/off` remain independent. The hover pass avoids taking native map mouse clicks.
- **Events:** Frame callbacks explicitly accept `(self, event, ...)`. `ADDON_LOADED`, `PLAYER_ENTERING_WORLD`, map/zone events and skill/equipment/aura/level events trigger refresh. A throttled minimap update handles player movement; the former periodic skill scan was removed.
- **Recording at the Phase 2 checkpoint:** The compatibility shell itself has no gathering hooks or Interact wrapping. Phase 3 adds a **separate, opt-in** recording module, `GatherMapCapture.lua`, which is disabled by default until in-game verification. `/gmap testpin` remains an unsaved presentation fixture; no legacy records are deleted or rewritten.
- **Restrictions:** Avoids opening player/map panels programmatically, defers map-provider creation while in combat and skips combat redraw. Exact event behavior, pin pooling and map alignment are still unverified inside Forever.

Static test: `python3 -m unittest discover -s tests -p 'test_forever_*.py'`; syntax: `luac -p GatherMapData.lua GatherMapForever.lua` where installed. Passing mock/static tests does not prove the overlay works in-game.

## November 5 — 16×16 difficulty image assets on four corners

`GatherMapForever.lua` now maps `red`, `orange`, `yellow`, `green`, `gray`, `unknown` (purple) to six local texture files under `Interface\\AddOns\\GatherMap\\Textures\\Markers\\marker_*.tga`. The images originate from Babuni-directed AI generation, cropped and resized to **16×16 uncompressed RGBA TGA**. Each of the four corner Texture regions uses `SetTexture(path)` and a **6×6 UI-unit size**. The same `AddCorners` and `Style` paths apply to minimap and native world-map pins, with the old flat `SetColorTexture` no longer used for those corner textures.

The parent group frame, world anchoring, pooled identities, transitive merging, per-frame movement, private hover and saved-node schema are unchanged; gray still receives 85% parent alpha. New assets are **referenced at runtime**, not declared in the TOC. The stdlib package check requires all six files to be valid 32-bit 16×16 TGA files and includes them in the optional development-only installable bundle; mock tests check that all six classes map to exact asset paths.

Image rasterization remains client-dependent, and four separate textures still have distinct pixel positions. This is a visual experiment, not a verified cure for all movement flicker. Neither historical Gatherer herb icons nor existing third-party notices were changed.

## November 5 — stable frame ownership, corner rendering and combat update

After world-space grouping was implemented, actual Forever reports still showed shape flipping and movement errors. The remaining problems were frame **ownership**, not just the grouping algorithm: the previous `AcquireMini(count)` reused an existing frame based on the group's **position in the visible array**, and `Style` reset frame size and corners every 0.35 seconds, potentially for a different saved group. The other proven defect was the direct `InCombatLockdown` return in `TrackMiniPositions` and `DrawMinimap`.

`miniPins` is now an owned, bounded frame pool. Each cached group maintains a temporary `group.pin` link, while the frame maintains `pin.group`. The slow pass selects visible groups and marks their generation, releases only group/frame pairs absent from that generation, and assigns free frames only to new visible groups. Persistent pairs are not resized, recolored or re-created on routine updates. `activeMiniPins` lists currently displayed frames, and both hover and per-frame positioning use that list. There are still at most 300 active minimap groups, and saved records are never modified.

The minimap's unprotected frame positions continue updating in combat, based on its current player/world location. Client map/position/radius unavailability now hides stale frames, invalidates the transient view and schedules a later rebuild; it does not allow pins to move along with the player at the last offset. The **native world-map** provider, lazy UI setup and protected map-canvas calls retain their combat guards. The 3px corner textures may opt out of pixel-grid snapping to avoid edges independently shifting at fractional offsets; the grouped rectangle dimensions remain unchanged for each assigned group.

See [comparative minimap source research](FOREVER_MINIMAP_RESEARCH.md) for Forever's native tracking blips, GatherMate2 pin identity/movement, ForeverPlusPlus drawing and historical Gatherer's offset method. No third-party implementation was copied. Unit/mock tests test combat updates and frame identity; actual client taint, secure restrictions, FPS and visual behavior remain unverified.

## November 5 — stable group identity between minimap redraws

The user-reported half-second rectangle/square flicker exposed a second flaw after per-frame positioning was added: `DrawMinimap` still grouped **only nodes passing `MiniPoint` visibility clipping** at the character's current position. When one of two nearby resources crossed the view boundary, the next 0.35-second pass silently changed the group bounds from a merged rectangle to a single square. This also changed its center and caused a periodic snap independent of the per-frame tracking rate.

The corrected layout projects all valid visible-to-profession nodes of the current map into a **fixed, north-up world coordinate plane** at the current minimap world-unit scale. `GatherMapMarkers.Group` performs the original transitive same-kind/name overlap there, independent of the player, minimap position or rotation. The resulting groups store stable world-space centers, dimensions and source ordering. `miniGroups` caches this layout by map, instance, source table, radius, canvas dimensions and render revision. Large layouts use `GatherMapSpatial.BuildGroups` to index cached world centers; `spatial.Nearby` finds candidates at slow intervals, with deterministic original ordering and a 300 displayed-group cap.

`DrawMinimap` now **only assigns visible cached groups** to frame-pool entries, and `TrackMiniPositions` continues to move those same frames every game frame using the fixed centers. Viewport clipping no longer removes group members or recomputes group shapes. Explicit changes to source nodes, profession colors, zone/instance, minimap zoom/size or cache revision still rebuild layout as appropriate. This uses additional linear memory and grouping work on a change rather than repeated regrouping on every walk update. Since grouping uses the stationary north-up plane, rectangles retain their own dimensions while the player rotates; actual visual fidelity with rotated world maps requires a Forever client check.

The 0.35-second grouping pass described below is an **obsolete historical implementation detail**, superseded by this stationary layout. No saved data or native quest overlays are modified.

## November 5 — frame-rate minimap positioning over cached resource groups

The first live movement report showed world-fixed markers advancing in small jumps instead of keeping pace with the minimap. The source cause is likely the previous `DrawMinimap` path: it projected every displayed group only at the 0.35-second throttled redraw, even though the character position can change each frame.

`DrawMinimap` continues to perform expensive spatial candidate lookup, same-kind/name transitive grouping, color selection and frame-pool assignment at its normal throttled rate. Each visible group's screen-space center is converted back to a **fixed world-space anchor** using the pure `GatherMapMarkers.MiniWorldAnchor` helper and the grouping pass's player position, minimap radius, size and rotation. `TrackMiniPositions` runs during `OnUpdate`, reads the current player's position on the cached `UiMapID`, and moves only already-visible pooled frames with `markers.MiniPoint`. No node positions are changed or stored in `GatherMapDB`; original marker dimensions/color are retained. If a node leaves the viewport it is hidden until it returns or the next grouping pass assigns a new candidate. Changed zoom/dimensions/position failures request a full redraw; the main grouping pass still controls new arrivals.

Tests require visible pins to move after a 0.016-second frame while the group-counter stays unchanged, confirm inverse projection for rotated and non-square maps, and handle rotation-ignore mode. No extrapolation, lerping or raw-event polling was added. This is a **game-frame position update**, not a game-tested FPS claim; engine position resolution, restrictions and actual UI behavior still need Forever verification.

## November 5 — world-pin taint fix and anchored minimap markers

The Forever client reported `ADDON_ACTION_BLOCKED` for `Frame:SetPassThroughButtons()`. Blizzard's native `MapCanvasMixin:AcquirePin` invokes `pin:CheckMouseButtonPassthrough("RightButton")` even for a custom non-clickable frame. The inherited `MapCanvasPinMixin:CheckMouseButtonPassthrough` clears and sets passthrough using the protected C API. `GatherMapForeverWorldPinMixin` now defines a local no-op override because the XML template already specifies `enableMouse="false"`. `OnLoad` no longer redundantly calls potentially protected `EnableMouse(false)`. This leaves global Blizzard/other-addons' map mixins unchanged.

`GatherMapMarkers.MiniPoint` projects fixed world deltas into minimap offsets. The map's rotation is the inverse of counterclockwise `GetPlayerFacing()`, so it uses `sx' = sx cos(f) + sy sin(f)` and `sy' = -sx sin(f) + sy cos(f)`. `C_Minimap.IsRotateMinimapIgnored()` suppresses projection rotation if the client itself ignores it. Existing node/world-position caching uses the saved node's fixed map coordinates, not the player's position; only the camera center updates. `/gmap pinpos` reports the immutable temporary pin coordinates and current relative world displacement.

Lua fixtures now force a failure if GatherMap inherits the protected passthrough callback, or tries changing mouse state during pin `OnLoad`; simulated character walking must change the pin's minimap offset and eventually hide it beyond the minimap radius. Actual gameplay, map layering and camera transformations remain unverified.

## November 5 — settings menu and experimental capture diagnostics

The Forever runtime defines a single world-map **GatherMap** button and a lazily accessed settings panel with four independent rows. `GatherMapDB.enabled` controls minimap markers, `GatherMapDB.worldMapEnabled` controls world-map markers, `GatherMapDB.recordingEnabled` enables confirmed gathering capture, and `GatherMapDB.captureDebug` enables optional diagnostic chat. The first three keys already existed; `captureDebug` is additive and defaults false. Panels are parented to `WorldMapFrame` and only the small controls accept clicks; world-map resource pins remain passive.

`GatherMapCapture.lua` explicitly classifies known Forever spell IDs 1235236 (herb) and 1235230 (mining) alongside historical spell IDs. A recognized cast must still succeed, then correlate a loot GUID to the appropriate source type before `GatherMapRecord` is invoked. A second attempt on `LOOT_OPENED` handles loot-slot data absent on `LOOT_READY` without permitting cast-start-only writes. In-memory counters record recognized cast, success, loot, source match, successful record, refusal and failure; `/gmap capture debug` reports them and the latest reason. This is **mock-verified source behavior only**, not evidence of actual Forever event ordering or on-client resource recording.

## Forever installable layout and migration proof (development review)

The Camelot manifest loads `GatherMapData.lua`, `GatherMapMarkers.lua`, `GatherMapSpatial.lua`, `GatherMapDifficulty.lua`, `GatherMapMigration.lua`, **`GatherMapForever.lua` then `GatherMapWorldPins.xml`**, and `GatherMapCapture.lua`. Defining `GatherMapForeverWorldPinMixin` before the XML is required for the template's `mixin` reference. `tools/check_forever_package.py` verifies this order and builds an optional local ZIP whose `GatherMap/` directory includes the Camelot TOC, its referenced Lua/XML files and the 29 inherited herb icons—never the legacy 1.12 runtime or TOC.

The modern `C_Map.GetWorldPosFromMapPos` requires a Vector2DMixin; when `CreateVector2D` is absent, the renderer skips the projection rather than passing a speculative plain table. The Forever UI-source snapshot documents the required APIs; the user's exact client build and real map behavior still require verification.

For historical SavedVariables, `migrationLinks` only establishes a same-name zone candidate; `migrationGeometryChecks` stores **two or more independent observed coordinate anchors** with the original source coordinates and active client build. `Migration.Apply` refuses any link lacking two points at least 10% of the normalized map apart and each within 1.5% on both axes of observed in-game positions. Stored evidence becomes invalid when the client build changes or old source positions no longer match. This check is a conservative threshold, not a proven whole-zone transform. Legacy data remains unchanged; the external physical backup is still mandatory.

## Forever presentation caching and robustness (Phase 7, source implementation)

The minimap retains its 0.35-second bounded view check, but no longer traverses every saved node to build visible groups on every movement update in larger zones. `GatherMapSpatial.lua` projects eligible saved locations into an instance-keyed world-coordinate grid once per map/data revision (index threshold: 128 records). Subsequent player-position updates visit nearby cells and do exact radius checks. Invalid record coordinates are skipped in-memory, never removed from `GatherMapDB`; missing map-projection APIs leave the overlay hidden until usable positions return.

`MarkDirty` invalidates the data index, transient preview and world presentation cache on capture/migration. `MarkStyleDirty` invalidates only the presentation for profession/level/zone display changes, preserving the spatial index. The current view cache skips grouping when minimap map/position/radius/dimensions/rotation and revision are identical. World-map groups are cached by map ID, source, scale, canvas size and revision; 300 is the number of cached/rendered groups, not a storage cap. The world-map provider only removes its own pin template. The minimap frame pool tracks visible pins for hit testing and rendering, while map provider retries are bounded at two seconds if lazy Blizzard UI dependencies are missing.

The pure `GatherMapMarkers.lua` grouper preserves transitive 14px overlap for identical names and kinds. All points in one cell are connected through one representative; neighboring cells need one overlapping edge. This reduces comparisons with densely repeated resource entries while preserving marker bounds, priority colors and rendering identity.

`tests/test_forever_performance.lua` stresses 24,000 synthetic locations and 12,000 overlapping points; `tests/test_forever_display.lua` verifies simulated foreign-provider coexistence, missing APIs and corrupted entries. This validates controlled source behavior only. Actual allocations, frame timing, memory and compatibility with installed Forever addons must be measured in game.

## Forever legacy migration (Phase 6, source implementation)

`GatherMapMigration.lua` is the account-wide historical import boundary, loaded before `GatherMapForever.lua`. It operates only on the existing `GatherMapDB.nodes` table, preserving original `continent:zone` locations. `Migration.Link` requires a homogeneous legacy zoneName and a matching current `C_Map.GetMapInfo` zone map (`mapType == 3`) before storing a proposed modern UiMapID link. `Migration.Preview` produces a dry-run summary. `Migration.Apply(key, "confirm")` copies into `map:<UiMapID>` only after explicit confirmation, without touching the legacy key.

The schema source version is `legacySchemaVersion or version or 1`. An existing old SavedVariables table lacking a `version` field remains recognized as v1; new blank databases start at v3. A v1 missing kind is interpreted as herb on copies, v2 Skinning copies discard unreliable required values, and v3 values stay intact. Identical kind/name nodes within 0.004 normalized coordinates merge by occurrence-weighted centroid and count; different kinds/names never merge. Only eligible flat numeric-map keys are considered; malformed records and uncertain names remain in the original history.

Every application captures a source and before/after destination snapshot in `migrationBackups`, records `migrationLedger` to stop duplicate imports, and notifies the overlay renderer. Guarded rollback checks the current history and destination against immutable snapshots; if any later gathering changes them, it refuses to discard those discoveries. The snapshots are themselves stored in the same SavedVariables file, so an **independent filesystem backup remains essential**. `Backup-GatherMap.ps1` copies files while the game is closed; `Upgrade-SavedData.ps1` handles only the historical OctoGather folder/variable rename.

The map identity check is a **conservative candidate validation**, not evidence that old and Forever normalized map coordinates align. In-game checks of geography, save/reload and multiple characters remain outstanding.

## Forever map presentation (Phase 5, source implementation)

- `GatherMapMarkers.lua`: independent spatial grouping and pixel projection. A 14px resource hit rectangle is associated only with the same `kind` and `name`; a 14px grid and union-find combine any transitive overlap without changing account-wide saved node entries. Priority follows the existing color table. Group display is capped at 300 frames per map; database storage is not capped.
- Minimap: pooled mouse-disabled frames draw four 3px corner textures, gray at alpha 0.85. `C_Map` world positions are projected through `C_Minimap.GetViewRadius()`, facing and the minimap width/height, rejecting off-map/invalid positions. Cached unchanged view/data revisions skip expensive regrouping. Moves/zooms are redrawn at about 0.35 seconds, independently of hover.
- World map: an ordinary `MapCanvasDataProviderMixin` drives a virtual `MapCanvasPinMixin` template. The marker's center is normalized to `map:GetCanvas()`; grouping is measured in canvas pixels multiplied by `map:GetCanvasScale()`. MapCanvas handles pan and map changes; group recomputation on scale/size changes is deferred until the next bounded tick.
- Hover: separate, lazy-created label frame with texture border, mouse disabled, checked against visible pin bounds using each pin's effective scale. Its position refreshes approximately every 0.10 seconds without using GameTooltip, allowing normal map clicking and gathering tooltip use.
- Display preferences: `GatherMapDB.enabled` and `GatherMapDB.worldMapEnabled` remain independent. The world-map checkbox has a guaranteed visible text label and optional `/gmap world on|off` commands; neither mutates discoveries or `recordingEnabled`.
- Tests: pure marker geometry, simulated map canvas/UI scale, runtime/static assertions and Lua 5.1/5.4 compilation. These are mocked/off-client checks; no in-game fidelity or compatibility is established by passing them.

## Forever dynamic difficulty (Phase 4, source implementation)

`GatherMapDifficulty.lua` loads between the retained resource table and the Forever map runtime. It exposes `Refresh`, `Skill`, `IsVisible`, `Color` and `Reference` via the addon namespace. Profession ranks (learned state, base rank, modifier, temporary points and effective rank) stay in memory and are **not** persisted in the shared discovery database. Skill information comes from `C_SkillInfo`, with profession-specific fallback when necessary; zero/absent ranks do not make an unknown profession visible.

For herbs and minerals with Forever-specific published tables, colors use exact minimum/yellow/green/gray boundaries. Unknown or conflicting thresholds are purple rather than inferred from a legacy approximate offset; a known observed minimum may still establish red. Skinning and Lockpicking cannot be assigned full threshold color ranges without a verified model. Ordinary treasure still uses player level and chest tier, independent of gathering profession.

Skill changes, item/equipment changes, aura changes, and level changes mark the map for redraw. An additional skill-rank poll is no longer used. The existing 0.35-second minimap movement refresh is separate. All actual client behavior, including event delivery and modifiers, remains to be tested.

## Forever resource capture (unreleased, source implementation)

`GatherMapCapture.lua` is loaded **after** `GatherMapForever.lua` in the Forever manifest and communicates with it through `ns.GatherMapPosition` and `ns.GatherMapRecord`. The recorder is OFF by default, opt-in via slash command and unrelated to the optional legacy `Interact` hook.

The state machine is `UNIT_SPELLCAST_SENT` (candidate) → `UNIT_SPELLCAST_SUCCEEDED` (completed) → `LOOT_READY` (confirm matching loot source) → validated observation. A failed/interrupted cast cancels pending work; timeouts and `LOOT_CLOSED` clear context. Only GameObject GUIDs are accepted for gathering and chests; Creature GUIDs for Skinning. Skinning saves material-based hunting-location hints. The Pick Lock spell may be correlated with a later Opening for the same source during a bounded window. Named treasure checks reject generic opening of quest objects.

The writer validates map IDs, normalized positions, resource names, difficulty requirements and optional texture; deduplicates on same kind/name/map within 0.004 normalized units and a short event window. It does not modify legacy numeric continent-zone records. The live Forever client's spell/loot behavior remains unverified, and new data writes must not be enabled by default before that verification.

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
