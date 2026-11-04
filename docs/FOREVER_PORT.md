# GatherMap — Forever port preparation

**Status:** Phase 2 compatibility shell and opt-in Phase 3 recorder implemented in source; neither game-verified. Legacy map-key migration remains disabled.  
**Decision authority:** Babuni (human creative).  
**Target:** World of Warcraft Forever **only**, baseline 1.60.1 / Interface `16001` (reverify on the live build).  
**Development branch:** `feat/forever-port`, forked from legacy `main` commit `1df33f6365e47d885ee6a6ed0fbf87158a8ca726`.  
**Legacy runtime and published version:** `GatherMap.lua` (1,237 lines), `GatherMap.toc` (0.4.3 / Interface `11200`), [GitHub Release v0.4.3](https://github.com/babunidev/GatherMap/releases/tag/v0.4.3).  
**Source of truth:** [AGENTS.md](../AGENTS.md), [CONCEPT.md](../CONCEPT.md), [ARCHITECTURE.md](ARCHITECTURE.md), [DOCUMENTATION.md](DOCUMENTATION.md).

## Phase 2 — implementation record, November 4, 2026

The `feat/forever-port` branch now includes:

| File | Role |
| --- | --- |
| `GatherMap_Camelot.toc` | Forever-only manifest, Interface `16001`, development version `0.5.0-alpha`, `GatherMapDB` |
| `GatherMapData.lua` | Resource requirements, icons and colors retained from legacy 0.4.3 without claiming their thresholds were verified on Forever |
| `GatherMapWorldPins.xml` | Virtual map-canvas pin template |
| `GatherMapForever.lua` | Modern event callbacks, `C_SkillInfo` rank reads, `C_Map` and `C_Minimap` coordinates, native world-map provider, four-corner rendering, hover and display controls |
| `tests/test_forever_static.py` | Static manifest/API/asset regression checks; optional Lua parsing only if `luac` is installed |

Modern node reads are namespaced as `GatherMapDB.nodes["map:" .. UiMapID]`, **without changing or deleting** old `continent:zone` keys. At this Phase 2 checkpoint no writes were enabled; **Phase 3 subsequently added opt-in new-location writes only**. A temporary `/gmap testpin` marker is created in memory and disappears after `/gmap clear` or reload; it does not alter SavedVariables.

**API evidence:** `C_SkillInfo.GetSkillLineInfoByID` returns a table with rank/modifier/tempPoints, `C_Map.GetPlayerMapPosition(mapID, "player")` yields normalized zone coordinates, `C_Map.GetWorldPosFromMapPos` yields world positions, and `C_Minimap.GetViewRadius` yields a distance in yards. The world-map provider follows the native `MapCanvasDataProviderMixin` / `AcquirePin` model found in Forever UI sources and Forever-compatible map addons. This is implementation based on documented APIs, **not proof of correct runtime behavior**.

The latest publicly tracked pre-launch data build on November 4 was `1.60.1.70755`; Interface `16001`. Confirm with `/dump GetBuildInfo()` in the user's actual live client. The launch-time build could differ.

**Remaining before Phase 2 can be fully verified:**
- **Automatically verified:** GitHub Actions [Forever static CI run](https://github.com/babunidev/GatherMap/actions/runs/41898899469) completed successfully on November 4, 2026. It installed Lua 5.4, ran `luac5.4 -p GatherMapData.lua` and `luac5.4 -p GatherMapForever.lua`, then executed `python3 -m unittest discover -s tests -p 'test_forever_*.py'`. These checks validate syntax and repository invariants only, not the Forever client runtime.
- Load the addon on Forever and check `/gmap status`, `/gmap testpin`, minimap zoom, rotated minimap, native world-map pan/zoom, checkbox, map changes and combat taint.
- Verify skill ID 182 (Herbalism), 186 (Mining), 393 (Skinning), 633 (Lockpicking), effective modifiers and skill changes.
- Confirm that the legacy `GatherMapDB` values persist on reload and that no old nodes are rewritten or interpreted as new map IDs.

## Phase 3 — experimental resource recorder (November 4, 2026)

`GatherMapCapture.lua` implements an **opt-in** gathering pipeline. `UNIT_SPELLCAST_SENT` records a potential interaction context, `UNIT_SPELLCAST_SUCCEEDED` confirms spell completion, and `LOOT_READY` inspects `GetLootSourceInfo` for a matching GameObject (herb, mineral, chest, lock) or Creature (skin). `UNIT_SPELLCAST_FAILED` and `UNIT_SPELLCAST_INTERRUPTED` discard an attempt, while stale, unrelated and already-consumed loot is ignored.

Recording requires `GatherMapDB.recordingEnabled == true`, configured by `/gmap capture on|off`. It is disabled by default. Entries are written to `GatherMapDB.nodes["map:" .. UiMapID]` through a validated/deduplicating writer. The original `continent:zone` records remain unmodified. Legacy tree data remains preserved but no Survival mechanic has been confirmed. Basic node classification can use the source name or recognized gathered material; unknown names are discarded rather than guessed. Chest classification requires a recognized chest-like name; an earlier successful Pick Lock can temporarily classify a subsequent Opening as `lock`.

**Evidence distinction:** exact spell IDs and available events were cross-checked against existing Forever collectors (`tobarisu1/wow_forever_addons` GatherMemory and `Imemoth/wow-foreverdb`). This confirms a plausible Forever-specific approach, **not** successful operation in a running game. `GetLootSourceInfo`, `UnitGUID("npc")`, `C_TooltipInfo.GetWorldCursor`, secret values, event ordering and loot-source identity require direct validation on the target client. Missing source information currently fails closed: no record.

### Verification status and remaining work

- **Passed in CI:** [Step 3 run, November 4, 2026](https://github.com/babunidev/GatherMap/actions/runs/41901589381). GitHub Actions completed Lua 5.4 syntax checks for `GatherMapData.lua`, `GatherMapForever.lua`, and `GatherMapCapture.lua`; it ran `lua5.4 tests/test_forever_capture.lua` plus Python static/manifest checks. The Lua fixture uses **mocked** client APIs, not the actual game.
- **Not yet tested:** real Forever event signatures, UI interactions, loot attribution, map position fidelity, SaveVariables persistence, compatibility with other addons, and performance.
- **Status:** recording is **off by default** and a user must explicitly enable it with `/gmap capture on`.

### In-game verification backlog

1. Collect exact event argument traces in the actual Forever client using non-sensitive diagnostics; re-run with the current client build.
2. In-game: unsuccessful cast, interrupted cast, normal herb/mineral gather, Skinning, ordinary chest, Pick Lock → Opening, autoloot, repeated same node, adjacent nodes, delayed loot and unrelated loot.
3. Confirm stable GameObject and Creature source GUIDs, event argument types and name/requirement detection across each path.
4. Recheck the client build and secret-value restrictions; revise any unsupported behavior rather than replacing confirmation with guessing.
5. Verify saved node counts, map rendering, logout/reload and cross-character data without modifying old legacy records.
6. Resolve custom-resource and localization coverage before changing the default recording policy.

## Scope and preservation requirements

The original addon is a **self-learning**, account-wide record of observed herb, mineral, skinning, lockpicking, ordinary treasure and legacy woodcutting discoveries. It is not a current-spawn detector and does not import a full premade spawn catalog. Minimap and zone world-map markers use four difficulty-colored corner dots, resource icons on the world map, separate visibility preferences and **same-kind + same-name-only** transitive visual grouping. Skinning markers denote approximate hunting spots, not fixed creatures.

Preserve `GatherMapDB`, existing schema-v1/v2/v3 data, the historic `OctoGatherDB` name migration, previous releases, authorship and third-party credits. Never silently delete unknown resource types or unmatched saved zones. A legacy manifest version bump is **not** a port.

## Source inspection and compatibility risks

| Legacy implementation | Forever investigation / required work | Confidence |
| --- | --- | --- |
| `GetNumSkillLines`, `GetSkillLineInfo` | Use verified Forever `C_SkillInfo` methods; validate rank and effective profession bonuses | API candidate; untested in this addon |
| `GetMapZones`, `GetPlayerMapPosition`, `SetMapZoom`, index keys `continent:zone` | Use `C_Map` and stable map IDs; preserve old keys in migration evidence; verify zones and subzones | API candidate; migration unverified |
| `WorldMapButton`, old tooltip/frame templates | Rebuild on modern map canvas or verified map-pin integration; preserve native map actions and mouse hover | Unverified implementation |
| Implicit `event`, `arg1`, `this` callbacks | Use explicit callback parameters, available supported events and safe values | Modernization required |
| `SPELLCAST_STOP` commits a pending node | Correlate actual successful gathering/loot; stop alone is not conclusive success | Source-confirmed risk |
| Loot within 10 seconds of optional `Interact` hook | Verify correct source/object and avoid false positive discoveries | Source-confirmed risk |
| Zone-name strings, old minimap scaling tables | Revalidate Forever world-map dimensions, UI scaling and localization | Unverified |
| `OnUpdate` every 0.10s, regrouping up to 300 displayed groups | Cache/group efficiently while preserving original visual behavior and not capping database | Source-confirmed design/performance risk |
| Custom `Survival`/`Woodcutting` category | Preserve records; enable recording only if Forever really has a corresponding mechanic | Game feature unverified |
| `Upgrade-SavedData.ps1` derives target from single `.toc` | Review for `_Camelot`/`_Forever` manifest naming and filesystem differences; test with copies | Source-confirmed risk |

Do not assume a modern API's existence guarantees it works with Forever-specific restrictions. Capture current `GetBuildInfo()`, inspect official client/API changes and test events in the client before selecting implementations.

## Verification and migration sequence

1. Confirm actual Forever client build, interface, manifest suffix, Lua runtime, exposed events and map/skill APIs.
2. Define independent confirmed interaction→resource→position recording with failure and duplicate protection.
3. Define stable zone identifiers; generate a reviewed mapping for the **legacy** numeric keys and names. Keep ambiguous records intact in an import report.
4. Rebuild minimap/world-map rendering and professional difficulty from tested values. Preserve four-corner grouping behavior.
5. Add fixture/regression tests for records, legacy migrations, success/failure, map transformations, marker groups and performance.
6. Test in Forever: new character, multiple characters, skills, respec/effective bonuses, gathering/loot failures, zoom, world-map selection, combat restrictions, reload and logout.
7. Verify third-party rights, package contents, automation and CurseForge source settings before an explicitly approved release. Never publish from an untagged ordinary development commit without checking actual integration settings.

## Upstream attribution and licensing review — November 4, 2026

| Material | Provenance observed | Remaining action |
| --- | --- | --- |
| 29 `Icons/Herb*.tga` assets | Same filenames appear under [jsb/Gatherer](https://github.com/jsb/Gatherer/tree/master/Icons). No license file in that fork's root. The [original Gatherer listing](https://www.curseforge.com/wow/addons/gatherer) advertises **GPLv2**. | Determine exact authorship/derivation and applicable permissions/redistribution conditions; retain credits |
| Minimap zone/continent scaling constants | Credited to historical Gatherer in the existing architecture/content documentation | Verify which upstream code/data and terms apply |
| Grim Reaches dimensions | Previously credited to MetaHunt. Original GitHub path unavailable; [Gitea mirror](https://octowow.st/git/Meta/MetaHunt) points to [Codeberg upstream](https://codeberg.org/Duvelcorp/MetaHunt) | Trace the specific measurements; verify usage rights/attribution |
| GatherMap project | No root LICENSE found in reviewed Git tree | Human owner to determine licensing, taking third-party rights into account |

A license label on a related upstream distribution does not independently establish rights for every file in a historical fork. Attribution is necessary but does not by itself prove a redistribution license. No asset removal or license grant has been approved.

## Preparation verification and limitations

- GitHub default `main` at `1df33f6`, version `0.4.3` / Interface `11200`; released `v0.4.3` tag points to `0a01737`. Prior release artifacts and tags were not modified.
- Root instructions, documentation standard, source, manifest, migration helper, test fixtures, historical docs and asset inventory read.
- Remote GitHub state is inspectable; **local uncommitted worktree changes on Babuni's machine are not accessible remotely**.
- The initial preparation was documentation-only; the later Phase 2 source implementation has now passed GitHub CI Lua 5.4 syntax and static checks. No in-game API probe, installation, migration run, package, publishing tag or release was performed.
