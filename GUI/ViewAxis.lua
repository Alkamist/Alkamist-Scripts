package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Prototype = require("Prototype")

return Prototype:new{
    scale = 1.0,
    zoom = 1.0,
    scroll = 0.0,
    target = 0.0,
    changeScroll = function(self, change)
        local change = change / self.scale
        self.scroll = self.scroll - change / self.zoom
    end,
    changeZoom = function(self, change)
        local target = self.target / self.scale
        local sensitivity = 0.01
        local change = 2 ^ (sensitivity * change)

        self.zoom = self.zoom * change
        self.scroll = self.scroll + (change - 1.0) * target / self.zoom
    end
}