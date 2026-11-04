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

## November 4, 2026 — compatibility implementation choices

The port retains the original resource artwork, difficulty presentation and merge model in a new Forever runtime while leaving the legacy Lua and published tags untouched. This is a technical implementation checkpoint directed by the existing Forever-only project decision, **not** a decision to change the gathering concept.

- Native `MapCanvas` providers were selected instead of adding a new third-party map dependency for the first compatibility layer.
- New database reads use explicit `map:<UiMapID>` keys, rather than falsely treating old continent/zone indices as compatible; old values are preserved for a later backed-up migration.
- The old `Interact` wrapper and 1.12 gathering event handlers are not loaded on Forever. The new separate recorder is opt-in and defaults OFF until success and loot-source behavior can be tested in the actual game.
- A non-persistent `/gmap testpin` command permits visual testing before legacy data can be migrated; it does not record discoveries.
- The development manifest uses `0.5.0-alpha`, without tagging or publishing a version. Live client/API verification and third-party asset rights remain open.

## November 4, 2026 — conservative recording until verification

The Step 3 code introduces **source-correlated**, opt-in recording rather than the older model of recording directly on cast-stop, from arbitrary chat lines, or from an `Interact` timestamp. This retains the self-learning concept while avoiding known false-positive paths. An unrecognized source, unknown resource or unsupported old Survival action is kept out of new records rather than speculatively inferred.

Exact event behavior, lockpicking workflows and localized resource names remain unverified and therefore cannot justify enabling this feature by default. Legacy database keys are kept intact. This is an engineering safety choice, not a decision to remove any of the established resource categories.

## November 4, 2026 — resource-specific colors without guessed progression

The established four-corner color language is retained, but the old assumption that all resources change from orange to yellow to green to gray at fixed skill offsets has been replaced for documented Forever herbs and ores. Their individual published thresholds are more precise: Dreamfoil turns yellow at 290, not 295. Unknown names, special veins and conflicting observed requirements keep purple rather than inventing certainty.

Profession knowledge and effective rank are now separate concerns. Base rank, gear modifiers and temporary bonuses affect the current character's color, while the account-wide database stores discoveries only. Chest tiers remain level-based; historical woodcutting data remains stored but not presented as a supported Forever profession. These are implementation details consistent with the established design, **not new user-approved content or promises of in-game functionality**.

## November 4, 2026 — preserve the corners, modernize the overlay

The Phase 5 port keeps the already-established corner-marker design and independent minimap/world-map visibility controls. Repeated pairwise clustering was replaced by a spatial neighborhood search plus union-find, preserving same-resource-only transitive grouping without changing the underlying saved discoveries. World-map pins now rely on the native Forever-era map canvas for pan/position; clustering is recalculated after canvas scale and size changes rather than every frame.

A mouse-disabled independent hover label was selected instead of changing the game's shared GameTooltip. No new resource style, map information source, automatic database or dependency was introduced. Mocked tests cover geometry and data safety, but actual alignment, tooltip coexistence and unfamiliar map layouts are **not verified in game**.

## November 4, 2026 — do not guess the player's map history

Legacy continent/zone indexes cannot be assumed to equal Forever's numeric map IDs. The migration implementation therefore requires a manually linked, exact-name Forever zone, displays a dry-run count and requires explicit confirmation before copying any historic discoveries. An ambiguous or unsupported zone remains in the original database. The old name-change helper and the new zone-key importer serve different purposes.

Copies are non-destructive and preserve raw v1/v2/v3 history, with weighted merging of duplicate observations and an idempotency ledger. Snapshots allow rollback only if no newer data would be overwritten. An independent physical backup is still necessary because an in-SavedVariables snapshot does not protect against file loss. The exact equality of historical and Forever coordinate systems remains unverified; no public migration readiness is claimed.

## November 4, 2026 — optimize work, not the saved history

The Phase 7 implementation keeps the original 300 **displayed-group** cap instead of silently changing how many discoveries can be stored. Markers still group by matching name and kind with transitive overlap; a cached spatial index changes which records must be examined for each minimap view, not what data a character has learned. Skill changes invalidate marker colors, while new discoveries invalidate coordinates and layouts.

The code retains non-interactive pin ownership within GatherMap and does not override other addons' MapCanvas providers or the global GameTooltip. A mocked second provider survives redraws, but any assertion of actual compatibility with Mapster, TomTom, GatherMemory or custom minimap addons requires direct Forever gameplay testing. Memory use grows linearly for the optional spatial index; a 128-record threshold avoids that extra allocation on small maps. No creative redesign or public release was authorized by this engineering checkpoint.

## November 4, 2026 — safer migration and Forever-first documentation

The historical data importer previously allowed a zone-name link, preview and `apply ... confirm` even though same-name Forever maps could use different geometry. A new technical safety condition requires at least two separated legacy map anchors observed at matching positions on the same active client build, in addition to the existing physical backup and explicit confirmation. Missing or stale evidence refuses the copy. This prioritizes data integrity over convenience without changing the personal-discovery concept. The original records are retained regardless of result.

The public README and active roadmap now concern Forever exclusively. Historical 0.4.3 installation notes and earlier phased development are archived rather than erased. Recording remains opt-in; changing that default or the project license is **not** an approved decision. The original herb icons remain intact while their licensing requirements are investigated.

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
