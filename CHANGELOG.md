# GatherMap — verified commit history

**Creator:** Babuni.dev  
**Note:** Dates below are Git records, **not** claimed gameplay test dates or confirmed public releases.

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
