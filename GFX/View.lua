local View = {}

function View:new(init)
    local init = init or {}

    local self = setmetatable({}, { __index = self })

    self._xScale = init.xScale or 1.0
    self._yScale = init.yScale or 1.0
    self._zoom = {
        x =            init.xZoom or 1.0,
        xSensitivity = init.xZoomSensitivity or 1.0,
        y =            init.yZoom or 1.0,
        ySensitivity = init.yZoomSensitivity or 1.0
    }
    self._scroll = {
        x =       init.xScroll or 0.0,
        xTarget = init.xScrollTarget or 0.0,
        y =       init.yScroll or 0.0,
        yTarget = init.yScrollTarget or 0.0
    }

    return self
end

function View:getZoomX() return self._zoom.x end
function View:getZoomY() return self._zoom.y end
function View:getScrollX() return self._scroll.x end
function View:getScrollY() return self._scroll.y end

function View:changeScroll(xChange, yChange)
    local xChange = xChange / self._xScale
    local yChange = yChange / self._yScale

    self._scroll.x = self._scroll.x - xChange / self._zoom.x
    self._scroll.y = self._scroll.y - yChange / self._zoom.y
end

function View:changeZoom(xChange, yChange, centerOnTarget)
    local xChange = xChange / self._xScale
    local yChange = yChange / self._yScale
    local xTarget = self._scroll.xTarget / self._xScale
    local yTarget = self._scroll.yTarget / self._yScale
    local xSensitivity = 0.005 * self._zoom.xSensitivity * self._xScale
    local ySensitivity = 0.005 * self._zoom.ySensitivity * self._yScale

    self._zoom.x = self._zoom.x * (1.0 + xSensitivity * xChange)
    self._zoom.y = self._zoom.y * (1.0 + ySensitivity * yChange)

    if centerOnTarget then
        self._scroll.x = self._scroll.x + xSensitivity * xChange * xTarget / self._zoom.x
        self._scroll.y = self._scroll.y + ySensitivity * yChange * yTarget / self._zoom.y
    end
end

return View