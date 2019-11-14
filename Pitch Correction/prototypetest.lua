function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Prototype = require("Prototype")

local Test = Prototype:new{
    --calledWhenCreated = function(self)
    --    msg("Yee")
    --end,
    asdf = "yee",
    x = function(self) return self.asdf end
}

local Test2 = Prototype:new{
    prototypes = {
        { "test", Test:new() }
    },
    asdf = 0
}

test1 = Test2:new()