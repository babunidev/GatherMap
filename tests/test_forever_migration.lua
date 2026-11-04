-- Run from repo root: lua5.1 tests/test_forever_migration.lua
-- Deterministic mock only; real Forever SavedVariables persistence remains untested.
local ns={}
local currentID=37
local currentName="Elwynn Forest"
C_Map={GetMapInfo=function(id)
    if id==currentID then return {
        mapID=currentID,name=currentName,mapType=3,parentMapID=13
    } end
end}
ns.GatherMapPosition=function() return currentID,0.5,0.5 end
assert(loadfile("GatherMapMigration.lua"))("GatherMap",ns)
local M=assert(ns.GatherMapMigration)
local dirty=0
local function Init(db)
    M.Init(db,function() dirty=dirty+1 end)
end
local function Node(name,kind,x,y,count,zone,required)
    return {name=name,kind=kind,x=x,y=y,count=count,
        zoneName=zone or "Elwynn Forest",required=required,
        areaName="Test Area"}
end
local function Check(ok,message)
    assert(ok,message)
end

-- Two legacy herb records overlap an existing modern observation. Count and
-- weighted coordinates are preserved, without altering original saved records.
local first=Node("Peacebloom",nil,0.500,0.500,2)
local second=Node("Peacebloom","herb",0.502,0.502,3)
local tree=Node("Simple Wood Tree","wood",0.4,0.6,7)
local damaged=Node("Bad Coordinate","herb",1.4,0.4,1)
local existing=Node("Peacebloom","herb",0.501,0.501,4)
local old={
    nodes={["1:2"]={first,second,tree,damaged},
        ["map:37"]={existing},
        ["4:5"]={Node("Unknown Zone","herb",0.2,0.3,1,"Unmapped Island")}},
    enabled=false,worldMapEnabled=true,version=1,
}
Init(old)
local status=M.Status()
Check(status.zones==2 and status.records==5 and status.migrated==0,
    "original legacy inventory")
local countBefore=#old.nodes["map:37"]
local savedVersion=old.version
local sourceNodes=old.nodes["1:2"]
Check(M.Link("1:2"),"explicit same-name, same-zone link")
Check(old.migrationLinks["1:2"].mapID==37,"stable numeric UiMapID recorded")
local dry=M.Preview("1:2")
Check(dry.source==4 and dry.valid==3 and dry.skipped==1,
    "malformed record retained and reported")
Check(dry.merged==2 and dry.added==1 and dry.occurrences==12,
    "counts in dry-run, including existing nodes")
Check(#old.nodes["map:37"]==countBefore and old.version==savedVersion,
    "preview did not write nodes or version")
Check(not old.migrationLedger,"preview must not mark migrated")
local ok,err=M.Apply("1:2")
Check(not ok and err:find("confirm"),"explicit confirmation required")
ok,dry=M.Apply("1:2","confirm")
Check(ok,"migration apply")
Check(old.version==3 and old.legacySchemaVersion==1,
    "schema-v1 evidence preserved")
Check(#old.nodes["1:2"]==4 and sourceNodes[1]==first
    and first.kind==nil and first.count==2,"legacy data never modified")
Check(#old.nodes["map:37"]==2,"destination merge and a wood entry")
local combined=old.nodes["map:37"][1]
Check(combined.count==9 and combined.kind=="herb",
    "weighted count preserves all observations")
local expected=(0.501*4+0.500*2+0.502*3)/9
Check(math.abs(combined.x-expected)<0.0000000001,
    "weighted original coordinates retained")
Check(old.nodes["map:37"][2].kind=="wood"
    and old.nodes["map:37"][2].count==7,"unsupported wood history preserved")
Check(old.migrationBackups["1:2"][1].original[1].kind==nil
    and old.migrationBackups["1:2"][1].before[1].count==4,
    "source and destination snapshots stored before apply")
Check(old.migrationLedger["1:2"].mapID==37,"idempotent migration ledger")
Check(dirty==1,"mutation notifies UI once")
Check(not M.Apply("1:2","confirm"),"second apply must not double-count")

-- Model saving and loading the exact Lua table, then switching characters.
local function Encode(value)
    if type(value)=="string" then return string.format("%q",value) end
    if type(value)=="number" or type(value)=="boolean" then
        return tostring(value)
    end
    if type(value)=="nil" then return "nil" end
    assert(type(value)=="table","unsupported fixture data")
    local cells={}
    for key,item in pairs(value) do
        cells[#cells+1]="["..Encode(key).."]="..Encode(item)..","
    end
    return "{"..table.concat(cells).."}"
end
local exported="return "..Encode(old)
local loader=loadstring or load
local restored=assert(loader(exported))()
Init(restored)
Check(restored.migrationLedger["1:2"].mapID==37
    and restored.nodes["map:37"][1].count==9,
    "SavedVariables-style Lua round trip preserved migration")
Check(restored.enabled==false and restored.worldMapEnabled==true,
    "account settings persisted")
Check(restored.nodes["4:5"][1].name=="Unknown Zone",
    "unmatched/unmapped historical locations persisted")

-- Reject rollback when new discoveries have arrived since the migration.
local newNode=Node("Silverleaf","herb",0.7,0.8,1)
restored.nodes["map:37"][3]=newNode
local rollback,reason=M.Rollback("1:2")
Check(not rollback and reason:find("changed"),"don't discard newer observations")
Check(restored.nodes["map:37"][3]==newNode,"current data preserved on refusal")
restored.nodes["map:37"][3]=nil
rollback,reason=M.Rollback("1:2")
Check(rollback,"guarded rollback restores original destination")
Check(restored.nodes["map:37"][1].count==4
    and #restored.nodes["map:37"]==1,"destination restored")
Check(restored.version==1 and restored.legacySchemaVersion==nil,
    "schema metadata restored when final copied zone rolled back")
Check(restored.migrationBackups["1:2"][1].after[1].count==9,
    "immutable historical backups kept")
Check(restored.nodes["1:2"][1].kind==nil,
    "schema-v1 raw data preserved through rollback")
Check(dirty==2,"each destination mutation notifies UI")

-- v2 skin requirements are invalidated ONLY in the modern copy, not source.
local skin=Node("Light Leather","skin",0.2,0.3,6,nil,200)
local v2={nodes={["1:2"]={skin}},version=2}
Init(v2)
Check(M.Link("1:2"),"v2 link")
Check(M.Apply("1:2","confirm"),"v2 copy")
Check(v2.nodes["map:37"][1].kind=="skin"
    and v2.nodes["map:37"][1].required==nil
    and v2.nodes["map:37"][1].count==6,"v2 skin correction")
Check(skin.required==200 and v2.legacySchemaVersion==2,
    "v2 original records and version retained")

-- v3 requirements are retained exactly.
local lock=Node("Battered Chest","lock",0.2,0.35,2,nil,75)
local v3={nodes={["1:2"]={lock}},version=3}
Init(v3)
Check(M.Link("1:2"),"v3 link")
Check(M.Apply("1:2","confirm"),"v3 copy")
Check(v3.nodes["map:37"][1].required==75 and v3.version==3,
    "schema-v3 data retained")

-- Reject name mismatches, map type mismatch, missing name and mixed names.
local cross={nodes={["1:2"]={Node("Herb","herb",0.2,0.3,1,
    "Stranglethorn Vale")}},version=3}
Init(cross)
local linked,message=M.Link("1:2")
Check(not linked and message:find("mismatch"),"no name-only blind import")
currentName="Elwynn Forest"
local empty={nodes={["1:2"]={Node("Herb","herb",0.2,0.3,1,"")}},version=3}
Init(empty)
Check(not M.Link("1:2"),"no link for missing metadata")
local mixed={nodes={["1:2"]={
    Node("Herb","herb",0.2,0.3,1,"Elwynn Forest"),
    Node("Other","herb",0.3,0.4,1,"Stormwind City")}},version=3}
Init(mixed)
Check(not M.Link("1:2"),"no link for mixed historical zones")
local ambiguous={nodes={["1:2"]={first}},version=3}
currentName="Elwynn Forest";currentID=37
Init(ambiguous)
Check(not M.Link("map:37"),"no passing a modern key as a legacy key")
local src=nil
Check(not M.Preview("1:2"),"unlinked legacy key does not migrate")
C_Map.GetMapInfo=function(id) return {mapID=id,name="Elwynn Forest",mapType=2} end
Check(not M.Link("1:2"),"continent map is not a zone")
print("PASS: legacy schemas v1/v2/v3, explicit map links, previews, weighted counts, snapshots, guarded rollback, simulated reload/character change and unmatched records")
