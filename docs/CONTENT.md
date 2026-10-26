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

## Supported tree families

The custom Survival collection includes **Simple, Bright, Shade, Tropical, Dead and Star Wood Trees**. They depend on the custom client's Woodcutting/Survival behavior; standard Vanilla 1.12 cannot be assumed to have all of them.

## Map area content

The custom area dimension table includes **Hyjal, Scarlet Enclave, Lapidis Isle, Gillijim's Isle, Tel'Abim, Alah'Thalas, Gilneas, Icepoint Rock, Blackstone Island, Thalassian Highlands, Winter Veil Vale, Grim Reaches, Balor, Northwind, Moonwhisper Coast**.

Additional aliases translate a few old/current displayed names, including `Mount Hyjal` and `Island of Lapidis`. Other standard Vanilla maps use zone-name scaling and per-continent zoom metrics. The configured dimensions should be tested on the intended map clients before calling them accurate.

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
