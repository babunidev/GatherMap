-- GatherMap — Forever 1.60.1 API compatibility layer.
-- Renders native map-ID records and the opt-in experimental recorder.
-- Legacy continent-zone migration is deliberately disabled until verified.
local addonName, ns = ...
local R = ns.resources
local difficulty = ns.GatherMapDifficulty
local markers = ns.GatherMapMarkers
local db, provider, checkbox
local miniPins, mapPins = {}, {}
local worldCache = setmetatable({}, { __mode = "k" })
local activeTooltip, dirty, tick, skillDirty = nil, true, 0, false
local renderRevision = 0
local miniCache
local mapLabel, mapLabelText
local previewMarker -- temporary test fixture; never saved
local MAX_PINS, DOT_SIZE = 300, 3
local f = CreateFrame("Frame")

local function MarkDirty()
    renderRevision = renderRevision + 1
    dirty = true
end
local function Print(s)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff68cc70Gather Map:|r "..s) end
end
local function Valid(n)
    if issecretvalue and issecretvalue(n) then return false end
    return type(n)=="number" and n==n and n>=0 and n<=1
end
-- Difficulty is computed from this character's active skills. Never stored
-- alongside account-wide discoveries in GatherMapDB.
local function Difficulty(node)
    return difficulty.Color(node, UnitLevel("player"))
end
local function ShowNode(node)
    return difficulty.IsVisible(node)
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
local function VectorXY(value)
    if not value then return nil end
    if value.GetXY then return value:GetXY() end
    return value.x, value.y
end
local function PlayerMapPosition()
    local id=PlayerMapID()
    if not id or not C_Map.GetPlayerMapPosition then return end
    local pos=C_Map.GetPlayerMapPosition(id,"player")
    local x,y=VectorXY(pos)
    if Valid(x) and Valid(y) then return id,x,y end
end
-- A normalized observation writer shared with the separate Forever capture module.
-- Never interprets or alters the legacy "continent:zone" map keys.
local RECENT_DISTANCE, RECENT_SECONDS = 0.004, 2
local lastRecorded
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
            MarkDirty()
            return true,"updated"
        end
    end
    nodes[#nodes+1]={
        kind=kind,name=name,x=x,y=y,required=required,texture=texture,
        zoneName=zoneName,areaName=areaName,count=1,
    }
    lastRecorded={kind=kind,name=name,key=key,x=x,y=y,at=now}
    MarkDirty()
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
    local mapPosition = CreateVector2D and CreateVector2D(x, y) or {x=x, y=y}
    local instance,pos=C_Map.GetWorldPosFromMapPos(id,mapPosition)
    local wx,wy=VectorXY(pos)
    if not (instance and markers.Finite(wx) and markers.Finite(wy)) then return end
    if node then worldCache[node]={id=id,x=x,y=y,instance=instance,wx=wx,wy=wy} end
    return instance,wx,wy
end
-- The four 3px dots intentionally leave the marker centre clear.
local function AddCorners(pin)
    pin.corners = {}
    local points = {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}
    for i = 1, 4 do
        local dot = pin:CreateTexture(nil, "OVERLAY")
        dot:SetSize(DOT_SIZE, DOT_SIZE)
        dot:SetPoint(points[i], pin, points[i], 0, 0)
        pin.corners[i] = dot
    end
end
local function Style(pin, group)
    local color = R.colors[group.color] or R.colors.unknown
    pin.name = group.name
    pin:SetSize(math.max(14, group.right - group.left),
        math.max(14, group.top - group.bottom))
    pin:SetAlpha(group.color == "gray" and 0.85 or 1)
    for i = 1, 4 do
        pin.corners[i]:SetColorTexture(color[1], color[2], color[3], 1)
    end
    if pin.icon then pin.icon:SetTexture(group.icon) end
end
local function AcquireMini(index)
    local pin = miniPins[index]
    if pin then return pin end
    pin = CreateFrame("Frame", nil, Minimap)
    pin:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    pin:EnableMouse(false)
    AddCorners(pin)
    miniPins[index] = pin
    return pin
end
local function HideMini(first)
    for i = first, #miniPins do miniPins[i]:Hide() end
end
local function ClearMini()
    miniCache = nil
    HideMini(1)
end
local function DrawMinimap()
    if InCombatLockdown and InCombatLockdown() then return end
    if not (db and db.enabled and Minimap and Minimap:IsShown()
        and C_Minimap and C_Minimap.GetViewRadius) then
        ClearMini()
        return
    end
    local mapID, px, py = PlayerMapPosition()
    local nodes = mapID and MapNodes(mapID)
    if not nodes then ClearMini(); return end
    local instance, wx, wy = WorldPosition(mapID, px, py)
    local radius = C_Minimap.GetViewRadius()
    if not (instance and markers.Finite(wx) and markers.Finite(wy)
        and markers.Finite(radius) and radius > 0) then
        ClearMini()
        return
    end
    local width, height = Minimap:GetWidth(), Minimap:GetHeight()
    if not (width > 0 and height > 0) then ClearMini(); return end
    local rotate = GetCVarBool and GetCVarBool("rotateMinimap") or false
    local facing = rotate and GetPlayerFacing and GetPlayerFacing() or 0
    if not markers.Finite(facing) then facing = 0 end
    local previous = miniCache
    if previous and previous.mapID == mapID and previous.instance == instance
        and previous.x == wx and previous.y == wy
        and previous.radius == radius and previous.width == width
        and previous.height == height and previous.rotation == facing
        and previous.revision == renderRevision then return end
    miniCache = {mapID = mapID, instance = instance,
        x = wx, y = wy, radius = radius, width = width, height = height,
        rotation = facing, revision = renderRevision}

    local function Project(node)
        if not (type(node.x) == "number" and type(node.y) == "number"
            and Valid(node.x) and Valid(node.y)) then return nil end
        local nodeInstance, x, y = WorldPosition(mapID, node.x, node.y, node)
        if nodeInstance ~= instance then return nil end
        return markers.MiniPoint(x - wx, y - wy, radius, width, height,
            facing, rotate)
    end
    local groups = markers.Group(nodes, Project, ShowNode, Difficulty, Icon)
    local count = math.min(#groups, MAX_PINS)
    for i = 1, count do
        local group, pin = groups[i], AcquireMini(i)
        Style(pin, group)
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", Minimap, "CENTER",
            (group.left + group.right) / 2, (group.bottom + group.top) / 2)
        pin:Show()
    end
    HideMini(count + 1)
end

-- Native Blizzard map-canvas pins follow zoom, panning and map selection.
-- Frame templates are mouse-disabled to preserve the game's map controls.
GatherMapForeverWorldPinMixin = {}
function GatherMapForeverWorldPinMixin:OnLoad()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
    self:SetScalingLimits(1, 1, 1)
    self:EnableMouse(false)
    self.icon = self:CreateTexture(nil, "ARTWORK")
    self.icon:SetPoint("TOPLEFT", self, "TOPLEFT", 3, -3)
    self.icon:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -3, 3)
    self.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    AddCorners(self)
end
function GatherMapForeverWorldPinMixin:OnAcquired(group, canvasWidth, canvasHeight)
    self:SetPosition((group.left + group.right) / (2 * canvasWidth),
        (group.bottom + group.top) / (2 * canvasHeight))
    Style(self, group)
    mapPins[#mapPins + 1] = self
end
local providerMethods = {}
function providerMethods:RemoveAllData()
    -- Reused pool frames may represent different resource groups.
    activeTooltip = nil
    if mapLabel then mapLabel:Hide() end
    local map = self:GetMap()
    if map then map:RemoveAllPinsByTemplate("GatherMapForeverWorldPinTemplate") end
    for i = #mapPins, 1, -1 do mapPins[i] = nil end
end
function providerMethods:RefreshAllData()
    self:RemoveAllData()
    if not (db and db.worldMapEnabled) then return end
    local map = self:GetMap()
    if not map then return end
    local nodes = MapNodes(map:GetMapID())
    if not nodes then return end
    local canvas = map.GetCanvas and map:GetCanvas()
    if not canvas then return end
    local width, height = canvas:GetWidth(), canvas:GetHeight()
    local scale = map.GetCanvasScale and map:GetCanvasScale() or 1
    if not (markers.Finite(width) and markers.Finite(height)
        and markers.Finite(scale) and width > 0 and height > 0
        and scale > 0) then return end

    -- Collision geometry is measured in visible (zoomed) pixels.
    -- Coordinates remain normalized when assigned to MapCanvas pins.
    local function Project(node)
        return markers.WorldPoint(node.x, node.y, width, height, scale)
    end
    local groups = markers.Group(nodes, Project, ShowNode, Difficulty, Icon)
    local scaledWidth, scaledHeight = width * scale, height * scale
    for i = 1, math.min(#groups, MAX_PINS) do
        map:AcquirePin("GatherMapForeverWorldPinTemplate",
            groups[i], scaledWidth, scaledHeight)
    end
end
function providerMethods:OnCanvasScaleChanged()
    -- Map canvas zoom animates across frames. Recompute at the next 0.35s
    -- map tick rather than allocating groups for every animation frame.
    self.needsResizeRefresh = true
end
function providerMethods:OnCanvasSizeChanged()
    self.needsResizeRefresh = true
end

local function DrawWorld()
    if InCombatLockdown and InCombatLockdown() then return end
    if provider and WorldMapFrame and WorldMapFrame:IsShown() then
        provider:RefreshAllData()
    end
end
local function SetupWorld()
    if InCombatLockdown and InCombatLockdown() then return end
    if provider or not (db and WorldMapFrame and WorldMapFrame.AddDataProvider
        and MapCanvasPinMixin and MapCanvasDataProviderMixin
        and CreateFromMixins) then return end
    for name, method in pairs(MapCanvasPinMixin) do
        if GatherMapForeverWorldPinMixin[name] == nil then
            GatherMapForeverWorldPinMixin[name] = method
        end
    end
    provider = CreateFromMixins(MapCanvasDataProviderMixin, providerMethods)
    WorldMapFrame:AddDataProvider(provider)
    checkbox = CreateFrame("CheckButton", "GatherMapForeverMapToggle",
        WorldMapFrame, "UICheckButtonTemplate")
    checkbox:SetSize(24, 24)
    checkbox:SetPoint("TOPLEFT", WorldMapFrame.ScrollContainer or WorldMapFrame,
        "TOPLEFT", 14, -30)
    checkbox:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 10)
    local label = _G.GatherMapForeverMapToggleText
    if label then
        label:SetText("Gather Map")
        label:SetTextColor(0.41, 0.80, 0.44)
    end
    checkbox:SetChecked(db.worldMapEnabled)
    checkbox:SetScript("OnClick", function(self)
        db.worldMapEnabled = not not self:GetChecked()
        MarkDirty()
        DrawWorld()
    end)
end

-- A private label avoids reading or modifying GameTooltip during gathering.
-- It has no mouse input and cannot prevent dragging or clicking map art.
local function MarkerLabel()
    if mapLabel then return mapLabel end
    mapLabel = CreateFrame("Frame", nil, UIParent)
    mapLabel:SetFrameStrata("TOOLTIP")
    mapLabel:EnableMouse(false)
    mapLabel:SetSize(44, 22)
    local background = mapLabel:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(mapLabel)
    background:SetColorTexture(0.05, 0.05, 0.05, 0.92)
    mapLabelText = mapLabel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mapLabelText:SetPoint("CENTER", mapLabel, "CENTER")
    mapLabel:Hide()
    return mapLabel
end
local function HideLabel()
    if mapLabel then mapLabel:Hide() end
    activeTooltip = nil
end
local function Hover()
    if not (GetCursorPosition and UIParent) then return end
    local worldOpen = WorldMapFrame and WorldMapFrame:IsShown()
    local worldCanvas = worldOpen and WorldMapFrame.ScrollContainer
    local worldAllowed = worldOpen and worldCanvas
        and worldCanvas.IsMouseOver and worldCanvas:IsMouseOver()
    local miniAllowed = not worldOpen and Minimap and Minimap:IsShown()
        and Minimap.IsMouseOver and Minimap:IsMouseOver()
    if not worldAllowed and not miniAllowed then HideLabel(); return end
    local pool = worldAllowed and mapPins or miniPins
    local cx, cy = GetCursorPosition()
    local candidate
    for i = 1, #pool do
        local pin = pool[i]
        if pin:IsShown() and pin.name and pin:GetLeft() and pin:GetRight()
            and pin:GetBottom() and pin:GetTop() then
            local scale = pin:GetEffectiveScale()
            if scale and scale > 0 then
                local x, y = cx / scale, cy / scale
                if x >= pin:GetLeft() - 3 and x <= pin:GetRight() + 3
                    and y >= pin:GetBottom() - 3 and y <= pin:GetTop() + 3 then
                    candidate = pin
                    break
                end
            end
        end
    end
    if not candidate then HideLabel(); return end
    local label = MarkerLabel()
    if activeTooltip ~= candidate or mapLabelText:GetText() ~= candidate.name then
        activeTooltip = candidate
        mapLabelText:SetText(candidate.name)
        label:SetWidth(math.max(44, mapLabelText:GetStringWidth() + 18))
        label:Show()
    end
    local uiScale = UIParent:GetEffectiveScale()
    if not uiScale or uiScale <= 0 then HideLabel(); return end
    local x, y = cx / uiScale, cy / uiScale
    if x + label:GetWidth() + 18 > UIParent:GetWidth() then
        x = x - label:GetWidth() - 14
    else x = x + 14 end
    if y + label:GetHeight() + 18 > UIParent:GetHeight() then
        y = y - label:GetHeight() - 14
    else y = y + 14 end
    label:ClearAllPoints()
    label:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
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
    difficulty.Refresh()
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
    local function SkillText(kind)
        local observed = difficulty.Skill(kind)
        if not observed or not observed.present then return "not learned" end
        local bonus = observed.effective - observed.rank
        if bonus == 0 then return tostring(observed.rank) end
        return tostring(observed.rank) .. " (" .. (bonus >= 0 and "+" or "") ..
            tostring(bonus) .. " bonus)"
    end
    Print("Herbalism "..SkillText("herb")..", Mining "..SkillText("mineral")..
        ", Skinning "..SkillText("skin")..", Lockpicking "..SkillText("lock"))
    if ns.GatherMapCaptureStatus then Print(ns.GatherMapCaptureStatus()) end
    Print("Legacy saved-location migration is pending.")
end
SLASH_GATHERMAP1="/gmap"
SLASH_GATHERMAP2="/gathermap"
SlashCmdList["GATHERMAP"]=function(message)
    if not db then return end
    local command=(message or ""):lower():match("^%s*(.-)%s*$")
    if command=="on" or command=="show" then
        db.enabled=true;MarkDirty();Print("minimap overlay enabled.")
    elseif command=="off" or command=="hide" then
        db.enabled=false;MarkDirty();Print("minimap overlay hidden.")
    elseif command=="testpin" then
        local mapID,x,y=PlayerMapPosition()
        if not mapID then Print("No usable zone map position."); return end
        previewMarker={mapID=mapID,node={
            name="GatherMap preview",kind="treasure",x=x,y=y,count=1,
        }}
        MarkDirty()
        Print("Temporary purple test marker created at your position; not saved.")
    elseif command=="clear" then
        previewMarker=nil;MarkDirty()
        Print("Temporary marker cleared.")
    elseif command=="world on" or command=="world off" then
        db.worldMapEnabled = command == "world on"
        if checkbox then checkbox:SetChecked(db.worldMapEnabled) end
        MarkDirty()
        DrawWorld()
        Print("world-map overlay "..(db.worldMapEnabled and "enabled." or "hidden."))
    elseif command=="capture on" then
        if ns.GatherMapSetCapture then ns.GatherMapSetCapture(true) end
    elseif command=="capture off" then
        if ns.GatherMapSetCapture then ns.GatherMapSetCapture(false) end
    elseif command=="capture status" then
        if ns.GatherMapCaptureStatus then Print(ns.GatherMapCaptureStatus()) end
    elseif command=="count" or command=="status" or command=="debug" or command=="" then
        Status()
    else Print("commands: /gmap on, off, world on|off, status, testpin, clear, capture on|off|status") end
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
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
f:RegisterEvent("PROFESSION_EQUIPMENT_CHANGED")
f:RegisterEvent("UNIT_AURA")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:SetScript("OnEvent",function(self,event,loaded)
    if event=="ADDON_LOADED" then
        if loaded==addonName then Initialize()
        elseif db then SetupWorld() end
        return
    end
    if not db then return end
    if event=="PLAYER_ENTERING_WORLD" then
        skillDirty=true
        SetupWorld()
        dirty=true
    elseif event=="SKILL_LINES_CHANGED" or event=="CHAT_MSG_SKILL"
        or event=="PLAYER_EQUIPMENT_CHANGED"
        or event=="PROFESSION_EQUIPMENT_CHANGED" then
        skillDirty=true
    elseif event=="UNIT_AURA" then
        if issecretvalue and issecretvalue(loaded) then return end
        if loaded=="player" then skillDirty=true end
    else
        if event=="PLAYER_REGEN_ENABLED" then SetupWorld() end
        dirty=true
    end
end)
f:SetScript("OnUpdate",function(self,dt)
    if not db then return end
    tick=tick+dt
    if skillDirty then
        skillDirty=false
        if difficulty.Refresh() then MarkDirty() end
    end
    -- The world-map canvas is sometimes lazy-loaded after ADDON_LOADED.
    if not provider and WorldMapFrame and db then SetupWorld() end
    if tick<0.35 and not dirty then return end
    tick=0
    if dirty then SetupWorld();DrawWorld();dirty=false end
    if provider and provider.needsResizeRefresh and WorldMapFrame
        and WorldMapFrame:IsShown() then
        provider.needsResizeRefresh=false
        DrawWorld()
    end
    DrawMinimap()
    Hover()
end)
