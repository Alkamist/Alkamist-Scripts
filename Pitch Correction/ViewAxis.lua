local ViewAxis = {}
function ViewAxis.new(object)
    local self = {}

    self.scale = 1.0
    self.zoom = 1.0
    self.scroll = 0.0
    self.target = 0.0

    return Fn.makeNew(self, ViewAxis, object)
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