# GatherMap — verification and development roadmap

**Creator and approval authority:** Babuni.dev  
**Status of this file:** Technical verification backlog and possible alternatives, **not** creator-approved implementations.

## Implemented in source as of October 26, 2026

- Vanilla 1.12 manifest, **0.4.3**, account-wide `GatherMapDB`, optional `Interact`.
- Learning paths for **herb**, **mineral**, **wood**, **skin**, **lock** and **treasure**.
- Zone/subzone/coordinate records with near-position deduplication and occurrence counts.
- Current-skill difficulty and per-profession filtering; chest-level tiers.
- Four-dot minimap and world-map marker groups, resource artwork on world map, hover label.
- Separate persistent minimap `enabled` and world-map `worldMapEnabled` controls.
- Custom zone sizes and normalizations; automatic discovery in recognized 1.12 zone maps.
- 300-render-group cap per map, approximate 0.10s redraw interval.
- Migration of internal database schema version 1 and 2 into version 3 on initialization.
- PowerShell saved-data rename utility with backup/refusal logic and two regression test scripts.

This is a **source inventory**. No live-game behavior, interaction tool, migration run or regression-suite result was independently verified during this documentation audit.

## P0 — verify data integrity and compatibility

1. Run `tests/test_interact_hook.py` in an isolated environment with Python and **lupa providing Lua 5.1**. Verify old shared-upvalue recursion is detected in the fixture and current wrapper passes. Record exact versions and console output.
2. Run `tests/test_upgrade.ps1` in a trusted PowerShell environment against synthetic temporary fixtures. Ensure it preserves Unicode, saves originals, creates backups and refuses existing new files and unsafe folder names.
3. Test the helper against a **copy** of old real-world SavedVariables, never the only surviving file; confirm both account-wide and per-character file cases. Ensure the legacy variable name matches the old TOC.
4. Launch WoW with the intended **1.12-compatible client**, confirm TOC/file/icon loading and that the code's English event text and profession lookup actually work.
5. Create a successful herb/mining/tree interaction and a **failed/interrupted** interaction; verify only successes are recorded and duplicates merge as intended.
6. Run normal interaction and the optional [Interact](https://github.com/lookino/Interact) hotkey in separate tests; add another addon that wraps Interact to check hook-chain behavior and absence of recursion.
7. Test logout, `/reload`, multiple characters, schema-version-1/2 upgrades, and account-wide sharing without losing old records.
8. Test unknown-tooltip custom resources, missing names/icons, delayed loot, two resources of same name nearby, and gathering while standing at map coordinate (0,0) or in unsupported map areas.

## P1 — user experience and precise map behavior

9. Verify four-dot corner alignment across minimap zoom, indoor/outdoor, custom zone sizes and selected world-map zones.
10. Test marker grouping: same resource/overlapping rectangles should merge transitively; different kinds or names remain separate; worst difficulty wins inside a merged group.
11. Test both visibility switches independently. Hidden minimap pins must not prevent learning; world-map checkbox should persist across reload.
12. Test profession filtering across characters who have/do not have Herbalism, Mining, Survival, Skinning or Lockpicking. Treasure should remain visible irrespective of those skills.
13. Test difficulty threshold boundaries: red/orange at requirement, yellow at +25, green at +50, gray at +100; unknown purple. Verify chest-tier level color boundaries separately.
14. Test the moving-creature skinning case: stored location should be described as a hunting spot, not permanent node.
15. Verify the built-in 29 herb artwork files load and correct inventory/client fallbacks resolve for mining, skinning, trees and chests.
16. Validate every configured custom outdoor map, especially zone aliases and map index shifts; capture screenshots with test descriptions.
17. Check usability with dense nodes, 300-group display cap, pointer hover tooltips and 85% gray opacity.

## P2 — maintainability, scope and release

18. Profile redraw frequency, grouping costs and the saved-node count on slow client hardware; the current update loop recomputes visible groups frequently.
19. Verify English-only `GetSkillLineInfo` names, `CHAT_MSG_SPELL_SELF_BUFF` grammar and chest-name substring rules on localized clients.
20. Preserve upstream Gatherer/MetaHunt credits and resolve **third-party artwork and code licensing**, plus this repository's currently absent LICENSE, before wider redistribution.
21. Clarify old project naming in portfolio materials: **Octo Gather** historically, **Gather Map** now.
22. Add carefully scoped automated tests for grouping, difficulty thresholds, and learning-state transitions where feasible; mock tests do not substitute for live WoW.
23. Record each user-observed game result and any actual code changes in DEVLOG, CHANGELOG and DECISIONS with a commit.

## Open creative decisions (not approved)

- Should the addon continue **learning only by experience**, or ever support optional user-imported routes?
- Should a player hide skinning/hunting memories separately from true fixed nodes?
- Should marker clusters become clickable groups or remain a purely visual overlay?
- Should the resource list become editable through a UI rather than source/migration scripts?
- What is the acceptable client performance budget for large account databases?
- Which custom-client zones/languages should be officially advertised after actual testing?

Keep existing interaction concepts intact until Babuni.dev chooses otherwise.
