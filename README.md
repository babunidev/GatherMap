# Gather Map

**Author:** Babuni.dev

Gather Map is a self-learning resource map overlay for World of Warcraft
1.12. It remembers successfully gathered herbs, minerals, and Survival
trees, plus skinning results, lockpicking practice chests, and ordinary treasure
chests. Saved locations appear as four difficulty-colored corner dots on the
minimap and as resource icons framed by matching corner dots on the world map.

Locations are saved account-wide in `GatherMapDB`, so every character can use
the same database and the locations remain available after logout or `/reload`.

![Saved herbs on the Tanaris world map](Screenshots/world-map-tanaris.png)

## How it works

- Successfully gather, mine, cut a tree, skin, or open a chest to teach Gather
  Map the resource and position.
- Normal interaction and the
  [Interact](https://github.com/lookino/Interact) hotkey are supported.
- Each location records its main map zone and the smaller minimap subzone name.
- Marker colors are recalculated from the current character's Herbalism,
  Mining, Survival, Skinning, or Lockpicking skill. Ordinary treasure chests
  compare their chest tier with character level.
- Profession markers are only displayed when the current character has the
  corresponding profession or skill. Their account-wide saved locations are
  retained when playing a character without that profession.
- Custom resources can learn their requirement when the tooltip includes a
  `Requires Herbalism (N)`, `Requires Mining (N)`, or similar line.

## Supported resources

- **Herbalism:** saves the herb node and compares it with Herbalism.
- **Mining:** saves ore veins and deposits and compares them with Mining.
- **Survival:** saves Simple, Bright, Shade, Tropical, Dead, and Star Wood Trees
  after successful Woodcutting and compares them with Survival. Markers only
  appear on characters who know Survival; Find Trees does not need to remain
  active after a location has been learned.
- **Skinning:** saves the leather, hide, scale, or other item actually obtained
  and compares the skinned creature's requirement with Skinning. These markers
  are hunting spots rather than exact spawn points because creatures move. The
  requirement follows Vanilla's low-level and high-level creature formulas, so
  the corner color changes as the character's Skinning skill increases. Known
  Vanilla leathers and hides always use their exact inventory icons, even when
  the client has not cached the looted item's texture yet.
- **Lockpicking:** saves world chests that expose a Lockpicking requirement and
  compares them with the rogue's Lockpicking skill. These markers are only
  displayed while playing a rogue.
- **Treasure chests:** saves ordinary open-world chests. Known Vanilla chest
  tiers compare with character level; unknown custom tiers appear purple.

## Map markers

### Minimap

The minimap displays four small colored corner dots at every saved location
currently in range. Move the mouse inside the corners to see the resource name
beside the cursor.

![A Firebloom marker and tooltip on the minimap](Screenshots/minimap-tooltip.png)

### World map

The selected zone's world map displays the resource icon between four colored
corner dots. Move the mouse over a marker to see its resource name. Use the
**Gather Map** checkbox in the upper-left corner of the world map to show or
hide the overlay; the setting is saved account-wide.

Nearby markers for the same resource merge into a larger rectangular marker
when their bounds overlap; its four dots move to the outer corners. Different
resources remain separate and may overlap, preventing unrelated locations from
merging into oversized markers.

![Merged same-herb markers on the world map](Screenshots/world-map-merged-markers.png)

## Difficulty colors

For professions, the corner color compares the saved requirement with your
current skill:

| Color | Meaning |
| --- | --- |
| Red | You cannot gather it yet |
| Orange | Current skill through 24 points above the requirement |
| Yellow | 25-49 points above the requirement |
| Green | 50-99 points above the requirement |
| Gray | 100 or more points above the requirement |
| Purple | The resource requirement or chest tier is not known |

Ordinary treasure chests use the same progression idea with character level:
red is well above your level, yellow is around your level, green is below it,
and gray is at least ten levels below it.

Gray markers use 85% opacity on both maps so low-value locations remain
slightly subdued without becoming difficult to see. All other colors use full
opacity.

## Commands

- `/gathermap` or `/gathermap count` — show counts by resource and current skills.
- `/gathermap on` — show minimap markers.
- `/gathermap off` — hide minimap markers while continuing to learn locations.

## Installation

1. Extract or copy the `GatherMap` folder into `World of
   Warcraft\Interface\AddOns`.
2. Restart WoW or run `/reload` if the add-on was already installed.
3. Enable **Load out of date AddOns** on the character screen if the client asks
   for it.

No other add-on is required. Interact integration is enabled automatically when
Interact is installed.

## Upgrade from a previous add-on name

If you used this add-on under a previous folder name, migrate your saved data
before playing with the new installation. A normal file replacement is not
enough when the folder and saved-variable names change.

1. Fully close the game. Keep the previous add-on installed for this step.
2. Install the new `GatherMap` folder beside the previous folder.
3. Open PowerShell in `GatherMap` and run the following, replacing both example values:

   ```powershell
   .\Upgrade-SavedData.ps1 -ClientPath "C:\Games\World of Warcraft" -PreviousAddonName "PreviousAddonFolder"
   ```

The helper reads the previous TOC, copies account-wide and per-character saved
data to the new names, and saves backups under `AddonUpgradeBackups` in the
game folder. It keeps the original files intact and refuses to overwrite
existing saved data for the new add-on. It does not execute saved Lua code.

4. Disable the previous add-on and enable **GatherMap** before entering the world.
5. Check your settings and saved data. Keep the backups until you have verified them.

Further updates using the same add-on name keep your saved data normally.
On other operating systems, back up the files, then copy the previous add-on's
`.lua` file in each `WTF/Account/**/SavedVariables` directory to `GatherMap.lua`.
Change only the top-level variable name declared in the old TOC to the matching
name in the new TOC; leave its table contents unchanged. Do this with the game closed.

## Important limitations

Gather Map markers represent saved possible spawn locations or, for skinning,
places where a resource was previously obtained. Blizzard's yellow tracking
dot still indicates whether a tracked herb or mineral is currently spawned;
the Vanilla 1.12 API does not reveal the identity of an individual live
tracking dot.

World-map markers appear on a specifically selected zone map, not on the full
continent view. Gather Map includes minimap dimensions for supported custom outdoor and event maps: Hyjal, Scarlet Enclave, Lapidis Isle,
Gillijim's Isle, Tel'Abim, Alah'Thalas, Gilneas, Icepoint Rock, Blackstone
Island, Thalassian Highlands, Winter Veil Vale, Grim Reaches, Balor, Northwind,
and Moonwhisper Coast. Custom areas inside an existing Vanilla zone, such as
Tirisfal Uplands, automatically use their parent map's dimensions.

![Herbalism markers in the custom Grim Reaches zone](Screenshots/world-map-grim-reaches.png)

## Credits

- Minimap coordinate scaling and bundled herb artwork are based on the original
  [Gatherer](https://github.com/jsb/Gatherer) project for Vanilla WoW.
- Grim Reaches dimensions use map data from
  [MetaHunt](https://github.com/DuvelCorp/MetaHunt).
