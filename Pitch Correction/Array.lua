local Json = require("dkjson")

local reaper = reaper
local pairs = pairs
local io = io

local Array = {}

function Array.remove(t, fn)
    local n = #t
    local j = 1
    for i = 1, n do
        if not fn(i, j) then
            if i ~= j then
                t[j] = t[i]
                t[i] = nil
            end
            j = j + 1
        else
            t[i] = nil
        end
    end
end
function Array.insert(t, newThing, sortFn)
    local amount = #t
    if amount == 0 then
        t[1] = newThing
        return 1
    end

    for i = 1, amount do
        local thing = t[i]
        if not sortFn(thing, newThing) then
            tableInsert(t, i, newThing)
            return i
        end
    end

    t[amount + 1] = newThing
    return amount + 1
end
function Array.encodeAsString(points, pointMembers)
    local numberOfPoints = #points
    local numberOfMembers = #pointMembers
    local saveTable = {
        numberOfPoints = numberOfPoints,
        points = {}
    }
    for name, defaultValue in pairs(pointMembers) do
        for i = 1, numberOfPoints do
            local point = points[i]
            local value = point[name]
            if value == nil then value = defaultValue end
            if value == nil then value = 0 end
            saveTable.points[name] = saveTable.points[name] or {}
            saveTable.points[name][i] = value
        end
    end
    return Json.encode(saveTable, { indent = true })
end
function Array.decodeFromString(stringToDecode, pointMembers)
    local points = {}
    local decodedTable = Json.decode(stringToDecode)
    local numberOfPoints = decodedTable.numberOfPoints
    for name, defaultValue in pairs(pointMembers) do
        for i = 1, numberOfPoints do
            local pointMember = decodedTable.points[name]
            local value = defaultValue
            if pointMember then
                value = pointMember[i]
                if value == nil then value = defaultValue end
                if value == nil then value = 0 end
            end
            points[i] = points[i] or {}
            points[i][name] = value
        end
    end
    return points
end
function Array.loadFromFile(pathName, fileName, pointMembers)
    local fullFileName = pathName .. "\\" .. fileName
    local file = io.open(fullFileName)
    if file then
        local saveString = file:read("*all")
        file:close()
        return decodeFromString(saveString, pointMembers)
    end
end
function Array.saveToFile(points, pathName, fileName, pointMembers)
    local fullFileName = pathName .. "\\" .. fileName
    reaper.RecursiveCreateDirectory(pathName, 0)
    local saveString = encodeAsString(points, pointMembers)
    local file = io.open(fullFileName, "w")
    if file then
        file:write(saveString)
        file:close()
    end
end

return Array