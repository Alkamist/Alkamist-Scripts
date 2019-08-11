-------------- General Lua Functions --------------

local Lua = {}

function Lua.copyTable(source, base)
    if type(source) ~= "table" then return source end

    local meta = getmetatable(source)
    local new = base or {}

    for k, v in pairs(source) do
        if type(v) == "table" then
            if base then
                new[k] = GUI.table_copy(v, base[k])
            else
                new[k] = GUI.table_copy(v, nil)
            end

        else
            if not base or (base and new[k] == nil) then
                new[k] = v
            end
        end
    end

    setmetatable(new, meta)

    return new
end

function Lua.getTableLength(source)
    local length = 0
    for _ in pairs(source) do
        length = length + 1
    end

    return length
end

function Lua.distanceBetweenTwoPoints(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2

    return math.sqrt(dx * dx + dy * dy)
end

function Lua.minDistanceBetweenPointAndLineSegment(x, y, x1, y1, x2, y2)
    local A = x - x1
    local B = y - y1
    local C = x2 - x1
    local D = y2 - y1

    local dot = A * C + B * D
    local len_sq = C * C + D * D
    local param = -1

    local xx
    local yy

    if len_sq ~= 0 then
        param = dot / len_sq
    end

    if param < 0 then
        xx = x1
        yy = y1

    elseif param > 1 then
        xx = x2
        yy = y2

    else
        xx = x1 + param * C
        yy = y1 + param * D
    end

    local dx = x - xx
    local dy = y - yy

    return math.sqrt(dx * dx + dy * dy)
end

return Lua