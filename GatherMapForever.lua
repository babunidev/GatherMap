-- GatherMap — Forever 1.60.1 API compatibility layer.
-- Renders native map-ID records and the opt-in experimental recorder.
-- Legacy continent-zone keys are copied only by explicit, backed-up opt-in.
local addonName, ns = ...
local R = ns.resources
local difficulty = ns.GatherMapDifficulty
local markers = ns.GatherMapMarkers
local spatial = ns.GatherMapSpatial
local migration = ns.GatherMapMigration
local db, provider, menuButton, settingsPanel
local menuRows, menuStatus = {}, nil
local miniPins, mapPins = {}, {}
local activeMiniPins = {}
local miniGeneration = 0
local worldCache = setmetatable({}, { __mode = "k" })
local activeTooltip, dirty, tick, skillDirty = nil, true, 0, false
local hoverTick, providerRetryTick = 0, 0
local renderRevision = 0
local worldDirty = true
local visibleMiniPins = 0
local miniGroups, worldLayout, previewCache
local miniContext, worldContext = {}, {}
local miniCache
local mapLabel, mapLabelText
local previewMarker -- temporary test fixture; never saved
local MAX_PINS, DOT_SIZE, MIN_INDEX_NODES = 300, 6, 128
-- Six original tiny rounded-dot images, converted to RGBA TGA for Forever.
-- The historical unknown-difficulty key intentionally displays purple.
local markerRoot = "Interface\\AddOns\\GatherMap\\Textures\\Markers\\marker_"
local markerTextures = {
    red = markerRoot.."red.tga",
    orange = markerRoot.."orange.tga",
    yellow = markerRoot.."yellow.tga",
    green = markerRoot.."green.tga",
    gray = markerRoot.."gray.tga",
    unknown = markerRoot.."purple.tga",
}
local f = CreateFrame("Frame")

local function MarkStyleDirty()
    renderRevision = renderRevision + 1
    miniGroups, worldLayout = nil, nil
    worldDirty = true
    dirty = true
end
local function MarkDirty()
    previewCache = nil
    MarkStyleDirty()
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
    if issecretvalue and issecretvalue(mapID) then return end
    if not db or type(db.nodes)~="table" or type(mapID)~="number"
        or mapID<1 or mapID~=math.floor(mapID) then return end
    local nodes=db.nodes["map:"..mapID]
    if previewMarker and previewMarker.mapID==mapID then
        if previewCache and previewCache.source==nodes
            and previewCache.preview==previewMarker then
            return previewCache.nodes
        end
        local combined={}
        if type(nodes)=="table" then
            for i=1,#nodes do combined[i]=nodes[i] end
        end
        combined[#combined+1]=previewMarker.node
        previewCache={source=nodes,preview=previewMarker,nodes=combined}
        return combined
    end
    if type(nodes)=="table" then return nodes end
end
local function PlayerMapID()
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetMapInfo) then return end
    local id=C_Map.GetBestMapForUnit("player")
    for i=1,8 do
        if issecretvalue and issecretvalue(id) then return end
        if type(id)~="number" or id<1 or id~=math.floor(id) then return end
        local info=C_Map.GetMapInfo(id)
        if issecretvalue and issecretvalue(info) then return end
        if type(info)~="table" then return end
        local mapType=info.mapType
        if issecretvalue and issecretvalue(mapType) then return end
        if type(mapType)~="number" then return end
        if mapType==3 then return id end
        if mapType<3 then return end
        local parent=info.parentMapID
        if issecretvalue and issecretvalue(parent) then return end
        if type(parent)~="number" or parent<1 or parent==id then return end
        id=parent
    end
end
local function VectorXY(value)
    if issecretvalue and issecretvalue(value) then return nil end
    if type(value)~="table" and type(value)~="userdata" then return nil end
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
    if issecretvalue and issecretvalue(id) then return false,"position" end
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
    local requirement=observation.required
    if issecretvalue and issecretvalue(requirement) then requirement=nil end
    local required=tonumber(requirement)
    if required and (required<1 or required>999 or required~=required) then required=nil end
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
            local count=node.count
            if count==nil then count=1 end
            if type(count)~="number" or count~=count or count<1
                or count>=100000000 or count~=math.floor(count) then
                return false,"invalid saved occurrence count"
            end
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
    if not (C_Map and C_Map.GetWorldPosFromMapPos and Valid(x) and Valid(y)) then return end
    if node then
        local cached=worldCache[node]
        if cached and cached.id==id and cached.x==x and cached.y==y then
            return cached.instance,cached.wx,cached.wy
        end
    end
    -- The documented Forever C_Map signature requires a Vector2DMixin.
    -- A plain Lua table may be rejected; fail closed when the constructor is absent.
    if type(CreateVector2D)~="function" then return end
    local mapPosition = CreateVector2D(x, y)
    local instance,pos=C_Map.GetWorldPosFromMapPos(id,mapPosition)
    if issecretvalue and issecretvalue(instance) then return end
    local wx,wy=VectorXY(pos)
    if not (instance and markers.Finite(wx) and markers.Finite(wy)) then return end
    if node then worldCache[node]={id=id,x=x,y=y,instance=instance,wx=wx,wy=wy} end
    return instance,wx,wy
end
-- Group once in a fixed, unrotated world-coordinate plane. Translating
-- the player viewpoint must NEVER change which resource nodes form one
-- four-corner rectangle or how large that rectangle is.
local function ProjectMiniLayout(node)
    local context=miniContext
    local instance,x,y=WorldPosition(context.mapID,node.x,node.y,node)
    if instance~=context.instance or not markers.Finite(x)
        or not markers.Finite(y) then return nil end
    return -y*context.width/(context.radius*2),
        x*context.height/(context.radius*2)
end
local function SortMiniGroups(a,b)
    return a.order<b.order
end
local function ProjectWorld(node)
    return markers.WorldPoint(node.x,node.y,worldContext.width,
        worldContext.height,worldContext.scale)
end

-- Four small transparent textured dots leave the marker centre clear.
local function AddCorners(pin)
    pin.corners = {}
    local points = {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}
    for i = 1, 4 do
        local dot = pin:CreateTexture(nil, "OVERLAY")
        dot:SetSize(DOT_SIZE, DOT_SIZE)
        -- Fractional minimap offsets must not independently pixel-snap each
        -- corner; that makes a stable rectangle appear to shear or flip.
        if dot.SetSnapToPixelGrid then dot:SetSnapToPixelGrid(false) end
        if dot.SetTexelSnappingBias then dot:SetTexelSnappingBias(0) end
        dot:SetPoint(points[i], pin, points[i], 0, 0)
        pin.corners[i] = dot
    end
end
local function Style(pin, group)
    local texture = markerTextures[group.color] or markerTextures.unknown
    pin.name = group.name
    pin:SetSize(math.max(14, group.right - group.left),
        math.max(14, group.top - group.bottom))
    pin:SetAlpha(group.color == "gray" and 0.85 or 1)
    for i = 1, 4 do
        pin.corners[i]:SetTexture(texture)
    end
    if pin.icon then pin.icon:SetTexture(group.icon) end
end
-- Keep a frame owned by the SAME group for its entire visible lifetime.
-- A moving viewport must never restyle an old frame as a different resource.
local function AcquireMini()
    for i=1,#miniPins do
        local pin=miniPins[i]
        if not pin.group then return pin end
    end
    if #miniPins>=MAX_PINS then return nil end
    local pin=CreateFrame("Frame",nil,Minimap)
    pin:SetFrameLevel(Minimap:GetFrameLevel()+5)
    pin:EnableMouse(false)
    AddCorners(pin)
    miniPins[#miniPins+1]=pin
    return pin
end
local function ClearMini()
    miniCache=nil
    for i=1,#miniPins do
        local pin=miniPins[i]
        if pin.group then pin.group.pin=nil;pin.group=nil end
        pin:Hide()
    end
    for i=1,#activeMiniPins do activeMiniPins[i]=nil end
    visibleMiniPins=0
end
local function MinimapFacing()
    local rotate=GetCVarBool and GetCVarBool("rotateMinimap") or false
    if issecretvalue and issecretvalue(rotate) then rotate=false end
    if rotate and C_Minimap and C_Minimap.IsRotateMinimapIgnored then
        local ignored=C_Minimap.IsRotateMinimapIgnored()
        if not (issecretvalue and issecretvalue(ignored)) and ignored then
            rotate=false
        end
    end
    local facing=rotate and GetPlayerFacing and GetPlayerFacing() or 0
    if issecretvalue and issecretvalue(facing) then facing=0 end
    if not markers.Finite(facing) then facing=0 end
    return rotate,facing
end
-- Frame-rate tracking updates only already pooled marker anchors. Expensive
-- discovery grouping and spatial indexing stay on the slower map refresh.
local function TrackMiniPositions()
    if visibleMiniPins==0 or not (db and db.enabled and Minimap
        and Minimap:IsShown() and miniCache) then return end
    -- These are our own unprotected minimap frames. Their positions MUST
    -- continue updating in combat; only the native world-map provider is
    -- subject to the protected-operation guard.
    if not (C_Minimap and C_Minimap.GetViewRadius) then
        ClearMini();dirty=true;return
    end
    -- The zone ID is established by the slower map refresh. Only read the
    -- current vector here; do not traverse the map hierarchy every frame.
    local mapID=miniContext.mapID
    if not (mapID and C_Map and C_Map.GetPlayerMapPosition) then
        ClearMini();dirty=true;return
    end
    local pos=C_Map.GetPlayerMapPosition(mapID,"player")
    local x,y=VectorXY(pos)
    if not Valid(x) or not Valid(y) then ClearMini();dirty=true;return end
    local instance,wx,wy=WorldPosition(mapID,x,y)
    if instance~=miniContext.instance or not markers.Finite(wx)
        or not markers.Finite(wy) then ClearMini();dirty=true;return end
    local width,height=Minimap:GetWidth(),Minimap:GetHeight()
    local radius=C_Minimap.GetViewRadius()
    if issecretvalue and issecretvalue(radius) then
        ClearMini();dirty=true;return
    end
    if not (markers.Finite(radius) and radius>0
        and width==miniContext.width and height==miniContext.height
        and radius==miniContext.radius) then
        ClearMini();dirty=true;return
    end
    local rotate,facing=MinimapFacing()
    if miniContext.lastWX==wx and miniContext.lastWY==wy
        and miniContext.lastFacing==facing and miniContext.lastRotate==rotate then
        return
    end
    miniContext.lastWX,miniContext.lastWY=wx,wy
    miniContext.lastFacing,miniContext.lastRotate=facing,rotate
    for i=1,visibleMiniPins do
        local pin=activeMiniPins[i]
        local sx,sy
        if pin.worldInstance==instance and markers.Finite(pin.worldX)
            and markers.Finite(pin.worldY) then
            sx,sy=markers.MiniPoint(pin.worldX-wx,pin.worldY-wy,
                radius,width,height,facing,rotate)
        end
        if sx then
            if pin.lastSX~=sx or pin.lastSY~=sy then
                pin:SetPoint("CENTER",Minimap,"CENTER",sx,sy)
                pin.lastSX,pin.lastSY=sx,sy
            end
            if not pin:IsShown() then pin:Show() end
        elseif pin:IsShown() then
            pin:Hide()
        end
    end
end
local function DrawMinimap()
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
    if issecretvalue and issecretvalue(radius) then ClearMini();return end
    if not (instance and markers.Finite(wx) and markers.Finite(wy)
        and markers.Finite(radius) and radius > 0) then
        ClearMini()
        return
    end
    local width, height = Minimap:GetWidth(), Minimap:GetHeight()
    if not (markers.Finite(width) and markers.Finite(height)
        and width > 0 and height > 0) then ClearMini();return end
    local rotate,facing=MinimapFacing()
    local previous = miniCache
    if previous and previous.mapID == mapID and previous.instance == instance
        and previous.x == wx and previous.y == wy
        and previous.radius == radius and previous.width == width
        and previous.height == height and previous.rotation == facing
        and previous.revision == renderRevision then return end
    miniCache = {mapID = mapID, instance = instance,
        x = wx, y = wy, radius = radius, width = width, height = height,
        rotation = facing, revision = renderRevision}

    miniContext.mapID, miniContext.instance = mapID, instance
    miniContext.x, miniContext.y = wx, wy
    miniContext.radius, miniContext.width, miniContext.height =
        radius, width, height
    miniContext.facing, miniContext.rotate = facing, rotate
    local layout=miniGroups
    if not layout or layout.mapID~=mapID or layout.instance~=instance
        or layout.source~=nodes or layout.radius~=radius
        or layout.width~=width or layout.height~=height
        or layout.revision~=renderRevision then
        local groups=markers.Group(nodes,ProjectMiniLayout,
            ShowNode,Difficulty,Icon)
        local worldXFactor=radius*2/height
        local worldYFactor=-radius*2/width
        for i=1,#groups do
            local group=groups[i]
            group.worldX=(group.bottom+group.top)/2*worldXFactor
            group.worldY=(group.left+group.right)/2*worldYFactor
            group.worldInstance=instance
            group.order=i
        end
        local index
        if spatial and #groups>=MIN_INDEX_NODES then
            index=spatial.BuildGroups(groups,instance)
        end
        layout={mapID=mapID,instance=instance,source=nodes,
            radius=radius,width=width,height=height,
            revision=renderRevision,groups=groups,index=index}
        miniGroups=layout
    end

    -- Only visibility and position depend on the moving viewpoint.
    -- The immutable group dimensions and members are shared by both passes.
    local candidates=layout.groups
    if layout.index then
        candidates=spatial.Nearby(layout.index,instance,wx,wy,
            radius*1.15)
        table.sort(candidates,SortMiniGroups)
    end
    miniGeneration=miniGeneration+1
    local generation=miniGeneration
    local visibleGroups={}
    for i=1,#candidates do
        if #visibleGroups>=MAX_PINS then break end
        local group=candidates[i]
        local sx,sy=markers.MiniPoint(group.worldX-wx,group.worldY-wy,
            radius,width,height,facing,rotate)
        if sx then
            group.generation=generation
            group.drawX,group.drawY=sx,sy
            visibleGroups[#visibleGroups+1]=group
        end
    end

    -- Release only groups that actually left the view. All other groups
    -- retain their frame identity and corner dimensions across redraws.
    for i=1,#miniPins do
        local pin=miniPins[i]
        if pin.group and pin.group.generation~=generation then
            pin.group.pin=nil
            pin.group=nil
            pin:Hide()
        end
    end
    local count=0
    for i=1,#visibleGroups do
        local group=visibleGroups[i]
        local pin=group.pin
        if not pin then
            pin=AcquireMini()
            if not pin then break end
            group.pin=pin
            pin.group=group
            Style(pin,group)
        end
        count=count+1
        pin.worldX,pin.worldY=group.worldX,group.worldY
        pin.worldInstance=instance
        if pin.lastSX~=group.drawX or pin.lastSY~=group.drawY then
            -- One CENTER point: SetPoint replaces this same anchor.
            pin:SetPoint("CENTER",Minimap,"CENTER",group.drawX,group.drawY)
            pin.lastSX,pin.lastSY=group.drawX,group.drawY
        end
        if not pin:IsShown() then pin:Show() end
        activeMiniPins[count]=pin
    end
    for i=count+1,#activeMiniPins do activeMiniPins[i]=nil end
    visibleMiniPins=count
    miniContext.lastWX,miniContext.lastWY=wx,wy
    miniContext.lastFacing,miniContext.lastRotate=facing,rotate
end

-- Native Blizzard map-canvas pins follow zoom, panning and map selection.
-- Frame templates are mouse-disabled to preserve the game's map controls.
GatherMapForeverWorldPinMixin = {}
-- Forever's MapCanvas:AcquirePin() calls this after OnAcquired, and the
-- inherited implementation invokes the protected SetPassThroughButtons().
-- Our frame is completely mouse-disabled; it requires no passthrough setup.
-- Override ONLY our own template, never Blizzard's global pin mixin.
function GatherMapForeverWorldPinMixin:CheckMouseButtonPassthrough()
    -- Deliberately empty.
end
function GatherMapForeverWorldPinMixin:OnLoad()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
    self:SetScalingLimits(1, 1, 1)
    -- The XML template already has enableMouse="false". Avoid another
    -- protected mouse-state mutation during client map refreshes.
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
    local mapID=map:GetMapID()
    local previous=worldLayout
    local groups
    if previous and previous.mapID==mapID and previous.source==nodes
        and previous.width==width and previous.height==height
        and previous.scale==scale and previous.revision==renderRevision then
        groups=previous.groups
    else
        worldContext.width,worldContext.height,worldContext.scale=width,height,scale
        groups=markers.Group(nodes, ProjectWorld, ShowNode, Difficulty, Icon)
        -- Keep only the existing 300 display groups in the retained cache.
        -- All saved discoveries and transitive grouping are unchanged.
        for i=#groups,MAX_PINS+1,-1 do groups[i]=nil end
        worldLayout={mapID=mapID,source=nodes,width=width,height=height,
            scale=scale,revision=renderRevision,groups=groups}
    end
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
        worldDirty=false
        provider:RefreshAllData()
    end
end
-- A single map button opens a compact toggle panel. Saved nodes are untouched.
local function UpdateMenu()
    if not settingsPanel then return end
    local flags={db and db.enabled,db and db.worldMapEnabled,
        db and db.recordingEnabled,db and db.captureDebug}
    local names={"Minimap markers","World-map markers",
        "Record discoveries","Diagnostic chat"}
    for i=1,#menuRows do
        local active=flags[i]==true
        local text=menuRows[i].label
        text:SetText(names[i]..": "..(active and "ON" or "OFF"))
        if active then text:SetTextColor(0.42,0.85,0.56)
        else text:SetTextColor(0.72,0.72,0.72) end
    end
    if menuStatus then
        menuStatus:SetText("Last: "..(ns.GatherMapCaptureLast
            and ns.GatherMapCaptureLast()
            or "Capture diagnostics unavailable"))
    end
end
local function ToggleSetting(index)
    if not db then return end
    if index==1 then
        db.enabled=not db.enabled
        MarkStyleDirty()
        if not db.enabled then ClearMini() end
    elseif index==2 then
        db.worldMapEnabled=not db.worldMapEnabled
        worldDirty=true
        DrawWorld()
    elseif index==3 then
        if ns.GatherMapSetCapture then
            ns.GatherMapSetCapture(not db.recordingEnabled)
        end
    elseif index==4 then
        if ns.GatherMapSetCaptureDebug then
            ns.GatherMapSetCaptureDebug(not db.captureDebug)
        end
    end
    UpdateMenu()
end
local function CreateMenu()
    if menuButton or not WorldMapFrame then return end
    local anchor=WorldMapFrame.ScrollContainer or WorldMapFrame
    menuButton=CreateFrame("Button","GatherMapForeverMenuButton",WorldMapFrame)
    menuButton:SetSize(104,24)
    menuButton:SetPoint("TOPLEFT",anchor,"TOPLEFT",14,-30)
    menuButton:SetFrameLevel(WorldMapFrame:GetFrameLevel()+10)
    local background=menuButton:CreateTexture(nil,"BACKGROUND")
    background:SetAllPoints(menuButton)
    background:SetColorTexture(0.08,0.12,0.10,0.94)
    local caption=menuButton:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    caption:SetPoint("CENTER",menuButton,"CENTER")
    caption:SetText("GatherMap")
    caption:SetTextColor(0.55,0.9,0.65)

    settingsPanel=CreateFrame("Frame","GatherMapForeverSettingsPanel",WorldMapFrame)
    settingsPanel:SetSize(236,194)
    settingsPanel:SetPoint("TOPLEFT",menuButton,"BOTTOMLEFT",0,-3)
    settingsPanel:SetFrameLevel(menuButton:GetFrameLevel()+2)
    settingsPanel:EnableMouse(true)
    local back=settingsPanel:CreateTexture(nil,"BACKGROUND")
    back:SetAllPoints(settingsPanel)
    back:SetColorTexture(0.055,0.075,0.075,0.96)
    local heading=settingsPanel:CreateFontString(nil,"OVERLAY","GameFontNormal")
    heading:SetPoint("TOPLEFT",settingsPanel,"TOPLEFT",12,-10)
    heading:SetText("GatherMap settings")
    for i=1,4 do
        local row=CreateFrame("Button","GatherMapForeverSetting"..i,settingsPanel)
        row:SetSize(212,26)
        row:SetPoint("TOPLEFT",settingsPanel,"TOPLEFT",12,-(31+(i-1)*28))
        local tile=row:CreateTexture(nil,"BACKGROUND")
        tile:SetAllPoints(row)
        tile:SetColorTexture(0.15,0.19,0.17,0.96)
        row.label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        row.label:SetPoint("LEFT",row,"LEFT",8,0)
        row:SetScript("OnClick",function() ToggleSetting(i) end)
        menuRows[i]=row
    end
    menuStatus=settingsPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    menuStatus:SetPoint("TOPLEFT",settingsPanel,"TOPLEFT",12,-150)
    menuStatus:SetWidth(212)
    menuStatus:SetJustifyH("LEFT")
    menuStatus:SetText("No gathering captured yet")
    settingsPanel:Hide()
    menuButton:SetScript("OnClick",function()
        if settingsPanel:IsShown() then settingsPanel:Hide()
        else UpdateMenu();settingsPanel:Show() end
    end)
    UpdateMenu()
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
    CreateMenu()
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
    -- Lightweight original-style tooltip border, without GameTooltip.
    local borders = {
        {"TOPLEFT", "TOPRIGHT", 1, true},
        {"BOTTOMLEFT", "BOTTOMRIGHT", 1, true},
        {"TOPLEFT", "BOTTOMLEFT", 1, false},
        {"TOPRIGHT", "BOTTOMRIGHT", 1, false},
    }
    for i = 1, #borders do
        local line = mapLabel:CreateTexture(nil, "BORDER")
        line:SetColorTexture(0.4, 0.4, 0.4, 1)
        local edge = borders[i]
        line:SetPoint(edge[1], mapLabel, edge[1])
        line:SetPoint(edge[2], mapLabel, edge[2])
        if edge[4] then line:SetHeight(1) else line:SetWidth(1) end
    end
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
    local pool = worldAllowed and mapPins or activeMiniPins
    local visible = worldAllowed and #mapPins or visibleMiniPins
    if visible==0 then HideLabel();return end
    local cx, cy = GetCursorPosition()
    local candidate
    for i = 1, visible do
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
    local isNew = GatherMapDB==nil
    if isNew then GatherMapDB={} end
    db=GatherMapDB
    if db.nodes~=nil and type(db.nodes)~="table" then
        Print("Invalid saved nodes; leaving existing data untouched.")
        db=nil
        return
    end
    if db.nodes==nil then db.nodes={} end
    if db.enabled==nil then db.enabled=true end
    if db.worldMapEnabled==nil then db.worldMapEnabled=true end
    -- The absent version of an existing database means schema v1, NOT v3.
    -- Preserve it until an explicit, non-destructive migration applies.
    if isNew then db.version=3 end
    if migration then migration.Init(db, MarkDirty) end
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
    if migration then
        local state = migration.Status()
        if state then
            Print("Historical zones "..state.zones..": "..state.migrated..
                " copied, "..state.unmatched.." unmapped; "..state.records..
                " original records preserved.")
        end
    end
end
local function MigrationCommand(command)
    if not migration then Print("Migration module unavailable."); return end
    local action,key,confirm=command:match("^migrate%s+(%S+)%s+(%S+)%s*(%S*)$")
    if command=="migrate" or command=="migrate help" then
        Print("migrate status | link <key> | anchor <key> <node-index> | preview <key> | apply <key> confirm | rollback <key>")
        Print("Make a physical SavedVariables backup with the game closed first.")
        return
    end
    if command=="migrate status" then
        local summary=migration.Status()
        if summary then
            Print(summary.zones.." historical zones, "..summary.records..
                " original records; "..summary.links.." links, "..
                summary.migrated.." copied, "..summary.unmatched.." still unmatched.")
        end
        return
    end
    if not key then Print("Invalid migration command; /gmap migrate help"); return end
    if action=="link" then
        local ok,info=migration.Link(key)
        Print(ok and info or ("link refused: "..tostring(info)))
    elseif action=="anchor" then
        local ok,result=migration.VerifyAnchor(key,confirm)
        Print(ok and result or ("anchor refused: "..tostring(result)))
    elseif action=="preview" then
        local summary,err=migration.Preview(key)
        if not summary then Print("preview refused: "..tostring(err)); return end
        Print("Preview "..key.." -> "..summary.zone.." UiMapID "..
            summary.mapID..": "..summary.source.." source nodes, "..
            summary.added.." new, "..summary.merged.." merged, "..
            summary.skipped.." invalid (kept in legacy data), "..
            summary.occurrences.." observations.")
        Print("Coordinate evidence: "..tostring(summary.geometryReason)..
            ". Name match alone never authorizes import.")
    elseif action=="apply" then
        local ok,result=migration.Apply(key,confirm)
        if ok then
            Print("Copied "..result.valid.." legacy nodes into "..result.target..
                "; original locations and SavedVariables snapshots preserved.")
        else Print("apply refused: "..tostring(result)) end
    elseif action=="rollback" then
        local ok,result=migration.Rollback(key)
        Print(ok and result or ("rollback refused: "..tostring(result)))
    else Print("Invalid migration action; /gmap migrate help") end
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
    elseif command=="pinpos" then
        local id,x,y=PlayerMapPosition()
        if not id then Print("Current player map position unavailable."); return end
        if not previewMarker then
            Print("No temporary test marker; use /gmap testpin first.")
            return
        end
        if previewMarker.mapID~=id then
            Print("Test marker belongs to another zone map.")
            return
        end
        local currentInstance,wx,wy=WorldPosition(id,x,y)
        local savedInstance,nx,ny=WorldPosition(id,
            previewMarker.node.x,previewMarker.node.y,previewMarker.node)
        if currentInstance~=savedInstance or not nx or not wx then
            Print("Player/test marker world coordinates unavailable.")
            return
        end
        Print(string.format(
            "Test marker fixed (%.4f, %.4f); player (%.4f, %.4f); world delta (%.1f, %.1f).",
            previewMarker.node.x,previewMarker.node.y,x,y,nx-wx,ny-wy))
    elseif command=="world on" or command=="world off" then
        db.worldMapEnabled = command == "world on"
        worldDirty=true
        UpdateMenu()
        DrawWorld()
        Print("world-map overlay "..(db.worldMapEnabled and "enabled." or "hidden."))
    elseif command=="migrate" or command:match("^migrate%s") then
        MigrationCommand(command)
    elseif command=="capture on" then
        if ns.GatherMapSetCapture then ns.GatherMapSetCapture(true) end
    elseif command=="capture off" then
        if ns.GatherMapSetCapture then ns.GatherMapSetCapture(false) end
    elseif command=="capture status" then
        if ns.GatherMapCaptureStatus then Print(ns.GatherMapCaptureStatus()) end
    elseif command=="capture debug" then
        if ns.GatherMapCaptureDiagnostics then Print(ns.GatherMapCaptureDiagnostics()) end
    elseif command=="capture debug on" or command=="capture debug off" then
        if ns.GatherMapSetCaptureDebug then
            ns.GatherMapSetCaptureDebug(command=="capture debug on")
            Print("Capture diagnostic chat "..(db.captureDebug and "enabled." or "disabled."))
        end
    elseif command=="menu" then
        if settingsPanel then
            if settingsPanel:IsShown() then settingsPanel:Hide()
            else UpdateMenu();settingsPanel:Show() end
        else Print("Open the world map to access GatherMap settings.") end
    elseif command=="count" or command=="status" or command=="debug" or command=="" then
        Status()
    else Print("commands: /gmap menu, on, off, world on|off, status, testpin, pinpos, clear, migrate help, capture on|off|status|debug") end
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
        MarkDirty()
    elseif event=="SKILL_LINES_CHANGED" or event=="CHAT_MSG_SKILL"
        or event=="PLAYER_EQUIPMENT_CHANGED"
        or event=="PROFESSION_EQUIPMENT_CHANGED" then
        skillDirty=true
    elseif event=="UNIT_AURA" then
        if issecretvalue and issecretvalue(loaded) then return end
        if loaded=="player" then skillDirty=true end
    else
        if event=="PLAYER_REGEN_ENABLED" then SetupWorld() end
        if event=="MINIMAP_UPDATE_ZOOM" then
            dirty=true
        else
            MarkStyleDirty()
        end
    end
end)
f:SetScript("OnUpdate",function(self,dt)
    if not db then return end
    tick=tick+dt
    hoverTick=hoverTick+dt
    if hoverTick>=0.10 then
        hoverTick=0
        Hover()
    end
    if skillDirty then
        skillDirty=false
        if difficulty.Refresh() then MarkStyleDirty() end
    end
    TrackMiniPositions()
    -- Retry lazy native-map initialization on a slow cadence only.
    if not provider and WorldMapFrame then
        providerRetryTick=providerRetryTick+dt
        if providerRetryTick>=2 then
            providerRetryTick=0
            SetupWorld()
        end
    end
    if tick<0.35 and not dirty then return end
    tick=0
    if dirty then dirty=false end
    if provider and provider.needsResizeRefresh and WorldMapFrame
        and WorldMapFrame:IsShown() then
        provider.needsResizeRefresh=false
        worldDirty=true
    end
    if worldDirty then DrawWorld() end
    DrawMinimap()
end)
