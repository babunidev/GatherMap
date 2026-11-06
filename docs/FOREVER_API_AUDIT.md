# Forever API compatibility audit — November 4, 2026

**Scope:** GatherMap Forever development only, not a claim of live gameplay success.

## Reference baseline

The [Gethe/wow-ui-source `forever` branch](https://github.com/Gethe/wow-ui-source/tree/forever) was checked at commit [`eac30af`](https://github.com/Gethe/wow-ui-source/commit/eac30af597e5aaa43a60f6675ef5fdcea100375f), published November 4, 2026 at 18:16 UTC and labeled **1.60.1 (70790)**. This is a client-UI-source snapshot; **the build installed on the player's machine was not read**. Forever's documented Interface remains `16001`. Confirm with `/dump GetBuildInfo()` inside the client before release.

| GatherMap use | Source evidence | Verdict / limitation |
| --- | --- | --- |
| Skill lines and bonuses | [SkillInfoDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SkillInfoDocumentation.lua): `GetNumSkillLines`, `GetSkillLineInfo`, `GetSkillLineInfoByID`, fields `rank`, `modifier`, `tempPoints`, `SKILL_LINES_CHANGED` | Confirmed in API declarations; effective values not tested in-game |
| Profession fallback | [TradeSkillUIDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/TradeSkillUIDocumentation.lua): `GetProfessionInfoBySkillLineID` | Present; historical profession IDs and modifier behavior require actual character testing |
| Map and positions | [MapDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua): `GetBestMapForUnit`, `GetMapInfo`, `GetPlayerMapPosition`, `GetWorldPosFromMapPos` | Present. World-position input is a **vector2**, not an arbitrary Lua table; require `CreateVector2D` |
| Minimap radius | [MinimapDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapDocumentation.lua): `C_Minimap.GetViewRadius` returns yards | Present; map rotation, clipping and scale remain game-unverified |
| Gathering cast events | [UnitDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua): `UNIT_SPELLCAST_SENT(unit,target,castGUID,spellID)`, `UNIT_SPELLCAST_SUCCEEDED(unit,castGUID,spellID,castBarID?)`; failed/interrupted equivalents | Signatures confirmed; events may include **secret values**, and correlated loot timing remains game-unverified |
| Loot window events | [LootDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/LootDocumentation.lua): `LOOT_READY(autoloot)`, `LOOT_OPENED(autoLoot,isFromItem)`, `LOOT_CLOSED` | Declared; ordering/autoloot behavior still requires live testing |
| Loot-source ownership | [Warcraft Wiki GetLootSourceInfo](https://warcraft.wiki.gg/wiki/API:GetLootSourceInfo): returns GUID/quantity pairs; GameObject sources possible | Documented on modern UI; source GUID form, absence and restrictions are not proven for all Forever objects |
| World cursor tooltip | [TooltipInfoDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua): `C_TooltipInfo.GetWorldCursor` | Present; returned types/lines for Forever resources unverified |
| World map pins | [Blizzard_MapCanvas](https://github.com/Gethe/wow-ui-source/tree/forever/Interface/AddOns/Blizzard_MapCanvas): native provider and pin mixins | Source model available; exact template mixin resolution, pin layering, zoom refresh and combat taint still need in-game confirmation |

## Implementation findings

- Forever's `_Camelot.toc` takes precedence over a historical bare `.toc` in observed Forever-specific addon implementations; do not confuse the legacy `11200` manifest with the development `16001` manifest. See [Forever addon field guide](https://github.com/mparke/forever-addons/blob/main/docs/research/forever-addon-field-guide.md); live loading still must be checked.
- The global `GatherMapForeverWorldPinMixin` must be defined **before** `GatherMapWorldPins.xml` references it. The development manifest now lists the runtime before its template.
- The modern map API explicitly takes `vector2` for world-map projection. The runtime now fails closed if `CreateVector2D` is absent rather than passing an unverified table substitute.
- Gathering recording remains **OFF** by default. API presence and syntactic tests cannot prove a successful herb/ore/skin/treasure capture in Forever.
- Existing `C_Map`, tooltip, effective-skill and provider paths contain defensive checks, but their combat-specific secret-value behavior and API return semantics have **not** been tested on the installed client.
- New base game resources, named extra zones and Survival/Woodcutting support are not asserted without game evidence.

## Remaining API verification

Record the installed build and Interface first. Trace observed `UNIT_SPELLCAST_*`, `LOOT_READY`, `LOOT_CLOSED`, GUID/source availability, tooltip type and `C_SkillInfo` data using safe, non-personal diagnostics. Test world-pin template loading, `MapCanvas` provider callbacks, `CreateVector2D` and combat restrictions on that build. Only then reclassify any runtime behavior from source-confirmed to tested-in-game.

## November 6 — local installation and event recheck

Local installation metadata reports Forever **1.60.1.70790**, matching the existing source baseline; this is not an in-client GetBuildInfo result. The current upstream [Unit declarations](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua) still declare SENT(unit,target,castGUID,spellID) and SUCCEEDED(unit,castGUID,spellID,castBarID). A live Silverleaf gather supplied SENT(player,target,castGUID,2368) and SUCCEEDED(player,castGUID,2368,castBarID); these confirm that payload for the observed action. Recognition now includes 2368. No private GUID is retained here.
