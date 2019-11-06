local function Point(parameters, fromObject)
    local parameters = parameters or {}
    local instance = fromObject or {}

    local _x = parameters.x or 0
    local _y = parameters.y or 0

    function instance:getX() return _x end
    function instance:getY() return _y end

    function instance:setX(value) _x = value end
    function instance:setY(value) _y = value end
    function instance:changeX(change) _x = _x + change end
    function instance:changeY(change) _y = _y + change end

    return instance
end

return Point