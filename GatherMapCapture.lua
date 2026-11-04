-- GatherMap — opt-in Forever gathering recorder, development version.
-- Only a confirmed player spell AND a correlated loot source may write a node.
-- Does not depend on the old Interact hook or legacy chat message grammar.
local addonName, ns = ...
local R = ns.resources
local frame = CreateFrame("Frame")
local pending, unlock, lootCaptured
local MAX_WAIT, UNLOCK_WAIT = 10, 18
local spellKinds = {
    [2366] = "herb", [2575] = "mineral",
    [8613] = "skin", [8617] = "skin", [8618] = "skin",
    [10768] = "skin", [3365] = "treasure", [22810] = "treasure",
    [1804] = "lock",
}
local spellNameKinds = {
    ["Herb Gathering"] = "herb", ["Mining"] = "mineral",
    ["Skinning"] = "skin", ["Opening"] = "treasure",
    ["Opening - No Text"] = "treasure", ["Pick Lock"] = "lock",
}
local function IsSecret(v)
    return type(issecretvalue) == "function" and issecretvalue(v)
end
local function PublicString(v)
    if IsSecret(v) or type(v) ~= "string" or v == "" then return nil end
    return v
end
local function PublicNumber(v)
    if IsSecret(v) or type(v) ~= "number" or v ~= v then return nil end
    return v
end
local function Now()
    return GetTime and GetTime() or 0
end
local function Enabled()
    return type(GatherMapDB) == "table"
        and GatherMapDB.recordingEnabled == true
        and type(GatherMapDB.nodes) == "table"
end
local function Notify(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff68cc70Gather Map:|r " .. message)
    end
end
local function SpellKind(spellID)
    spellID = PublicNumber(spellID)
    if not spellID then return nil end
    if spellKinds[spellID] then return spellKinds[spellID] end
    local name = C_Spell and C_Spell.GetSpellName
        and PublicString(C_Spell.GetSpellName(spellID))
    return name and spellNameKinds[name] or nil
end
local function SourceType(guid)
    guid = PublicString(guid)
    if not guid then return nil end
    if guid:match("^GameObject%-") then return "object" end
    if guid:match("^Creature%-") or guid:match("^Vehicle%-") then
        return "creature"
    end
    if guid:match("^Item%-") then return "item" end
    return nil
end
local function NpcSource(kind)
    if not (UnitGUID and UnitName) then return nil,nil end
    local token = kind == "skin" and "target" or "npc"
    local guid = PublicString(UnitGUID(token))
    local name = PublicString(UnitName(token))
    local wanted = kind == "skin" and "creature" or "object"
    if SourceType(guid) ~= wanted then return nil,nil end
    return guid,name
end
local function ObjectTooltip(kind)
    if not (C_TooltipInfo and C_TooltipInfo.GetWorldCursor) then
        return nil,nil
    end
    local tooltip = C_TooltipInfo.GetWorldCursor()
    if IsSecret(tooltip) or type(tooltip)~="table" then return nil,nil end
    local objectType = Enum and Enum.TooltipDataType
        and Enum.TooltipDataType.Object or 4
    if IsSecret(tooltip.type) or tooltip.type ~= objectType then return nil,nil end
    local lines = tooltip.lines
    if type(lines) ~= "table" then return nil,nil end
    local first = lines[1]
    local name = first and PublicString(first.leftText)
    local required
    for i = 2, #lines do
        local line = lines[i]
        local text = line and PublicString(line.leftText)
        if text then
            local value = text:match("%((%d+)%)")
            local skill = kind=="herb" and "Herbalism"
                or kind=="mineral" and "Mining"
                or kind=="lock" and "Lockpicking"
            if value and skill and text:find(skill,1,true) then
                required = tonumber(value)
                break
            end
        end
    end
    return name,required
end
local function IsChest(name)
    name = PublicString(name)
    if not name then return false end
    if R.treasureLevels[name] then return true end
    for _,part in ipairs({"Chest","Footlocker","Coffer","Strongbox",
        "Treasure","Cache"}) do
        if name:find(part,1,true) then return true end
    end
    return false
end
local function IsActionLabel(name)
    if not name then return true end
    if spellNameKinds[name] then return true end
    return name == "Fishing Bobber" or name == "Unknown"
end
local function KindRequirement(kind,name)
    if kind == "herb" then return R.herbRequirements[name] end
    if kind == "mineral" then return R.mineralRequirements[name] end
    if kind == "treasure" then return R.treasureLevels[name] end
end
local function SkinRequirement(level)
    level = PublicNumber(level)
    if not level or level <= 0 then return nil end
    if level <= 10 then return 1 end
    if level <= 20 then return (level-10)*10 end
    return level*5
end
local function CurrentLocation()
    if not ns.GatherMapPosition then return nil end
    local mapID,x,y = ns.GatherMapPosition()
    if not PublicNumber(mapID) or not PublicNumber(x) or not PublicNumber(y) then
        return nil
    end
    return { mapID=mapID,x=x,y=y }
end
local function CaptureContext(kind,target)
    local guid,npcName = NpcSource(kind)
    local tooltipName,required
    if kind ~= "skin" then tooltipName,required = ObjectTooltip(kind) end
    local targetName = PublicString(target)
    local name
    if kind == "skin" then
        name = npcName
    elseif targetName and not IsActionLabel(targetName) then
        name = targetName
    else
        name = npcName or tooltipName
    end
    if IsActionLabel(name) then name = nil end
    local level
    if kind == "skin" and UnitLevel then
        level = PublicNumber(UnitLevel("target"))
        required = SkinRequirement(level)
    end
    return { guid=guid,name=name,required=required,
        position=CurrentLocation() }
end
local function Start(unit,target,castGUID,spellID)
    if not Enabled() or PublicString(unit) ~= "player" then return end
    local kind=SpellKind(spellID)
    if not kind then
        -- Another action supersedes any previous unfinished gathering attempt.
        pending=nil
        return
    end
    local ctx=CaptureContext(kind,target)
    pending={kind=kind,castGUID=PublicString(castGUID),
        spellID=PublicNumber(spellID),ctx=ctx,
        at=Now(),success=false}
    lootCaptured=false
end
local function Completed(unit,castGUID,spellID)
    if not Enabled() or PublicString(unit) ~= "player" then return end
    local kind=SpellKind(spellID)
    if not kind then return end
    local cast=PublicString(castGUID)
    local now=Now()
    local previous=pending
    if previous and previous.success then
        -- Ignore duplicate SUCCEEDED without creating a second attempt.
        if previous.castGUID and previous.castGUID==cast then return end
        previous=nil
    end
    if not previous or previous.kind~=kind
        or (previous.castGUID and cast and previous.castGUID~=cast)
        or now-previous.at>MAX_WAIT then
        previous={kind=kind,castGUID=cast,spellID=PublicNumber(spellID),
            ctx=CaptureContext(kind,nil),at=now}
    end
    if kind=="treasure" and unlock and now-unlock.at<=UNLOCK_WAIT then
        local a,b=previous.ctx,unlock.ctx
        if (not a.guid or not b.guid or a.guid==b.guid)
            and (not a.name or not b.name or a.name==b.name) then
            previous.kind="lock"
            if not a.name then a.name=b.name end
            if not a.required then a.required=b.required end
        end
    end
    previous.success=true
    previous.at=now
    if not previous.ctx.position then previous.ctx.position=CurrentLocation() end
    if kind=="lock" then
        unlock={ctx=previous.ctx,at=now}
    end
    pending=previous
    lootCaptured=false
end
local function Failed(unit,castGUID,spellID)
    if PublicString(unit)~="player" then return end
    if not pending then return end
    local guid=PublicString(castGUID)
    if (pending.castGUID and guid and pending.castGUID~=guid) then return end
    pending=nil
    lootCaptured=false
end
local function LootSources(slot)
    if not GetLootSourceInfo then return {} end
    local raw={GetLootSourceInfo(slot)}
    local result={}
    for i=1,#raw,2 do
        local guid=PublicString(raw[i])
        if guid and SourceType(guid) then result[#result+1]=guid end
    end
    return result
end
local function MatchLootSource(ctx,wanted,sources)
    for _,guid in ipairs(sources) do
        if SourceType(guid)==wanted and (not ctx.guid or ctx.guid==guid) then
            return guid
        end
    end
    return nil
end
local function LootInfo(slot)
    if not GetLootSlotInfo then return nil,nil end
    local texture,name=GetLootSlotInfo(slot)
    return PublicString(name), PublicNumber(texture) or PublicString(texture)
end
local function Record(kind,name,ctx,texture)
    local pos=ctx.position
    if not pos or not PublicString(name) then return false end
    if not ns.GatherMapRecord then return false end
    local requirement=ctx.required or KindRequirement(kind,name)
    local observed={
        kind=kind,name=name,required=requirement,texture=texture,
        mapID=pos.mapID,x=pos.x,y=pos.y,
        zoneName=GetZoneText and PublicString(GetZoneText()) or nil,
        areaName=GetSubZoneText and PublicString(GetSubZoneText()) or nil,
    }
    local ok=ns.GatherMapRecord(observed)
    return ok==true
end
local function LootReady()
    if not Enabled() or not pending or not pending.success or lootCaptured then return end
    if Now()-pending.at>MAX_WAIT then pending=nil;return end
    if not (GetNumLootItems and GetLootSlotInfo and GetLootSourceInfo) then return end
    local count=PublicNumber(GetNumLootItems()) or 0
    if count<=0 then return end
    local kind,ctx=pending.kind,pending.ctx
    local sourceWanted=kind=="skin" and "creature" or "object"
    local matching={}
    local anyMatch=false
    for slot=1,count do
        local name,texture=LootInfo(slot)
        local source=MatchLootSource(ctx,sourceWanted,LootSources(slot))
        if source then
            matching[#matching+1]={name=name,texture=texture,source=source}
            anyMatch=true
        end
    end
    if not anyMatch then return end
    -- Ignore loot from other sources when the window contains several objects.
    if not ctx.guid and #matching>0 then ctx.guid=matching[1].source end
    local sameSource={}
    for _,entry in ipairs(matching) do
        if entry.source==ctx.guid then sameSource[#sameSource+1]=entry end
    end
    if #sameSource==0 then return end
    matching=sameSource
    local name=ctx.name
    if kind=="herb" or kind=="mineral" then
        -- Loot names can identify common node types when tooltips were absent.
        if not name then
            for _,item in ipairs(matching) do
                if kind=="herb" and item.name and R.herbRequirements[item.name] then
                    name=item.name
                    break
                elseif kind=="mineral" and item.name and R.miningLootNodes[item.name] then
                    name=R.miningLootNodes[item.name]
                    break
                end
            end
        end
        if name then Record(kind,name,ctx,matching[1].texture) end
    elseif kind=="skin" then
        -- Skinning points are remembered material/hunting locations, not spawns.
        local seen={}
        for _,item in ipairs(matching) do
            if item.name and not seen[item.name] then
                seen[item.name]=true
                Record("skin",item.name,ctx,item.texture)
            end
        end
    elseif (kind=="lock" or kind=="treasure") and IsChest(name) then
        Record(kind,name,ctx,matching[1].texture)
    end
    lootCaptured=true
    pending=nil
end
local function ClearLoot()
    lootCaptured=false
    if pending and pending.success then pending=nil end
end
local function CaptureStatus()
    return "Recording "..(Enabled() and "enabled (experimental)" or
        "disabled (default)").."; confirmed spell + matching loot source required."
end
ns.GatherMapCaptureStatus=CaptureStatus
ns.GatherMapSetCapture=function(enabled)
    if type(GatherMapDB)~="table" or type(GatherMapDB.nodes)~="table" then
        Notify("Cannot change recording: saved database unavailable.")
        return
    end
    GatherMapDB.recordingEnabled=not not enabled
    pending=nil;unlock=nil;lootCaptured=false
    Notify(CaptureStatus())
end

frame:RegisterEvent("UNIT_SPELLCAST_SENT")
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED","player")
frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED","player")
frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED","player")
frame:RegisterEvent("LOOT_READY")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("LOOT_CLOSED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent",function(_,event,...)
    if event=="UNIT_SPELLCAST_SENT" then Start(...)
    elseif event=="UNIT_SPELLCAST_SUCCEEDED" then Completed(...)
    elseif event=="UNIT_SPELLCAST_FAILED" or event=="UNIT_SPELLCAST_INTERRUPTED" then
        Failed(...)
    elseif event=="LOOT_READY" then LootReady()
    elseif event=="LOOT_OPENED" then
        local _,fromItem=...
        if not IsSecret(fromItem) and fromItem==true then pending=nil end
    elseif event=="LOOT_CLOSED" then ClearLoot()
    elseif event=="PLAYER_ENTERING_WORLD" then
        pending=nil;unlock=nil;lootCaptured=false
    end
end)

-- Exposed for deterministic fixture tests; no real game action is initiated.
ns.GatherMapCaptureTest={
    Frame=frame,Kind=SpellKind,SourceType=SourceType,
    GetPending=function() return pending end,
}
