# GatherMap — visual, navigation and interaction design

**Creator and creative director:** Babuni.dev.

## A map that remembers, not a map that reveals everything

Gather Map begins with a subtle design decision: it learns **after discovery**. The overlay is a personal memory of gathering and exploring, so it should remain recognizable as an annotation layer on the game's own maps rather than pretending to know live spawns.

The work is not an alternative full-screen navigation app. It attaches to the native **minimap** and **world map**, retaining their familiar spatial context.

## Four corners, space in the middle

A small resource is marked by **four 3-pixel colored corner dots**, leaving its center mostly clear on the minimap. When the world map is open, a resource icon sits inside matching colored corners. The design moved here from early full rectangular outlines, with a visible September 7 commit documenting that choice.

Hovering uses a separate compact label frame so the map can display the resource name without competing with the native GameTooltip used during gathering. This is especially appropriate in a 1.12 UI, where tooltip behavior and mouse layers vary.

<box>
![Minimap tooltip](../Screenshots/minimap-tooltip.png)
</box>

## Dynamic difficulty as a personal reading of the world

Red, orange, yellow, green, gray and purple are not static property labels printed on resources. They are interpretations relative to the **current character's skill or level**. Something once red can become gray as the player grows; an old account-wide discovery can become red again for a new character.

Purple is meaningful uncertainty: the addon cannot derive a requirement from its known table or an object tooltip. It avoids guessing. Gray uses **85% opacity**, a September adjustment from less legible variants.

Profession resources are hidden if the character doesn't know the corresponding skill. That keeps a low-level/new-profession minimap from becoming an irrelevant collection of everything the account has ever found. Ordinary treasure is the exception and can remain visible to any class.

## Grouping without erasing identity

Same-type and same-name markers merge when their drawn rectangles overlap. The group's four corners expand to the new overall bounds. If multiple nearby nodes have different requirements, the group's strongest difficulty priority is used. Resources with different names/types remain separate even when they overlap.

This prevents the visual clutter of duplicate marks without collapsing distinct types into meaningless giant boxes.

<box>
![Grouped world map markers](../Screenshots/world-map-merged-markers.png)
</box>

## Controls and affordances

The minimap overlay is governed by `/gmap on` / `off`, while a **Gather Map** checkbox on the world map controls the world overlay. Both are stored. No control removes learned locations or turns off discovery merely to hide markers.

The status command prints total saved points, type counts, skill ranks and whether the current zone has known scaling. This makes the system slightly diagnosable without introducing another settings window.

## Areas requiring genuine user testing

- Dense nodes vs. 300-group drawing cap.
- Different minimap sizes, UI scaling and indoor/outdoor zoom.
- Readability of colored 3px corner dots and 85%-opacity gray in varying environments.
- Hover zones and mouse-layer conflicts with other minimap addons.
- Whether skinning hunting areas need their own visual distinction from stationary herbs and ore.
- Whether hidden-profession defaults match the creator's preferred exploration style.

These are evaluation questions, **not** an approved redesign or a claimed accessibility test.
