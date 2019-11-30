local DragTracker = {}

function DragTracker:new()
    local self = self or {}

    self.control = self.control
    self.thingsToTrack = self.thingsToTrack
    self._wasPressedInsideThing = {}

    return self
end

function DragTracker:wasPressedInsideThing(thing)
    return self._wasPressedInsideThing[thing]
end
function DragTracker:justDraggedThing(thing)
    return self:wasPressedInsideThing(thing) and self.control:justDragged()
end
function DragTracker:justStartedDraggingThing(thing)
    return self:wasPressedInsideThing(thing) and self.control:justStartedDragging()
end
function DragTracker:justStoppedDraggingThing(thing)
    return self:wasPressedInsideThing(thing) and self.control:justStoppedDragging()
end
function DragTracker:update()
    bounds.update(self)

    local controls = self.controls
    for i = 1, #self.controls do
        local control = controls[i]
        controlPoint.x = control.x
        controlPoint.y = control.y

        if control:justPressed() and self:pointIsInside(controlPoint) then
            self._controlWasPressedInside[control] = true
        end
        if control:justReleased() then
            self._controlWasPressedInside[control] = false
        end
    end
end

return DragTracker