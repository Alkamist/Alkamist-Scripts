local function ViewAxis(parameters)
    local parameters = parameters or {}
    local instance = {}

    local _scale = parameters.scale or 1.0
    local _zoom = parameters.zoom or 1.0
    local _scroll = parameters.scroll or 0.0
    local _target = parameters.target or 0.0

    function instance:getScale() return _scale end
    function instance:getZoom() return _zoom end
    function instance:getScroll() return _scroll end
    function instance:getTarget() return _target end

    function instance:setScale(value) _scale = value end
    function instance:setTarget(value) _target = value end

    function instance:changeScroll(change)
        local change = change / _scale
        _scroll = _scroll - change / _zoom
    end
    function instance:changeZoom(change)
        local target = _target / _scale
        local sensitivity = 0.01
        local change = 2 ^ (sensitivity * change)

        _zoom = _zoom * change
        _scroll = _scroll + (change - 1.0) * target / _zoom
    end

    return instance
end

return ViewAxis