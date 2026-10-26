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
