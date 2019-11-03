local PitchPoints = {}

function PitchPoints:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.x = init.x or 0
    self.y = init.y or 0
    self.w = init.w or 0
    self.h = init.h or 0

    self.color = init.color or { 0.3, 0.3, 0.3, 1.0, 0 }

    self.points = init.points or {}

    return self
end

function PitchPoints:draw(color, pointSize, pointsAsSquare, maximumTimeToDrawLine)
    local points = self.points

    for i = 1, #points do
        local point = points[i]
        local nextPoint = points[i + 1]

        if nextPoint and nextPoint.time - point.time <= maximumTimeToDrawLine then
            self:drawSegment(i, color)
        end

        self:drawPoint(i, color, pointSize, pointsAsSquare)
    end
end

return PitchPoints