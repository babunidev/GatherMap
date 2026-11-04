-- GatherMap — Forever 1.60.1 API compatibility layer.
-- This phase displays native map-ID records. New gathering capture and legacy
-- key migration are deliberately disabled until separately verified.
local addonName, ns = ...
local R = ns.resources
local db, provider, checkbox
local miniPins, mapPins = {}, {}
local ranks = { herb = 0, mineral = 0, skin = 0, lock = 0, wood = 0 }
local worldCache = setmetatable({}, { __mode = "k" })
local activeTooltip, dirty, tick, skillTick = nil, true, 0, 0
local previewMarker -- temporary test fixture; never saved
local MAX_PINS, DOT_SIZE = 300, 3
local f = CreateFrame("Frame")

local function Print(s)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff68cc70Gather Map:|r "..s) end
end
local function Valid(n)
    if issecretvalue and issecretvalue(n) then return false end
    return type(n)=="number" and n==n and n>=0 and n<=1
end
local function SkillValue(info)
    if not info or info.isHeader then return 0 end
    return (tonumber(info.rank) or 0)+(tonumber(info.modifier) or 0)
        +(tonumber(info.tempPoints) or 0)
end
local skillIDs = { herb=182, mineral=186, skin=393, lock=633 }
local function RefreshSkills()
    if not C_SkillInfo then return false end
    local new = { herb=0, mineral=0, skin=0, lock=0, wood=0 }
    if C_SkillInfo.GetSkillLineInfoByID then
        for kind,id in pairs(skillIDs) do
            new[kind] = SkillValue(C_SkillInfo.GetSkillLineInfoByID(id))
        end
    end
    if C_SkillInfo.GetNumSkillLines and C_SkillInfo.GetSkillLineInfo then
        for i=1,(C_SkillInfo.GetNumSkillLines() or 0) do
            local info=C_SkillInfo.GetSkillLineInfo(i)
            if info and not info.isHeader then
                for kind,name in pairs(R.resourceSkills) do
                    if kind~="wood" and info.name==name and new[kind]==0 then
                        new[kind]=SkillValue(info)
                    end
                end
            end
        end
    end
    local changed=false
    for kind,value in pairs(new) do
        if ranks[kind]~=value then changed=true; ranks[kind]=value end
    end
    if changed then dirty=true end
    return changed
end

local function Difficulty(node)
    local kind=node.kind or "herb"
    local required=tonumber(node.required)
    if not required then
        local lookup = kind=="herb" and R.herbRequirements
            or kind=="mineral" and R.mineralRequirements
            or kind=="treasure" and R.treasureLevels
            or kind=="wood" and R.treeRequirements
        required=lookup and lookup[node.name]
    end
    if not required then return "unknown" end
    if kind=="treasure" then
        local d=required-(UnitLevel("player") or 0)
        if d>=6 then return "red" elseif d>=3 then return "orange"
        elseif d>=-2 then return "yellow" elseif d>=-9 then return "green"
        else return "gray" end
    end
    local skill=ranks[kind] or 0
    if skill<required then return "red"
    elseif skill<required+25 then return "orange"
    elseif skill<required+50 then return "yellow"
    elseif skill<required+100 then return "green"
    else return "gray" end
end
local function ShowNode(node)
    local kind=node.kind or "herb"
    return kind=="treasure" or (ranks[kind] or 0)>0
end
local function Icon(node)
    local kind,name=node.kind or "herb",node.name
    if kind=="skin" and R.skinIcons[name] then return R.skinIcons[name] end
    if kind=="wood" and R.woodIcons[name] then return R.woodIcons[name] end
    if type(node.texture)=="string" or type(node.texture)=="number" then return node.texture end
    if kind=="herb" then return R.herbIcons[name] or R.herbIcons.Peacebloom end
    if kind=="mineral" then
        return R.mineralIcons[name] or R.mineralIcons[(name or ""):gsub("^Ooze Covered ","")]
            or R.fallbackIcons.mineral
    end
    return R.fallbackIcons[kind] or R.fallbackIcons.treasure
end

local function MapNodes(mapID)
    if not db or type(db.nodes)~="table" or type(mapID)~="number" then return end
    local nodes=db.nodes["map:"..mapID]
    if previewMarker and previewMarker.mapID==mapID then
        local combined={}
        if type(nodes)=="table" then
            for i=1,#nodes do combined[i]=nodes[i] end
        end
        combined[#combined+1]=previewMarker.node
        return combined
    end
    if type(nodes)=="table" then return nodes end
end
local function PlayerMapID()
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetMapInfo) then return end
    local id=C_Map.GetBestMapForUnit("player")
    for i=1,8 do
        if not id then return end
        local info=C_Map.GetMapInfo(id)
        if not info then return end
        if info.mapType==3 then return id end
        if info.mapType<3 or not info.parentMapID or info.parentMapID==0 then return end
        id=info.parentMapID
    end
end
local function PlayerMapPosition()
    local id=PlayerMapID()
    if not id or not C_Map.GetPlayerMapPosition then return end
    local pos=C_Map.GetPlayerMapPosition(id,"player")
    if pos and Valid(pos.x) and Valid(pos.y) then return id,pos.x,pos.y end
end
-- A normalized observation writer shared with the separate Forever capture module.
-- Never interprets or alters the legacy "continent:zone" map keys.
local RECENT_DISTANCE, RECENT_SECONDS = 0.004, 2
local recorded, lastRecorded = nil, nil
local allowedKind = { herb=true, mineral=true, skin=true, lock=true, treasure=true }
ns.GatherMapPosition = PlayerMapPosition
ns.GatherMapRecord = function(observation)
    if type(observation)~="table" or not db or type(db.nodes)~="table" then
        return false,"database"
    end
    local kind,name=observation.kind,observation.name
    if not allowedKind[kind] or type(name)~="string"
        or #name==0 or #name>128 or name:find("[%c]") then
        return false,"invalid resource"
    end
    local id,x,y=observation.mapID,observation.x,observation.y
    if type(id)~="number" or id<1 or id~=math.floor(id)
        or not Valid(x) or not Valid(y) then return false,"position" end
    local key="map:"..id
    local nodes=db.nodes[key]
    if nodes==nil then nodes={};db.nodes[key]=nodes end
    if type(nodes)~="table" then return false,"invalid saved zone" end

    local now=GetTime()
    if lastRecorded and lastRecorded.kind==kind and lastRecorded.name==name
        and lastRecorded.key==key and now-lastRecorded.at<RECENT_SECONDS
        and math.abs(lastRecorded.x-x)<=RECENT_DISTANCE
        and math.abs(lastRecorded.y-y)<=RECENT_DISTANCE then
        return false,"duplicate event"
    end
    local required=tonumber(observation.required)
    if required and (required<1 or required>999) then required=nil end
    local texture=observation.texture
    if type(texture)~="number" and type(texture)~="string" then texture=nil end
    local zoneName=type(observation.zoneName)=="string" and observation.zoneName or ""
    local areaName=type(observation.areaName)=="string" and observation.areaName or ""
    for i=1,#nodes do
        local node=nodes[i]
        if type(node)=="table" and node.kind==kind and node.name==name
            and Valid(node.x) and Valid(node.y)
            and math.abs(node.x-x)<=RECENT_DISTANCE
            and math.abs(node.y-y)<=RECENT_DISTANCE then
            local count=tonumber(node.count) or 1
            if count<1 then count=1 end
            if count>100000000 then count=100000000 end
            node.x=(node.x*count+x)/(count+1)
            node.y=(node.y*count+y)/(count+1)
            node.count=count+1
            if required then node.required=required end
            if texture then node.texture=texture end
            if zoneName~="" then node.zoneName=zoneName end
            if areaName~="" then node.areaName=areaName end
            lastRecorded={kind=kind,name=name,key=key,x=x,y=y,at=now}
            dirty=true
            return true,"updated"
        end
    end
    nodes[#nodes+1]={
        kind=kind,name=name,x=x,y=y,required=required,texture=texture,
        zoneName=zoneName,areaName=areaName,count=1,
    }
    lastRecorded={kind=kind,name=name,key=key,x=x,y=y,at=now}
    dirty=true
    return true,"learned"
end

local function WorldPosition(id,x,y,node)
    if not C_Map.GetWorldPosFromMapPos then return end
    if node then
        local cached=worldCache[node]
        if cached and cached.id==id and cached.x==x and cached.y==y then
            return cached.instance,cached.wx,cached.wy
        end
    end
    local instance,pos=C_Map.GetWorldPosFromMapPos(id,{x=x,y=y})
    if not (instance and pos and type(pos.x)=="number" and type(pos.y)=="number") then return end
    if node then worldCache[node]={id=id,x=x,y=y,instance=instance,wx=pos.x,wy=pos.y} end
    return instance,pos.x,pos.y
end
local function Overlaps(a,b)
    return a.left<=b.right and a.right>=b.left and a.bottom<=b.top and a.top>=b.bottom
end
local function AddGroup(groups,x,y,node)
    local kind=node.kind or "herb"
    local group={left=x-7,right=x+7,bottom=y-7,top=y+7,
        key=kind..":"..node.name,name=node.name,icon=Icon(node),color=Difficulty(node)}
    local merged=true
    while merged do
        merged=false
        for i=#groups,1,-1 do
            local other=groups[i]
            if group.key==other.key and Overlaps(group,other) then
                group.left=math.min(group.left,other.left)
                group.right=math.max(group.right,other.right)
                group.bottom=math.min(group.bottom,other.bottom)
                group.top=math.max(group.top,other.top)
                if R.difficultyPriority[other.color]>R.difficultyPriority[group.color] then
                    group.color=other.color
                end
                table.remove(groups,i); merged=true
            end
        end
    end
    groups[#groups+1]=group
end
local function AddCorners(pin)
    pin.corners={}
    local points={"TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT"}
    for i=1,4 do
        local tex=pin:CreateTexture(nil,"OVERLAY")
        tex:SetSize(DOT_SIZE,DOT_SIZE)
        tex:SetPoint(points[i],pin,points[i])
        pin.corners[i]=tex
    end
end
local function Style(pin,g)
    local c=R.colors[g.color]
    pin.name=g.name
    pin:SetSize(math.max(14,g.right-g.left),math.max(14,g.top-g.bottom))
    pin:SetAlpha(g.color=="gray" and 0.85 or 1)
    for i=1,4 do pin.corners[i]:SetColorTexture(c[1],c[2],c[3],1) end
    if pin.icon then pin.icon:SetTexture(g.icon) end
end
local function AcquireMini(index)
    if miniPins[index] then return miniPins[index] end
    local pin=CreateFrame("Frame",nil,Minimap)
    pin:SetFrameLevel(Minimap:GetFrameLevel()+5)
    pin:EnableMouse(false)
    AddCorners(pin)
    miniPins[index]=pin
    return pin
end
local function HideMini(start)
    for i=start,#miniPins do miniPins[i]:Hide() end
end
local function DrawMinimap()
    if InCombatLockdown and InCombatLockdown() then return end
    if not (db and db.enabled and Minimap and Minimap:IsShown()
        and C_Minimap and C_Minimap.GetViewRadius) then HideMini(1); return end
    local mapID,px,py=PlayerMapPosition()
    local nodes=mapID and MapNodes(mapID)
    if not nodes then HideMini(1); return end
    local instance,wx,wy=WorldPosition(mapID,px,py)
    local radius=C_Minimap.GetViewRadius()
    if not(instance and wx and wy and type(radius)=="number" and radius>0) then
        HideMini(1); return
    end
    local w,h=Minimap:GetWidth()/2,Minimap:GetHeight()/2
    local rotate=GetCVarBool and GetCVarBool("rotateMinimap")
    local facing=rotate and GetPlayerFacing and GetPlayerFacing() or 0
    if type(facing)~="number" or (issecretvalue and issecretvalue(facing)) then facing=0 end
    local s,c=math.sin(facing),math.cos(facing)
    local groups={}
    for _,node in ipairs(nodes) do
        if type(node)=="table" and type(node.name)=="string" and
            Valid(node.x) and Valid(node.y) and ShowNode(node) then
            local other,x,y=WorldPosition(mapID,node.x,node.y,node)
            if other==instance then
                local dx,dy=x-wx,y-wy
                if dx*dx+dy*dy<=radius*radius then
                    -- World X increases north; world Y increases west.
                    local sx,sy=-dy/radius*w,dx/radius*h
                    if rotate then sx,sy=sx*c-sy*s,sx*s+sy*c end
                    AddGroup(groups,sx,sy,node)
                end
            end
        end
    end
    local count=math.min(MAX_PINS,#groups)
    for i=1,count do
        local g=groups[i]
        local pin=AcquireMini(i)
        Style(pin,g)
        pin:ClearAllPoints()
        pin:SetPoint("CENTER",Minimap,"CENTER",
            (g.left+g.right)/2,(g.bottom+g.top)/2)
        pin:Show()
    end
    HideMini(count+1)
end

-- Map mixins are installed when Blizzard's MapCanvas code is available.
GatherMapForeverWorldPinMixin={}
function GatherMapForeverWorldPinMixin:OnLoad()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
    self:SetScalingLimits(1,1,1.2)
    self:EnableMouse(false)
    self.icon=self:CreateTexture(nil,"ARTWORK")
    self.icon:SetPoint("TOPLEFT",self,"TOPLEFT",3,-3)
    self.icon:SetPoint("BOTTOMRIGHT",self,"BOTTOMRIGHT",-3,3)
    self.icon:SetTexCoord(0.08,0.92,0.08,0.92)
    AddCorners(self)
end
function GatherMapForeverWorldPinMixin:OnAcquired(g,width,height)
    self:SetPosition((g.left+g.right)/(2*width),(g.bottom+g.top)/(2*height))
    Style(self,g)
    mapPins[#mapPins+1]=self
end
local providerMethods={}
function providerMethods:RemoveAllData()
    self:GetMap():RemoveAllPinsByTemplate("GatherMapForeverWorldPinTemplate")
    for i=#mapPins,1,-1 do mapPins[i]=nil end
end
function providerMethods:RefreshAllData()
    self:RemoveAllData()
    if not(db and db.worldMapEnabled) then return end
    local map=self:GetMap()
    local nodes=MapNodes(map:GetMapID())
    if not nodes then return end
    local canvas=map.ScrollContainer
    local w=canvas and canvas:GetWidth() or map:GetWidth()
    local h=canvas and canvas:GetHeight() or map:GetHeight()
    if not(w and h and w>0 and h>0) then return end
    local groups={}
    for _,node in ipairs(nodes) do
        if type(node)=="table" and type(node.name)=="string" and
            Valid(node.x) and Valid(node.y) and ShowNode(node) then
            AddGroup(groups,node.x*w,node.y*h,node)
        end
    end
    for i=1,math.min(MAX_PINS,#groups) do
        map:AcquirePin("GatherMapForeverWorldPinTemplate",groups[i],w,h)
    end
end
local function DrawWorld()
    if InCombatLockdown and InCombatLockdown() then return end
    if provider and WorldMapFrame and WorldMapFrame:IsShown() then
        provider:RefreshAllData()
    end
end
local function SetupWorld()
    if InCombatLockdown and InCombatLockdown() then return end
    if provider or not(db and WorldMapFrame and WorldMapFrame.AddDataProvider
        and MapCanvasPinMixin and MapCanvasDataProviderMixin and CreateFromMixins) then return end
    for name,method in pairs(MapCanvasPinMixin) do
        if GatherMapForeverWorldPinMixin[name]==nil then
            GatherMapForeverWorldPinMixin[name]=method
        end
    end
    provider=CreateFromMixins(MapCanvasDataProviderMixin,providerMethods)
    WorldMapFrame:AddDataProvider(provider)
    checkbox=CreateFrame("CheckButton","GatherMapForeverMapToggle",
        WorldMapFrame,"UICheckButtonTemplate")
    checkbox:SetSize(24,24)
    checkbox:SetPoint("TOPLEFT",WorldMapFrame,"TOPLEFT",46,-26)
    local label=_G.GatherMapForeverMapToggleText
    if label then label:SetText("Gather Map");label:SetTextColor(0.41,0.80,0.44) end
    checkbox:SetChecked(db.worldMapEnabled)
    checkbox:SetScript("OnClick",function(self)
        db.worldMapEnabled=not not self:GetChecked()
        DrawWorld()
    end)
end

-- Passive hover preserves native map clicks and dragging.
local function Hover()
    if not (GetCursorPosition and UIParent and GameTooltip) then return end
    local x,y=GetCursorPosition()
    local scale=UIParent:GetEffectiveScale()
    if not scale or scale<=0 then return end
    x,y=x/scale,y/scale
    local pool=WorldMapFrame and WorldMapFrame:IsShown() and mapPins or miniPins
    local candidate
    for _,pin in ipairs(pool) do
        if pin:IsShown() and pin.name and pin:GetLeft() and pin:GetRight()
            and pin:GetBottom() and pin:GetTop()
            and x>=pin:GetLeft() and x<=pin:GetRight()
            and y>=pin:GetBottom() and y<=pin:GetTop() then
            candidate=pin;break
        end
    end
    if candidate==activeTooltip then return end
    activeTooltip=candidate
    if candidate then
        GameTooltip:SetOwner(UIParent,"ANCHOR_CURSOR")
        GameTooltip:SetText(candidate.name)
        GameTooltip:Show()
    elseif GameTooltip:IsOwned(UIParent) then GameTooltip:Hide() end
end

local function Initialize()
    -- Keep malformed existing SavedVariables intact for manual recovery.
    -- Silently replacing them could erase the player's discovery history.
    if GatherMapDB~=nil and type(GatherMapDB)~="table" then
        Print("Invalid saved database; leaving existing data untouched.")
        return
    end
    if GatherMapDB==nil then GatherMapDB={} end
    db=GatherMapDB
    if db.nodes~=nil and type(db.nodes)~="table" then
        Print("Invalid saved nodes; leaving existing data untouched.")
        db=nil
        return
    end
    if db.nodes==nil then db.nodes={} end
    if db.enabled==nil then db.enabled=true end
    if db.worldMapEnabled==nil then db.worldMapEnabled=true end
    if db.version==nil then db.version=3 end
    RefreshSkills()
    SetupWorld()
    dirty=true
end
local function Status()
    local mapped,legacy=0,0
    for key,nodes in pairs(db.nodes) do
        if type(nodes)=="table" then
            if type(key)=="string" and key:match("^map:%d+$") then mapped=mapped+#nodes
            else legacy=legacy+#nodes end
        end
    end
    Print("Forever preview: "..mapped.." UiMapID records, "..legacy..
        " untouched legacy records. Map "..tostring(PlayerMapID()))
    Print("Herbalism "..ranks.herb..", Mining "..ranks.mineral..
        ", Skinning "..ranks.skin..", Lockpicking "..ranks.lock)
    if ns.GatherMapCaptureStatus then Print(ns.GatherMapCaptureStatus()) end
    Print("Legacy saved-location migration is pending.")
end
SLASH_GATHERMAP1="/gmap"
SLASH_GATHERMAP2="/gathermap"
SlashCmdList["GATHERMAP"]=function(message)
    if not db then return end
    local command=(message or ""):lower():match("^%s*(.-)%s*$")
    if command=="on" or command=="show" then
        db.enabled=true;dirty=true;Print("minimap overlay enabled.")
    elseif command=="off" or command=="hide" then
        db.enabled=false;dirty=true;Print("minimap overlay hidden.")
    elseif command=="testpin" then
        local mapID,x,y=PlayerMapPosition()
        if not mapID then Print("No usable zone map position."); return end
        previewMarker={mapID=mapID,node={
            name="GatherMap preview",kind="treasure",x=x,y=y,count=1,
        }}
        dirty=true
        Print("Temporary purple test marker created at your position; not saved.")
    elseif command=="clear" then
        previewMarker=nil;dirty=true
        Print("Temporary marker cleared.")
    elseif command=="capture on" then
        if ns.GatherMapSetCapture then ns.GatherMapSetCapture(true) end
    elseif command=="capture off" then
        if ns.GatherMapSetCapture then ns.GatherMapSetCapture(false) end
    elseif command=="capture status" then
        if ns.GatherMapCaptureStatus then Print(ns.GatherMapCaptureStatus()) end
    elseif command=="count" or command=="status" or command=="debug" or command=="" then
        Status()
    else Print("commands: /gmap on, off, status, testpin, clear, capture on|off|status") end
end

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("SKILL_LINES_CHANGED")
f:RegisterEvent("CHAT_MSG_SKILL")
f:RegisterEvent("MINIMAP_UPDATE_ZOOM")
f:RegisterEvent("ZONE_CHANGED")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("PLAYER_MAP_CHANGED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent",function(self,event,loaded)
    if event=="ADDON_LOADED" then
        if loaded==addonName then Initialize()
        elseif db then SetupWorld() end
        return
    end
    if not db then return end
    if event=="PLAYER_ENTERING_WORLD" then RefreshSkills();SetupWorld()
    elseif event=="SKILL_LINES_CHANGED" or event=="CHAT_MSG_SKILL" then RefreshSkills()
    elseif event=="PLAYER_REGEN_ENABLED" then SetupWorld() end
    dirty=true
end)
f:SetScript("OnUpdate",function(self,dt)
    if not db then return end
    tick=tick+dt
    skillTick=skillTick+dt
    if skillTick>=3 then
        skillTick=0
        if RefreshSkills() then DrawWorld() end
    end
    if tick<0.35 and not dirty then return end
    tick=0
    if dirty then SetupWorld();DrawWorld();dirty=false end
    DrawMinimap()
    Hover()
end)
