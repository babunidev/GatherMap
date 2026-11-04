-- Run from repository root: lua5.1 tests/test_forever_display.lua
-- Mock canvas/UI integration: no in-game claim, no real map pixels.
local frames = {}
local function Frame(parent)
    local f = {parent=parent,width=200,height=200,visible=true,checked=false,scripts={}}
    function f:GetFrameLevel() return 4 end
    function f:SetFrameLevel() end
    function f:SetFrameStrata() end
    function f:SetSize(w,h) self.width=w;self.height=h end
    function f:GetWidth() return self.width end
    function f:GetHeight() return self.height end
    function f:SetWidth(w) self.width=w end
    function f:SetHeight(h) self.height=h end
    function f:EnableMouse(v) self.mouseEnabled=v end
    function f:IsShown() return self.visible end
    function f:Show() self.visible=true end
    function f:Hide() self.visible=false end
    function f:SetPoint() end
    function f:ClearAllPoints() end
    function f:SetAlpha(a) self.alpha=a end
    function f:RegisterEvent() end
    function f:RegisterUnitEvent() end
    function f:SetScript(name,fn) self.scripts[name]=fn end
    function f:CreateTexture()
        local t=Frame(self)
        function t:SetColorTexture(r,g,b,a) self.color={r,g,b,a} end
        function t:SetTexture(texture) self.texture=texture end
        function t:SetTexCoord() end
        function t:SetAllPoints() end
        return t
    end
    function f:CreateFontString()
        local t=Frame(self)
        function t:SetText(v) self.text=v end
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
function WorldMapFrame:GetMapID() return 37 end
function WorldMapFrame:GetCanvas() return canvas end
function WorldMapFrame:GetCanvasScale() return scale end
function WorldMapFrame:AddDataProvider(provider)
    self.provider=provider
    provider:OnAdded(self)
end
function WorldMapFrame:RemoveAllPinsByTemplate(template)
    self.pins={}
end
function WorldMapFrame:AcquirePin(template,group,w,h)
    self.pins=self.pins or {}
    local pin=Frame(canvas)
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
MapCanvasPinMixin={}
MapCanvasDataProviderMixin={
    OnAdded=function(self,map) self.owningMap=map end,
    GetMap=function(self) return self.owningMap end,
}
local now=500
GetTime=function() return now end
GetCursorPosition=function() return 300,200 end
GetCVarBool=function() return false end
GetPlayerFacing=function() return 0 end
GetZoneText=function() return "Elwynn Forest" end
GetSubZoneText=function() return "Northshire Valley" end
UnitLevel=function() return 20 end
C_Map={
    GetBestMapForUnit=function() return 37 end,
    GetMapInfo=function(id) return {mapType=3} end,
    GetPlayerMapPosition=function(id) return {x=0.5,y=0.5} end,
    GetWorldPosFromMapPos=function(id,position)
        return 1,{x=position.x*1000,y=position.y*1000}
    end,
}
C_Minimap={GetViewRadius=function() return 300 end}
local chats={}
DEFAULT_CHAT_FRAME={AddMessage=function(_,msg) chats[#chats+1]=msg end}
SlashCmdList={}
local ns={resources={
    difficultyPriority={unknown=0,gray=1,green=2,yellow=3,orange=4,red=5},
    colors={unknown={0.7,0.35,1},gray={0.5,0.5,0.5}},
    skinIcons={},woodIcons={},mineralIcons={},herbIcons={Peacebloom="icon-herb"},
    fallbackIcons={treasure="chest-texture",mineral="ore-texture"},
}}
ns.GatherMapDifficulty={
    Refresh=function() return false end,
    Color=function() return "unknown" end,
    IsVisible=function(node) return node.kind=="treasure" or node.kind=="herb" end,
    Skill=function() return {present=false} end,
}
assert(loadfile("GatherMapMarkers.lua"))("GatherMap",ns)
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
assert(#WorldMapFrame.pins==1,"at half zoom the two chests merge")
assert(GatherMapDB.enabled==false and GatherMapDB.worldMapEnabled==true,
    "two display preferences must be independent")
assert(#GatherMapDB.nodes["map:37"]==2,"visual merging must not change stored nodes")
assert(GatherMapDB.nodes["1:2"][1].name=="Legacy Herb")
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
local toggle=assert(_G.GatherMapForeverMapToggle)
toggle:SetChecked(false)
toggle.scripts.OnClick(toggle)
assert(GatherMapDB.worldMapEnabled==false and GatherMapDB.enabled==false)
assert(#WorldMapFrame.pins==0,"turning off the world overlay removes pins")
toggle:SetChecked(true)
toggle.scripts.OnClick(toggle)
assert(#WorldMapFrame.pins==1,"restoring world overlay reacquires pins")

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
print("PASS: world scale/resize, native provider, grouped pins, independent saved controls, minimap toggle and data safety")

