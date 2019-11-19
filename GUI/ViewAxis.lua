local ViewAxis = {}

function ViewAxis:new(parameters)
    local parameters = parameters or {}
    local self = parameters.fromObject or {}

    local _scale = parameters.scale or 1.0
    local _zoom = parameters.zoom or 1.0
    local _scroll = parameters.scroll or 0.0
    local _target = parameters.target or 0.0

    function self:getScale() return _scale end
    function self:setScale(value) _scale = value end
    function self:getZoom() return _zoom end
    function self:setZoom(value) _zoom = value end
    function self:getScroll() return _scroll end
    function self:setScroll(value) _scroll = value end
    function self:getTarget() return _target end
    function self:setTarget(value) _target = value end
    function self:changeScroll(change)
        local change = change / _scale
        _scroll = _scroll - change / _zoom
    end
    function self:changeZoom(change)
        local target = _target / _scale
        local sensitivity = 0.01
        local change = 2 ^ (sensitivity * change)
        _zoom = _zoom * change
        _scroll = _scroll + (change - 1.0) * target / _zoom
    end

    return self
end

return ViewAxis