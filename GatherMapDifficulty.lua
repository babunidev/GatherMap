-- GatherMap — WoW Forever skill-aware marker colors.
-- The first/yellow/green/gray breakpoints below come from the *Forever-specific*
-- node tables on Warcraft Wiki, reviewed November 4, 2026; not independently
-- measured in the user's game. Unlisted nodes and legacy-only categories are
-- deliberately NOT assigned speculative complete thresholds.
local addonName, ns = ...
local reference = {
    herb = {
        ["Peacebloom"] = { 1, 25, 50, 100 },
        ["Silverleaf"] = { 1, 25, 50, 100 },
        ["Earthroot"] = { 15, 40, 65, 115 },
        ["Mageroyal"] = { 50, 75, 100, 150 },
        ["Briarthorn"] = { 70, 95, 120, 170 },
        ["Stranglekelp"] = { 85, 110, 135, 185 },
        ["Bruiseweed"] = { 100, 125, 150, 200 },
        ["Wild Steelbloom"] = { 115, 140, 165, 215 },
        ["Grave Moss"] = { 120, 145, 170, 220 },
        ["Kingsblood"] = { 125, 150, 175, 225 },
        ["Liferoot"] = { 150, 175, 200, 250 },
        ["Fadeleaf"] = { 160, 185, 210, 260 },
        ["Goldthorn"] = { 170, 195, 220, 270 },
        ["Khadgar's Whisker"] = { 185, 210, 235, 285 },
        ["Wintersbite"] = { 195, 220, 245, 295 },
        ["Firebloom"] = { 205, 230, 255, 305 },
        ["Purple Lotus"] = { 210, 235, 260, 310 },
        ["Arthas' Tears"] = { 220, 245, 270, 320 },
        ["Sungrass"] = { 230, 255, 280, 330 },
        ["Blindweed"] = { 235, 260, 285, 335 },
        ["Ghost Mushroom"] = { 245, 270, 295, 345 },
        ["Gromsblood"] = { 250, 275, 300, 350 },
        ["Golden Sansam"] = { 260, 285, 310, 360 },
        ["Dreamfoil"] = { 270, 290, 315, 370 },
        ["Mountain Silversage"] = { 280, 305, 330, 380 },
        ["Plaguebloom"] = { 285, 310, 335, 385 },
        ["Icecap"] = { 290, 315, 340, 390 },
        ["Black Lotus"] = { 300, 325, 350, 400 },
    },
    mineral = {
        ["Copper Vein"] = { 1, 25, 50, 100 },
        ["Tin Vein"] = { 65, 90, 115, 165 },
        ["Silver Vein"] = { 75, 100, 125, 175 },
        ["Iron Deposit"] = { 125, 150, 175, 225 },
        ["Mithril Deposit"] = { 175, 200, 225, 275 },
        ["Truesilver Deposit"] = { 230, 255, 280, 330 },
        ["Dark Iron Deposit"] = { 230, 255, 280, 330 },
        ["Small Thorium Vein"] = { 245, 270, 295, 345 },
        ["Rich Thorium Vein"] = { 275, 300, 325, 375 },
    },
}
local skillIDs = { herb = 182, mineral = 186, skin = 393, lock = 633 }
local skillNames = ns.resources.resourceSkills
local kindByID = {}
for kind, id in pairs(skillIDs) do kindByID[id] = kind end

local state = {}
local function Empty()
    return { rank = 0, modifier = 0, tempPoints = 0,
        effective = 0, present = false }
end
for kind in pairs(skillIDs) do state[kind] = Empty() end

local function PublicNumber(n)
    if issecretvalue and issecretvalue(n) then return nil end
    if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge then
        return nil
    end
    return n
end

local function FromSkillInfo(info)
    if type(info) ~= "table" or info.isHeader then return nil end
    local base = PublicNumber(info.rank)
    if not base or base <= 0 then return nil end
    local modifier = PublicNumber(info.modifier) or 0
    local tempPoints = PublicNumber(info.tempPoints) or 0
    return { rank = base, modifier = modifier, tempPoints = tempPoints,
        effective = math.max(0, base + modifier + tempPoints), present = true }
end

local function FromProfessionInfo(info)
    if type(info) ~= "table" then return nil end
    local base = PublicNumber(info.skillLevel)
    if not base or base <= 0 then return nil end
    local modifier = PublicNumber(info.skillModifier) or 0
    return { rank = base, modifier = modifier, tempPoints = 0,
        effective = math.max(0, base + modifier), present = true }
end

local function Refresh()
    local nextState = {}
    for kind in pairs(skillIDs) do nextState[kind] = Empty() end

    local skillApi = C_SkillInfo
    if skillApi and skillApi.GetNumSkillLines and skillApi.GetSkillLineInfo then
        local count = PublicNumber(skillApi.GetNumSkillLines()) or 0
        for i = 1, math.min(count, 1024) do
            local entry = skillApi.GetSkillLineInfo(i)
            if type(entry) == "table" and not entry.isHeader then
                local id = PublicNumber(entry.skillID)
                local kind = id and kindByID[id]
                if not kind and type(entry.name) == "string" then
                    for candidate, name in pairs(skillNames) do
                        if candidate ~= "wood" and entry.name == name then
                            kind = candidate
                            break
                        end
                    end
                end
                if kind then
                    local observed = FromSkillInfo(entry)
                    if observed then nextState[kind] = observed end
                end
            end
        end
    end

    -- A collapsed skill group can omit its children from the indexed list.
    -- ByID is used only for a learned rank; unknown/unlearned skills stay absent.
    if skillApi and skillApi.GetSkillLineInfoByID then
        for kind, id in pairs(skillIDs) do
            if not nextState[kind].present then
                local observed = FromSkillInfo(skillApi.GetSkillLineInfoByID(id))
                if observed then nextState[kind] = observed end
            end
        end
    end

    -- Read the profession-specific modifier when C_SkillInfo cannot supply it.
    -- Does not invent a profession for a non-positive base skill.
    local trade = C_TradeSkillUI
    if trade and trade.GetProfessionInfoBySkillLineID then
        for _, kind in ipairs({"herb", "mineral", "skin"}) do
            if not nextState[kind].present then
                local info = trade.GetProfessionInfoBySkillLineID(skillIDs[kind])
                local observed = FromProfessionInfo(info)
                if observed then nextState[kind] = observed end
            end
        end
    end

    local changed = false
    for kind in pairs(skillIDs) do
        local old, new = state[kind], nextState[kind]
        if old.rank ~= new.rank or old.modifier ~= new.modifier
            or old.tempPoints ~= new.tempPoints or old.effective ~= new.effective
            or old.present ~= new.present then
            changed = true
        end
        state[kind] = new
    end
    return changed
end

local function Skill(kind)
    local info = state[kind]
    if not info then return nil end
    return { rank = info.rank, modifier = info.modifier,
        tempPoints = info.tempPoints, effective = info.effective,
        present = info.present }
end

local function IsVisible(node)
    if type(node) ~= "table" then return false end
    local kind = node.kind or "herb"
    if kind == "treasure" then return true end
    -- No supported Survival/Woodcutting profession has been verified.
    if kind == "wood" then return false end
    return state[kind] ~= nil and state[kind].present
end

local function ColorForThresholds(skill, thresholds)
    if skill < thresholds[1] then return "red" end
    if skill < thresholds[2] then return "orange" end
    if skill < thresholds[3] then return "yellow" end
    if skill < thresholds[4] then return "green" end
    return "gray"
end

local function TreasureColor(node, playerLevel)
    local required = PublicNumber(node.required)
        or PublicNumber(ns.resources.treasureLevels[node.name])
    playerLevel = PublicNumber(playerLevel)
    if not required or not playerLevel then return "unknown" end
    local delta = required - playerLevel
    if delta >= 6 then return "red" end
    if delta >= 3 then return "orange" end
    if delta >= -2 then return "yellow" end
    if delta >= -9 then return "green" end
    return "gray"
end

local function Color(node, playerLevel)
    if type(node) ~= "table" then return "unknown" end
    local kind = node.kind or "herb"
    if kind == "treasure" then return TreasureColor(node, playerLevel) end
    local info = state[kind]
    if not info or not info.present then return "unknown" end
    local kindThresholds = reference[kind]
    local thresholds = kindThresholds and kindThresholds[node.name]
    local observedRequirement = PublicNumber(node.required)

    if thresholds then
        -- A different observed requirement means this is not demonstrably the
        -- reference node (custom variation, changed Forever content, etc.).
        if observedRequirement and observedRequirement ~= thresholds[1] then
            if info.effective < observedRequirement then return "red" end
            return "unknown"
        end
        return ColorForThresholds(info.effective, thresholds)
    end

    -- Unknown thresholds: an independently observed minimum only establishes
    -- when the resource is still red, not when it turns yellow/green/gray.
    if observedRequirement and observedRequirement > 0
        and info.effective < observedRequirement then return "red" end
    return "unknown"
end

ns.GatherMapDifficulty = {
    Refresh = Refresh, Skill = Skill, IsVisible = IsVisible,
    Color = Color, Reference = reference,
}
