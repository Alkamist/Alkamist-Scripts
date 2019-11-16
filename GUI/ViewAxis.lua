local ViewAxis = {}
function ViewAxis:new(initialValues)
    local self = {}

    self.scale = initialValues.scale or 1.0
    self.zoom = initialValues.zoom or 1.0
    self.scroll = initialValues.scroll or 0.0
    self.target = initialValues.target or 0.0
    function self:changeScroll(change)
        local change = change / self.scale
        self.scroll = self.scroll - change / self.zoom
    end
    function self:changeZoom(change)
        local target = self.target / self.scale
        local sensitivity = 0.01
        local change = 2 ^ (sensitivity * change)
        self.zoom = self.zoom * change
        self.scroll = self.scroll + (change - 1.0) * target / self.zoom
    end

    return self
end