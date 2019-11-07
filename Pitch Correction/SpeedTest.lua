local reaper = reaper

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

--local function Test1()
--    local instance = {}
--
--    local _x1 = 5
--
--    for i = 1, 400 do
--        instance[i] = function(self)
--            local sum = 0
--            local x1 = _x1
--            for i = 1, 1000 do
--                sum = sum + x1
--            end
--            return sum
--        end
--    end
--
--    return instance
--end

local function testFunction(self)
    return self.x + self.y + self.z
end

local Test1 = {}
function Test1:new()
    local self = {
        x = 1,
        y = 2,
        z = 3,
        testFunction = testFunction,
        testFunction1 = testFunction,
        testFunction2 = testFunction,
        testFunction3 = testFunction,
        testFunction4 = testFunction,
        testFunction5 = testFunction,
        testFunction6 = testFunction,
        testFunction7 = testFunction,
        testFunction8 = testFunction,
    }

    return self
end



--local test1 = Test1:new()
--local timer = reaper.time_precise()
--for i = 1, 1000000 do
--    local value = test1:testFunction()
--end
--msg(reaper.time_precise() - timer)



local Test2 = {}
function Test2:new()
    local self = setmetatable({}, { __index = self })

    self.x = 1
    self.y = 2
    self.z = 3

    return self
end
function Test2:testFunction() return self.x + self.y + self.z end
function Test2:testFunction1() return self.x + self.y + self.z end
function Test2:testFunction2() return self.x + self.y + self.z end
function Test2:testFunction3() return self.x + self.y + self.z end
function Test2:testFunction4() return self.x + self.y + self.z end
function Test2:testFunction5() return self.x + self.y + self.z end
function Test2:testFunction6() return self.x + self.y + self.z end
function Test2:testFunction7() return self.x + self.y + self.z end
function Test2:testFunction8() return self.x + self.y + self.z end


--local test2 = Test2:new()
--local timer = reaper.time_precise()
--for i = 1, 1000000 do
--    local value = test2:testFunction()
--end
--msg(reaper.time_precise() - timer)

local out = {}
for i = 1, 100000 do
    out[i] = Test2:new()
end
msg(collectgarbage("count"))