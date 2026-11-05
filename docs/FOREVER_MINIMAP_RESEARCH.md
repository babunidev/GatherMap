# Forever minimap positioning research — November 5, 2026

**Scope:** World of Warcraft Forever only; historical code studied as a reference, not ported verbatim. **Status:** Source comparisons and simulated Lua checks; no independent live-client retest of this fix.

## 1. Native golden gathering dots

The little gold resource dots from Find Herbs/Find Minerals are drawn by the game client's minimap tracking renderer. [ForeverPlusPlus's API research](https://github.com/xIGBClutchIx/ForeverPlusPlus/blob/main/docs/forever-api.md) and [Forever Minimap API declarations](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapDocumentation.lua) describe `C_Minimap.GetTrackingInfo`, `GetViewRadius` and tracking configuration, but no documented list of the exact drawn dot locations or an API for binding user-defined saved pins to those internal engine markers. GatherMap therefore needs its own **world-anchored visual frames** for historical discoveries. It must not modify Blizzard's resource dots, their tracking state or quest objectives.

## 2. Three comparable addon approaches

- [Historical Gatherer `Gatherer.lua`](https://github.com/jsb/Gatherer/blob/master/Gatherer.lua): its `Gatherer_OnUpdate` identifies nearby saved locations and recalculates offsets from the **player's position**, anchoring `GatherNote` frames on `Minimap`. It cached a nearby list and recalculated only after sufficient travel, but used old continent/zone map scales; **not a Forever-compatible implementation**.
- [GatherMate2 `Display.lua`](https://github.com/Nevcairiel/GatherMate2/blob/master/Display.lua): its update frame performs `UpdateIconPositions` between less frequent `UpdateMiniMap(true)` passes, while pins are keyed by saved node identity (coordinate/type), retain their world positions and change visual style only on node/scale/appearance changes. Its pin textures explicitly disable independent pixel-grid snapping via `SetSnapToPixelGrid(false)` and `SetTexelSnappingBias(0)`. The current GatherMate2 project [lists a Forever-supported 1.60.1 build](https://www.curseforge.com/wow/addons/gathermate2/files/9414760), but the exact source revision corresponding to that package has not been independently established.
- [ForeverPlusPlus `MinimapNodeIcons.lua`](https://github.com/xIGBClutchIx/ForeverPlusPlus/blob/main/ForeverPlusPlus/Modules/Map/MinimapNodeIcons/MinimapNodeIcons.lua): an actively Forever-oriented overlay projects discovered map positions relative to the player's coordinates, map width/height, minimap radius and facing. It repositions the frame from the current view and only resets `pin:SetSize` and icon/ring styling if the displayed node or its appearance has changed. Its probing of native minimap dots is **separate** from the drawing of saved map locations; it cannot turn GatherMap saved nodes into native renderer dots.

These approaches differ in implementation, but support the same principle: **saved world location and frame identity must not depend on the current viewport list index**. Nothing was copied from third-party code.

## 3. Why GatherMap behaved differently

Before this correction:
1. An expensive map-group pass ran every approximately 0.35 seconds, while a separate faster pass repositioned already-visible marker frames.
2. `DrawMinimap` called `AcquireMini(count)`, reusing a pooled frame based solely on its **current ordinal position**. When a resource entered/exited view and the list shifted, `Style(pin, group)` ran again on that same frame, potentially changing its width and height and producing the reported square/rectangle transitions.
3. `TrackMiniPositions` and `DrawMinimap` both returned immediately when `InCombatLockdown()` was true. The player's map continued scrolling, but markers stopped updating, causing them to ride along with the player until combat ended.
4. The 3px colored corner textures did not request non-snapped rendering; at fractional UI-scale and continuously changing frame offsets, independently snapped corners could add visible asymmetry. The actual proportion of the observed artifact attributable to pixel snapping is **not proven**.

The previous fix that grouped nodes in world coordinates reduced one kind of viewport-dependent clustering error, but **did not** solve ordinal frame ownership or the explicit combat freeze.

## 4. Targeted implementation

- Retain the cached, world-coordinate transitive groups and their original rectangle dimensions; unchanged group objects now **own a specific minimap frame** as long as they remain visible.
- On each slower visibility pass, select visible group objects first, release only frames whose group actually left view, then reuse free frames only for genuinely new visible groups.
- `Style` and `SetSize` run only on a group-to-frame assignment or when a new style/group cache is constructed—not on ordinary walking updates.
- The per-frame path reads the current player position and updates the **same active group frames**, even during combat. The protected world-map canvas provider still retains its combat restrictions.
- The corner textures opt out of pixel-grid snapping when those texture APIs exist. Corner dimensions remain 3 UI units, anchored to the four original frame corners.
- When map position, radius or projections are unavailable, invalidate or hide old markers rather than leaving stale frames attached to a moving minimap.
- Maintain the original 300 simultaneously visible marker limit, resource-kind/name separation, account-wide saved nodes, all six difficulty colors and the independent world-map overlay.

## 5. Evidence and remaining Forever tests

Mocked Lua checks must force the client combat flag, walk the player across resource entry/exit boundaries, assert the surviving marker retains **frame identity** and its four corners' dimensions, and show an unchanged group is not resized during routine redraws. They also preserve the previous tests for map rotation, zoom, spatial grouping, native world-map provider coexistence, migration and gathering capture.

**Required on-client verification:** in WoW Forever, check at least two nearby nodes while moving, while stationary, during and after combat, at different minimap zoom levels/UI scales and with rotation enabled/disabled. Compare the marker to Blizzard's own resource dot (only where one exists) and observe whether any residual periodic jump follows a position API update. Record the client build and `/gmap pinpos` data; mock passes are not an in-game success claim.

**Out of scope:** replacing GatherMap's four-corner design with ordinary tracking dots, scanning native dots, importing a third-party drawing library or altering Blizzard's tracking system.
