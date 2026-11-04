# Historical GatherMap 0.4.3 — archived client instructions

**Historical reference only.** This project now supports **World of Warcraft Forever exclusively**; the 1.12-compatible runtime remains in the repository to preserve provenance and data migration logic, not as a currently supported install.

The last public legacy manifest was [`GatherMap.toc`](../GatherMap.toc) (`Interface: 11200`, version `0.4.3`) and loaded [`GatherMap.lua`](../GatherMap.lua). It used an optional `Interact` dependency and historical `continent:zone` map keys. The previous 1.12 installation required `GatherMap.toc`, `GatherMap.lua` and `Icons/` together inside `Interface/AddOns/GatherMap/`.

Legacy recording covered herbs, minerals, skinning materials, ordinary chests, lockpicking and custom Survival/Woodcutting trees; in-game behavior was never independently confirmed during the modern repository audit. Source data includes older schema-v1/v2/v3 migrations and historical normalization constants. Do not infer Forever support from this client.

- Historical public GitHub tag/release: [v0.4.3](https://github.com/babunidev/GatherMap/releases/tag/v0.4.3).
- Historical OctoGather rename helper: [`Upgrade-SavedData.ps1`](../Upgrade-SavedData.ps1) (separate from modern map-key migration).
- Detailed source evidence: [`docs/FOREVER_PORT.md`](FOREVER_PORT.md) and [`docs/CONTENT.md`](CONTENT.md).
- Earlier plans and source-audit notes: [roadmap archive](ROADMAP_ARCHIVE_2026-11-04.md).

No further 1.12/Vanilla/Classic development or release is planned.
