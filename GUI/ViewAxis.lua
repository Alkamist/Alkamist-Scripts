local ViewAxis = {}
function ViewAxis.new(object)
    local self = {}

    self.scale = 1.0
    self.zoom = 1.0
    self.scroll = 0.0
    self.target = 0.0

    local object = object or {}
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    return object
end

function ViewAxis.changeScroll(self, change)
    local change = change / self.scale
    self.scroll = self.scroll - change / self.zoom
end
function ViewAxis.changeZoom(self, change)
    local target = self.target / self.scale
    local sensitivity = 0.01
    local change = 2 ^ (sensitivity * change)
    self.zoom = self.zoom * change
    self.scroll = self.scroll + (change - 1.0) * target / self.zoom
end

return ViewAxis