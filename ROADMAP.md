# GatherMap — Forever development roadmap

**Target:** World of Warcraft Forever exclusively. **Development:** `feat/forever-port`, `0.5.0-alpha` / Interface `16001`. **Last review:** November 4, 2026. Historical releases and legacy source are preserved, not actively supported.

`[x]` means implemented or verified in the **source/automated environment**, **not** in-game; each live-client verification remains separately unchecked. The detailed former roadmap is retained in [the roadmap history archive](docs/ROADMAP_ARCHIVE_2026-11-04.md).

## 1. Implemented development phases

- [x] Repository/history preparation, Forever-only development branch and source preservation.
- [x] New Camelot manifest, modern skill/map/event compatibility shell, and native MapCanvas provider source.
- [x] Opt-in herb/mineral/skinning/treasure/lock recorder with cast-success and loot-source correlation.
- [x] Current-character dynamic difficulty with 37 documented resource threshold tables, unknown purple, level-based treasure.
- [x] Four-corner minimap/world-map markers, world icons, hover and independent saved visibility settings.
- [x] Explicit, non-destructive legacy zone migration with snapshots and guarded rollback.
- [x] Spatial indexing, pooled marker frames, event-aware rendering and large synthetic regression fixtures.
- [x] Lua 5.1/5.4 syntax and mock/fixture checks in GitHub Actions.

### November 5 — repeated in-game minimap glitch: frame ownership and combat

- [x] Trace the **combat-only freeze** to explicit `InCombatLockdown()` returns inside both minimap render paths; keep the world-map protected guard, but continue updating GatherMap's own non-secure minimap frames during combat.
- [x] Trace recurring visual changes to the use of `AcquireMini(count)`: the frame at an ordinal list position was repeatedly assigned a different visible group and restyled/resized.
- [x] Keep a marker frame assigned to its resource-group identity for as long as that group is visible; release frames only when their group leaves the view.
- [x] Avoid redundant `SetSize`, color updates, and clear/reanchor operations during unchanged per-frame and slow redraws; opt out of independently snapped 3px corner textures.
- [x] Review [historical Gatherer, GatherMate2, ForeverPlusPlus and Forever's minimap tracking declarations](docs/FOREVER_MINIMAP_RESEARCH.md). The native gold dots are drawn by the client and expose no documented arbitrary-saved-node pin API.
- [x] Add combat-movement regression and surviving-frame ownership/size assertions during other nodes entering and leaving view; keep previous viewport grouping tests.
- [ ] **In-game:** confirm pinned groups stay in position **during combat**, while walking and turning, not merely snap back afterward.
- [ ] **In-game:** check whether four-corner marker shape, size and position remain stable when other groups enter/leave view, at several zoom/UI scales and with custom minimaps.
- [ ] **In-game:** if any residual jump persists, capture the Forever build, rotation, `/gmap pinpos`, and compare the native blip to marker movement to identify position API update delay.

### November 5 — stable minimap shapes and regrouping fix

- [x] Diagnose the reported half-second square/rectangle change: screen-space groups were rebuilt from individually clipped nodes as the player moved, so membership, size and center changed at the 0.35-second boundary.
- [x] Build same-name/kind transitive groups once per map/data/zoom/style revision in a fixed world-coordinate plane; preserve rectangle bounds and group identity across character movement.
- [x] Index stable group centers for large databases and query only nearby groups at the view refresh; reuse pooled frames and per-frame position tracking.
- [x] Add a regression that crosses the exact viewport boundary where a two-node merged rectangle previously shrank to a single 14px square.
- [x] [Lua 5.1/5.4 and complete mock/fixture checks passed](https://github.com/babunidev/GatherMap/actions/runs/41967656417), including repeated 0.35-second boundary transitions and cached-group indexing.
- [ ] **In-game:** confirm no rectangle/square flip or periodic snap while walking, turning or approaching the edge of the minimap.
- [ ] **In-game:** verify overlapping group bounds on rotating/non-square minimaps and confirm large groups are not visually oversized.
- [ ] **In-game:** profile cache rebuilding at zoom/style/data changes and long travel, including frame behavior in combat.

### November 5 — minimap marker smoothness

- [x] Identify coarse 0.35-second marker repositioning as a likely cause of the reported movement lag, distinct from Blizzard's normal overlapping quest-objective icon.
- [x] Keep resource search/merging on the throttled interval, but cache fixed world-space group centers and update existing minimap marker positions on individual game frames.
- [x] Honor current rotation, rotation-ignore and minimap view radius, hiding out-of-range pins without changing their stored coordinates.
- [x] Add sub-0.35-second movement, rotation, grouping-budget and fixed-world-anchor regression tests.
- [ ] **In-game:** confirm markers travel continuously relative to player position while walking, turning, changing zoom and UI scale.
- [ ] **In-game:** compare performance for dense zones, during combat and after adding a new resource; check for residual 0.35-second jumps or stale pins.

### November 5 — blocked world-map action and moving test marker

- [x] Trace the reported `ADDON_ACTION_BLOCKED Frame:SetPassThroughButtons()` to Blizzard `MapCanvasMixin:AcquirePin` invoking the inherited passthrough callback.
- [x] Override passthrough handling only on GatherMap's mouse-disabled pin template; rely on XML to disable mouse input instead of calling `EnableMouse(false)` at runtime.
- [x] Correct counterclockwise-facing minimap rotation and respect the client's minimap rotation-ignore setting.
- [x] Add regression tests that intentionally make the inherited passthrough method fail, simulate walking away from a fixed `/gmap testpin` marker and check it disappears beyond range.
- [x] Verify the dedicated fix branch through [successful Lua/PowerShell/static CI run 41963074092](https://github.com/babunidev/GatherMap/actions/runs/41963074092); no in-game resolution claim.
- [x] Add `/gmap pinpos` for opt-in saved-vs-current position diagnostics; no saved discovery modification.
- [ ] **In-game:** confirm the blocked-action error no longer appears opening, zooming, panning or closing the world map, including in combat.
- [ ] **In-game:** verify the temporary marker remains at its original world location as the character walks and rotates the minimap; capture `/gmap pinpos` before and after moving.
- [ ] **In-game:** verify actual recorded resource markers (not only testpin) remain world-anchored and behave correctly with custom minimap shapes.

### November 5 — first real installation feedback

- [x] Investigate no recorded nodes despite working addon-list entry and map control. Found the recorder is independently **OFF by default**; the former checkbox only changed world-map visibility.
- [x] Replace the world-map checkbox with one expandable GatherMap settings button for four independent switches (minimap/world display, recording, diagnostic messages).
- [x] Add explicit Forever gathering spell IDs, source-matched `LOOT_OPENED` retry and opt-in counters/rejection reporting, without allowing unsupported or failed gather records.
- [x] Add mocked menu and capture regressions to the source test workflow.
- [ ] **In-game:** validate that the menu switches recording ON and that actual harvested herbs/minerals are added and displayed; capture `/gmap capture debug` if not.
- [ ] **In-game:** test map button click/layer behavior, settings persistence and no unintended gameplay actions.

## 2. Development tasks outside the client

- [x] Recheck declared map, minimap, skill, cast, loot and tooltip APIs against Forever UI-source **1.60.1.70790**; see [API audit](docs/FOREVER_API_AUDIT.md). **Runtime behavior remains unverified.**
- [x] Audit the Camelot manifest, runtime load order, referenced icon files and installable folder; add offline [package verifier](tools/check_forever_package.py) and CI coverage.
- [x] Make README Forever-first; move historical client instructions to [legacy archive](docs/LEGACY_0_4_3.md).
- [x] Consolidate roadmap; keep all in-game testing in §3 and preserve previous entries in [historical roadmap](docs/ROADMAP_ARCHIVE_2026-11-04.md).
- [x] Review experimental recording: it **stays disabled by default**. A changed default requires a separate explicit design decision after genuine game evidence.
- [x] Trace 29 inherited herb icons to byte-identical files in jsb/Gatherer; confirm the published Gatherer project lists GPLv2; document [remaining legal questions](docs/THIRD_PARTY_ASSETS.md).
- [x] Strengthen historical zone migration: two separated current-build coordinate anchors are now required before applying; previous-build/missing evidence refuses the import.
- [x] Publish a reproducible [in-game test plan](docs/TEST_PLAN.md), including commands, expected results, backup instructions and redacted diagnostics.

**Automated verification:** [Successful CI run on November 4, 2026](https://github.com/babunidev/GatherMap/actions/runs/41920490126) passed Lua 5.1/5.4 syntax and all migration, map, difficulty, capture, stress, PowerShell backup, static and 38-file development ZIP tests. This is **not** evidence of in-game validation or third-party licensing clearance.
- [ ] **Resolve third-party redistribution terms** for all inherited icons and historical mapping sources. Do not add an unapproved first-party `LICENSE` or replace assets without Babuni's decision.
- [ ] **Verify CurseForge publication automation/settings**, optional `.pkgmeta`, full release ZIP policy and exact official Forever target before releasing. Repository files alone do not prove publisher configuration.
- [ ] Fix any API, display, capture, saved-data or performance defects discovered during the game tests.

## 3. In-game verification — Forever only

### Client start and API behavior
- [ ] Record `/dump GetBuildInfo()` and confirm the actual Interface and flavor TOC selected; start with only GatherMap enabled.
- [ ] Verify no XML, event-registration, missing-API, Lua, secret-value, taint or blocked-action errors at login, combat, `/reload` and logout.
- [ ] Verify real MapCanvas pin callbacks, `CreateVector2D`, minimap radius, zoom/rotation and profession skill APIs/modifiers.

### Gathering and node recording
- [ ] Turn **Record discoveries ON** in the GatherMap map menu, gather herbs and mine veins, then skin creatures/open chests/pick locks; verify correct source/name/position/count and `/gmap capture debug` counters.
- [ ] Test failed/interrupted casts, delayed loot, autoloot, multiple loot sources, missing tooltips, repeated gather and neighboring nodes.
- [ ] Test unknown/custom resource names, localization, delayed events and absent GUIDs. Verify no speculative/false discoveries.
- [ ] Investigate any actual Forever Survival/Woodcutting mechanic without modifying unsupported historical records.

### Difficulty, map display and preferences
- [ ] Check six colors against actual skill thresholds, bonus gear, temporary buffs, profession learning and ordinary chest level.
- [ ] Compare two characters using the same account-wide nodes; verify filtering and differing colors.
- [ ] Verify four corners, world-map resource icons, transitive same-name/kind merging, passive hover, independent controls and persistence.
- [ ] Test indoor/outdoor, cities, extra zones, map panning/zoom/insets, UI scaling and circular/square minimap shapes.

### Saved-data integrity
- [ ] Back up a **copy** of real `WTF` data with the game closed; verify v1/v2/v3 legacy preservation and OctoGather name migration where relevant.
- [ ] Compare two separated historical coordinates with actual Forever positions. Validate old-zone links and `/gmap migrate anchor` behavior; keep ambiguous maps unlinked.
- [ ] Preview migration on disposable saved data, apply only with sufficient evidence, check weighted counts and guarded rollback.
- [ ] Test `/reload`, logout, relog and a second character. Confirm no modern or historical data loss.

### Performance and coexistence
- [ ] Measure actual client FPS, memory/GC, frame counts and errors with dense/large saved databases; check 300 visible-group cap.
- [ ] Test combat and movement with another **Forever-compatible** gathering/map addon installed (one at a time), plus custom minimap controllers.
- [ ] Confirm no repeated warnings, chat spam, map clicks/hover conflicts, pin loss or addon traffic.

## 4. Public release gate — explicit approval required

- [ ] Close critical gameplay bugs; rerun tests and inspect the final diff.
- [ ] Resolve asset rights and LICENSE decision; prepare accurate README, CHANGELOG, credits and player-facing notes.
- [ ] Verify CurseForge source/automation and approved packaging settings, addon directory content and Forever game version.
- [ ] Receive Babuni's explicit approval **for a named public version**; only then tag/publish and confirm GitHub/CurseForge results.

No public Forever version is authorized. The previous public GatherMap `v0.4.3` is historical only.
