-- Run: lua5.1 tests/test_forever_performance.lua
-- Deterministic scaling/integrity checks; timings are informational,
-- NOT evidence of real client FPS or compatibility.
local ns={resources={difficultyPriority={
    unknown=0,gray=1,green=2,yellow=3,orange=4,red=5}}}
assert(loadfile("GatherMapMarkers.lua"))("GatherMap",ns)
assert(loadfile("GatherMapSpatial.lua"))("GatherMap",ns)
local M,S=ns.GatherMapMarkers,ns.GatherMapSpatial
local function Node(i)
    return {kind="herb",name="Peacebloom",x=(i%157)/157,
        y=(math.floor(i/157)%157)/157,count=1}
end
local count=24000
local nodes={}
for i=1,count do nodes[i]=Node(i) end
local before=nodes[1]
local calls=0
local function Project(node)
    calls=calls+1
    return 1,node.x*30000,node.y*30000
end
local start=os.clock()
local index=S.Build(nodes,Project)
local buildTime=os.clock()-start
assert(index and index.valid==count and #index.all==count)
assert(calls==count,"one spatial-build projection per node")

local function CheckQuery(x,y,radius)
    local results=S.Nearby(index,1,x,y,radius)
    local expected={}
    for i=1,count do
        local node=nodes[i]
        local dx=node.x*30000-x
        local dy=node.y*30000-y
        if dx*dx+dy*dy<=radius*radius then expected[node]=true end
    end
    local seen={}
    for _,node in ipairs(results) do
        assert(expected[node],"spatial query included an out-of-range location")
        assert(not seen[node],"same node returned more than once")
        seen[node]=true
        expected[node]=nil
    end
    assert(next(expected)==nil,"spatial query lost visible locations")
    return #results
end
local near=CheckQuery(14000,9000,120)
assert(near>0 and near<count/10,"query should contain nearby nodes without rendering the whole database")
CheckQuery(14012,9020,120)
CheckQuery(0,0,1)
CheckQuery(30000,30000,300)
CheckQuery(15000,15000,15000) -- very large radius triggers safe fallback
assert(calls==count,"movement queries must reuse projected coordinates")
assert(#nodes==count and nodes[1]==before and before.count==1,
    "spatial indexing must never mutate source SavedVariables")

local extras={
    {kind="herb",name="Bad",x=0/0,y=0.4},
    {kind="herb",name="Bad",x=-1,y=0.4},
    {kind="herb",name="Bad",x=0.5,y=math.huge},
    "not a record",false,
}
for i=1,#extras do nodes[#nodes+1]=extras[i] end
local idx2=S.Build(nodes,Project)
assert(idx2.valid==count,"corrupt data is preserved but excluded from index")
assert(#nodes==count+#extras,"original malformed rows must remain unmodified")
assert(#S.Nearby(index,999,14000,9000,100)==0,
    "other instances cannot leak into local minimap queries")
assert(#S.Nearby(index,1,0,0,0)==0)
assert(#S.Nearby(index,1,0/0,0,500)==0)
assert(#S.Nearby(nil,1,0,0,500)==0)

-- Worst case for an old nine-cell, all-pairs neighbor test: dense nodes
-- in a single 14px cell, all of the same name and kind.
local dense={}
for i=1,12000 do
    dense[i]={kind="herb",name="Peacebloom",
        x=(i%50)*0.15,y=(i%37)*0.19,color=i==12000 and "red" or "gray"}
end
local stamp=os.clock()
local groups=M.Group(dense,function(n) return n.x,n.y end,
    function() return true end,
    function(n) return n.color end,
    function() return 1 end)
local denseTime=os.clock()-stamp
assert(#groups==1 and groups[1].color=="red",
    "dense transitive clustering must retain exact geometry and priority")
assert(#dense==12000 and dense[1].color=="gray",
    "grouping cannot rewrite source rows")
print(string.format(
    "PASS: 24k indexed nodes, 12k same-cell markers, invalid data and exact radius queries; projected=%d, near=%d; build=%.3fs dense=%.3fs (CI-only)",
    calls,near,buildTime,denseTime))
