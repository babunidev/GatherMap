-- Run from repository root: lua5.4 tests/test_forever_difficulty.lua
-- Mock API tests: threshold boundaries, current-character skill ownership,
-- bonuses, equipment changes, level-based treasure, unknown requirements.
local ns = {resources = {
    resourceSkills = {herb="Herbalism",mineral="Mining",skin="Skinning",
        lock="Lockpicking",wood="Survival"},
    treasureLevels = {["Battered Chest"]=20},
}}
local sharedNodes = {["map:37"]={
    {name="Dreamfoil",kind="herb",x=0.42,y=0.63},
    {name="Copper Vein",kind="mineral",x=0.2,y=0.8},
}}
local GatherMapDB = {nodes=sharedNodes,version=3}
local originalNodes = sharedNodes
local originalDreamfoil = sharedNodes["map:37"][1]

local character = {
    [182]={skillID=182,name="Herbalism",rank=270,modifier=0,tempPoints=0},
    [186]={skillID=186,name="Mining",rank=75,modifier=0,tempPoints=0},
    [393]={skillID=393,name="Skinning",rank=50,modifier=0,tempPoints=0},
    [633]={skillID=633,name="Lockpicking",rank=25,modifier=0,tempPoints=0},
}
local function List()
    local result = {}
    for _,id in ipairs({182,186,393,633}) do
        if character[id] then result[#result+1]=character[id] end
    end
    return result
end
C_SkillInfo={
    GetNumSkillLines=function() return #List() end,
    GetSkillLineInfo=function(index) return List()[index] end,
    GetSkillLineInfoByID=function(id) return character[id] end,
}
local alpha = assert(loadfile("GatherMapDifficulty.lua"))("GatherMap",ns)
local D=assert(ns.GatherMapDifficulty)
assert(D.Refresh())
assert(not D.Refresh(),"unchanged skill states must not trigger redraw")

local herbNode = sharedNodes["map:37"][1]
local oreNode = sharedNodes["map:37"][2]
assert(D.Color(herbNode)=="orange","270 Dreamfoil must be orange")
character[182].rank=289
assert(D.Refresh())
assert(D.Color(herbNode)=="orange")
character[182].rank=290
assert(D.Refresh())
assert(D.Color(herbNode)=="yellow","Dreamfoil turns yellow at 290")
character[182].rank=315
assert(D.Refresh())
assert(D.Color(herbNode)=="green","Dreamfoil turns green at 315")
character[182].rank=370
assert(D.Refresh())
assert(D.Color(herbNode)=="gray","Dreamfoil turns gray at 370")

-- The requested six category palette, including minimum too high.
local lotus = {name="Black Lotus",kind="herb"}
character[182].rank=299
D.Refresh()
assert(D.Color(lotus)=="red")
character[182].rank=300
D.Refresh()
assert(D.Color(lotus)=="orange")
character[182].rank=325
D.Refresh()
assert(D.Color(lotus)=="yellow")
character[182].rank=350
D.Refresh()
assert(D.Color(lotus)=="green")
character[182].rank=400
D.Refresh()
assert(D.Color(lotus)=="gray")
assert(D.Color({name="Unknown Herb",kind="herb"})=="unknown",
    "Unknown requirement must remain purple, not estimated")

-- Verify all 28 herb and 9 ore reference breakpoints.
for kind, tableOfNodes in pairs(D.Reference) do
    local id=kind=="herb" and 182 or 186
    for name,thresholds in pairs(tableOfNodes) do
        assert(#thresholds==4 and thresholds[1]<thresholds[2]
            and thresholds[2]<thresholds[3] and thresholds[3]<thresholds[4],
            "bad reference data: "..name)
        local node={name=name,kind=kind}
        for i,value in ipairs(thresholds) do
            character[id].rank=value
            D.Refresh()
            local expected=({"orange","yellow","green","gray"})[i]
            assert(D.Color(node)==expected,
                name.." at "..value.." expected "..expected.." got "..D.Color(node))
        end
        character[id].rank=thresholds[1]+1
        character[id].modifier=-2
        D.Refresh()
        assert(D.Color(node)=="red",
            name.." must account for negative skill modifiers")
        character[id].modifier=0
    end
end

-- Equipment, enchantment, and temporary buffs alter only effective skill.
character[182].rank=20
character[182].modifier=2
character[182].tempPoints=3
assert(D.Refresh())
local rank=D.Skill("herb")
assert(rank.present and rank.rank==20 and rank.effective==25)
assert(D.Color({name="Peacebloom",kind="herb"})=="yellow")
character[182].modifier=0
character[182].tempPoints=0
assert(D.Refresh())
assert(D.Color({name="Peacebloom",kind="herb"})=="orange")

-- A changed observed minimum is treated as a distinct/unverified variant.
character[182].rank=50;D.Refresh()
assert(D.Color({name="Peacebloom",kind="herb",required=60})=="red")
assert(D.Color({name="Peacebloom",kind="herb",required=2})=="unknown")
assert(D.Color({name="Never Seen",kind="herb",required=55})=="red")
assert(D.Color({name="Never Seen",kind="herb",required=1})=="unknown")

-- Skinning/lockpicking remain visible when learned, but unknown color
-- thresholds are not invented from the minimum requirement alone.
assert(D.IsVisible({kind="skin",name="Light Leather",required=20}))
assert(D.IsVisible({kind="lock",name="Battered Chest",required=30}))
assert(D.Color({kind="skin",name="Light Leather",required=20})=="unknown")
assert(D.Color({kind="lock",name="Battered Chest",required=30})=="red")
assert(not D.IsVisible({kind="wood",name="Simple Wood Tree"}))
assert(D.IsVisible({kind="treasure",name="Battered Chest"}))

-- Treasure is based on level, never on profession rank.
local chest={kind="treasure",name="Battered Chest"}
assert(D.Color(chest,14)=="red")
assert(D.Color(chest,17)=="orange")
assert(D.Color(chest,20)=="yellow")
assert(D.Color(chest,23)=="green")
assert(D.Color(chest,30)=="gray")
assert(D.Color({kind="treasure",name="Unknown Chest"},20)=="unknown")
assert(D.Color({kind="treasure",name="Unknown Chest"},nil)=="unknown")

-- Second character on the same account; no skill cache belongs to the DB.
local toonA=D.Skill("herb")
character[182]=nil
character[186].rank=300
assert(D.Refresh())
assert(not D.IsVisible(herbNode))
assert(D.IsVisible(oreNode))
assert(D.Color(oreNode)=="gray")
assert(D.Skill("herb").present==false)
assert(toonA.rank==50,"state copy should not be mutated by another character")
assert(GatherMapDB.nodes==originalNodes)
assert(sharedNodes["map:37"][1]==originalDreamfoil)
assert(originalDreamfoil.required==nil and originalDreamfoil.name=="Dreamfoil")

-- Collapsed indexed skill list must still find a learned skill by ID.
C_SkillInfo.GetNumSkillLines=function() return 0 end
character[182]={skillID=182,name="Herbalism",rank=100,modifier=5,tempPoints=0}
assert(D.Refresh())
assert(D.IsVisible(herbNode))
assert(D.Skill("herb").effective==105)

-- If the skill API is unavailable, don't reuse the prior character's skills.
C_SkillInfo=nil
C_TradeSkillUI=nil
assert(D.Refresh())
assert(not D.IsVisible(herbNode))

-- Profession API fallback when skill-list API is absent.
C_TradeSkillUI={GetProfessionInfoBySkillLineID=function(id)
    if id==182 then return {skillLevel=12,skillModifier=5} end
end}
assert(D.Refresh())
assert(D.IsVisible(herbNode))
assert(D.Skill("herb").effective==17)
assert(D.Color({kind="herb",name="Peacebloom"})=="orange")

print("PASS: 37 resource tables, six colors, boundaries, bonuses, professions, per-character state, treasures and unknowns")
