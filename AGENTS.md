# GatherMap — development instructions for humans and AI collaborators

**Creative direction and authorship:** Babuni.  
**Current installed identity:** GatherMap, formerly OctoGather, manifest version 0.4.3 for Vanilla interface 11200.

## Read before changing anything

Start with `README.md`, `CONCEPT.md`, `ROADMAP.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/DEVLOG.md`, `GatherMap.lua`, `GatherMap.toc`, `Upgrade-SavedData.ps1`, and the tests. The project is a self-learning resource map, **not** a static imported map-database frontend.

Do not erase Babuni's creative authorship, invent older conversations, or claim past AI proposals were approved without evidence.

## Forever-only development scope (November 4, 2026)

All **new** implementation, testing, maintenance and future releases target **World of Warcraft Forever exclusively**. The historical 0.4.3 runtime and original 1.12 interface remain preserved on `main` and earlier tags; their presence is historical, **not** Forever compatibility. Development lives on `feat/forever-port` until explicitly reviewed and merged. See [docs/FOREVER_PORT.md](docs/FOREVER_PORT.md) for the technical preparation record.

Check the active Forever build/interface, Lua capabilities, events, map/profession APIs and addon restrictions before implementation. Baseline at preparation: **1.60.1 / Interface 16001**; the live build and package details require verification after client updates. Do not convert the legacy TOC to 16001 without porting its runtime, or describe proposed features as implemented.

Keep account-wide discovery data, the original personal-learning concept, marker colors/merging, historical attributions and migrations intact. Never create publishing tags, GitHub Releases or CurseForge uploads without explicit approval for that version.

## Preserve these source-level invariants

- **Record confirmed gathering/loot interactions**, not speculative available live spawns. Skinning saved points are hunting-location hints, not fixed nodes.
- Keep account-wide `GatherMapDB` across characters and calculate display difficulty from **current** profession ranks/level. Hide resources where the current profession is absent; always permit ordinary treasure.
- Preserve `herb`, `mineral`, `skin`, `lock`, `treasure`, `wood` category semantics, fallback defaults for older records and requirement handling.
- Use four-corner markers, world-map resource icons, hover text, and **same-resource-only** transitive merging. Do not turn separate resource types into one large group.
- Treat `Attack`/interaction timing and game events as fallible. Do not assert a game action succeeded merely because `SPELLCAST_START` fired.
- The `Interact` hook must **not recurse** when other addons change the global function. Run and preserve `tests/test_interact_hook.py` where possible.
- Maintain backward compatibility for schema-v1 herb-only data, schema-v2 skin requirements and the **OctoGatherDB → GatherMapDB** rename migration. No user data should be overwritten or discarded casually.
- Names and coordinates for custom zones require evidence; avoid guessed map sizes.
- The rendering loop is about **0.10 seconds** with a 300-group display cap per map; profile any change for performance.
- Keep third-party attribution for Gatherer icons/scaling and MetaHunt map data. No LICENSE file was observed: do not assign an unapproved license to authored or borrowed assets.

## Development and validation process

1. Record what Babuni wants to change and why, with clear boundaries and any proposed alternatives.
2. Explain whether a change affects resource recognition, persistence, UI, performance, client support or external attribution.
3. For runtime changes, run the existing focused Interact and migration fixture tests when their Python/Lua/PowerShell dependencies are available, and capture outputs.
4. Separately test on the intended WoW 1.12-compatible client with positive, negative and migration scenarios; mock/fixture tests aren't equivalent to actual client play.
5. Preserve backups and full original datasets during saved-variable migrations; test changes with copies, not sole surviving files.
6. Update README, CONCEPT, ROADMAP, CHANGELOG, AGENTS, and `docs/ARCHITECTURE.md`, `docs/DESIGN.md`, `docs/CONTENT.md`, `docs/DECISIONS.md`, `docs/DEVLOG.md`, `docs/AI_COLLABORATION.md` for substantial changes.
7. Credit the creative for the vision, accurately attribute the AI's implementation and documentation work, record rejected alternatives and actual commit/verification results.
8. Keep private SavedVariables, player coordinates, account information and credentials out of portfolio publications.

The 2026-10-26 pass is **documentation-only**, not permission to alter Lua, binaries, scripts or artwork.

## Repository-local documentation standard

Before writing or changing project documentation, read [docs/DOCUMENTATION.md](docs/DOCUMENTATION.md). These rules travel with this repository and do not depend on the babuni.dev ChatGPT Project. Preserve all project-specific technical, creative, canon, safety, licensing, and historical rules in this file; follow the linked standard for public first-person narrative, human–AI attribution, concise development journals, decision records, and evidence-based verification. **Babuni** is the human creative; **babuni.dev** is the website/portfolio, not the person. Preserve third-party credits and historical legal notices. References above to a dated “documentation-only audit” describe that past task, not a permanent ban on later authorized implementation.
