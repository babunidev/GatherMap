-- GatherMap Forever — reusable world-coordinate lookup for minimap drawing.
-- Source data and snapshots are never modified or re-keyed.
local _, ns = ...
local CELL = 128
local MAX_QUERY_CELLS = 4096
local function Finite(n)
    return type(n)=="number" and n==n and n~=math.huge and n~=-math.huge
end
local function ValidCoord(n)
    return Finite(n) and n>=0 and n<=1
end

local function Build(nodes, project, allowProjected)
    if type(nodes)~="table" or type(project)~="function" then return nil end
    local index={source=nodes, cells={}, all={}, valid=0}
    for i=1,#nodes do
        local node=nodes[i]
        if type(node)=="table" and (allowProjected
            or (ValidCoord(node.x) and ValidCoord(node.y))) then
            local instance,x,y=project(node)
            if (type(instance)=="number" or type(instance)=="string")
                and Finite(x) and Finite(y) then
                local item={node=node,x=x,y=y,instance=instance}
                index.valid=index.valid+1
                index.all[#index.all+1]=item
                local realm=index.cells[instance]
                if not realm then realm={}; index.cells[instance]=realm end
                local cx,cy=math.floor(x/CELL),math.floor(y/CELL)
                local row=realm[cx]
                if not row then row={};realm[cx]=row end
                local bucket=row[cy]
                if not bucket then bucket={};row[cy]=bucket end
                bucket[#bucket+1]=item
            end
        end
    end
    return index
end

-- The returned candidate list is disposable. The index and its saved nodes
-- remain intact across player movement and repeated queries.
local function Nearby(index,instance,x,y,radius)
    if not index or not Finite(x) or not Finite(y)
        or not Finite(radius) or radius<=0 then return {} end
    local realm=index.cells[instance]
    if not realm then return {} end
    local x1,x2=math.floor((x-radius)/CELL),math.floor((x+radius)/CELL)
    local y1,y2=math.floor((y-radius)/CELL),math.floor((y+radius)/CELL)
    local cells=(x2-x1+1)*(y2-y1+1)
    local source=index.all
    local result={}
    local radius2=radius*radius
    if cells>MAX_QUERY_CELLS then
        -- Deliberately fall back to the projected list rather than iterating
        -- millions of empty grid cells at an unusual minimap radius.
        for i=1,#source do
            local item=source[i]
            if item.instance==instance and
                (item.x-x)^2+(item.y-y)^2<=radius2 then
                result[#result+1]=item.node
            end
        end
        return result
    end
    for cx=x1,x2 do
        local row=realm[cx]
        if row then
            for cy=y1,y2 do
                local bucket=row[cy]
                if bucket then
                    for i=1,#bucket do
                        local item=bucket[i]
                        if (item.x-x)^2+(item.y-y)^2<=radius2 then
                            result[#result+1]=item.node
                        end
                    end
                end
            end
        end
    end
    return result
end

-- Pre-projected display groups have world centers but no SavedVariables
-- coordinates. Reuse the same spatial buckets without pretending that
-- their world coordinates lie in normalized 0..1 map space.
local function BuildGroups(groups,instance)
    if type(groups)~="table" then return nil end
    return Build(groups,function(group)
        return instance,group.worldX,group.worldY
    end,true)
end
ns.GatherMapSpatial={Build=Build,BuildGroups=BuildGroups,
    Nearby=Nearby,CellSize=CELL}
