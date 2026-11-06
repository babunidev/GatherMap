-- Forever resources: retained unchanged from the legacy 0.4.3 source.
-- Exact thresholds/assets require separate Forever and licensing verification.
local addonName, ns = ...
local herbRequirements = {
    ["Peacebloom"] = 1, ["Silverleaf"] = 1, ["Earthroot"] = 15,
    ["Mageroyal"] = 50, ["Briarthorn"] = 70, ["Stranglekelp"] = 85,
    ["Bruiseweed"] = 100, ["Wild Steelbloom"] = 115, ["Grave Moss"] = 120,
    ["Kingsblood"] = 125, ["Liferoot"] = 150, ["Fadeleaf"] = 160,
    ["Goldthorn"] = 170, ["Khadgar's Whisker"] = 185, ["Wintersbite"] = 195,
    ["Firebloom"] = 205, ["Purple Lotus"] = 210, ["Arthas' Tears"] = 220,
    ["Sungrass"] = 230, ["Blindweed"] = 235, ["Ghost Mushroom"] = 245,
    ["Gromsblood"] = 250, ["Golden Sansam"] = 260, ["Dreamfoil"] = 270,
    ["Mountain Silversage"] = 280, ["Plaguebloom"] = 285, ["Icecap"] = 290,
    ["Black Lotus"] = 300,
}

local mineralRequirements = {
    ["Copper Vein"] = 1,
    ["Ooze Covered Copper Vein"] = 1,
    ["Tin Vein"] = 65,
    ["Ooze Covered Tin Vein"] = 65,
    ["Silver Vein"] = 75,
    ["Ooze Covered Silver Vein"] = 75,
    ["Iron Deposit"] = 125,
    ["Ooze Covered Iron Deposit"] = 125,
    ["Gold Vein"] = 155,
    ["Ooze Covered Gold Vein"] = 155,
    ["Mithril Deposit"] = 175,
    ["Ooze Covered Mithril Deposit"] = 175,
    ["Truesilver Deposit"] = 230,
    ["Ooze Covered Truesilver Deposit"] = 230,
    ["Dark Iron Deposit"] = 230,
    ["Small Thorium Vein"] = 245,
    ["Ooze Covered Thorium Vein"] = 245,
    ["Rich Thorium Vein"] = 275,
    ["Ooze Covered Rich Thorium Vein"] = 275,
    ["Hakkari Thorium Vein"] = 275,
    ["Small Obsidian Chunk"] = 305,
    ["Large Obsidian Chunk"] = 305,
}

local miningLootNodes = {
    ["Copper Ore"] = "Copper Vein",
    ["Tin Ore"] = "Tin Vein",
    ["Silver Ore"] = "Silver Vein",
    ["Iron Ore"] = "Iron Deposit",
    ["Gold Ore"] = "Gold Vein",
    ["Mithril Ore"] = "Mithril Deposit",
    ["Truesilver Ore"] = "Truesilver Deposit",
    ["Dark Iron Ore"] = "Dark Iron Deposit",
    -- Thorium Ore alone cannot tell us whether Interact used a Small or Rich
    -- vein, so keep the generic fallback purple instead of guessing wrongly.
    ["Thorium Ore"] = "Thorium Vein",
    ["Small Obsidian Shard"] = "Small Obsidian Chunk",
    ["Large Obsidian Shard"] = "Large Obsidian Chunk",
}

-- Ordinary treasure chests have no skill requirement in the client tooltip.
-- These levels represent the chest tier, so their color follows character
-- level instead of a profession. Unknown/custom chest tiers remain purple.
local treasureLevels = {
    ["Battered Chest"] = 5,
    ["Tattered Chest"] = 15,
    ["Solid Chest"] = 20,
    ["Large Battered Chest"] = 25,
    ["Large Iron Bound Chest"] = 30,
    ["Large Solid Chest"] = 35,
    ["Buccaneer's Strongbox"] = 40,
    ["Bound Chest"] = 45,
    ["Large Mithril Bound Chest"] = 50,
    ["Large Darkwood Chest"] = 55,
}

local treeRequirements = {
    ["Simple Wood Tree"] = 5,
    ["Bright Wood Tree"] = 125,
    ["Shade Wood Tree"] = 175,
    ["Tropical Wood Tree"] = 225,
    ["Dead Wood Tree"] = 250,
    ["Star Wood Tree"] = 270,
}

local woodLootNodes = {
    ["Simple Wood"] = "Simple Wood Tree",
    ["Bright Wood"] = "Bright Wood Tree",
    ["Shade Wood"] = "Shade Wood Tree",
    ["Tropical Wood"] = "Tropical Wood Tree",
    ["Star Wood"] = "Star Wood Tree",
}

local resourceSkills = {
    herb = "Herbalism",
    mineral = "Mining",
    skin = "Skinning",
    lock = "Lockpicking",
    wood = "Survival",
}

local iconRoot = "Interface\\AddOns\\GatherMap\\Icons\\"
local herbIcons = {
    ["Peacebloom"] = iconRoot .. "HerbPeacebloom",
    ["Silverleaf"] = iconRoot .. "HerbSilverleaf",
    ["Earthroot"] = iconRoot .. "HerbEarthroot",
    ["Mageroyal"] = iconRoot .. "HerbMageroyal",
    ["Briarthorn"] = iconRoot .. "HerbBriarthorn",
    ["Stranglekelp"] = iconRoot .. "HerbStranglekelp",
    ["Bruiseweed"] = iconRoot .. "HerbBruiseweed",
    ["Wild Steelbloom"] = iconRoot .. "HerbWildSteelbloom",
    ["Grave Moss"] = iconRoot .. "HerbGraveMoss",
    ["Kingsblood"] = iconRoot .. "HerbKingsblood",
    ["Liferoot"] = iconRoot .. "HerbLiferoot",
    ["Fadeleaf"] = iconRoot .. "HerbFadeleaf",
    ["Goldthorn"] = iconRoot .. "HerbGoldthorn",
    ["Khadgar's Whisker"] = iconRoot .. "HerbKhadgarsWhisker",
    ["Wintersbite"] = iconRoot .. "HerbWintersbite",
    ["Firebloom"] = iconRoot .. "HerbFirebloom",
    ["Purple Lotus"] = iconRoot .. "HerbPurpleLotus",
    ["Arthas' Tears"] = iconRoot .. "HerbArthasTears",
    ["Sungrass"] = iconRoot .. "HerbSungrass",
    ["Blindweed"] = iconRoot .. "HerbBlindweed",
    ["Ghost Mushroom"] = iconRoot .. "HerbGhostMushroom",
    ["Gromsblood"] = iconRoot .. "HerbGromsblood",
    ["Golden Sansam"] = iconRoot .. "HerbGoldenSansam",
    ["Dreamfoil"] = iconRoot .. "HerbDreamfoil",
    ["Mountain Silversage"] = iconRoot .. "HerbMountainSilversage",
    ["Plaguebloom"] = iconRoot .. "HerbPlaguebloom",
    ["Icecap"] = iconRoot .. "HerbIcecap",
    ["Black Lotus"] = iconRoot .. "HerbBlackLotus",
}

local mineralIcons = {
    ["Copper Vein"] = "Interface\\Icons\\INV_Ore_Copper_01",
    ["Tin Vein"] = "Interface\\Icons\\INV_Ore_Tin_01",
    ["Silver Vein"] = "Interface\\Icons\\INV_Ore_Thorium_01",
    ["Iron Deposit"] = "Interface\\Icons\\INV_Ore_Iron_01",
    ["Gold Vein"] = "Interface\\Icons\\INV_Ore_Gold_01",
    ["Mithril Deposit"] = "Interface\\Icons\\INV_Ore_Mithril_02",
    ["Truesilver Deposit"] = "Interface\\Icons\\INV_Ore_TrueSilver_01",
    ["Dark Iron Deposit"] = "Interface\\Icons\\INV_Ore_Mithril_01",
    ["Small Thorium Vein"] = "Interface\\Icons\\INV_Ore_Thorium_02",
    ["Rich Thorium Vein"] = "Interface\\Icons\\INV_Ore_Thorium_02",
    ["Thorium Vein"] = "Interface\\Icons\\INV_Ore_Thorium_02",
    ["Small Obsidian Chunk"] = "Interface\\Icons\\INV_Stone_15",
    ["Large Obsidian Chunk"] = "Interface\\Icons\\INV_Stone_15",
}

-- GetItemInfo can return no texture when an item is not cached yet. Keep the
-- Vanilla Skinning materials explicit so that falling back never makes a low-
-- level leather look like Rugged Leather.
local skinIcons = {
    ["Ruined Leather Scraps"] = "Interface\\Icons\\INV_Misc_Pelt_Bear_Ruin_05",
    ["Light Leather"] = "Interface\\Icons\\INV_Misc_LeatherScrap_03",
    ["Light Hide"] = "Interface\\Icons\\INV_Misc_Pelt_Wolf_Ruin_02",
    ["Medium Leather"] = "Interface\\Icons\\INV_Misc_LeatherScrap_05",
    ["Medium Hide"] = "Interface\\Icons\\INV_Misc_Pelt_Boar_Ruin_02",
    ["Heavy Leather"] = "Interface\\Icons\\INV_Misc_LeatherScrap_07",
    ["Heavy Hide"] = "Interface\\Icons\\INV_Misc_Pelt_Wolf_Ruin_03",
    ["Thick Leather"] = "Interface\\Icons\\INV_Misc_LeatherScrap_08",
    ["Thick Hide"] = "Interface\\Icons\\INV_Misc_Pelt_Bear_Ruin_01",
    ["Rugged Leather"] = "Interface\\Icons\\INV_Misc_LeatherScrap_02",
    ["Rugged Hide"] = "Interface\\Icons\\INV_Misc_Pelt_Bear_Ruin_02",
    ["Thin Kodo Leather"] = "Interface\\Icons\\INV_Misc_LeatherScrap_06",
    ["Thick Wolfhide"] = "Interface\\Icons\\INV_Misc_Pelt_02",
    ["Shadowcat Hide"] = "Interface\\Icons\\INV_Misc_Pelt_01",
    ["Warbear Leather"] = "Interface\\Icons\\INV_Misc_Pelt_Bear_Ruin_05",
    ["Frostsaber Leather"] = "Interface\\Icons\\INV_Misc_Pelt_06",
    ["Chimera Leather"] = "Interface\\Icons\\INV_Misc_LeatherScrap_01",
    ["Devilsaur Leather"] = "Interface\\Icons\\INV_Misc_Pelt_03",
    ["Primal Bat Leather"] = "Interface\\Icons\\INV_Misc_Pelt_01",
    ["Primal Tiger Leather"] = "Interface\\Icons\\INV_Misc_Pelt_04",
    ["Core Leather"] = "Interface\\Icons\\INV_Ammo_FireTar",
    ["Pristine Hide of the Beast"] = "Interface\\Icons\\INV_Misc_MonsterScales_15",
}

local woodIcons = {
    ["Simple Wood Tree"] = "Interface\\Icons\\simple_wood_1",
    ["Bright Wood Tree"] = "Interface\\Icons\\oak_wood_1",
    ["Shade Wood Tree"] = "Interface\\Icons\\pine_wood_1",
    ["Tropical Wood Tree"] = "Interface\\Icons\\tropical_logs_1",
    ["Dead Wood Tree"] = "Interface\\Icons\\star_log_2",
    ["Star Wood Tree"] = "Interface\\Icons\\star_log_2",
}

local fallbackIcons = {
    mineral = "Interface\\Icons\\INV_Pick_02",
    skin = "Interface\\Icons\\INV_Misc_LeatherScrap_02",
    lock = "Interface\\Icons\\INV_Misc_Key_03",
    treasure = "Interface\\Icons\\INV_Misc_Chest_01",
    wood = "Interface\\Icons\\INV_Axe_01",
}

local colors = {
    red    = { 1.00, 0.12, 0.12 },
    orange = { 1.00, 0.50, 0.00 },
    yellow = { 1.00, 0.90, 0.10 },
    green  = { 0.20, 1.00, 0.20 },
    gray   = { 0.55, 0.55, 0.55 },
    unknown = { 0.70, 0.35, 1.00 },
}

local difficultyPriority = {
    unknown = 0, gray = 1, green = 2, yellow = 3, orange = 4, red = 5,
}


ns.resources = {
    herbRequirements = herbRequirements,
    mineralRequirements = mineralRequirements,
    miningLootNodes = miningLootNodes,
    treasureLevels = treasureLevels,
    treeRequirements = treeRequirements,
    woodLootNodes = woodLootNodes,
    resourceSkills = resourceSkills,
    herbIcons = herbIcons,
    mineralIcons = mineralIcons,
    skinIcons = skinIcons,
    woodIcons = woodIcons,
    fallbackIcons = fallbackIcons,
    colors = colors,
    difficultyPriority = difficultyPriority,
}
