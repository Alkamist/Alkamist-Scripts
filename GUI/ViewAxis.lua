package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")

local ViewAxis = {}
function ViewAxis:new(object)
    local self = Proxy:new(self)

    self.scale = 1.0
    self.zoom = 1.0
    self.scroll = 0.0
    self.target = 0.0

    if object then for k, v in pairs(object) do self[k] = v end end
    return self
end

function ViewAxis:changeScroll(change)
    local scale = self.scale
    local scroll = self.scroll
    local zoom = self.zoom
    local change = change / scale

    self.scroll = scroll - change / zoom
end
function ViewAxis:changeZoom(change)
    local target = self.target
    local scale = self.scale
    local scroll = self.scroll
    local zoom = self.zoom
    local sensitivity = 0.01
    local scaledTarget = target / scale
    local change = 2 ^ (sensitivity * change)

    self.zoom = zoom * change
    self.scroll = scroll + (change - 1.0) * target / zoom
end

return ViewAxis