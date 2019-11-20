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
    local change = change / self.scale
    self.scroll = self.scroll - change / self.zoom
end
function ViewAxis:changeZoom(change)
    local target = self.target / self.scale
    local sensitivity = 0.01
    local change = 2 ^ (sensitivity * change)
    self.zoom = self.zoom * change
    self.scroll = self.scroll + (change - 1.0) * target / self.zoom
end

return ViewAxis