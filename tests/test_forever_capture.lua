-- Deterministic mocks for the Forever-only resource recorder.
-- Run: lua5.4 tests/test_forever_capture.lua
local ns={
    resources={
        herbRequirements={Peacebloom=1,Silverleaf=1},
        mineralRequirements={["Copper Vein"]=1},
        miningLootNodes={["Copper Ore"]="Copper Vein"},
        treasureLevels={["Battered Chest"]=5},
    }
}
local f
local now=100
local target="Peacebloom"
local tooltipName="Peacebloom"
local npcGuid="GameObject-1-2-3"
local corpseGuid="Creature-1-2-4"
local lootGuid=npcGuid
local lootName="Peacebloom"
local slotTexture=123
local level=12
local records={}
GatherMapDB={nodes={}}
DEFAULT_CHAT_FRAME={AddMessage=function() end}
local actions={}
CreateFrame=function()
    f={events={},
        RegisterEvent=function(self,event) self.events[event]=true end,
        RegisterUnitEvent=function(self,event,unit) self.events[event]=unit end,
        SetScript=function(self,which,callback) self[which]=callback end}
    return f
end
GetTime=function() return now end
C_Spell={GetSpellName=function(id)
    local names={[2366]="Herb Gathering",[2575]="Mining",[8613]="Skinning",
        [1804]="Pick Lock",[3365]="Opening"}
    return names[id]
end}
UnitGUID=function(unit)
    if unit=="npc" then return npcGuid end
    if unit=="target" then return corpseGuid end
end
UnitName=function(unit)
    if unit=="npc" then return target end
    if unit=="target" then return "Forest Wolf" end
end
UnitLevel=function() return level end
Enum={TooltipDataType={Object=4}}
C_TooltipInfo={GetWorldCursor=function()
    return {type=4,lines={{leftText=tooltipName},
        {leftText="Requires Herbalism (1)"}}}
end}
GetNumLootItems=function() return 1 end
GetLootSourceInfo=function() return lootGuid,1 end
GetLootSlotInfo=function() return slotTexture,lootName,1 end
GetZoneText=function() return "Elwynn Forest" end
GetSubZoneText=function() return "Northshire Valley" end
ns.GatherMapPosition=function() return 37,0.15,0.67 end
ns.GatherMapRecord=function(observation)
    records[#records+1]=observation
    return true,"learned"
end
assert(loadfile("GatherMapCapture.lua"))("GatherMap",ns)
assert(f.events.UNIT_SPELLCAST_SUCCEEDED=="player")
assert(f.events.UNIT_SPELLCAST_INTERRUPTED=="player")
assert(f.events.LOOT_READY)

local function event(kind,...)
    f.OnEvent(f,kind,...)
end
local function clear()
    for i=#records,1,-1 do records[i]=nil end
    event("PLAYER_ENTERING_WORLD")
    now=now+25
end
local function sent(id,targetName)
    event("UNIT_SPELLCAST_SENT","player",targetName or target,"cast-"..now,id)
end
local function succeeded(id)
    event("UNIT_SPELLCAST_SUCCEEDED","player","cast-"..now,id)
end
local function loot()
    event("LOOT_READY",false)
end
local function check(kind,name)
    assert(#records==1,"expected one record, got "..#records)
    assert(records[1].kind==kind, tostring(records[1].kind))
    assert(records[1].name==name, tostring(records[1].name))
    assert(records[1].mapID==37 and records[1].x==0.15)
end

-- Default disabled, even complete success+loot must not write.
sent(2366);succeeded(2366);loot()
assert(#records==0)
ns.GatherMapSetCapture(true)
assert(GatherMapDB.recordingEnabled==true)

-- Cast start and cast stop alone are not sufficient.
sent(2366);loot()
assert(#records==0)
clear()

-- Herb: success + loot from same object; no duplicate LOOT_READY.
target,tooltipName,lootName="Peacebloom","Peacebloom","Peacebloom"
npcGuid,lootGuid="GameObject-a","GameObject-a"
sent(2366);succeeded(2366);loot();check("herb","Peacebloom")
loot();assert(#records==1)
clear()

-- Failure/interruption: never save.
sent(2366)
event("UNIT_SPELLCAST_INTERRUPTED","player","cast-"..now,2366)
loot()
assert(#records==0)
clear()

-- Success but unrelated loot source: reject.
sent(2366);succeeded(2366)
lootGuid="GameObject-unrelated";loot()
assert(#records==0)
clear()

-- Mining: known item fallback when object name is unavailable.
npcGuid,lootGuid="GameObject-copper","GameObject-copper"
target,tooltipName,lootName="","","Copper Ore"
sent(2575)
succeeded(2575);loot()
check("mineral","Copper Vein")
clear()

-- Skinning: derive material from loot, approximate at player's location.
corpseGuid,lootGuid="Creature-skin","Creature-skin"
lootName="Light Leather"
sent(8613,"Forest Wolf");succeeded(8613);loot()
check("skin","Light Leather")
assert(records[1].required==20,"level 12 should require skinning 20")
clear()

-- Treasure: recognized chest, GameObject source, successful Opening.
target,tooltipName,lootName="Battered Chest","Battered Chest","Old Boot"
npcGuid,lootGuid="GameObject-chest","GameObject-chest"
sent(3365);succeeded(3365);loot()
check("treasure","Battered Chest")
clear()

-- Do not record a generic quest item opened with Opening.
target,tooltipName="Strange Crystal","Strange Crystal"
sent(3365);succeeded(3365);loot()
assert(#records==0)
clear()

-- Lockpicking followed by opening the same chest: retain lock classification.
target,tooltipName="Battered Chest","Battered Chest"
sent(1804);succeeded(1804)
now=now+2
sent(3365);succeeded(3365);loot()
check("lock","Battered Chest")
clear()

-- Expired success + subsequent loot cannot record.
sent(2366);succeeded(2366)
now=now+11
loot()
assert(#records==0)
clear()

-- Unrelated player spell and unrelated loot do not record.
sent(133);succeeded(133);loot()
assert(#records==0)
ns.GatherMapSetCapture(false)
clear()
sent(2366);succeeded(2366);loot()
assert(#records==0)
print("PASS: successful herb/mining/skinning/treasure/lock correlation; failed, stale, unrelated, duplicated and disabled paths")
