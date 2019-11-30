local RectangularBounds = {}

function RectangularBounds.new(x, y, width, height)
    local self = {}

    self.x = x
    self.y = y
    self.width = width
    self.height = height

    function self:pointIsInside(point)
        local x, y, w, h = self.x, self.y, self.width, self.height
        local pointX, pointY = point.x, point.y
        return pointX >= x and pointX <= x + w
            and pointY >= y and pointY <= y + h
    end

    return self
end

return RectangularBounds