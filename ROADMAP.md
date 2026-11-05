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
