# GatherMap — development journal

**Author:** Babuni.dev

## Source-grounded retrospective — 2026-10-26

A self-learning Vanilla WoW resource map that remembers gathered locations account-wide and displays profession-sensitive difficulty markers. The repository's organization reveals a concrete implementation pattern: GatherMap.lua captures interaction/gathering information and renders minimap/world-map markers; GatherMapDB stores resource positions, zones and subzones. The repository includes test_interact_hook.py and resource screenshots. The map learns from actual gathering instead of a fixed imported database; markers change color with character skill while account-wide discoveries remain available.

The chronological reasons for each earlier change cannot be established from the current snapshot. This session's AI role was to interpret and document existing material, not to originate the project. No tests were executed here. Run the hook test and verify successful gather detection, custom resource requirements, map placement, skill-dependent filtering and save/load in game.
