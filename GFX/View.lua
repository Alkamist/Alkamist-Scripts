local View = {}
function View:new(object)
    local object = object or {}
    object._base = self
    self.init(object)
    return object
end

function View:init()
    setmetatable(self, { __index = self._base })
    self.zoom = {
        x = 1.0,
        xSensitivity = 3.0,
        y = 1.0,
        ySensitivity = 3.0
    }
    self.scroll = {
        x = 0.0,
        xTarget = 0.0,
        y = 0.0,
        yTarget = 0.0
    }
end

function View:changeScroll(xChange, yChange)
    self.scroll.x = self.scroll.x - xChange / self.zoom.x
    self.scroll.y = self.scroll.y - yChange / self.zoom.y

    --self.scroll.x = math.min(math.max(0.0, scrollX), 1.0 - self.zoom.x)
    --self.scroll.y = math.min(math.max(0.0, scrollY), 1.0 - self.zoom.y)
end

function View:changeZoom(xChange, yChange, centerOnTarget)
    self.zoom.x = self.zoom.x * (1.0 + self.zoom.xSensitivity * xChange)
    self.zoom.y = self.zoom.y * (1.0 + self.zoom.ySensitivity * yChange)

    if centerOnTarget then
        self.scroll.x = self.scroll.x + self.zoom.xSensitivity * xChange * self.scroll.xTarget / self.zoom.x
        self.scroll.y = self.scroll.y + self.zoom.ySensitivity * yChange * self.scroll.yTarget / self.zoom.y
    end
end

return View