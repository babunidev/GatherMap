# GatherMap — human–AI collaboration and provenance

**Creative owner and director:** Babuni.dev.

## Keep the actual creative author visible

The original project and its distinctive **self-learning** world-memory concept belong to Babuni.dev. Existing history also shows a coherent visual language of four colored corners, merging nodes, skill-aware coloring and a gradual expansion beyond herbs. The late documentation assistant did **not** originate those decisions.

Upstream third-party sources are explicitly acknowledged:
- **Gatherer** — minimap coordinate scaling and bundled herb artwork.
- **MetaHunt** — Grim Reaches zone map dimensions.
- **Interact** — optional external addon API integration.

Maintaining upstream credit matters just as much as distinguishing author-written code from AI-assisted documentation. No blanket open-source license has been established by the current repository tree.

## AI work actually performed on 2026-10-26

The assistant:
- Inspected repository files and history, including `GatherMap.lua` (1,237 lines), current TOC/README, both fixture tests, migration script, resource screenshots and September git diffs.
- Distinguished initial **Octo Gather** version 0.2.6 from today's **Gather Map** 0.4.3 and identified all substantive September milestones.
- Traced resource capture state and stored node structure, profession/level-based colors, custom maps, minimap/world-map marker grouping and 300-group cap.
- Documented the **old recursive Interact hook problem and source fix** without claiming that the fix was verified in-game.
- Explained account-wide database migrations, rename helper, third-party provenance, language constraints and possible performance risks.
- Expanded or created eleven Markdown docs: README, CONCEPT, ROADMAP, CHANGELOG, AGENTS and `docs/` architecture/design/content/decisions/devlog/collaboration.

This session provided **research, editorial organization and technical interpretation**. It did not inspect any private game account, change source/art/migration code, run the fixture tests, or claim responsibility for the original creative direction.

## Standard to use for future iterations

Document, alongside source changes:
1. **Creator direction:** What Babuni.dev wanted, what game feeling motivated it, and constraints.
2. **AI proposals:** What any assistant suggested or implemented, explicitly separate from the user's ideas.
3. **Alternatives and corrections:** Rejected marker styles, failed experiments, compatibility bugs and why direction changed.
4. **Creator decisions:** Only those actually accepted/rejected/postponed; do not upgrade suggestions into approvals.
5. **Implementation:** Which game scripts, art assets, migration code and documentation files changed; exact commit/PR.
6. **Verification:** Test command and version, in-game client details, results, screenshots and remaining unverified points.

Retrospective writing must cite real sources and remain privacy-safe: don't publish raw private conversations, local user paths, credentials or actual SavedVariables without permission. Portfolio material can summarize creative evolution and use the project's committed screenshots while retaining source credits.

The current audit is documentation-only and does not license third-party art or approve a redesign.

## November 4, 2026 — Forever data migration implementation

The Forever-only port remains under Babuni's creative direction: earlier discoveries, resource identities and the personal-learning design must survive changes to the game's map APIs. This checkpoint adds AI-implemented `GatherMapMigration.lua`, a physical SavedVariables backup helper, a multi-manifest correction to the historical OctoGather rename script, and regression fixtures for schemas and map-key safety.

Automated testing passed in the [successful Phase 6 GitHub Actions run](https://github.com/babunidev/GatherMap/actions/runs/41909880251), using dummy records and disposable PowerShell folders. It verifies copy-on-import, explicit mapping, weighted counts, refusal to repeat an import, guarded rollback and preservation of original files. It **does not** imply the AI tested the user's actual game installation, accessed personal SavedVariables, proved historical/Forever coordinate equivalence or obtained authorization for a public version.

## November 4, 2026 — Forever performance and reliability checkpoint

Babuni's established visual design and self-learning account-wide history remain the constraints. AI implementation added `GatherMapSpatial.lua`, revised `GatherMapMarkers.lua` and the Forever runtime's cache invalidation, reinforced map and saved-data guards, and extended the mocked display and capture fixtures. No original concept, resource set, marker style or third-party artwork was changed.

The synthetic CI checks exercise 24,000 indexed records and 12,000 densely overlapping markers, compare exact-radius queries, reject invalid data, and simulate another registered map provider. These results do not establish in-game FPS, a real two-addon installation, actual memory use or successful gameplay with Forever.

## November 4, 2026 — API audit, package validation and documentation consolidation

AI-assisted review used the Forever UI-source snapshot `1.60.1.70790` to cross-check map, skill, cast, loot and tooltip signatures; compared Git blob hashes for all 29 bundled herb icons against `jsb/Gatherer`; and prepared a local package inspector and exact in-game test plan. The README and roadmap were consolidated without rewriting the historical source or deleting prior planning evidence.

An earlier manual migration path was found to depend on matched names without independent coordinate evidence. The implementation now requires two separated, current-build anchor checks before a user can execute an import. The method remains an explicit user-driven safety check, not verified geometry for every node.

[GitHub Actions run 41920490126](https://github.com/babunidev/GatherMap/actions/runs/41920490126) passed the complete development suite, including a disposable 38-file ZIP. Automated compile, fixture and package tests remain distinct from an actual Forever session. Copyright permissions, release/version approval and CurseForge integration remain the human creative's decision and/or additional verification obligations.

## November 5, 2026 — gather recording triage and settings menu

Babuni reported that the installed addon loaded and showed its world-map checkbox but did not save actual harvested resources, and requested one compact button with all on/off settings. AI source investigation found the recording default was disabled independently of visibility, identified two Forever gathering spell IDs and added opt-in capture diagnostics, a safer delayed-loot retry and a four-row map menu. Lua mock tests were extended for the panel and recorder. These do not constitute an actual in-game success test or permission to publish a public version.

## November 5, 2026 — protected MapCanvas pin call and moving minimap marker

Babuni reported an actual Forever `ADDON_ACTION_BLOCKED` trace showing `Frame:SetPassThroughButtons()` in Blizzard's `MapCanvasMixin:AcquirePin`, plus a temporary minimap square following the character. AI investigation compared the captured call stack to the Forever UI-source implementation and identified the inherited mouse-passthrough method. Code overrides it only in GatherMap's own pin mixin and relies on the XML template for mouse-disabled behavior. It also reverses the minimap-facing rotation transform, checks for rotation-ignore mode and adds a `/gmap pinpos` diagnostic.

Regression fixtures simulate blocked inherited pin methods and player movement; [CI run 41963074092](https://github.com/babunidev/GatherMap/actions/runs/41963074092) passed under Lua 5.1 and 5.4, plus existing PowerShell/static checks. No live client was operated by AI. These changes should not be presented as verified in-game until the original error and moving-marker reproduction are retested there.

## November 5, 2026 — minimizing movement jitter without expensive full redraws

Babuni reported a minimap marker moving in visible steps and clarified that a nearby quest-objective indicator was normal Blizzard behavior. AI investigation found that the Forever runtime projected visible resource groups only at a 0.35-second refresh. The new code retains throttled resource grouping and builds a per-group fixed world-space center for frame-rate repositioning, with inverse projection and rotation/clipping guards. Tests simulate 0.016-second movement and require the resource-group call count not to increase during those frames.

No Blizzard quest indicator was modified. The private client was not accessible; smoothness and any performance impact remain game-unverified.

## November 5, 2026 — repeatable minimap group-shape regression

Babuni reported rectangle/square changes and snapbacks at roughly half-second intervals despite the earlier frame-rate tracking work. AI source review found that the 0.35-second rebuild still used viewport-clipped resource positions for transitive grouping, so group dimensions and identities changed as the player moved. The implementation now caches groups in a static world coordinate plane and checks only whole-group visibility on movement. The regression fixture simulates a two-node merged chest rectangle straddling the clip edge, requiring unchanged dimensions and no unnecessary regroup across multiple refreshes. The complete automated suite [passed on commit 4b9205a](https://github.com/babunidev/GatherMap/actions/runs/41967656417); this is source/mock evidence only. No actual Forever gameplay was performed by AI, and release approval was neither requested nor granted.
