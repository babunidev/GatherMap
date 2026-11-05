# GatherMap — resource content, coordinate data and art provenance

**Creative author / project maintainer:** Babuni.dev.  
**Source:** Committed Lua lookup tables, icon directory, screenshots and README.

## Data content categories

The addon supports six typed saved-resource families:

| Internal `kind` | Learned object or source | Requirement basis | Visual asset |
| --- | --- | --- | --- |
| `herb` | Herb node / recognized herb loot | Known Herbalism thresholds or tooltip | 29 bundled herb TGA icons |
| `mineral` | Veins/deposits or ore-loot fallback | Known Mining thresholds or tooltip | WoW ore icons / fallback |
| `wood` | Survival/Woodcutting trees | Known tree requirements or tooltip | Wood/tree client icons and fallback |
| `skin` | Looted leather/hide/scale/etc. | Derived from skinned creature level | Known native item icon or looted icon |
| `lock` | Lockpicking-required chest | Lockpicking requirement | Chest/key fallback texture |
| `treasure` | Regular named treasure chest | Known chest level tier, else unknown | Chest fallback texture |

An account-wide record contains `name`, normalized `x`, `y`, resource `kind`, required level/skill when known, a remembered icon texture when available, an occurrence `count`, `zoneName` and `areaName`. It is grouped under the `continent:zone` key in `GatherMapDB.nodes`.

The addon retains observations rather than current-spawn truth. Mining loot can be ambiguous (e.g. Thorium Ore doesn't reveal whether a vein was Small or Rich). For skinning the saved record is tied to **actual looted material** and a position where a creature was skinned; the creature can move.

## Forever migration representation (unreleased, November 4, 2026)

The original `GatherMapDB.nodes["continent:zone"]` representation is retained as historical data. New Forever observations use `GatherMapDB.nodes["map:" .. UiMapID]`. A manually approved `migrationLinks` entry associates a legacy key with a modern zone by matching historical `zoneName` against `C_Map.GetMapInfo`, but **matching a zone label alone cannot prove normalized coordinate identity**.

`migrationLedger` records successfully copied keys, and `migrationBackups` retains copies of original and before/after destination data for guarded rollback. The legacy source is never deleted. Unknown or custom zones remain in their original representation until actual Forever map/coordinate evidence exists. Actual private SavedVariables must never be committed to this repository.

## Supported tree families

The custom Survival collection includes **Simple, Bright, Shade, Tropical, Dead and Star Wood Trees**. They depend on the custom client's Woodcutting/Survival behavior; standard Vanilla 1.12 cannot be assumed to have all of them.

## Map area content

The custom area dimension table includes **Hyjal, Scarlet Enclave, Lapidis Isle, Gillijim's Isle, Tel'Abim, Alah'Thalas, Gilneas, Icepoint Rock, Blackstone Island, Thalassian Highlands, Winter Veil Vale, Grim Reaches, Balor, Northwind, Moonwhisper Coast**.

Additional aliases translate a few old/current displayed names, including `Mount Hyjal` and `Island of Lapidis`. Other standard Vanilla maps use zone-name scaling and per-continent zoom metrics. The configured dimensions should be tested on the intended map clients before calling them accurate.

## Forever six-color minimap/world-map marker textures

Babuni-directed AI-generated rounded, subtly textured colored dots are cropped and stored as `Textures/Markers/marker_red.tga`, `marker_orange.tga`, `marker_yellow.tga`, `marker_green.tga`, `marker_gray.tga`, `marker_purple.tga`. Each runtime asset is **16×16 RGBA** with transparent surroundings, shown as a **6×6 UI-unit texture** at each of four corners. The difficulty subsystem uses `unknown` as the internal key for purple. These new images are independent of the 29 historic herb icons; see [asset provenance](THIRD_PARTY_ASSETS.md).

## Bundled images and screenshots

The repository contains **29 `Icons/Herb*.tga` files** and **four `Screenshots/*.png` files** used for documentation:

- [Herbalism on Tanaris world map](../Screenshots/world-map-tanaris.png)
- [Minimap Firebloom label](../Screenshots/minimap-tooltip.png)
- [Overlapping same-resource marker groups](../Screenshots/world-map-merged-markers.png)
- [Custom Grim Reaches map](../Screenshots/world-map-grim-reaches.png)

The icon textures and coordinate constants are **not solely original Babuni.dev art/data**:
- [Gatherer](https://github.com/jsb/Gatherer) is credited for original Vanilla herb artwork and minimap scaling.
- [MetaHunt](https://github.com/DuvelCorp/MetaHunt) is credited for Grim Reaches dimensions.
- [Interact](https://github.com/lookino/Interact) is an optional integration API, not a bundled source asset.

The **attribution distinction matters** for Babuni.dev's portfolio: the creative accomplishment includes the data capture, normalization, skill-aware display, merging and interaction integration, while third-party artwork and measurements must retain their own credit.

## Source files and player privacy

Actual `GatherMapDB` saved records live in the user's WoW SavedVariables files, not in this repository. A public portfolio must not upload the creator's actual account data, private gameplay route history or other players' details without review.

The repository contains **no LICENSE** as of the October 26 audit. Resolve first-party and upstream licenses/redistribution terms before declaring assets free to reuse.

## November 4, 2026 — third-party provenance check for Forever

- **Gatherer icon files:** the 29 `Icons/Herb*.tga` filenames correspond to files in [jsb/Gatherer](https://github.com/jsb/Gatherer/tree/master/Icons). That repository's root did not show a LICENSE file. The [Gatherer CurseForge project](https://www.curseforge.com/wow/addons/gatherer) lists **GPLv2**, but a complete file-by-file license chain for this historical fork and its icons was **not** verified. Retain Gatherer/Norganna attribution and investigate the exact permission and license obligations before distributing a Forever package.
- **Gatherer map scaling:** original mapping/scaling constants are credited to historical Gatherer sources; verify their provenance separately from artwork.
- **MetaHunt map measurements:** `DuvelCorp/MetaHunt` on GitHub was not accessible at review time. A [MetaHunt mirror](https://octowow.st/git/Meta/MetaHunt) identifies its upstream as [Codeberg Duvelcorp/MetaHunt](https://codeberg.org/Duvelcorp/MetaHunt). The cited measurements and reuse terms were **not** independently matched to a specific licensed file. Preserve attribution and do not assert a redistribution grant.
- **GatherMap itself:** no root LICENSE was present at the reviewed commit. Do not invent or assign a project license; retain all source and historical credits while rights are investigated.

This is a provenance investigation, **not** permission to remove credited assets, claim ownership of them or publish a new release.

## Exact icon provenance check — November 4, 2026

A recursive Git blob-SHA comparison between `babunidev/GatherMap` (`feat/forever-port`) and `jsb/Gatherer` (`master`) checked all `Icons/Herb*.tga` paths: **29 present in each repository, 29 exact byte matches, zero differences**. The [Gatherer CurseForge license listing](https://www.curseforge.com/wow/addons/gatherer/license) and [SourceForge project](https://sourceforge.net/projects/gatherer/) specify GPLv2 for their Gatherer distributions. This establishes file identity with the historical repository, not an independently proven copyright/licensing chain for each image.

The [MetaHunt mirror](https://octowow.st/git/Meta/MetaHunt) was located, but the precise upstream geometry file/rights remain unverified. Full findings and unresolved publication requirements: [`docs/THIRD_PARTY_ASSETS.md`](THIRD_PARTY_ASSETS.md). No new license was assigned, and the same 29 icon files are unchanged.


## November 4, 2026 — Forever resource difficulty references

`GatherMapDifficulty.lua` adds separate **Forever-specific full skill-color boundaries** for 28 herbs and nine ore nodes, taken from the community-maintained Warcraft Wiki [Forever herbalism techniques](https://warcraft.wiki.gg/wiki/Forever_herbalism_techniques) and [Forever mining techniques](https://warcraft.wiki.gg/wiki/Forever_mining_techniques), consulted November 4, 2026. This information is distinct from the inherited, unverified minimum-requirement lookup in `GatherMapData.lua`. Actual colors and all thresholds still require in-game comparison.

Dreamfoil demonstrates why the old uniform skill offsets are insufficient: its minimum/yellow/green/gray levels are **270/290/315/370**. Some ore veins, variants and new Forever resources have no published complete row, and Skinning/Lockpicking have no validated full progression. Those cases are purple unless a directly observed minimum establishes red. Do not fill missing data by guessing. The data is used for presentation only and does not change account-wide node records.
