-------------- General Lua Functions --------------

local Lua = {}

function Lua.clamp(number, low, high)
    return math.min(math.max(number, low), high)
end

function Lua.floatsAreEqual(float1, float2, tolerance)
    if float1 == nil or float2 == nil then return false end

    return math.abs(float1 - float2) < tolerance
end

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

function Lua.arrayRemove(t, fnRemove)
    local j, n = 1, #t;

    for i = 1, n do
        if not fnRemove(t, i, j) then
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil;
        end
    end

    return t;
end

function Lua.getFileName(url)
  return url:match("[^/\\]+$")
end

-- Returns the Path, Filename, and Extension as 3 values
function Lua.splitFileName(url)
    return string.match(url, "(.-)([^\\]-([^\\%.]+))$")
end

function Lua.frequencyToNote(frequency)
    local note = 69 + 12 * math.log(frequency / 440) / math.log(2);
    return math.min( math.max(note, 0), 127 )
end

function Lua.rangesOverlap(range1, range2)
    local range1IsInsideRange2 = range1.left >= range2.left and range1.left <= range2.right
                              or range1.right >= range2.left and range1.right <= range2.right

    local range2IsInsideRange1 = range2.left >= range1.left and range2.left <= range1.right
                              or range2.right >= range1.left and range2.right <= range1.right

    return range1IsInsideRange2 or range2IsInsideRange1
end

function Lua.getStringValues(str)
    local values = {}

    for value in string.gmatch(str, "[%.%-%d]+") do
        table.insert( values, tonumber(value) )
    end

    return values
end

function Lua.fileExists(fileName)
    local f = io.open(fileName, "rb")
    if f then f:close() end
    return f ~= nil
end

function Lua.getFileLines(fileName)
    if not Lua.fileExists(fileName) then return {} end

    local lines = {}

    for line in io.lines(fileName) do
        lines[#lines + 1] = line
    end

    return lines
end

function Lua.getStringLines(inputString)
    if type(inputString) ~= "string" then return {} end

    local lines = {}

    for line in inputString:gmatch("([^\r\n]+)") do
        table.insert(lines, line)
    end

    return lines
end

function Lua.getFileString(fileName)
    if not Lua.fileExists(fileName) then return nil end

    local file = io.open(fileName, "rb")

    local fileString = file:read("*all")
    file:close()

    return fileString
end

return Lua