function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Prototype = require("Prototype")

local Test = Prototype:new{
    x = {
        get = function(self, field) return field.value end,
        set = function(self, value, field) field.value = value end
    },
    asdf = function(self) msg(self.x) end
}

local Test2 = Prototype:new{
    prototypes = {
        { "test", Test }
    },
}

local test2 = Test2:new()

test2.x = 5
msg(test2.x)
test2:asdf()