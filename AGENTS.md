# GatherMap — development instructions for humans and AI collaborators

**Creative direction and authorship:** Babuni.  
**Historical public identity:** GatherMap, formerly OctoGather, legacy manifest 0.4.3 / Interface 11200. **Current development manifest:** `GatherMap_Camelot.toc`, 0.5.0-alpha / Interface 16001; unreleased and not game-verified.

## Read before changing anything

Start with `README.md`, `CONCEPT.md`, `ROADMAP.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/DEVLOG.md`, `GatherMap.lua`, `GatherMap.toc`, `Upgrade-SavedData.ps1`, and the tests. The project is a self-learning resource map, **not** a static imported map-database frontend.

Do not erase Babuni's creative authorship, invent older conversations, or claim past AI proposals were approved without evidence.

## Forever-only development scope (November 4, 2026)

All **new** implementation, testing, maintenance and future releases target **World of Warcraft Forever exclusively**. The historical 0.4.3 runtime and original 1.12 interface remain preserved on `main` and earlier tags; their presence is historical, **not** Forever compatibility. Development lives on `feat/forever-port` until explicitly reviewed and merged. See [docs/FOREVER_PORT.md](docs/FOREVER_PORT.md) for the technical preparation record.

Check the active Forever build/interface, Lua capabilities, events, map/profession APIs and addon restrictions before implementation. Baseline at preparation: **1.60.1 / Interface 16001**; the live build and package details require verification after client updates. Do not convert the legacy TOC to 16001 without porting its runtime, or describe proposed features as implemented.

Keep account-wide discovery data, the original personal-learning concept, marker colors/merging, historical attributions and migrations intact. Never create publishing tags, GitHub Releases or CurseForge uploads without explicit approval for that version.

## Current branch entry point — Forever 0.5.0-alpha shell

This development branch adds `GatherMap_Camelot.toc`, `GatherMapData.lua`, `GatherMapWorldPins.xml`, and `GatherMapForever.lua`. The old `GatherMap.toc` and `GatherMap.lua` are intentionally preserved as the **legacy 0.4.3 source**, not loaded by the Forever manifest.

The Forever runtime currently reads only `map:<UiMapID>` nodes. **Do not migrate legacy `continent:zone` keys by numeric assumption or enable speculative gathering writes.** `/gmap testpin` creates an unsaved test marker; `/gmap clear` removes it. The source-level recorder remains opt-in and game-unverified. The schema-v1/v2/v3 and old map-key copier is implemented but requires explicit backups, linking and confirmation; actual Forever geometry and persistence still need in-game evidence. Validate new changes with `tests/test_forever_static.py` and Lua syntax checks when available.

## Active Forever workflow and release-readiness boundaries

Start with this `AGENTS.md` and `docs/DOCUMENTATION.md`, then inspect `README.md`, `ROADMAP.md`, `CONCEPT.md`, source/TOCs, current branch/working tree, releases and relevant docs. Forever is the **only** supported client. The active README and roadmap are Forever-first; legacy 0.4.3 history is kept under `docs/LEGACY_0_4_3.md` and `docs/ROADMAP_ARCHIVE_2026-11-04.md`.

`docs/FOREVER_API_AUDIT.md` records source-confirmed client APIs (baseline snapshot build 70790); `docs/TEST_PLAN.md` collects **all game-only tests**; `docs/THIRD_PARTY_ASSETS.md` records icon provenance and open licensing questions. `tools/check_forever_package.py` validates the Camelot manifest, runtime file order and icon references, optionally building a local development ZIP with no legacy TOC/runtime. **Never** treat its success as license clearance or public-release authorization.

The old-zone importer must refuse `apply` unless two distant historical node coordinates have been explicitly matched against positions on the same Forever client build (`/gmap migrate anchor`). A link by zone name is not geometry proof. Preserve every legacy source row, backups and rollback protection. Recording remains **OFF** by default until live evidence and explicit direction justify otherwise. Do not assign a LICENSE, publish a tag or upload to CurseForge without Babuni's specific approval.

## Phase 7 performance and coexistence boundaries

`GatherMapSpatial.lua` provides an optional instance-keyed world-coordinate index for larger Forever maps, and `GatherMapMarkers.lua` groups same-kind/name entries transitively using cell representatives. Maintain the original four-corner colors and the 300 **displayed-group** cap; no performance change may remove, truncate or silently re-key SavedVariables. Cache only derived display state, invalidate it on relevant capture/migration or skill changes, and keep native map providers and GameTooltip owned by their respective addons. Do not add chat spam or repeated pollers. Run the 24k-node synthetic benchmark and mocked alternate-provider fixture, but require actual Forever tests with other map/gathering addons before claiming coexistence.

## Phase 6 legacy migration safety boundary

`GatherMapMigration.lua` is a strictly opt-in copy mechanism, not an automatic map-key conversion. Never treat `continent:zone` numbers as Forever `UiMapID` values. Preserve legacy rows, raw v1/v2/v3 history, unmatched/custom regions, original counts and coordinates. New IDs require exact zone metadata validation and manual user confirmation; matching names do not prove map geometry. Apply only after preview and with physical backups from `Backup-GatherMap.ps1` while WoW is closed. Retain snapshot/ledger state, refuse overwrites and guard rollback against post-import observations. No claimed in-game migration until actual Forever maps and SavedVariables reloads are tested. The renamed-addon helper `Upgrade-SavedData.ps1` handles **OctoGatherDB → GatherMapDB**, not coordinate mapping.

## Phase 5 map presentation boundaries

`GatherMapMarkers.lua` is the Forever-only screen-space geometry/grouping module. Retain four 3px corner dots, world-map resource icons, 85%-opacity gray, resource name/kind separation, transitive overlap merging and the 300 **displayed-group** limit. Do not merge saved nodes to optimize visual clustering. The minimap and world-map preferences remain independent of each other and of discovery recording. Use a private mouse-disabled hover label; do not take ownership of native map clicks/dragging or GameTooltip. Run `tests/test_forever_markers.lua` and `tests/test_forever_display.lua` with Lua 5.1/5.4, then verify real map zoom, scaling, city/custom zones and other addons in Forever before claiming visual fidelity.

## Phase 4 color system and evidence standard

`GatherMapDifficulty.lua` is the current-character skill and threshold authority. Load it before `GatherMapForever.lua`. Do not store skill ranks in `GatherMapDB`; show only learned professions and compute effective skill from rank + verified modifiers/temporary points. Keep all six colors, character-level treasure tiers, and unknown purple; the explicit Forever herb/ore tables are community-documented, **not yet verified live**, and missing thresholds must not be invented. Test exceptions (e.g., Dreamfoil) and different characters' views of shared records.

## Phase 3 recorder safety boundary

`GatherMapCapture.lua` is the experimental Forever-only recorder. It defaults to `recordingEnabled = false` and must not write a discovery from cast-start, cast-stop, generic loot text or a nearby object alone. Require a completed recognized player spell and correlated, appropriate-type loot source. Preserve historical `GatherMapDB.nodes` data, suppress duplicate observations and keep the legacy wood category without inventing a Forever Survival API. Before changing the default setting, record genuine Forever in-game success and failure evidence for each supported category.

## Preserve these source-level invariants

- **Record confirmed gathering/loot interactions**, not speculative available live spawns. Skinning saved points are hunting-location hints, not fixed nodes.
- Keep account-wide `GatherMapDB` across characters and calculate display difficulty from **current** profession ranks/level. Hide resources where the current profession is absent; always permit ordinary treasure.
- Preserve `herb`, `mineral`, `skin`, `lock`, `treasure`, `wood` category semantics, fallback defaults for older records and requirement handling.
- Use four-corner markers, world-map resource icons, hover text, and **same-resource-only** transitive merging. Do not turn separate resource types into one large group.
- Treat `Attack`/interaction timing and game events as fallible. Do not assert a game action succeeded merely because `SPELLCAST_START` fired.
- The `Interact` hook must **not recurse** when other addons change the global function. Run and preserve `tests/test_interact_hook.py` where possible.
- Maintain backward compatibility for schema-v1 herb-only data, schema-v2 skin requirements and the **OctoGatherDB → GatherMapDB** rename migration. No user data should be overwritten or discarded casually.
- Names and coordinates for custom zones require evidence; avoid guessed map sizes.
- The Forever overlay throttles minimap updates around **0.35 seconds** and hover around **0.10 seconds**, with a 300-displayed-group cap. Check actual client performance before changing this.
- Keep third-party attribution for Gatherer icons/scaling and MetaHunt map data. No LICENSE file was observed: do not assign an unapproved license to authored or borrowed assets.

## Development and validation process

1. Record what Babuni wants to change and why, with clear boundaries and any proposed alternatives.
2. Explain whether a change affects resource recognition, persistence, UI, performance, client support or external attribution.
3. For runtime changes, run the existing focused Interact and migration fixture tests when their Python/Lua/PowerShell dependencies are available, and capture outputs.
4. Separately test all new functionality **exclusively in World of Warcraft Forever** with positive, negative and migration scenarios; historic 1.12 code is for source/reference comparison only. Mock/fixture tests are not game tests.
5. Preserve backups and full original datasets during saved-variable migrations; test changes with copies, not sole surviving files.
6. Update README, CONCEPT, ROADMAP, CHANGELOG, AGENTS, and `docs/ARCHITECTURE.md`, `docs/DESIGN.md`, `docs/CONTENT.md`, `docs/DECISIONS.md`, `docs/DEVLOG.md`, `docs/AI_COLLABORATION.md` for substantial changes.
7. Credit the creative for the vision, accurately attribute the AI's implementation and documentation work, record rejected alternatives and actual commit/verification results.
8. Keep private SavedVariables, player coordinates, account information and credentials out of portfolio publications.

The 2026-10-26 pass is **documentation-only**, not permission to alter Lua, binaries, scripts or artwork.

## Repository-local documentation standard

Before writing or changing project documentation, read [docs/DOCUMENTATION.md](docs/DOCUMENTATION.md). These rules travel with this repository and do not depend on the babuni.dev ChatGPT Project. Preserve all project-specific technical, creative, canon, safety, licensing, and historical rules in this file; follow the linked standard for public first-person narrative, human–AI attribution, concise development journals, decision records, and evidence-based verification. **Babuni** is the human creative; **babuni.dev** is the website/portfolio, not the person. Preserve third-party credits and historical legal notices. References above to a dated “documentation-only audit” describe that past task, not a permanent ban on later authorized implementation.
