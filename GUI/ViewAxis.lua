local ViewAxis = {}

function ViewAxis:new(parameters)
    local self = setmetatable({}, { __index = self })
    local parameters = parameters or {}

    self:setScale(parameters.scale or 1.0)
    self:setZoom(parameters.zoom or 1.0)
    self:setScroll(parameters.scroll or 0.0)
    self:setTarget(parameters.target or 0.0)

    return self
end

function ViewAxis:getScale() return self._scale end
function ViewAxis:setScale(value) self._scale = value end
function ViewAxis:getZoom() return self._zoom end
function ViewAxis:setZoom(value) self._zoom = value end
function ViewAxis:getScroll() return self._scroll end
function ViewAxis:setScroll(value) self._scroll = value end
function ViewAxis:getTarget() return self._target end
function ViewAxis:setTarget(value) self._target = value end

function ViewAxis:changeScroll(change)
    local scale = self:getScale()
    local scroll = self:getScroll()
    local zoom = self:getZoom()

    local change = change / scale

    self:setScroll(scroll - change / zoom)
end
function ViewAxis:changeZoom(change)
    local target = self:getTarget()
    local scale = self:getScale()
    local scroll = self:getScroll()
    local zoom = self:getZoom()

    local sensitivity = 0.01
    local scaledTarget = target / scale
    local change = 2 ^ (sensitivity * change)

    self:setZoom(zoom * change)
    self:setScroll(scroll + (change - 1.0) * target / zoom)
end

return ViewAxis