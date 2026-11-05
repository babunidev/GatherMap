# GatherMap Forever — reproducible in-game test plan

**Status:** Procedures prepared, **no in-game tests performed**. Only World of Warcraft Forever is supported. Keep public-release decisions separate from this checklist.

## Before any test

1. Close Forever. Copy the client's entire `WTF` directory to a dated location outside the game, or run `pwsh ./Backup-GatherMap.ps1 -ClientPath "/path/to/Forever-client"` from this repository with PowerShell installed. Keep backups private and do not commit any player SavedVariables. Check the real game folder, which may differ from old beta installation paths.
2. In your local checkout, run `git pull --ff-only` on `feat/forever-port`. For a disposable development ZIP, run `python3 tools/check_forever_package.py --output /tmp/GatherMap-forever-dev.zip`. Extract the `GatherMap` directory directly into the **Forever client's** `Interface/AddOns/`; do not nest it twice. The ZIP contains only the Camelot manifest and its runtime/art assets; it is **not an approved public package**.
3. Start with GatherMap alone. Enable Lua errors: `/console scriptErrors 1`. Record `/dump GetBuildInfo()`, `/gmap status`, `/gmap capture status` and the in-game AddOns list.
4. **Expected:** The addon is recognized and initializes without Lua/XML errors; `/gmap capture status` says recording disabled. Preserve any raw logs, but remove account names, character identifiers and private coordinates before sharing diagnostics.

## A — Map and UI (no new saved discoveries)

| Action | Expected | Evidence |
| --- | --- | --- |
| `/gmap testpin` in an outdoor zone | Purple temporary four-corner marker at player's current position | Screenshot of minimap/world map, UI scale and zone |
| Open world map; pan and zoom | Center icon and corners track the intended map position | Screenshots before/after, no blocked actions |
| `/gmap clear` | Temporary pin disappears, SavedVariables unchanged | `/gmap status`, map screenshot |
| `/gmap on` / `/gmap off` | Minimap only changes; world-map toggle does not | Side-by-side screenshots |
| Click **GatherMap** on world map | Expand/collapse four-switch settings menu, without dragging or blocking map pins | Screenshot, Lua error check |
| Switch **Minimap markers** / **World-map markers** independently | Each switches its own overlay; no shared discovery deletion | Screenshots before/after |
| Switch **Record discoveries** / **Diagnostic chat** | Capture is OFF initially; each switch persists independently of displays | /gmap status and /gmap capture debug |
| `/gmap world on` / `/gmap world off` | World-map only changes; minimap remains independent | Side-by-side screenshots |
| Toggle map settings; `/reload` | Visibility preferences survive | Screenshot after reload |
| Rotate, zoom and resize minimap; UI scale changes; move to city/custom map | No misaligned/stuck corners, Lua errors or map input blocking | Zone, minimap shape and UI-scale notes |
| Hover markers, click map, drag map, combat on/off | Label appears without stealing GameTooltip or blocking normal actions | Errors, input behavior |

## B — Recording (enable only on disposable test data)

1. Record saved-node counts with `/gmap status` before starting. Open the world-map **GatherMap** button and turn **Record discoveries ON** (or use `/gmap capture on`). It begins OFF by default. Turn it OFF after testing. Temporarily enable **Diagnostic chat** if a successful gather is not saved.
2. Gather one known herb (Forever spell `1235236`) and one ore vein (Forever spell `1235230`), then skin one creature, open an ordinary chest and pick a lock. Expected: each successful action creates one resource-kind record with the correct map position and classification; Skinning is an approximate hunting location.
3. Repeat one location and then visit a nearby different node. Expected: occurrence count increases only after a new verified gather; distinct resources remain distinct.
4. Deliberately interrupt a gathering cast, gather from an unrelated source, test autoloot/delayed-loot and missing-tooltip situations. Expected: no speculative records; inspect actual `UNIT_SPELLCAST_*` and `LOOT_READY` behavior rather than inferring success from cast stops.
5. Inspect unusual/special Forever resources, any localized client, Skinning and lockpicking. Expected: unknown thresholds remain purple; no assumed Survival/Woodcutting action.
6. Run `/gmap capture debug` after each gather and note recognized casts, success, loot events, source matches, saved records and last refusal. Then confirm `/reload`, logout and a second character retain shared discoveries and display/recording switches without copying current-character profession ranks to `GatherMapDB`.

## C — Difficulty and character state

- At a known herb/ore threshold, compare the marker to the real gather skill and game tooltip. Check red, orange, yellow, green and gray where published; purple for unknown resource requirements.
- Equip/unequip skill-bonus gear and apply/remove temporary bonuses. Expected: effective skill changes marker color without editing shared nodes.
- Switch to a different profession character using the same account data. Expected: learned-profession filtering and colors change per character; ordinary chest color depends on level.

## D — Database migration (high risk; copies only)

1. Test only with a disposable **copy** of actual SavedVariables after preserving a separate physical backup. Never operate on the sole surviving copy.
2. Run `/gmap migrate status` and inspect legacy keys. Stand inside the associated Forever zone and run `/gmap migrate link <continent:zone>`.
3. Choose **two known historical node indexes in that zone** at least 10% of the normalized map apart. At each actual world location, run `/gmap migrate anchor <continent:zone> <node-index>`. The current character's normalized `C_Map` position must be within 1.5 percentage points of the corresponding historical record in each axis, and both observations must be on the same client build.
4. Run `/gmap migrate preview <continent:zone>`. Expected: it reports geometry evidence, count, weighted duplicates and skipped invalid entries **without writing a modern zone**. A matching zone name **alone** must never allow `apply`.
5. Only after checking backup and preview, run `/gmap migrate apply <continent:zone> confirm`. Expected: new `map:<UiMapID>` records appear; old `continent:zone` records remain intact; snapshot and migration ledger prevent importing twice.
6. Recheck map geometry and node counts. Test `/reload`, logout and a second character using the disposable data. If a modern record changes after import, `rollback` must refuse to overwrite it; otherwise `/gmap migrate rollback <key>` should restore the pre-import target.
7. Record ambiguous/unmatched zones as **not migrated**. Passing two anchors is a conservative geometric check, **not proof that every point in the zone is aligned**; retain original records and compare multiple landmarks.

## E — Performance and coexistence

- Record FPS/memory with 0, 100, 1,000 and 10,000+ saved nodes (synthetic data or a backup), with minimap/world map shown and hidden. Compare stationary and moving views, zoom changes, event bursts and combat.
- Test GatherMap alone, then with one verified Forever-compatible map/gathering addon at a time (GatherMemory/TobarisuMap, Mapster, TomTom where a Forever build exists). Expected: native map pins, tooltips, clicks, SavedVariables and error logs remain independent.
- Test busy cities, unusual zone layouts, indoor/outdoor transitions, non-square minimap and the 300-visible-group boundary. The cap limits *rendered* groups, never storage.

## Record format

For each test record: **date**, Forever **build/interface**, development **commit**, character class and relevant profession ranks (no name), test case, reproduction steps, observed result, expected result, screenshot/log reference (redacted), **pass/fail/unverified**, and any issue/commit fixing it. A mocked CI pass is not a gameplay pass.
