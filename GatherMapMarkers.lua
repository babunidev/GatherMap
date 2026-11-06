-- GatherMap — screen-space marker grouping for the Forever overlay.
-- Pure Lua: no frames, no SavedVariables mutations, no game API dependency.
-- Nearby rectangles merge transitively only for the SAME kind and name.
local _, ns = ...
local HALF_SIZE, CELL_SIZE = 7, 14
local priority = ns.resources.difficultyPriority
local function Finite(n)
    return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end
local function Root(parent, i)
    while parent[i] ~= i do
        parent[i] = parent[parent[i]]
        i = parent[i]
    end
    return i
end
local function Union(parent, sizes, a, b)
    a, b = Root(parent, a), Root(parent, b)
    if a == b then return end
    if sizes[a] < sizes[b] then a, b = b, a end
    parent[b] = a
    sizes[a] = sizes[a] + sizes[b]
end
local function Group(nodes, project, shown, difficulty, icon)
    local points, parent, sizes = {}, {}, {}
    local cells = {}
    if type(nodes) ~= "table" then return {} end
    for _, node in ipairs(nodes) do
        if type(node) == "table" and type(node.name) == "string"
            and node.name ~= "" and shown(node) then
            local x, y = project(node)
            if Finite(x) and Finite(y) then
                local i = #points + 1
                local kind = type(node.kind) == "string" and node.kind or "herb"
                local p = { x = x, y = y, kind = kind, name = node.name,
                    color = difficulty(node), icon = icon(node) }
                points[i], parent[i], sizes[i] = p, i, 1

                local byKind = cells[kind]
                if not byKind then byKind = {}; cells[kind] = byKind end
                local byName = byKind[node.name]
                if not byName then byName = {}; byKind[node.name] = byName end

                local cx, cy = math.floor(x / CELL_SIZE), math.floor(y / CELL_SIZE)
                for dx = -1, 1 do
                    for dy = -1, 1 do
                        local key = (cx + dx) .. ":" .. (cy + dy)
                        local nearby = byName[key]
                        if nearby then
                            if dx == 0 and dy == 0 then
                                -- All points in one 14px cell overlap. Every
                                -- inserted point joins the first representative.
                                Union(parent, sizes, i, nearby[1])
                            else
                                -- All points within a neighbor cell are already
                                -- connected. One overlapping witness suffices.
                                for j = 1, #nearby do
                                    local k = nearby[j]
                                    local other = points[k]
                                    if math.abs(other.x - x) <= CELL_SIZE
                                        and math.abs(other.y - y) <= CELL_SIZE then
                                        Union(parent, sizes, i, k)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
                local key = cx .. ":" .. cy
                local bucket = byName[key]
                if not bucket then bucket = {}; byName[key] = bucket end
                bucket[#bucket + 1] = i
            end
        end
    end

    local roots, groups = {}, {}
    -- The connected components reproduce the original transitive overlap,
    -- without expanding individual SavedVariables or losing distinct types.
    for i = 1, #points do
        local p = points[i]
        local root = Root(parent, i)
        local g = roots[root]
        if not g then
            g = {left = p.x - HALF_SIZE, right = p.x + HALF_SIZE,
                bottom = p.y - HALF_SIZE, top = p.y + HALF_SIZE,
                name = p.name, kind = p.kind, color = p.color, icon = p.icon}
            roots[root] = g
            groups[#groups + 1] = g
        else
            g.left = math.min(g.left, p.x - HALF_SIZE)
            g.right = math.max(g.right, p.x + HALF_SIZE)
            g.bottom = math.min(g.bottom, p.y - HALF_SIZE)
            g.top = math.max(g.top, p.y + HALF_SIZE)
            if (priority[p.color] or 0) > (priority[g.color] or 0) then
                g.color = p.color
            end
        end
    end
    return groups
end

-- Pure geometry helpers also used by fixture tests without a WoW client.
local function WorldPoint(x, y, width, height, scale)
    if not (Finite(x) and Finite(y) and Finite(width)
        and Finite(height) and Finite(scale)
        and width > 0 and height > 0 and scale > 0) then return nil end
    if x < 0 or x > 1 or y < 0 or y > 1 then return nil end
    return x * width * scale, y * height * scale
end
local function MiniPoint(dx, dy, radius, width, height, facing, rotate)
    if not (Finite(dx) and Finite(dy) and Finite(radius)
        and Finite(width) and Finite(height) and radius > 0
        and width > 0 and height > 0) then return nil end
    if dx * dx + dy * dy > radius * radius then return nil end
    local halfX, halfY = width / 2, height / 2
    local sx, sy = -dy / radius * halfX, dx / radius * halfY
    if rotate then
        if not Finite(facing) then return nil end
        local sn, cs = math.sin(facing), math.cos(facing)
        -- Facing increases counterclockwise, but rotating the minimap
        -- turns the world in the opposite direction (player stays upright).
        sx, sy = sx * cs + sy * sn, -sx * sn + sy * cs
    end
    local safeX, safeY = math.max(1, halfX - 8), math.max(1, halfY - 8)
    if (sx / safeX) ^ 2 + (sy / safeY) ^ 2 > 1 then return nil end
    return sx, sy
end
-- Recover the fixed world location of a grouped marker's screen center.
-- The group can be repositioned each frame without regrouping saved nodes.
local function MiniWorldAnchor(sx,sy,wx,wy,radius,width,height,facing,rotate)
    if not (Finite(sx) and Finite(sy) and Finite(wx) and Finite(wy)
        and Finite(radius) and radius>0
        and Finite(width) and Finite(height) and width>0 and height>0) then
        return nil
    end
    if rotate then
        if not Finite(facing) then return nil end
        local sn,cs=math.sin(facing),math.cos(facing)
        -- Undo the inverse-facing minimap rotation from MiniPoint.
        sx,sy=sx*cs-sy*sn,sx*sn+sy*cs
    end
    return wx + sy*radius*2/height, wy - sx*radius*2/width
end

ns.GatherMapMarkers = {
    Group = Group,
    Finite = Finite,
    WorldPoint = WorldPoint,
    MiniPoint = MiniPoint,
    MiniWorldAnchor = MiniWorldAnchor,
    HalfSize = HALF_SIZE,
}
