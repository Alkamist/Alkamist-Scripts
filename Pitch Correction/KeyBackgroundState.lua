local GUI = require("GUI")

local ipairs = ipairs
local table = table
local tableInsert = table.insert

local math = math
local floor = math.floor
local ceil = math.ceil

local whiteKeyMultiples = {1, 3, 4, 6, 8, 9, 11}
local whiteKeyNumbers = {}
for i = 1, 11 do
    for _, value in ipairs(whiteKeyMultiples) do
        tableInsert(whiteKeyNumbers, (i - 1) * 12 + value)
    end
end

local function round(number)
    return number > 0 and floor(number + 0.5) or ceil(number - 0.5)
end

local KeyBackgroundState = {}

function KeyBackgroundState:requires()
    return self.KeyBackgroundState
end
function KeyBackgroundState:getDefaults()
    local defaults = {}
    return defaults
end
function KeyBackgroundState:update()

end

return KeyBackgroundState