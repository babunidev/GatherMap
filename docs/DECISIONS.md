# GatherMap — evidence-based design decisions

**Creative authority:** Babuni.dev. This is a retrospective code/commit record, not an invented series of meetings.

## November 4, 2026 — confirmed Forever-only development direction

Babuni directed the port of GatherMap to **World of Warcraft Forever exclusively**, with a repository audit and preparation before runtime changes. This is a confirmed target decision, not confirmation that any feature is already working on Forever.

- Create a separate `feat/forever-port` development branch from `main` at `1df33f6365e47d885ee6a6ed0fbf87158a8ca726`.
- Preserve the original self-learning discovery design, difficulty-colored four-corner visuals, account-wide records and the `OctoGather` → `GatherMap` history.
- Keep 0.4.3/Interface 11200 runtime, older release tags and public downloads unchanged while the port remains unverified.
- Reverify the modern Forever APIs and game-specific systems; do not infer a working client from a TOC change.
- Keep rights and licensing questions open until the exact inherited assets and upstream conditions are verified.
- Require separate, explicit approval before any version is published.

No decision was made to import static spawn databases, remove saved resource kinds, select a mapping library or publish the port. See [FOREVER_PORT.md](FOREVER_PORT.md).

## Observed design evolution

| Date | Evidence | Design direction shown in the implementation |
| --- | --- | --- |
| Sep 5, 2026 | `0cd8e97` | Start with self-learned herbalism data, minimap + zone-world-map drawings |
| Sep 6 | `7d4d029` | Extend to mines, skinning, locked/ordinary chests and 300-pin group cap |
| Sep 6 | `4eabd57`, `bd98a2d` | Correct skinning requirement model and improve icon specificity |
| Sep 6 | `8f890b2` | Filter profession markers by current character without deleting shared nodes |
| Sep 6 | `bec4f92` | Add custom Survival trees / Woodcutting |
| Sep 7 | `dc6f4ba`, `9572119` | Shift from full outlines to four corner dots, then raise gray alpha |
| Sep 7 | `1cb631f` | Prevent recursive optional Interact hook chains; add focused regression script |
| Sep 18 | `0a01737` | Rename Octo Gather → Gather Map and migrate old SavedVariables safely |

The Git messages/diffs demonstrate **what changed**. They don't contain an independently recoverable conversation about which AI alternatives were debated, who wrote each source line, or why every change was preferred.

## Architectural tradeoffs visible today

- **Learned, not imported:** gives a personal exploration record; cannot show unknown locations or current live spawns.
- **Account-wide storage, character-aware rendering:** preserves one discovery memory but hides professions a given character cannot use.
- **Icon/resource-type categorization:** distinguishes herb, mining, wood, skin, locks and treasure, with each using a different requirement model.
- **Near-position deduplication:** uses a **0.004 x/y** window and weighted averaging, potentially combining distinct nodes located extremely close together.
- **Marker group merging:** combines the on-screen outlines for matching kind/name only, while leaving underlying saved database nodes untouched.
- **Ten redraws per second:** responsive to movement/zoom but potentially expensive for large saved databases.
- **Client zone indices:** compatibility with extra maps uses name lookup and custom sizes, but the primary DB key is still numeric continent/zone, which may shift across different clients.
- **English skill/action/tooltip matching:** avoids some complexity, but isn't guaranteed locale-neutral.
- **Optional Interact wrapping:** convenience requires careful wrapper chain ownership and regression coverage.
- **Rename with migration:** provider-neutral identity improves clarity but requires work to preserve earlier player data.

## Open questions requiring Babuni.dev decision

1. Should dense resource categories or skinning spots have user-controlled filters in addition to profession filtering?
2. Should future versions store a stable zone identity to support saved-data moves across clients with different zone indices?
3. Is the exact **0.004** dedupe window suitable for tightly packed herb/mining spawns?
4. Should rendering be made event-driven/adaptive rather than always running at ~10 Hz?
5. Which non-English locales and custom zones should be tested as actual supported environments?
6. Should the player see a confidence indicator for loot-inferred resources or moving-creature hunting spots?
7. How should Babuni.dev license the original code while retaining required credits and permissions for bundled art and upstream scaling data?

**Proposed alternatives remain proposals**, not prior author decisions. No implementation changes were made during the current documentation audit.
