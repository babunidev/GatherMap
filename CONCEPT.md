# GatherMap — concept and original creative direction

**Creator and creative director:** Babuni.dev  
**Public project:** Gather Map, formerly Octo Gather  
**Target:** Vanilla WoW 1.12-compatible addons, with additional named custom maps.

## Learn the world by exploring it

Rather than filling the map with an imported atlas from the start, Gather Map learns **from what the player actually gathers**. A successful action creates a local discovery that the player can recognize on a subsequent journey. It turns ordinary gathering into a gradual act of mapping.

That makes two forms of knowledge coexist: the world may contain a resource *now*, and the player may remember *where one previously appeared*. The addon deals in the second kind of knowledge. It does not know whether a mining vein or herb currently exists at a stored position. Skinning locations are even looser: they are memories of moving creatures yielding items, not static spawn-point promises.

The basic experience is personal and unobtrusive. It rewards curiosity and revisiting familiar routes without taking over navigation or gathering actions.

## A visible language of four corners

The visual system is intentionally different from a map full of solid opaque pins. **Four small corner dots** surround a location on the minimap; the world map adds the recognizable resource artwork inside those corners. The corner colors describe how hard the resource would be for the **character currently playing**. Red is too difficult, orange is just reachable, yellow and green become easier, gray is old territory, and purple communicates uncertainty.

A single account-wide memory can therefore look different for an experienced herbalist and a character who has yet to learn the profession. The data belongs to the player; the presentation is contextual.

When same-resource markers overlap, the dots are pushed to the outside of the merged group instead of stacking a blur of duplicate frames. Distinct resource types remain independent.

## From herbs to a broader ecology

The first September 5 version documented herbs. The September 6 commits expanded the world that could be remembered: minerals, chests, skinning, woodcutting trees and profession-aware hiding. This growth is a meaningful creative turn—not merely a bigger database. Each resource asks a different question of the interface:
- A herb or ore deposit has a fixed node, often a known gathering requirement.
- A chest may have a skill lock or only a tier relative to the character's level.
- A skinned creature leaves behind a hunting memory, not a node.
- A custom Survival tree belongs to a profession absent from standard Vanilla 1.12.
- Unknown custom resources may reveal their own requirements through a tooltip, or remain honestly purple.

The current implementation accommodates those distinctions while keeping one consistent visual vocabulary.

## The engineering context is part of the work

Additional client maps do not necessarily preserve numeric zone indices from classic Gatherer. The implementation uses zone names, aliases and specific scaling dimensions; it also handles an optional Interact hotkey API. The September 7 fix for recursion after other addons wrap `Interact` demonstrates how an apparently simple quality-of-life project has to cope with shared, mutable game-client functions.

In September the project moved from **Octo Gather** to the more provider-neutral **Gather Map** identity. The rename was both technical and documentary because SavedVariables, icon paths and installation names had to match—and old saved data needed a careful migration.

## Creative authorship, not an invented origin story

These principles are grounded in the original README, feature history and current source. The available commits do **not** reproduce all of Babuni.dev's original thinking or show who drafted every function. The creator's core ideas and direction remain credited to Babuni.dev. The AI documentation assistant's later analysis and wording are a separate contribution.

Do not replace this living exploration record with a generic imported-mining database, excessive map clutter or a conventional web-map dashboard without the creator's decision.
