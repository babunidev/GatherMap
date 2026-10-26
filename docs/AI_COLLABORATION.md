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
