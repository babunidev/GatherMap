# GatherMap — narrative development journal

**Original creator and creative director:** Babuni.dev  
**Retrospective written:** October 26, 2026 from GitHub commits, repository README, Lua, migration utility, tests and screenshots. No missing original chat transcript has been fabricated.

## The first idea: let the map learn the player's routes

Gather Map began as **Octo Gather**, a Vanilla 1.12 map addon that learned a location *after* the player successfully picked a herb. It wasn't meant to supply a permanent imported atlas that magically knew every resource spawn. The player discovers something, and the client remembers it for later.

That distinction is the heart of the creative contribution. It is modest in terms of interface but meaningful in terms of experience: the world becomes legible through play. The record is **account-wide**, yet the markers can change their colors when another character views the same place with a different profession skill.

The initial substantive commit, **`0cd8e97` on September 5, 2026**, arrived as “Initial Octo Gather release.” It included a nearly finished herbalism prototype, `OctoGather.lua`, a 1.12 TOC at version **0.2.6**, 29 herb art files, and four documentation screenshots. That first version displayed saved herbs on both the minimap and selected zone world map with difficulty-colored rectangular outlines. It read current Herbalism skill and compared it against requirements, initially drawing a maximum of 100 pins.

The source already credited [Gatherer](https://github.com/jsb/Gatherer) for original zone scaling and herb artwork and [MetaHunt](https://github.com/DuvelCorp/MetaHunt) for the Grim Reaches map dimensions. Those aren't incidental footnotes: using verified existing map geometry and recognizable game artwork made the creator's own recording and UI logic usable in an older game client. The portfolio must distinguish **Babuni.dev's creative/system design** from those upstream resources.

The original repository history does not contain a separate recorded ideation conversation. This journal interprets the intent through the README and code, rather than claiming to quote an unavailable design discussion.

## September 6: the herb notebook becomes a resource atlas

The next day's changes were unusually concentrated. Commit **`7d4d029`** expanded the program to learn **mining, skinning, locked chests and ordinary treasure**. The data format needed a `kind` field because one location could no longer mean only “herb.” The addon started handling more tooltip, cast, loot and skill information to make those categories recognizable; the maximum rendered group count increased to 300.

That expansion revealed that not all “resource locations” mean the same thing. An herb sits at a ground node. Mining loot may identify its likely ore source, though it may not uniquely identify a vein. A skinned hide is produced by a **moving creature**, so a saved point is a useful hunting memory rather than a reliable stationary node. Locked chests use **Lockpicking** difficulty, while ordinary chests lack profession requirements and instead use a tier relative to the player's level.

Two later September 6 commits show small, deliberate improvements to accuracy: **`4eabd57`** corrected the difficulty formula for low-level skinnable creatures, and **`bd98a2d`** mapped known skin materials to better inventory icons. The current internal DB migration later clears older unreliable skin requirements while keeping saved locations—evidence that the design values preserving player discoveries more than preserving every early formula result.

The same day, **`8f890b2`** hid nodes when the current character lacked their profession, without deleting them from account-wide storage. This change protected readability. A new character shouldn't be confronted with every previous herbalism memory unless it has a reason to use it.

Then **`bec4f92`** added **Survival Woodcutting** and six specific tree types: Simple, Bright, Shade, Tropical, Dead and Star Wood. This mattered because the custom-client ecosystem supported a profession that standard Vanilla didn't. The project was becoming a flexible place-memory system rather than a fixed table of old Blizzard herbs.

## September 7: a visual language becomes distinct

The project originally used full colored rectangular outlines. Commit **`dc6f4ba`**, “Replace marker outlines with corner dots,” transformed that into **four small colored corner dots** on the minimap and a resource icon nested within four dots on the world map.

The system continues to group overlapping markers for the **same resource** into one larger rectangle; but the rectangle is now expressed only by its outer corners, leaving the underlying native map more visible. When a line of same-resource marker bounds overlaps transitively, the merge algorithm repeatedly checks the growing group. Other resources are kept independent, preventing a confusing combined cluster that means no particular thing.

Later that day **`9572119`** increased gray marker opacity to **85%** and refreshed screenshots. That is a concrete usability iteration, not merely a CSS-style cosmetic tweak. A marker representing an easy or low-value node still needs to remain visible enough to be useful.

The user-facing map has two independent display toggles. One is the chat command controlling minimap markers; another is the world-map checkbox. Hiding pins doesn't erase previously learned data, which fits the project's original premise of accumulating exploration memory.

## September 7: learning to coexist with other addons

The commit **`1cb631f`**, “Prevent recursive Interact hook chains,” tackles a technical problem that is especially interesting in a portfolio narrative. Gather Map supports the optional [Interact](https://github.com/lookino/Interact) hotkey. It needs to notice when that API is used because a subsequent loot event may identify a resource even when the game never exposed an ordinary object tooltip.

But WoW addons can replace global Lua functions. If Gather Map's wrapper always consults **one shared variable** holding a previous `Interact` function, another addon can wrap Gather Map, which then rewraps that addon, causing the supposedly old function reference to point into the new chain. The result can be recursive calls rather than one clean delegation.

The revised `InstallInteractHook` closes over a **different predecessor for each installed wrapper**, so an older wrapper continues pointing to the function it was created to wrap. It also checks for repeated installs and is invoked during later update checks to notice replacement.

That fix came with **`tests/test_interact_hook.py`**, a narrow regression fixture that uses Lua 5.1 through Python lupa to demonstrate the old chain's recursion and validate the new approach under synthetic conditions. The test is part of the project history; this documentation pass **did not execute it** and it cannot replace an actual WoW 1.12 integration test.

This is an example of why development process deserves a place in the finished portfolio: the visible result remains four harmless map corners, but it relies on subtle cooperation between independently authored addons.

## September 18: the project finds a more general identity

The September 18 commit **`0a01737`**, “Use provider-neutral names and client compatibility descriptions,” renamed **Octo Gather** to **Gather Map** throughout the addon title, Lua script, TOC, SavedVariables identifier, icon path and README. The manifest became version **0.4.3**.

The user-facing identity was broader, but the rename came with a technical cost. A player's old discoveries were in files named for the previous addon and a top-level variable **`OctoGatherDB`**. Simply changing the folder and enabling the new code would not automatically restore that data.

So the repository added **`Upgrade-SavedData.ps1`**: a migration helper that reads the TOC variables, copies relevant saved files, preserves originals, creates backups, refuses to overwrite an existing destination and rewrites top-level variable assignments without evaluating saved Lua. It also added **`tests/test_upgrade.ps1`** with synthetic account/character SavedVariables, Unicode text, backup checks and overwrite/path-name refusal checks.

This is a distinct iteration beyond maps and gathering. The project needed to respect the player's accumulated personal history precisely because the idea was to remember exploration. A migration that silently lost nodes would defeat the original concept.

No execution log for the PowerShell fixture was inspected in this audit. The source is a safeguard design, not proof that a user's actual files were successfully migrated.

## October 26: from code archive to portfolio record

The next visible commits on **October 26** updated the TOC/README author attribution to **Babuni.dev** and added a first set of short documentation files and links. The current documentation review expands those into a technical architecture, interaction-design record, content/provenance inventory, roadmap, decisions register and this narrative journal.

A complete public account must preserve several boundaries. The saved map is a **memory of observed points**, not a live spawn oracle. Skinning is a hunting approximation. Marker color derives from current skill, not a frozen reward label. Custom-client zones have configured dimensions rather than universal compatibility guarantees. The original visual and technical work belongs to the creator, while upstream artwork/data belong with the credited projects.

**Human contribution:** Babuni.dev's creative idea and authority over the implementation's direction. **AI contribution in this October 26 session:** source and Git audit, reconstruction of the feature/visual/history chronology, technical risk analysis, and authored/committed Markdown documentation. The inspected history cannot identify who wrote every earlier code line or recreate discussions that were not supplied.

**Verified this session:** Git tree and code structure, commit differences, docs/link state after the documentation commit (when checked). **Not performed:** modifying Lua or other runtime files, running a live Vanilla client, a PowerShell migration, the Python/Lua hook fixture, or reading the user's SavedVariables.

## The next creative and technical questions

What does the player experience on a crowded minimap with hundreds of saved locations? How does the marker system feel for a Skinner who is chasing moving creatures rather than revisiting static resource nodes? How should custom map aliases be tested across game clients? When should the system prefer an unknown purple marker over a guessed requirement? These are productive next questions, not approvals to replace the existing system.

The most revealing part of this project may be its pattern of iteration: **learn a herb, learn more kinds of world object, refine the marks, fix compatibility, preserve the player's memories through a rename**. That progression is worthy of a portfolio entry because the software's small map symbols tell a much larger story about preserving discovery.

## November 4, 2026: keeping the discoveries, changing the client

GatherMap's next development home is World of Warcraft Forever. With the older 1.12 code and its published releases preserved, the plan is to carry the personal gathering memory into the new client rather than turn it into a premade database of every spawn. The changing skill colors and four-corner markers are part of what makes that familiar map worth keeping.

Before touching the Lua, an AI-assisted repository review checked the manifest, code, earlier decisions, migration scripts and known third-party sources. A separate Forever branch was created for the work. The review also found permissions that cannot be assumed from attribution alone, so the inherited icons and measurements remain a documented question. This entry records preparation only; no part of the addon has been verified in Forever yet.

## November 4, 2026: a map that can begin again

Moving GatherMap to Forever requires more than changing the interface number. The older addon remembers what was gathered and how difficult it felt for each character, and those memories should not become casualties of a new map system. This development checkpoint keeps the old implementation intact while adding a separate Forever entry point.

AI-assisted work introduced modern map and profession access, a native map-pin overlay and a temporary test marker that never touches saved discoveries. Automatic gathering recognition remains deliberately inactive until it can distinguish confirmed successes from misleading spell and loot events. The source is now prepared for client testing, but no successful Forever gameplay test has been claimed. GitHub Actions subsequently passed Lua syntax and source/manifest checks for this checkpoint; the real map behavior and resource capture still require evidence from the Forever client.

## November 4, 2026: making a remembered place earn its place

A discovered herb or ore vein ought to appear because it was actually gathered, not just because a cast started and happened to stop nearby. That difference matters more once the map begins accumulating a character's history. The Forever implementation now has a separate, opt-in recorder that waits for spell success and the corresponding loot source before saving a new point.

AI-assisted work added classification for herbs, minerals, skinning materials and chests, plus checks for interruption, unrelated loot and duplicate events. The first recorder is deliberately cautious: missing evidence leaves the map unchanged. It still needs testing in the client before ordinary gathering can be relied upon, and the older discoveries remain preserved for a separate migration. The automated development checks passed with a mock client, but the real gathering and loot sequence is still an open in-game test.

## November 4, 2026: the same discoveries, different hands

One of GatherMap's oldest ideas is that the world remembers a place, while each character sees it differently. A new herbalist should not read a patch of herbs the way a practiced one does, and a borrowed pair of enchanted gloves may alter that answer for a while.

During the Forever port, AI-assisted research found that the color thresholds are not always separated by the neat intervals used in the old client code. The new module keeps the four-corner design, reads the current character's profession bonuses, and uses documented thresholds where available. Unknown resources remain purple rather than being assigned a convenient guess. Automated fixtures check the same saved nodes under different skill profiles; the actual game still has to confirm the behavior.

## November 4, 2026: four corners on a different map

What mattered to me about GatherMap's markers was always their small footprint. The colors belong at the corners, with enough space left for the world underneath. Bringing them to Forever required new map-canvas positioning, but not a new visual language.

AI-assisted work rebuilt the grouping around those same boundaries, replaced shared-tooltip handling with a small private label, and separated quick cursor feedback from slower map redraws. Tests simulate different map sizes and zoom levels, including the same saved discoveries displayed on a new canvas. The actual Forever map still needs to show whether those corners sit where they should.

## November 4, 2026: keeping the old map on the shelf

An old place on my map should not vanish merely because the game now gives it a different number. Those saved encounters belong to the journeys that led there, including the uncertain ones and the gathering spots that may no longer exist.

The Forever port now offers an AI-assisted, deliberately guarded way to copy some of that history. A zone must first be matched by its recorded name, then previewed and explicitly confirmed, while the original record stays untouched. Backups and a refusal to overwrite later discoveries matter more here than the convenience of an automatic conversion. The script and mock-data tests passed in the development workflow, but whether the old coordinates still land on the right patch of ground remains a question for the actual game.

## November 4, 2026: keeping the map quiet as it fills

The more places my map remembers, the less sense it makes to search every old discovery whenever a character takes another step. The map should stay a small companion, showing what is nearby without making the game feel heavier as its memory grows.

AI-assisted development separated location data from the moment-to-moment picture, adding a spatial index and making dense groups easier to calculate. The existing four corners and the 300-visible-group limit remain familiar. Synthetic tests now cover thousands of overlapping markers and a second mocked map provider. Actual performance and coexistence with other Forever addons still need to be observed in the game itself.

## November 4, 2026: keeping the road to Forever readable

The old GatherMap instructions still spoke mostly to a different client, even though the port's map, recording and data systems had already moved on. For anyone opening the repository now, the first page needed to describe what exists today and what has only been simulated.

AI-assisted work checked a newer Forever UI-source snapshot, separated old installation notes from the active instructions, consolidated the roadmap and wrote a test plan that keeps all gameplay checks together. The same pass traced every bundled herb icon back to matching Gatherer files, without assuming that a familiar source settles the licensing question. Historical map imports now ask for two real coordinate comparisons before copying anything. The work remains a development checkpoint; no claim of live success or public release follows from it.

## November 5, 2026: the checkbox was not the recorder

The first installed Forever build put its control on my map, yet harvesting a resource taught GatherMap nothing. Its old checkbox only governed visibility, while the recording system began disabled in the background. Having these controls apart made the problem hard to spot.

The requested change is a small map button with a compact menu for both overlays and the gathering recorder, plus optional diagnostics. AI-assisted debugging also recognized newer Forever gathering spell IDs and added a second opportunity to read loot details after a confirmed interaction. Automated checks can exercise the code, but seeing an actual harvest appear on the map remains the decisive game test.

## November 5, 2026: a marker that belongs to the ground

On my first Forever map test, the little square didn't behave as a remembered place should, and opening the world map triggered a protected-action error. The old icon wasn't the problem by itself; an inherited Blizzard map-pin method tried to change protected mouse settings while the addon was drawing.

AI-assisted investigation traced that call through Forever's native map canvas and narrowed the fix to GatherMap's own mouse-disabled pin template. The minimap's rotation direction was corrected as well, and a temporary test pin can now report its fixed position against the character's changing coordinates. Mock tests can guard those calculations, but the actual ground beneath that square is still the test that matters.

## November 5, 2026: giving a remembered place a steadier hand

The quest pointer on my minimap turned out to be doing exactly what Blizzard intended. GatherMap's little square was the one with an awkward gait: it held the right general location, but slid toward my character in short steps while moving through the world.

The previous overlay placed the whole set of markers only a few times per second. With AI-assisted changes, the map still groups nearby discoveries at that slower pace, while each existing marker keeps its own world-space anchor and can move smoothly against the player's position every frame. The four corners, the account's saved places and the quest overlay remain untouched. Actual movement in Forever will decide whether the new timing matches the terrain.
