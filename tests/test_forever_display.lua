-- Run from repository root: lua5.1 tests/test_forever_display.lua
-- Mock canvas/UI integration: no in-game claim, no real map pixels.
local frames = {}
local function Frame(parent)
    local f = {parent=parent,width=200,height=200,visible=true,checked=false,scripts={}}
    function f:GetFrameLevel() return 4 end
    function f:SetFrameLevel() end
    function f:SetFrameStrata() end
    function f:SetSize(w,h)
        self.width=w;self.height=h
        self.sizeCalls=(self.sizeCalls or 0)+1
    end
    function f:GetWidth() return self.width end
    function f:GetHeight() return self.height end
    function f:SetWidth(w) self.width=w end
    function f:SetHeight(h) self.height=h end
    function f:EnableMouse(v) self.mouseEnabled=v end
    function f:IsShown() return self.visible end
    function f:Show() self.visible=true end
    function f:Hide() self.visible=false end
    function f:SetPoint(...) self.lastPoint={...} end
    function f:ClearAllPoints() self.lastPoint=nil end
    function f:SetPassThroughButtons()
        error("Protected SetPassThroughButtons called by GatherMap map pin")
    end
    function f:SetAlpha(a) self.alpha=a end
    function f:RegisterEvent() end
    function f:RegisterUnitEvent() end
    function f:SetScript(name,fn) self.scripts[name]=fn end
    function f:CreateTexture()
        local t=Frame(self)
        function t:SetColorTexture(r,g,b,a) self.color={r,g,b,a} end
        function t:SetSnapToPixelGrid(value) self.pixelSnap=value end
        function t:SetTexelSnappingBias(value) self.snapBias=value end
        function t:SetTexture(texture) self.texture=texture end
        function t:SetTexCoord() end
        function t:SetAllPoints() end
        return t
    end
    function f:CreateFontString()
        local t=Frame(self)
        function t:SetText(v) self.text=v end
        function t:SetTextColor() end
        function t:SetJustifyH() end
        function t:GetText() return self.text end
        function t:GetStringWidth() return #(self.text or "")*6 end
        return t
    end
    function f:GetEffectiveScale() return 1 end
    function f:GetLeft() return nil end
    function f:GetRight() return nil end
    function f:GetTop() return nil end
    function f:GetBottom() return nil end
    function f:IsMouseOver() return self.mouseOver == true end
    function f:SetChecked(v) self.checked=v end
    function f:GetChecked() return self.checked end
    frames[#frames+1]=f
    return f
end
UIParent=Frame()
UIParent:SetSize(1920,1080)
Minimap=Frame(UIParent);Minimap:SetSize(220,180)
local canvas=Frame(UIParent);canvas:SetSize(1000,600)
local scale=0.5
WorldMapFrame=Frame(UIParent)
WorldMapFrame.ScrollContainer=Frame(WorldMapFrame)
local foreignProvider={name="UnrelatedMapAddon"}
local foreignPin={name="Other addon pin"}
WorldMapFrame.providers={foreignProvider}
WorldMapFrame.otherAddonPins={foreignPin}
function WorldMapFrame:GetMapID() return 37 end
function WorldMapFrame:GetCanvas() return canvas end
function WorldMapFrame:GetCanvasScale() return scale end
function WorldMapFrame:AddDataProvider(provider)
    self.providers[#self.providers+1]=provider
    self.provider=provider
    provider:OnAdded(self)
end
function WorldMapFrame:RemoveAllPinsByTemplate(template)
    assert(template=="GatherMapForeverWorldPinTemplate",
        "GatherMap may only remove its own pin template")
    self.pins={}
end
function WorldMapFrame:AcquirePin(template,group,w,h)
    self.pins=self.pins or {}
    local pin=Frame(canvas)
    -- The virtual XML template explicitly sets enableMouse="false".
    pin.mouseEnabled=false
    function pin:EnableMouse()
        error("Protected EnableMouse must not be called during pin OnLoad")
    end
    for name,value in pairs(GatherMapForeverWorldPinMixin) do
        pin[name]=value
    end
    function pin:UseFrameLevelType() end
    function pin:SetScalingLimits() end
    function pin:SetPosition(x,y)
        self.posX=x;self.posY=y
    end
    pin:OnLoad()
    pin:OnAcquired(group,w,h)
    -- Model the exact protected call reported by the Forever client:
    -- MapCanvas:AcquirePin invokes this after OnAcquired.
    pin:CheckMouseButtonPassthrough("RightButton")
    assert(pin.mouseEnabled==false,"map pin must not intercept input")
    self.pins[#self.pins+1]=pin
end
WorldMapFrame.pins={}
function CreateFrame(_,name,parent)
    local result=Frame(parent)
    if name then _G[name]=result end
    return result
end
function CreateFromMixins(...)
    local result={}
    for i=1,select("#",...) do
        for name,value in pairs(select(i,...)) do result[name]=value end
    end
    return result
end
MapCanvasPinMixin={
    CheckMouseButtonPassthrough=function(self)
        -- A non-overridden inherited method would invoke a protected API.
        self:SetPassThroughButtons()
    end,
}
MapCanvasDataProviderMixin={
    OnAdded=function(self,map) self.owningMap=map end,
    GetMap=function(self) return self.owningMap end,
}
local now=500
GetTime=function() return now end
GetCursorPosition=function() return 300,200 end
GetCVarBool=function() return false end
GetPlayerFacing=function() return 0 end
local inCombat=false
InCombatLockdown=function() return inCombat end
GetZoneText=function() return "Elwynn Forest" end
GetSubZoneText=function() return "Northshire Valley" end
UnitLevel=function() return 20 end
CreateVector2D=function(x,y) return {x=x,y=y} end
local playerX,playerY=0.5,0.5
C_Map={
    GetBestMapForUnit=function() return 37 end,
    GetMapInfo=function(id) return {mapType=3} end,
    GetPlayerMapPosition=function(id) return {x=playerX,y=playerY} end,
    GetWorldPosFromMapPos=function(id,position)
        return 1,{x=position.x*1000,y=position.y*1000}
    end,
}
C_Minimap={GetViewRadius=function() return 300 end,
    IsRotateMinimapIgnored=function() return false end}
local chats={}
DEFAULT_CHAT_FRAME={AddMessage=function(_,msg) chats[#chats+1]=msg end}
SlashCmdList={}
local ns={resources={
    difficultyPriority={unknown=0,gray=1,green=2,yellow=3,orange=4,red=5},
    colors={unknown={0.7,0.35,1},gray={0.5,0.5,0.5}},
    skinIcons={},woodIcons={},mineralIcons={},herbIcons={Peacebloom="icon-herb"},
    fallbackIcons={treasure="chest-texture",mineral="ore-texture"},
}}
ns.GatherMapSetCapture=function(enabled) GatherMapDB.recordingEnabled=enabled end
ns.GatherMapSetCaptureDebug=function(enabled) GatherMapDB.captureDebug=enabled end
ns.GatherMapCaptureLast=function() return "No capture event" end
ns.GatherMapDifficulty={
    Refresh=function() return false end,
    Color=function() return "unknown" end,
    IsVisible=function(node) return node.kind=="treasure" or node.kind=="herb" end,
    Skill=function() return {present=false} end,
}
assert(loadfile("GatherMapMarkers.lua"))("GatherMap",ns)
local groupCalls=0
local originalGroup=ns.GatherMapMarkers.Group
ns.GatherMapMarkers.Group=function(...)
    groupCalls=groupCalls+1
    return originalGroup(...)
end
assert(loadfile("GatherMapSpatial.lua"))("GatherMap",ns)
assert(loadfile("GatherMapMigration.lua"))("GatherMap",ns)
local first={name="Battered Chest",kind="treasure",x=0.5,y=0.5,count=1}
local second={name="Battered Chest",kind="treasure",x=0.518,y=0.5,count=1}
GatherMapDB={nodes={["map:37"]={first,second},["1:2"]={
    {name="Legacy Herb",kind="herb",x=0.2,y=0.3}
}},version=3,enabled=false,worldMapEnabled=true}
local sameNodes=GatherMapDB.nodes
local eventFrameCount=#frames
assert(loadfile("GatherMapForever.lua"))("GatherMap",ns)
local mainFrame=frames[eventFrameCount+1]
assert(type(mainFrame.scripts.OnEvent)=="function")
mainFrame.scripts.OnEvent(mainFrame,"ADDON_LOADED","GatherMap")
mainFrame.scripts.OnUpdate(mainFrame,0.4)
assert(WorldMapFrame.provider~=nil)
assert(WorldMapFrame.providers[1]==foreignProvider
    and #WorldMapFrame.providers==2)
assert(WorldMapFrame.otherAddonPins[1]==foreignPin,
    "other map addon pins cannot be removed by our provider")
assert(#WorldMapFrame.pins==1,"at half zoom the two chests merge")
assert(GatherMapDB.enabled==false and GatherMapDB.worldMapEnabled==true,
    "two display preferences must be independent")
assert(#GatherMapDB.nodes["map:37"]==2,"visual merging must not change stored nodes")
assert(GatherMapDB.nodes["1:2"][1].name=="Legacy Herb")
assert(ns.GatherMapMigration.Status().unmatched==1,
    "legacy locations must still be present")
-- Scale callback schedules refresh; the next 0.35s update splits markers.
scale=1
WorldMapFrame.provider:OnCanvasScaleChanged()
assert(WorldMapFrame.provider.needsResizeRefresh==true)
mainFrame.scripts.OnUpdate(mainFrame,0.4)
assert(#WorldMapFrame.pins==2,"at 1x zoom the two chests must separate")
-- Map resizing recomputes pixel-space overlap.
canvas:SetSize(500,300)
WorldMapFrame.provider:OnCanvasSizeChanged()
mainFrame.scripts.OnUpdate(mainFrame,0.4)
assert(#WorldMapFrame.pins==1,"narrower canvas should merge normalized nodes")
local menuButton=assert(_G.GatherMapForeverMenuButton)
local panel=assert(_G.GatherMapForeverSettingsPanel)
assert(not panel:IsShown(),"settings panel starts collapsed")
assert(_G.GatherMapForeverMapToggle==nil,"old map checkbox removed")
menuButton.scripts.OnClick(menuButton)
assert(panel:IsShown(),"one click opens settings")
local miniRow=assert(_G.GatherMapForeverSetting1)
local worldRow=assert(_G.GatherMapForeverSetting2)
local captureRow=assert(_G.GatherMapForeverSetting3)
local debugRow=assert(_G.GatherMapForeverSetting4)
assert(worldRow.label.text=="World-map markers: ON")
worldRow.scripts.OnClick(worldRow)
assert(GatherMapDB.worldMapEnabled==false and GatherMapDB.enabled==false)
assert(worldRow.label.text=="World-map markers: OFF")
assert(#WorldMapFrame.pins==0,"world-map toggle only removes our world pins")
worldRow.scripts.OnClick(worldRow)
assert(GatherMapDB.worldMapEnabled==true)
assert(#WorldMapFrame.pins==1,"restoring world overlay reacquires pins")
assert(GatherMapDB.recordingEnabled==nil)
captureRow.scripts.OnClick(captureRow)
assert(GatherMapDB.recordingEnabled==true,"capture setting is independently toggled")
assert(captureRow.label.text=="Record discoveries: ON")
debugRow.scripts.OnClick(debugRow)
assert(GatherMapDB.captureDebug==true,"diagnostics toggle saved")
debugRow.scripts.OnClick(debugRow)
assert(GatherMapDB.captureDebug==false)
captureRow.scripts.OnClick(captureRow)
assert(GatherMapDB.recordingEnabled==false)
menuButton.scripts.OnClick(menuButton)
assert(not panel:IsShown(),"button collapses settings")
SlashCmdList.GATHERMAP("menu")
assert(panel:IsShown(),"/gmap menu opens identical panel")
SlashCmdList.GATHERMAP("menu")
assert(not panel:IsShown())

-- Independently enable minimap without changing world setting.
WorldMapFrame:Hide()
Minimap:Show()
SlashCmdList.GATHERMAP("on")
mainFrame.scripts.OnUpdate(mainFrame,0.4)
assert(GatherMapDB.enabled==true and GatherMapDB.worldMapEnabled==true)
local miniCount=0
for _,fr in ipairs(frames) do
    if fr.parent==Minimap and fr:IsShown() then miniCount=miniCount+1 end
end
assert(miniCount>0,"minimap group must appear")
-- Simulate a viewport boundary. Previously the first chest fell just offscreen
-- on the next 0.35s pass; its merged rectangle shrank to one 14px square.
-- Fixed-world grouping must preserve the shape across repeated refreshes.
local chestPin
for _,fr in ipairs(frames) do
    if fr.parent==Minimap and fr.name=="Battered Chest"
        and fr:IsShown() then chestPin=fr;break end
end
assert(chestPin and chestPin:GetHeight()>14,
    "two nearby chest nodes must form the original merged rectangle")
local fixedWidth,fixedHeight=chestPin:GetWidth(),chestPin:GetHeight()
local styleCount=chestPin.sizeCalls
local originalCorners=chestPin.corners
for _,corner in ipairs(originalCorners) do
    assert(corner.pixelSnap==false and corner.snapBias==0,
        "four corners should not pixel-snap independently while moving")
end
local initialGroupCalls=groupCalls
playerX=0.78
mainFrame.scripts.OnUpdate(mainFrame,0.4)
assert(chestPin:IsShown(),"merged chest center remains on the minimap edge")
assert(chestPin:GetWidth()==fixedWidth and chestPin:GetHeight()==fixedHeight,
    "viewport clipping must not turn a rectangle into a square")
assert(groupCalls==initialGroupCalls,
    "walking must not regroup world-anchored resource locations")
playerX=0.77
mainFrame.scripts.OnUpdate(mainFrame,0.4)
assert(chestPin:GetWidth()==fixedWidth and chestPin:GetHeight()==fixedHeight)
playerX=0.5
mainFrame.scripts.OnUpdate(mainFrame,0.4)
assert(chestPin:GetWidth()==fixedWidth and chestPin:GetHeight()==fixedHeight)
assert(groupCalls==initialGroupCalls,
    "repeated slow refreshes must use the same stable world groups")
assert(chestPin.sizeCalls==styleCount and chestPin.corners==originalCorners,
    "walking and slow refresh must not restyle or resize the marker")
-- A new marker entering/leaving the view must never steal or resize
-- another marker's pooled frame. The old index-based pool did just that.
playerX=0.70
SlashCmdList.GATHERMAP("testpin")
mainFrame.scripts.OnUpdate(mainFrame,0.4)
assert(chestPin.name=="Battered Chest" and chestPin:IsShown(),
    "new test marker cannot steal existing chest frame")
local stableOwner,stableShapeCalls=chestPin, chestPin.sizeCalls
playerX=0.27
mainFrame.scripts.OnUpdate(mainFrame,0.4)
assert(chestPin==stableOwner and chestPin.name=="Battered Chest"
    and chestPin.sizeCalls==stableShapeCalls and chestPin:IsShown(),
    "other visible group leaving view must not change surviving frame")
playerX=0.70
mainFrame.scripts.OnUpdate(mainFrame,0.4)
assert(chestPin==stableOwner and chestPin.name=="Battered Chest"
    and chestPin.sizeCalls==stableShapeCalls,
    "another visible group returning cannot restyle the chest")
SlashCmdList.GATHERMAP("clear")
playerX=0.5
mainFrame.scripts.OnUpdate(mainFrame,0.4)
-- A temporary testpin must stay fixed in world coordinates while the
-- character moves, rather than remaining attached to the player arrow.
SlashCmdList.GATHERMAP("testpin")
mainFrame.scripts.OnUpdate(mainFrame,0.4)
local previewPin
for _,fr in ipairs(frames) do
    if fr.parent==Minimap and fr.name=="GatherMap preview"
        and fr:IsShown() then previewPin=fr;break end
end
assert(previewPin and previewPin.lastPoint,"preview marker should be visible")
local initialX,initialY=previewPin.lastPoint[4],previewPin.lastPoint[5]
assert(math.abs(initialX)<0.0001 and math.abs(initialY)<0.0001,
    "testpin begins where character stands")
local groupsBeforeMove=groupCalls
playerX=0.51
mainFrame.scripts.OnUpdate(mainFrame,0.016)
assert(groupCalls==groupsBeforeMove,
    "a short frame must reposition without rebuilding grouped resources")
assert(previewPin.lastPoint and previewPin.lastPoint[5]<initialY,
    "fixed marker must move on the first short movement frame")
playerX=0.55
mainFrame.scripts.OnUpdate(mainFrame,0.016)
assert(groupCalls==groupsBeforeMove,
    "walking at frame rate must reuse resource groups")
assert(previewPin.lastPoint,
    "preview marker should remain visible after a short walk")
local movedX,movedY=previewPin.lastPoint[4],previewPin.lastPoint[5]
assert(math.abs(movedY-initialY)>1 and movedY<initialY,
    "fixed testpin must move south on minimap when player travels north")
assert(math.abs(movedX-initialX)<0.001)
-- Combat is NOT a world-map edit. Unprotected minimap pins must stay
-- anchored while the character fights, not hitchhike on the player arrow.
local beforeCombat=previewPin.lastPoint[5]
local styleBeforeCombat=chestPin.sizeCalls
inCombat=true
playerX=0.60
mainFrame.scripts.OnUpdate(mainFrame,0.016)
assert(previewPin.lastPoint[5]<beforeCombat,
    "minimap marker must move relative to player during combat")
local duringCombat=previewPin.lastPoint[5]
mainFrame.scripts.OnUpdate(mainFrame,0.4)
assert(previewPin.lastPoint[5]==duringCombat,
    "slow refresh may not snap a stable pin back in combat")
assert(chestPin.sizeCalls==styleBeforeCombat or not chestPin:IsShown(),
    "combat movement must not resize old marker frames")
inCombat=false
playerX=0.55
mainFrame.scripts.OnUpdate(mainFrame,0.016)
local rotateMinimap,ignoredRotation,playerFacing=false,false,0
GetCVarBool=function(name) return name=="rotateMinimap" and rotateMinimap end
GetPlayerFacing=function() return playerFacing end
C_Minimap.IsRotateMinimapIgnored=function() return ignoredRotation end
rotateMinimap=true;playerFacing=math.pi/2
mainFrame.scripts.OnUpdate(mainFrame,0.016)
assert(previewPin.lastPoint and previewPin.lastPoint[4]<-10,
    "rotation must reposition the pinned marker before the 0.35s grouping tick")
assert(groupCalls==groupsBeforeMove)
ignoredRotation=true
mainFrame.scripts.OnUpdate(mainFrame,0.016)
assert(math.abs(previewPin.lastPoint[4])<0.001,
    "minimap rotation-ignore mode must disable addon rotation immediately")
rotateMinimap=false;ignoredRotation=false;playerFacing=0
mainFrame.scripts.OnUpdate(mainFrame,0.016)
SlashCmdList.GATHERMAP("pinpos")
assert(chats[#chats]:find("world delta",1,true)
    and chats[#chats]:find("-50.0",1,true),
    "position diagnostics must report the fixed marker offset")
playerX=0.95
mainFrame.scripts.OnUpdate(mainFrame,0.4)
assert(not previewPin:IsShown(),
    "fixed marker must disappear outside minimap radius")
SlashCmdList.GATHERMAP("clear")
playerX=0.5
mainFrame.scripts.OnUpdate(mainFrame,0.4)
assert(#GatherMapDB.nodes["map:37"]==2,
    "moving temporary marker cannot write discoveries")
SlashCmdList.GATHERMAP("off")
mainFrame.scripts.OnUpdate(mainFrame,0.4)
for _,fr in ipairs(frames) do
    if fr.parent==Minimap then assert(not fr:IsShown()) end
end
assert(GatherMapDB.worldMapEnabled==true)
SlashCmdList.GATHERMAP("world off")
assert(GatherMapDB.worldMapEnabled==false)
SlashCmdList.GATHERMAP("world on")
assert(GatherMapDB.worldMapEnabled==true)
assert(GatherMapDB.nodes==sameNodes)
assert(GatherMapDB.nodes["map:37"][1]==first)
assert(first.x==0.5 and second.x==0.518)
SlashCmdList.GATHERMAP("migrate status")
SlashCmdList.GATHERMAP("migrate link 1:2")
assert(GatherMapDB.nodes["1:2"][1].name=="Legacy Herb")
assert(not GatherMapDB.migrationLedger,
    "unknown legacy zone labels must not be migrated")
-- Preview pin must never add a permanent SavedVariables record.
WorldMapFrame:Show()
SlashCmdList.GATHERMAP("testpin")
WorldMapFrame.provider:RefreshAllData()
assert(#WorldMapFrame.pins==2,"preview and ordinary chest must stay distinct")
assert(#GatherMapDB.nodes["map:37"]==2)
SlashCmdList.GATHERMAP("clear")
WorldMapFrame.provider:RefreshAllData()
assert(#WorldMapFrame.pins==1 and #GatherMapDB.nodes["map:37"]==2)
-- Flush the pending world redraw before identifying the pin to hover.
-- Otherwise a scheduled refresh correctly releases and reuses its frame.
mainFrame.scripts.OnUpdate(mainFrame,0.4)

-- Test scaled cursor coordinates against a real in-memory map pin and ensure
-- the private hover tooltip uses no game tooltip or mouse interception.
local pin=WorldMapFrame.pins[1]
local uiScale=0.75
function UIParent:GetEffectiveScale() return uiScale end
function pin:GetEffectiveScale() return uiScale end
function pin:GetLeft() return self.posX*canvas.width-self.width/2 end
function pin:GetRight() return self.posX*canvas.width+self.width/2 end
function pin:GetBottom() return (1-self.posY)*canvas.height-self.height/2 end
function pin:GetTop() return (1-self.posY)*canvas.height+self.height/2 end
WorldMapFrame.ScrollContainer.mouseOver=true
GetCursorPosition=function()
    return pin.posX*canvas.width*uiScale,(1-pin.posY)*canvas.height*uiScale
end
local totalBefore=#frames
mainFrame.scripts.OnUpdate(mainFrame,0.15)
local label
for i=totalBefore+1,#frames do
    local region=frames[i]
    if region.parent==UIParent and region.mouseEnabled==false and region:IsShown() then
        label=region
    end
end
assert(label and label.mouseEnabled==false,
    "scaled world-map hover should show a non-interactive private label")
GetCursorPosition=function() return 0,0 end
mainFrame.scripts.OnUpdate(mainFrame,0.15)
assert(not label:IsShown(),"hover label must hide when the cursor leaves")
assert(GatherMapDB.nodes==sameNodes)
print("PASS: world zoom/resize, native provider, custom tooltips, UI scale, stored toggles, preview and data safety")

-- Incomplete map APIs and malformed SavedVariables must fail closed.
WorldMapFrame:Hide()
Minimap:Show()
SlashCmdList.GATHERMAP("on")
local oldGetBest=C_Map.GetBestMapForUnit
C_Map.GetBestMapForUnit=function() return nil end
mainFrame.scripts.OnEvent(mainFrame,"PLAYER_MAP_CHANGED")
mainFrame.scripts.OnUpdate(mainFrame,0.4)
C_Map.GetBestMapForUnit=function() return 37 end
local oldInfo=C_Map.GetMapInfo
C_Map.GetMapInfo=function() return {mapType="invalid"} end
mainFrame.scripts.OnEvent(mainFrame,"PLAYER_MAP_CHANGED")
mainFrame.scripts.OnUpdate(mainFrame,0.4)
C_Map.GetMapInfo=oldInfo
local priorWorldPos=C_Map.GetWorldPosFromMapPos
C_Map.GetWorldPosFromMapPos=nil
mainFrame.scripts.OnEvent(mainFrame,"PLAYER_MAP_CHANGED")
mainFrame.scripts.OnUpdate(mainFrame,0.4)
C_Map.GetWorldPosFromMapPos=priorWorldPos
C_Map.GetBestMapForUnit=oldGetBest
GatherMapDB.nodes["map:37"][3]={name="Corrupted",kind="herb",x=0/0,y=0.2}
GatherMapDB.nodes["map:37"][4]={name="Other Corruption",kind="herb",x=1.2,y=0.2}
GatherMapDB.nodes["map:37"][5]="not-a-resource"
mainFrame.scripts.OnEvent(mainFrame,"PLAYER_ENTERING_WORLD")
mainFrame.scripts.OnUpdate(mainFrame,0.4)
assert(GatherMapDB.nodes["map:37"][3].name=="Corrupted"
    and #GatherMapDB.nodes["map:37"]==5)
assert(WorldMapFrame.otherAddonPins[1]==foreignPin)
assert(WorldMapFrame.providers[1]==foreignProvider
    and #WorldMapFrame.providers==2)
assert(Minimap.mouseEnabled~=false,
    "our pins must never disable input on other minimap owners")
print("PASS: native provider coexists with another provider; malformed records and missing map functions fail closed")


