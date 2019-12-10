local Position = require("Position")

local math = math
local abs = math.abs
local min = math.min
local max = math.max

return function(self)
    local self = self or {}
    if self.BoxSelect then return self end
    self.BoxSelect = true
    Position(self)
    local _positionUpdatePreviousState = self.updatePreviousState

    local _startingX
    local _startingY
    local _isActive

    function self.getBodyColor() return _isPressed end
    function self.setBodyColor(v) _isPressed = v end
    function self.wasPreviouslyPressed() return _wasPreviouslyPressed end
    function self.setWasPreviouslyPressed(v) _wasPreviouslyPressed = v end
    function self.hasDraggedSincePress() return _hasDraggedSincePress end
    function self.setHasDraggedSincePress(v) _hasDraggedSincePress = v end

    function self.justPressed() return self.isPressed() and not self.wasPreviouslyPressed() end
    function self.justReleased() return not self.isPressed() and self.wasPreviouslyPressed() end
    function self.justDragged() return self.isPressed() and self.justMoved() end
    function self.justStartedDragging() return self.justDragged() and not self.hasDraggedSincePress() end
    function self.justStoppedDragging() return self.justReleased() and self.hasDraggedSincePress() end

    function self.updatePreviousState(dt)
        if self.justDragged() then self.setHasDraggedSincePress(true) end
        if self.justReleased() then self.setHasDraggedSincePress(false) end
        self.setWasPreviouslyPressed(self.isPressed())
        _positionUpdatePreviousState(dt)
    end

    self.setIsPressed(false)
    self.setWasPreviouslyPressed(false)
    self.setHasDraggedSincePress(false)

    return self
end







local BoxSelect = {}

function BoxSelect:new(object)
    local object = object or {}
    local defaults = {}

    defaults.startingX = 0
    defaults.startingY = 0
    defaults.isActive = false

    defaults.objectsToSelect = {}
    defaults.objectIsSelected = {}
    defaults.selectionControl = nil
    defaults.additiveControl = nil
    defaults.inversionControl = nil

    defaults.bodyColor = { 1, 1, 1, -0.04, 1 }
    defaults.outlineColor = { 1, 1, 1, 0.3, 1 }

    for k, v in pairs(defaults) do if object[k] == nil then object[k] = v end end
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    return Widget:new(object)
end

function BoxSelect:startSelection(point)
    self.startingX = point.x
    self.startingY = point.y
    self.x = self.startingX
    self.y = self.startingY
    self.width = 0
    self.height = 0
end
function BoxSelect:editSelection(point)
    self.isActive = true

    self.x = min(self.startingX, point.x)
    self.y = min(self.startingY, point.y)
    self.width = abs(self.startingX - point.x)
    self.height = abs(self.startingY - point.y)
end
function BoxSelect:makeSelection()
    local objectsToSelect = self.objectsToSelect
    local additiveControl = self.additiveControl
    local inversionControl = self.inversionControl
    local objectIsSelected = self.objectIsSelected
    local pointIsInside = self.pointIsInside

    if objectsToSelect then
        for i = 1, #objectsToSelect do
            local object = objectsToSelect[i]

            if pointIsInside(self, object) then
                if inversionControl.isPressed then
                    objectIsSelected[object] = not objectIsSelected[object]
                else
                    objectIsSelected[object] = true
                end
            else
                if not additiveControl.isPressed and not inversionControl.isPressed then
                    objectIsSelected[object] = false
                end
            end
        end
    end
    self.isActive = false
end
function BoxSelect:update()
    local selectionControl = self.selectionControl
    if selectionControl.justPressed then self:startSelection(selectionControl) end
    if selectionControl.isPressed then self:editSelection(selectionControl) end
    if selectionControl.justReleased then self:makeSelection() end
end
function BoxSelect:draw()
    local w, h = self.width, self.height

    if self.isActive then
        -- Draw the body.
        self:setColor(self.bodyColor)
        self:drawRectangle(1, 1, w - 2, h - 2, true)

        -- Draw the outline.
        self:setColor(self.outlineColor)
        self:drawRectangle(0, 0, w, h, false)
    end
end

return BoxSelect