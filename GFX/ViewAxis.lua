local math = math

local ViewAxis = {}

function ViewAxis:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.scale =  init.scale  or 1.0
    self.zoom =   init.zoom   or 1.0
    self.scroll = init.scroll or 0.0
    self.target = init.target or 0.0

    return self
end

function ViewAxis:changeScroll(change)
    local change = change / self.scale
    self.scroll = self.scroll - change / self.zoom
end

function ViewAxis:changeZoom(change)
    local target = self.target / self.scale
    local sensitivity = 0.007
    local change = math.max(sensitivity * change, -0.99)

    self.zoom = self.zoom * (1.0 + change)
    self.scroll = self.scroll + change * target / self.zoom
end

return ViewAxis