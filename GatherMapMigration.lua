-- GatherMap Forever — non-destructive legacy discovery migration.
-- Old "continent:zone" indices are NOT UiMapIDs. Only explicitly linked zone
-- names may be copied. Legacy locations and their metadata are never removed.
local _, ns = ...
local Migration = {}
local DATABASE_LIMIT = 10000
local DISTANCE = 0.004
local kinds = { herb=true, mineral=true, skin=true, lock=true,
    treasure=true, wood=true }

local db, changed
local function Finite(n)
    return type(n)=="number" and n==n and n~=math.huge and n~=-math.huge
end
local function Coord(n)
    return Finite(n) and n>=0 and n<=1
end
local function Name(s)
    if type(s)~="string" then return nil end
    s=s:match("^%s*(.-)%s*$")
    if s=="" or #s>128 then return nil end
    return s
end
local function Key(s)
    return type(s)=="string" and s:match("^[1-9]%d*:[1-9]%d*$")~=nil
end
local function Copy(value,seen,depth)
    if type(value)~="table" then return value end
    if depth>16 then error("nested saved data exceeds safe depth") end
    if seen[value] then error("cyclic saved data cannot be migrated safely") end
    seen[value]=true
    local cloned={}
    for k,v in pairs(value) do cloned[Copy(k,seen,depth+1)]=Copy(v,seen,depth+1) end
    seen[value]=nil
    return cloned
end
local function Clone(value)
    return Copy(value,{},0)
end
local function Equal(a,b,seen)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    if seen[a]==b then return true end
    seen[a]=b
    for k,v in pairs(a) do
        if not Equal(v,b[k],seen) then return false end
    end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
local function SourceVersion()
    local v=tonumber(db and (db.legacySchemaVersion or db.version)) or 1
    if v<1 or v>3 or v~=math.floor(v) then return nil end
    return v
end
local function Source(key)
    if not db or type(db.nodes)~="table" or not Key(key) then
        return nil,"not a legacy continent:zone key"
    end
    local nodes=db.nodes[key]
    if type(nodes)~="table" then return nil,"legacy zone not found" end
    if #nodes==0 then return nil,"legacy zone is empty" end
    if #nodes>DATABASE_LIMIT then return nil,"zone too large for safe in-game migration" end
    if not SourceVersion() then return nil,"unknown historical schema version" end
    return nodes
end
local function ZoneName(nodes)
    local zone
    for i=1,#nodes do
        local node=nodes[i]
        if type(node)~="table" then return nil,"malformed legacy record" end
        local name=Name(node.zoneName)
        if not name then return nil,"missing historical zone name" end
        if zone and zone~=name then return nil,"multiple historical zone names" end
        zone=name
    end
    return zone
end
local function Metadata(id)
    if not (C_Map and C_Map.GetMapInfo and Finite(id)
        and id>0 and id==math.floor(id)) then return nil end
    local info=C_Map.GetMapInfo(id)
    if type(info)~="table" or info.mapID~=id
        or info.mapType~=3 or not Name(info.name) then return nil end
    return info
end
local function LinkFor(key)
    local links=db.migrationLinks
    if type(links)~="table" then return nil,"no zone link" end
    local link=links[key]
    if type(link)~="table" then return nil,"no zone link" end
    local info=Metadata(link.mapID)
    if not info or Name(info.name)~=link.name then
        return nil,"zone mapping not valid on this client build"
    end
    local source,err=Source(key)
    if not source then return nil,err end
    local oldName,e=ZoneName(source)
    if not oldName then return nil,e end
    if oldName~=link.name then return nil,"historical and Forever zone names differ" end
    return link,source
end
local function Candidate(node,version)
    if type(node)~="table" or not Name(node.name)
        or not Coord(node.x) or not Coord(node.y) then return nil end
    local kind=node.kind or "herb"
    if not kinds[kind] then return nil end
    local count=node.count
    if count==nil then count=1 end
    if not (Finite(count) and count>0 and count==math.floor(count)
        and count<=100000000) then return nil end
    local item=Clone(node)
    item.name=Name(item.name)
    item.kind=kind
    item.count=count
    if version<3 and kind=="skin" then item.required=nil end
    return item
end
local function Merge(target,candidate)
    for i=1,#target do
        local existing=target[i]
        if type(existing)=="table" and (existing.kind or "herb")==candidate.kind
            and existing.name==candidate.name
            and Coord(existing.x) and Coord(existing.y)
            and math.abs(existing.x-candidate.x)<=DISTANCE
            and math.abs(existing.y-candidate.y)<=DISTANCE then
            local previous=existing.count or 1
            if not (Finite(previous) and previous>=1
                and previous==math.floor(previous)
                and previous+candidate.count<=100000000) then
                return nil,"invalid or overflowing destination count"
            end
            local total=previous+candidate.count
            existing.x=(existing.x*previous+candidate.x*candidate.count)/total
            existing.y=(existing.y*previous+candidate.y*candidate.count)/total
            existing.count=total
            -- Keep current observations authoritative if requirements conflict.
            if existing.required==nil then existing.required=candidate.required end
            if existing.texture==nil then existing.texture=candidate.texture end
            if existing.zoneName==nil then existing.zoneName=candidate.zoneName end
            if existing.areaName==nil then existing.areaName=candidate.areaName end
            return "merged"
        end
    end
    target[#target+1]=candidate
    return "new"
end
local function Build(key)
    local link,source=LinkFor(key)
    if not link then return nil,source end
    if type(db.migrationLedger)=="table" and db.migrationLedger[key] then
        return nil,"already migrated (use status or guarded rollback)"
    end
    local targetKey="map:"..link.mapID
    local existing=db.nodes[targetKey]
    if existing~=nil and type(existing)~="table" then
        return nil,"invalid destination; not overwritten"
    end
    if (existing and #existing or 0)+#source>DATABASE_LIMIT then
        return nil,"destination too large for safe in-game migration"
    end
    local version=SourceVersion()
    local copyOK,dest=pcall(Clone,existing or {})
    if not copyOK then return nil,"destination could not be copied" end
    local summary={source=#source,valid=0,skipped=0,merged=0,added=0,
        occurrences=0,zone=link.name,mapID=link.mapID,key=key,target=targetKey}
    for i=1,#source do
        local ok,candidate=pcall(Candidate,source[i],version)
        if not ok then return nil,"legacy saved data could not be copied" end
        if candidate then
            local action,why=Merge(dest,candidate)
            if not action then return nil,why end
            summary.valid=summary.valid+1
            summary.occurrences=summary.occurrences+candidate.count
            if action=="new" then summary.added=summary.added+1
            else summary.merged=summary.merged+1 end
        else summary.skipped=summary.skipped+1 end
    end
    if summary.valid==0 then return nil,"no valid migratable nodes" end
    return {summary=summary,source=source,before=existing,after=dest,
        targetKey=targetKey,version=version}
end
function Migration.Init(database,notifyChanged)
    db=database
    changed=notifyChanged
end
function Migration.Status()
    if not db or type(db.nodes)~="table" then return nil end
    local info={zones=0,records=0,links=0,migrated=0,unmatched=0}
    for key,nodes in pairs(db.nodes) do
        if Key(key) and type(nodes)=="table" then
            info.zones=info.zones+1
            info.records=info.records+#nodes
            local done=type(db.migrationLedger)=="table"
                and db.migrationLedger[key]
            if done then info.migrated=info.migrated+1
            else info.unmatched=info.unmatched+1 end
            if type(db.migrationLinks)=="table"
                and db.migrationLinks[key] then info.links=info.links+1 end
        end
    end
    return info
end
function Migration.Link(key)
    local source,err=Source(key)
    if not source then return false,err end
    if type(db.migrationLedger)=="table" and db.migrationLedger[key] then
        return false,"already migrated" end
    local zone,why=ZoneName(source)
    if not zone then return false,why end
    local mapID=ns.GatherMapPosition and ns.GatherMapPosition()
    local info=Metadata(mapID)
    if not info then return false,"stand inside a supported Forever zone map" end
    if zone~=Name(info.name) then
        return false,"zone name mismatch: legacy "..zone.." / Forever "..info.name
    end
    if type(db.migrationLinks)~="table" then db.migrationLinks={} end
    -- Avoid two historical indexes accidentally importing the same locations
    -- twice under one modern zone without independent review.
    for sourceKey,existingLink in pairs(db.migrationLinks) do
        if sourceKey~=key and type(existingLink)=="table"
            and existingLink.mapID==mapID then
            return false,"another historical key is already linked to this UiMapID"
        end
    end
    local old=db.migrationLinks[key]
    if old and (old.mapID~=mapID or old.name~=zone) then
        return false,"different mapping already linked; no overwrite"
    end
    db.migrationLinks[key]={mapID=mapID,name=zone}
    return true,"linked "..key.." to UiMapID "..mapID..
        " ("..zone.."); coordinates still require visual verification"
end
function Migration.Preview(key)
    local result,err=Build(key)
    if not result then return nil,err end
    return result.summary
end
function Migration.Apply(key,confirmation)
    if confirmation~="confirm" then
        return false,"requires explicit 'confirm'; preserve an external backup first"
    end
    local result,err=Build(key)
    if not result then return false,err end
    local previousBackups=db.migrationBackups
    if previousBackups~=nil and type(previousBackups)~="table" then
        return false,"invalid migration backup store; refusing to modify it"
    end
    if db.migrationLedger~=nil and type(db.migrationLedger)~="table" then
        return false,"invalid migration ledger"
    end
    local oldList=previousBackups and previousBackups[key]
    if oldList~=nil and type(oldList)~="table" then
        return false,"invalid existing backup history"
    end
    if oldList and #oldList>=10 then return false,"backup history full" end
    local ok,backup=pcall(function()
        return {before=Clone(result.before),after=Clone(result.after),
            original=Clone(result.source),target=result.targetKey,
            version=db.version,legacyVersion=db.legacySchemaVersion}
    end)
    if not ok then return false,"unable to make SavedVariables backup" end
    if not previousBackups then previousBackups={};db.migrationBackups=previousBackups end
    if not oldList then oldList={};previousBackups[key]=oldList end
    oldList[#oldList+1]=backup
    if not db.migrationLedger then db.migrationLedger={} end
    db.nodes[result.targetKey]=result.after
    db.migrationLedger[key]={mapID=result.summary.mapID,
        backupIndex=#oldList,sourceRecords=result.summary.source}
    if result.version<3 then db.legacySchemaVersion=result.version end
    db.version=3
    if changed then changed() end
    return true,result.summary
end
function Migration.Rollback(key)
    if not db or type(db.migrationLedger)~="table" then
        return false,"no completed migration"
    end
    local record=db.migrationLedger[key]
    if not record then return false,"no completed migration" end
    local backups=db.migrationBackups
    local list=type(backups)=="table" and backups[key]
    local backup=type(list)=="table" and list[record.backupIndex]
    if type(backup)~="table" or type(backup.target)~="string" then
        return false,"backup missing"
    end
    if not Equal(db.nodes[backup.target],backup.after,{}) then
        return false,"destination changed since migration; refusing to discard new discoveries"
    end
    if not Equal(db.nodes[key],backup.original,{}) then
        return false,"original legacy data changed; refusing rollback"
    end
    local ok,restored=pcall(Clone,backup.before)
    if not ok then return false,"backup could not be restored" end
    db.nodes[backup.target]=restored
    db.migrationLedger[key]=nil
    local other=false
    for _ in pairs(db.migrationLedger) do other=true;break end
    if not other then
        db.version=backup.version
        db.legacySchemaVersion=backup.legacyVersion
    end
    if changed then changed() end
    return true,"destination restored; legacy records and backup history retained"
end
ns.GatherMapMigration=Migration
