local View = {}

function View:new(init)
    local init = init or {}

    local self = setmetatable({}, { __index = self })

    self.xScale = init.xScale or 1.0
    self.yScale = init.yScale or 1.0
    self.zoom = {
        x =            init.xZoom or 1.0,
        xSensitivity = init.xZoomSensitivity or 1.0,
        y =            init.yZoom or 1.0,
        ySensitivity = init.yZoomSensitivity or 1.0
    }
    self.scroll = {
        x =       init.xScroll or 0.0,
        xTarget = init.xScrollTarget or 0.0,
        y =       init.yScroll or 0.0,
        yTarget = init.yScrollTarget or 0.0
    }

    return self
end

function View:changeScroll(xChange, yChange)
    local xChange = xChange / self.xScale
    local yChange = yChange / self.yScale

    self.scroll.x = self.scroll.x - xChange / self.zoom.x
    self.scroll.y = self.scroll.y - yChange / self.zoom.y
end

function View:changeZoom(xChange, yChange, centerOnTarget)
    local xChange = xChange / self.xScale
    local yChange = yChange / self.yScale
    local xTarget = self.scroll.xTarget / self.xScale
    local yTarget = self.scroll.yTarget / self.yScale
    local xSensitivity = 0.005 * self.zoom.xSensitivity * self.xScale
    local ySensitivity = 0.005 * self.zoom.ySensitivity * self.yScale

    self.zoom.x = self.zoom.x * (1.0 + xSensitivity * xChange)
    self.zoom.y = self.zoom.y * (1.0 + ySensitivity * yChange)

    if centerOnTarget then
        self.scroll.x = self.scroll.x + xSensitivity * xChange * xTarget / self.zoom.x
        self.scroll.y = self.scroll.y + ySensitivity * yChange * yTarget / self.zoom.y
    end
end

return View