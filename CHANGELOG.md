# GatherMap — verified commit history

**Creator:** Babuni.dev  
**Note:** Dates below are Git records, **not** claimed gameplay test dates or confirmed public releases.

## Unreleased — Step 7 performance and reliability (November 4, 2026)

- Added `GatherMapSpatial.lua`, a reusable 128-world-unit grid to query nearby recorded points without rescanning a large map after every movement; small maps skip index allocation.
- Optimized `GatherMapMarkers.lua` union-find grouping: all points in one 14px cell are connected to its representative, and a neighboring cell requires only one confirmed overlapping pair. Same-resource-only transitivity remains unchanged.
- Added separate data and style invalidation, cached native world-map layouts, deferred map-provider initialization retries, and tracked visible minimap frames to reduce layout work and hover checks.
- Retained the **300 displayed-group cap** without limiting or editing `GatherMapDB`, and capped retained world-layout group tables to those actually displayed.
- Added fail-closed handling for absent/incomplete map metadata, unusable coordinates and corrupted occurrence counts. Repeated identical recording-switch commands no longer emit redundant chat notifications.
- Added `tests/test_forever_performance.lua` (24,000 generated map records and 12,000 dense pins) and simulated coexistence with another MapCanvas provider; kept previous migration, difficulty, capture and display tests.
- No new third-party dependencies, invasive tooltip hooks, global map overrides or new recurring addon-message traffic.
- **Not game-tested:** actual client FPS/memory, unusual map geometry or coexistence with other Forever gathering/map addons. No public release.

## Unreleased — Step 6 saved-data migration safeguards (November 4, 2026)

- Added `GatherMapMigration.lua` for explicit legacy `continent:zone` → `map:<UiMapID>` copying with exact zone-name validation, preview and typed confirmation. Unmatched, unsupported and ambiguous history remains intact.
- Preserved v1 herb defaults, the v2 Skinning correction and v3 data. Weighted merging retains occurrence counts/coordinates; repeated imports are blocked by a ledger.
- Preserved the original legacy zone tables. Backed-up source/target snapshots and guarded rollback prevent overwriting later discoveries.
- Added `Backup-GatherMap.ps1` for physical account/character SavedVariables backups with the game closed. Updated `Upgrade-SavedData.ps1` to select the Forever manifest while retaining the old OctoGather rename flow.
- Added mock Lua saved-variable round-trip/migration regression tests and disposable PowerShell filesystem tests.
- **Automated verification passed:** [successful Phase 6 GitHub Actions run](https://github.com/babunidev/GatherMap/actions/runs/41909880251), including Lua 5.1/5.4 migration fixtures, PowerShell rename/backup tests, previous regression tests and Python static checks.
- **Known limitation:** a matching historical zone name does not establish map-art/coordinate equivalence. No automatic mapping or live Forever SavedVariables migration was performed; public release remains unapproved.

## Unreleased — Step 5 map overlay (November 4, 2026)

- Restored the original four-corner visual treatment on native Forever world-map pins and minimap overlays, including world icons and muted gray dots.
- Added `GatherMapMarkers.lua`: screen-space grouping with a spatial grid and union-find, preserving transitive overlaps only for identical resource names and kinds; no saved nodes are merged.
- Corrected world-map clustering geometry to use the actual canvas and zoom scale, rebuilding on canvas size/scale changes rather than per-frame animations.
- Cached unchanged minimap layouts and cached world-position conversions; separated frequent passive hover updates from minimap redraws.
- Replaced use of GameTooltip with a compact private mouse-pass-through label, leaving the game's tooltip and map interactions untouched.
- Restored persistent independent minimap/world-map visibility controls and added optional `/gmap world on|off` diagnostic commands.
- Added Lua 5.1/5.4 grouping, geometry and mocked map-provider tests, including different UI scales, zooming, resizing, and unchanged SavedVariables.
- **Automatically verified:** [GitHub Actions run 41907106572](https://github.com/babunidev/GatherMap/actions/runs/41907106572) passed Lua 5.1/5.4 compilation and mocked display, geometry, skill, capture and static tests.
- **Not yet tested in-game:** precise alignment on the active Forever build, mouse-layer behavior, custom minimap masks and unusual zone layouts. No public release.

## Unreleased — Step 4 dynamic difficulty (November 4, 2026)

- Added `GatherMapDifficulty.lua` for per-character learned profession detection and effective skill (base rank + modifier + temporary points).
- Added complete skill-up color boundaries for 28 herbs and nine ore nodes, cross-checked with Forever-specific Warcraft Wiki community tables. Previously uniform offsets were inaccurate for resources such as Dreamfoil.
- Preserved red/orange/yellow/green/gray/purple display, with purple for unverified thresholds and no unsupported Survival/Woodcutting assumptions.
- Updated skill, equipment, aura and player-level event handling to trigger recoloring without a separate periodic skill scan.
- Continued account-wide `GatherMapDB` storage without saving character-specific skills or modifying discoveries.
- Added Lua mock tests for 37 resource thresholds, bonuses, visibility, treasure levels, unknown requirements and character switching.
- In-game API values, real-player character switching, colors and rendering remain **unverified**. No public release.

## Unreleased — Step 3 experimental gathering recorder (November 4, 2026)

- Added a separate Forever recorder using player cast events, `LOOT_READY`, and loot-source GUID checks.
- Added herb, mining, skinning, ordinary-chest and lockpicking classification, including short-lived Pick Lock → Opening correlation.
- Added an opt-in switch (`/gmap capture on|off|status`). Automatic recording remains OFF by default until real client tests establish reliability.
- Added guarded new-`UiMapID` observation writes with spatial/time duplicate protection; historical numeric zone records remain unchanged.
- Added Lua mock-event fixtures for successful, interrupted, stale, duplicated and unrelated actions to the CI workflow.
- **Verified automatically:** GitHub Actions [Step 3 run](https://github.com/babunidev/GatherMap/actions/runs/41901589381) passed Lua syntax, mocked gathering success/failure/delayed-loot cases, and manifest/static tests. No Forever in-game behavior has been verified.
- This is an **unreleased, source-level implementation**. Exact Forever gameplay behavior has not yet been verified.

## Unreleased — 0.5.0-alpha Forever compatibility development (November 4, 2026)

- Added a Forever-only `GatherMap_Camelot.toc`, separate Lua runtime, resource tables and map-pin XML template.
- Replaced old map/skill/event interfaces with `C_Map`, `C_Minimap`, `C_SkillInfo` and explicit event callbacks.
- Introduced native map-provider pins, four-corner markers, passive hover and separate map visibility switches.
- Introduced modern `map:<UiMapID>` record reads, retaining legacy saved keys untouched until migration is developed.
- Added `/gmap testpin` and `clear` as non-persistent UI probes; gathering capture remains intentionally disabled.
- Added preliminary static regression checks. `luac5.4 -p` and the Forever manifest/API/asset Python checks **passed in GitHub Actions** on November 4, 2026 ([Forever static CI run](https://github.com/babunidev/GatherMap/actions/runs/41898899469)). No Forever in-game or saved-data migration tests have been performed.
- No changes to the old 0.4.3 Lua/TOC or published tags/releases. Development-only, not a public build.

## Unreleased — November 4, 2026: Forever port preparation (development branch)

- Established a separate Forever development branch without altering the old `main` runtime, release tags or public releases.
- Recorded Forever-only scope, the legacy compatibility boundary, porting risks, migration requirements and a staged technical roadmap.
- Reviewed the 29 inherited Gatherer herb icons, historical scaling credits, and MetaHunt data attribution. Redistribution permissions remain **unresolved** pending an asset/license audit.
- **Documentation only:** no Lua/TOC/runtime changes, in-game tests, new public version or deployment.

## 2026-10-26 — expanded documentation

- Rebuilt/expanded README, concept, roadmap, changelog and AGENTS rules, plus `docs/ARCHITECTURE.md`, `DESIGN.md`, `CONTENT.md`, `DECISIONS.md`, `DEVLOG.md` and `AI_COLLABORATION.md`.
- Described resource discovery, skill filters and difficulty, marker composition/merging, coordinate handling, optional Interact integration, data migration, provenance and third-party credits.
- Recovered the September feature and visual-history sequence from commits rather than speculating about conversations.
- **Documentation only:** no Lua, TOC, media, migration tool or test file edits. No runtime tests executed.

## 2026-09-05 — initial Octo Gather

**`0cd8e97` — “Initial Octo Gather release.”** Original `OctoGather.lua` / `.toc` v0.2.6, `OctoGatherDB`, 29 bundled herb TGA icons, screenshots, and self-learning herb points on minimap/world map. Early markers were outline-based, with a lower 100-pin display cap.

## 2026-09-06 — resource and interface expansion

| Commit | Observed change |
| --- | --- |
| `7d4d029` | Added mining, skinning, ordinary chests and lockpicking categories, map/tier data, 300-pin display cap, and broader loot/action recording; v0.3.0. |
| `4eabd570` | Corrected lower-level Skinning difficulty calculation. |
| `bd98a2d3` | Mapped skinning loot to more accurate vanilla item icons. |
| `8f890b2` | Hidden profession markers for characters without the respective skill, retaining account-wide saved data. |
| `bec4f926` | Added **Survival Woodcutting** and six custom tree categories, with skill-aware filtering. |

## 2026-09-07 — marker refinements and compatibility repair

| Commit | Observed change |
| --- | --- |
| `dc6f4ba5` | Replaced full marker outlines with the current **four corner dots**, including merging/hover adaptations. |
| `9572119` | Increased gray marker opacity to **85%** and refreshed map screenshots. |
| `1cb631f` | Reworked the optional Interact hook to capture a per-wrapper predecessor and prevent recursion when another addon chains/replaces `Interact`. Added regression test script. |

## 2026-09-18 — renamed to Gather Map

**`0a01737` — “Use provider-neutral names and client compatibility descriptions.”** Renamed original `OctoGather` source/manifest/variables/icon folder references and README labels to `GatherMap`. Advanced TOC metadata to **0.4.3**, added saved-data migration PowerShell helper and its fixture test. **Important:** data must be migrated when the addon/saved-variable name changes; the migration is not simply cosmetic.

## 2026-10-26 — attribution and initial documentation

- `39886f3` set the TOC author field to Babuni.dev.
- `08ad7c8` credited the creator in README.
- `410d1bd` created initial concept, roadmap, changelog, architecture, decisions, DEVLOG and agent rules.
- `e61febe` linked the preliminary documentation from README.

The present pass turns that scaffold into a fuller, source-specific portfolio record without changing the 0.4.3 runtime package.
