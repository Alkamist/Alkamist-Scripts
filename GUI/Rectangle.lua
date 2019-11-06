package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Point = require("GUI.Point")

local function Rectangle(parameters, fromObject)
    local parameters = parameters or {}
    local instance = Point(parameters, fromObject)

    local _point = {
        getX = instance.getX,
        getY = instance.getY
    }
    local _width = parameters.width or 0
    local _height = parameters.height or 0

    function instance:getWidth() return _width end
    function instance:getHeight() return _height end
    function instance:pointIsInside(pointX, pointY)
        local x = _point:getX()
        local y = _point:getY()
        return pointX >= x and pointX <= x + _width
           and pointY >= y and pointY <= y + _height
    end

    function instance:setWidth(value) _width = value end
    function instance:setHeight(value) _height = value end
    function instance:changeWidth(change) _width = _width + change end
    function instance:changeHeight(change) _height = _height + change end

    return instance
end

return Rectangle