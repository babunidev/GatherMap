# GatherMap — evidence-based design decisions

**Creative authority:** Babuni. This is a retrospective code/commit record, not an invented series of meetings.

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

## November 5, 2026 — centralize toggles, retain verified capture safeguards

Babuni requested that the single world-map checkbox be replaced by a compact **GatherMap** button opening a small menu containing all existing on/off options. The approved user interaction groups independent minimap and world-map visibility with the experimental gathering recorder and opt-in diagnostic messages. No display setting deletes discoveries or silently enables recording. Default recording remains disabled until observed live-client evidence permits changing policy.

A source review identified two additional possible reasons for silent recording failure: missing active Forever herbalism/mining IDs and loot-slot data becoming available after `LOOT_READY`. Explicit spell IDs and a second `LOOT_OPENED` attempt were added while retaining the successful cast + correlated loot-source requirement. The initial report establishes that the old installation did not record; it does not establish that the new implementation has worked in Forever.

## November 5, 2026 — keep the map input owned by Blizzard

The first Forever world-map test produced a protected-call report for `Frame:SetPassThroughButtons()` in Blizzard's map-canvas acquisition path. The native pin provider remains the intended implementation, but GatherMap's non-interactive marker template does not need mouse passthrough configuration. The targeted fix overrides that callback only on GatherMap's own pin mixin and lets the XML template disable mouse input. No global Blizzard mixin, hook or other addon provider is modified.

A separate minimap report said a small square moved with the player instead of remaining at a recorded location. The projection's facing rotation was reversed and is corrected; the client rotation-ignore API is now respected. A new temporary-pin position diagnostic and walking mock test help distinguish geometry from in-game map-data behavior. It is not yet known whether these changes fully resolve the observed live motion.

## November 5, 2026 — retain throttled grouping, update positioning every frame

The latest Forever playtest clarified that the overlapping quest-objective indicator was Blizzard's normal map overlay. GatherMap's separate symptom was a fixed marker that visually jumped or tugged toward the player as the character walked. The source rendered positions only during a 0.35-second full regrouping pass. Moving the expensive grouping to every frame would worsen performance, so the engineering fix retains slow grouping but stores each displayed group's world-space anchor and updates the existing noninteractive marker frames between passes.

This preserves the original four-corner markers, SavedVariables, independent toggles, resource grouping and 300-group display limit. The source solution is covered by short-frame fixtures, but no direct Forever FPS or smoothness evidence exists yet.

## November 5, 2026 — fixed-world grouping instead of a moving viewport

A real Forever playtest established that faster marker repositioning alone did not fix the layout: grouped corner markers changed from rectangles to squares as the player moved, typically at the slower regrouping cadence. Source analysis found the grouping set itself was changing because it was clipped to the minimap before clustering. The decision is to **group the world data in a stable coordinate plane**, then clip only the already-grouped results for display.

This preserves the original transitive merging and potentially rectangular four-corner shapes rather than forcing every marker to be square. It avoids making costly resource grouping run each frame. The technical cost is a full-map group cache, plus a spatial index for large databases, invalidated on meaningful data/zoom/style changes. Real rotating-minimap and large-group presentation still require testing.

## November 5, 2026 — stop reassigning visible frames, keep updating during combat

After two attempted rendering corrections, the client still showed intermittent shape flipping and, crucially, markers frozen to the minimap during combat. The combat freeze was traced to two explicit `InCombatLockdown` checks in minimap-only paths. The other suspected cause was confirmed in source: a pooled frame could be reassigned at every slow redraw based on its **list index**, changing its size and identity as other groups came into view.

The approved intent remains fixed world locations and four-corner rectangles. Rather than replacing the marker system with Blizzard's unaddressable internal resource dots or importing another addon's code, the implementation now follows the shared principle seen in GatherMate2 and ForeverPlusPlus: **stable frame ownership and movement-only position updates**. The original world-map provider remains separate; combat restrictions are preserved only where required. Texture snapping is disabled where supported. The source-level reasoning is recorded in `docs/FOREVER_MINIMAP_RESEARCH.md`; the actual client result is still a pending verification.

## November 5, 2026 — switch the corner glyphs to six authored images

After substantial minimap stability fixes, Babuni requested replacing flat, generated-in-code color squares with the six already generated, slightly rounded and subtly textured difficulty icons. The design continues to use **four corner dots** surrounding an otherwise empty center, and retains both isolated squares and merged rectangles. Six transparent 16×16 RGBA TGA files are used at a 6×6 display size. This is deliberately **not** a nine-slice image or a new parent-marker geometry system, because merged rectangles need arbitrary width/height without stretching artwork.

The colors remain red, orange, yellow, green, gray and internal `unknown` rendered purple; gray remains at 85% parent opacity. Both minimap and world-map corners use the same local assets. The historical 3px flat-color source remains in git history, and existing saved discoveries and third-party art are unchanged. Client appearance and any reduction in flicker remain to be observed.

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

## Open questions requiring Babuni's decision

1. Should dense resource categories or skinning spots have user-controlled filters in addition to profession filtering?
2. Should future versions store a stable zone identity to support saved-data moves across clients with different zone indices?
3. Is the exact **0.004** dedupe window suitable for tightly packed herb/mining spawns?
4. Should rendering be made event-driven/adaptive rather than always running at ~10 Hz?
5. Which non-English locales and custom zones should be tested as actual supported environments?
6. Should the player see a confidence indicator for loot-inferred resources or moving-creature hunting spots?
7. How should Babuni license the original code while retaining required credits and permissions for bundled art and upstream scaling data?

**Proposed alternatives remain proposals**, not prior creative decisions. The earlier October 26 documentation-only audit did not modify runtime files; subsequent Forever source development is recorded separately.

## November 6 — investigate recognition without weakening confirmation

Babuni requested investigation of missing new discoveries and a general review. AI implementation adds diagnostic distinctions and fixes a reproduced delayed-item-name retry defect. Generic loot and skill increases remain insufficient to write a discovery. The subsequent live Silverleaf trace identified 2368 in both SENT and SUCCEEDED; recognition now includes that evidence-backed herb ID. Other rank IDs are not guessed. Recording defaults and data migration remain unchanged.
