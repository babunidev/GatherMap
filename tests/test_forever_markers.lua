-- Run from repository root:
--   lua5.1 tests/test_forever_markers.lua
--   lua5.4 tests/test_forever_markers.lua
-- Pure-layout tests do NOT replace map-canvas or minimap tests in Forever.
local ns = {resources={difficultyPriority={
    unknown=0,gray=1,green=2,yellow=3,orange=4,red=5}}}
assert(loadfile("GatherMapMarkers.lua"))("GatherMap",ns)
local M = assert(ns.GatherMapMarkers)
local function Group(nodes)
    return M.Group(nodes,
        function(node) return node.x, node.y end,
        function(node) return node.visible ~= false end,
        function(node) return node.color or "unknown" end,
        function(node) return node.icon or "example-icon" end)
end
local function Node(name,kind,x,y,color)
    return {name=name,kind=kind,x=x,y=y,color=color}
end
local a=Node("Peacebloom","herb",0,0,"green")
local b=Node("Peacebloom","herb",13,0,"red")
local c=Node("Peacebloom","herb",27,0,"yellow")
local d=Node("Copper Vein","mineral",13,0,"orange")
local e=Node("Silverleaf","herb",13,0,"gray")
local f=Node("Peacebloom","skin",13,0,"unknown")
local records={a,b,c,d,e,f}
local groups=Group(records)
assert(#groups==4,"transitive same-kind/name group + 3 distinct resource kinds")
local g
for _,group in ipairs(groups) do
    if group.kind=="herb" and group.name=="Peacebloom" then g=group end
end
assert(g and g.left==-7 and g.right==34 and g.bottom==-7 and g.top==7)
assert(g.color=="red","merged group must use most restrictive color")
assert(g.icon=="example-icon")
assert(a.x==0 and b.x==13 and c.x==27,"grouping must not mutate data")

-- Input order cannot change transitive connectivity.
local reversed=Group({c,d,b,f,a,e})
local found
for _,group in ipairs(reversed) do
    if group.kind=="herb" and group.name=="Peacebloom" then found=group end
end
assert(found and found.left==-7 and found.right==34 and found.color=="red")
assert(#reversed==#groups)

-- Boundary overlap is inclusive; more than 14px apart does not merge.
assert(#Group({Node("X","herb",0,0),Node("X","herb",14,14)})==1)
assert(#Group({Node("X","herb",0,0),Node("X","herb",14.01,14)})==2)
assert(#Group({Node("X","herb",0,0),Node("X","herb",0,14.01)})==2)
assert(#Group({Node("X","herb",0,0),Node("X","herb",0,-14)})==1)
assert(#Group({Node("X","herb",0,0),Node("X","herb",0,-14.01)})==2)

-- A large cluster remains one visually merged group; unrelated resources
-- keep their own markers. The 300 pin cap never limits saved nodes.
local dense={}
for i=0,1499 do dense[#dense+1]=Node("Dense","herb",i*13,5,"yellow") end
local mergedDense=Group(dense)
assert(#mergedDense==1)
assert(mergedDense[1].left==-7 and mergedDense[1].right==1499*13+7)
local many={}
for i=1,400 do many[i]=Node("Separate","herb",i*30,0,"gray") end
assert(#Group(many)==400,"no storage truncation at 300 groups")

-- Nil/invalid map locations and unlearned kinds are rejected.
assert(#Group({{name="X",kind="herb",x=0,y=0,visible=false}})==0)
assert(#Group({Node("X","herb",0/0,0)})==0)
assert(#Group({Node("X","herb",math.huge,0)})==0)
assert(#Group({{name="",kind="herb",x=0,y=0}})==0)
assert(#Group({{name="Good",kind="herb",x=0,y=0},
    {name="Bad",kind="mineral",x=10/0,y=5}})==1)
assert(#Group({})==0)
assert(#Group(nil)==0)

-- Normalized world-map positions, canvas size and zoom scaling.
local x,y=M.WorldPoint(0.25,0.75,1000,600,1)
assert(x==250 and y==450)
x,y=M.WorldPoint(0.25,0.75,1000,600,2)
assert(x==500 and y==900)
assert(M.WorldPoint(-0.1,0.5,1000,600,1)==nil)
assert(M.WorldPoint(0.5,0.5,0,600,1)==nil)
assert(M.WorldPoint(0.5,0.5,1000,600,-1)==nil)
assert(M.WorldPoint(0.5,0.5,1000,600,1/0)==nil)

-- World zoom changes grouping without moving normalized node identity.
local worldNodes={
    Node("Map","herb",0.50,0.50),
    Node("Map","herb",0.518,0.50),
}
local function WorldGroups(scale)
    return M.Group(worldNodes, function(node)
        return M.WorldPoint(node.x,node.y,1000,600,scale)
    end,function() return true end,function() return "gray" end,function() return 1 end)
end
assert(#WorldGroups(0.5)==1,"9px apart at half zoom")
assert(#WorldGroups(1)==2,"18px apart at 1x zoom")
assert(#WorldGroups(2)==2)

-- Minimap screen-space orientation: X northward, Y westward.
x,y=M.MiniPoint(10,0,100,200,200,0,false)
assert(x==0 and y==10)
x,y=M.MiniPoint(0,10,100,200,200,0,false)
assert(x==-10 and y==0)
x,y=M.MiniPoint(10,0,100,200,200,math.pi/2,true)
assert(math.abs(x-10)<0.00001 and math.abs(y)<0.00001,
    "north lies to the right when facing west on a rotating minimap")
x,y=M.MiniPoint(10,0,100,200,200,3*math.pi/2,true)
assert(math.abs(x+10)<0.00001 and math.abs(y)<0.00001,
    "north lies to the left when facing east on a rotating minimap")
x,y=M.MiniPoint(0,10,100,200,200,math.pi/2,true)
assert(math.abs(x)<0.00001 and math.abs(y-10)<0.00001,
    "west lies ahead when facing west")
x,y=M.MiniPoint(10,0,100,300,160,0,false)
assert(x==0 and y==8,"non-square minimap projection")
assert(M.MiniPoint(500,0,100,200,200,0,false)==nil)
assert(M.MiniPoint(98,0,100,200,200,0,false)==nil,
    "clip marker before corners go outside minimap")
assert(M.MiniPoint(0,0,0,200,200,0,false)==nil)
-- Marker is fixed in world-space: when the player walks north past it,
-- its projection must move south (not stay at the player's minimap center).
local nodeX,nodeY=700,100
local playerX,playerY=700,100
x,y=M.MiniPoint(nodeX-playerX,nodeY-playerY,100,200,200,0,false)
assert(x==0 and y==0)
playerX=710
x,y=M.MiniPoint(nodeX-playerX,nodeY-playerY,100,200,200,0,false)
assert(x==0 and y==-10)
playerX=810
assert(M.MiniPoint(nodeX-playerX,nodeY-playerY,100,200,200,0,false)==nil,
    "fixed landmark disappears once outside the minimap radius")
print("PASS: markers transitive/separate, colors, clipping, dense sets, zoom, scaling and rotation")
