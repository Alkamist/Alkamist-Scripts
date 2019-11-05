local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

local function Test1()
    local self = {}

    local _x1 = 5

    function self:add()
        return _x1 + _x1 + _x1 + _x1
    end

    return self
end

local Test2 = {}
function Test2:new()
    local self = setmetatable({}, { __index = Test2 })

    self.x1 = 0

    return self
end
function Test2:add()
    return self.x1 + self.x1 + self.x1 + self.x1
end

local test1 = Test1()
local test2 = Test2:new()

local timer = reaper.time_precise()
for i = 1, 1000000 do
    local value = test1:add()
end
msg(reaper.time_precise() - timer)

timer = reaper.time_precise()
for i = 1, 1000000 do
    local value = test1.add()
end
msg(reaper.time_precise() - timer)

local timer = reaper.time_precise()
for i = 1, 1000000 do
    local value = test2:add()
end
msg(reaper.time_precise() - timer)