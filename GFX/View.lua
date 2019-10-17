local View = {}
function View:new(object)
    local object = object or {}
    object._base = self
    self.init(object)
    return object
end

function View:init()
    setmetatable(self, { __index = self._base })
    self.xScale = self.xScale or 1.0
    self.yScale = self.yScale or 1.0
    self.zoom = {
        x = 1.0,
        xSensitivity = 1.0,
        y = 1.0,
        ySensitivity = 1.0
    }
    self.scroll = {
        x = 0.0,
        xTarget = 0.0,
        y = 0.0,
        yTarget = 0.0
    }
end

function View:changeScroll(xChange, yChange)
    local xChange = xChange / self.xScale
    local yChange = yChange / self.yScale

    self.scroll.x = self.scroll.x - xChange / self.zoom.x
    self.scroll.y = self.scroll.y - yChange / self.zoom.y

    --self.scroll.x = math.min(math.max(0.0, scrollX), 1.0 - self.zoom.x)
    --self.scroll.y = math.min(math.max(0.0, scrollY), 1.0 - self.zoom.y)
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