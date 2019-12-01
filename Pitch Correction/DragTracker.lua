local DragTracker = {}

function DragTracker:new()
    local self = self or {}

    self.control = self.control
    self.objectsToTrack = self.objectsToTrack
    self._wasPressedInside = {}

    return self
end

function DragTracker:wasPressedInside(object)
    return self._wasPressedInside[object]
end
function DragTracker:justDragged(object)
    return self:wasPressedInside(object) and self.control:justDragged()
end
function DragTracker:justStartedDragging(object)
    return self:wasPressedInside(object) and self.control:justStartedDragging()
end
function DragTracker:justStoppedDragging(object)
    return self:wasPressedInside(object) and self.control:justStoppedDragging()
end
local controlPoint = {}
function DragTracker:update()
    local objectsToTrack = self.objectsToTrack
    local control = self.control
    local wasPressedInside = self._wasPressedInside
    for i = 1, #objectsToTrack do
        local object = objectsToTrack[i]
        controlPoint.x = control.x
        controlPoint.y = control.y
        if control:justPressed() and object:pointIsInside(controlPoint) then
            wasPressedInside[object] = true
        end
        if control:justReleased() then
            wasPressedInside[object] = false
        end
    end
end

return DragTracker