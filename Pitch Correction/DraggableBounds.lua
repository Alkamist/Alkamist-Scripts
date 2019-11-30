local DraggableBounds = {}

function DraggableBounds.new(bounds)
    local self = {}
    for k, v in pairs(bounds) do self[k] = v end

    self.controls = {}
    self._controlWasPressedInside = {}

    function self:controlWasPressedInside(control)
        return self._controlWasPressedInside[control]
    end
    function self:controlJustDragged(control)
        return self:controlWasPressedInside(control) and control.justDragged
    end
    function self:controlJustStartedDragging(control)
        return self:controlWasPressedInside(control) and control.justStartedDragging
    end
    function self:controlJustStoppedDragging(control)
        return self:controlWasPressedInside(control) and control.justStoppedDragging
    end
    local controlPoint = {}
    function self:update()
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

    return self
end

return DraggableBounds