# GatherMap — verified commit history

**Creator:** Babuni.dev  
**Note:** Dates below are Git records, **not** claimed gameplay test dates or confirmed public releases.

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
