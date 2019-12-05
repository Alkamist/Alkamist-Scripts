local Graphics = require("Graphics")

local Button = {}

function Button:new(object)
    local object = object or {}
    local defaults = {}

    defaults.x = 0
    defaults.previousX = 0
    defaults.y = 0
    defaults.previousY = 0
    defaults.justMoved = false
    defaults.width = 0
    defaults.height = 0

    defaults.pressControl = nil
    defaults.toggleControl = nil
    defaults.glowWhenControlIsInside = true
    defaults.isGlowing = false

    defaults.isPressed = false
    defaults.wasPreviouslyPressed = false
    defaults.justPressed = false
    defaults.justReleased = false
    defaults.justDragged = false
    defaults.justStartedDragging = false
    defaults.justStoppedDragging = false
    defaults.hasDraggedSincePress = false

    defaults.objectsToDrag = {}
    defaults.wasPressedInsideObject = {}
    defaults.justDraggedObject = {}
    defaults.justStartedDraggingObject = {}
    defaults.justStoppedDraggingObject = {}

    defaults.bodyColor = { 0.4, 0.4, 0.4, 1, 0 }
    defaults.outlineColor = { 0.15, 0.15, 0.15, 1, 0 }
    defaults.highlightColor = { 1, 1, 1, 0.1, 1 }
    defaults.pressedColor = { 1, 1, 1, -0.15, 1 }
    defaults.graphics = Graphics:new{
        x = object.x,
        y = object.y
    }

    for k, v in pairs(defaults) do if object[k] == nil then object[k] = v end end
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    return object
end

function Button:pointIsInside(point)
    return point.x >= self.x and point.y <= self.x + self.width
       and point.y >= self.y and point.y <= self.y + self.height
end
function Button:updatePressConditions()
    local pressControl = self.pressControl
    local toggleControl = self.toggleControl

    if pressControl then
        if self:pointIsInside(pressControl) and pressControl.justPressed then
            self.isPressed = true
        end
        if pressControl.justReleased then
            self.isPressed = false
        end
    end

    if toggleControl then
        if self:pointIsInside(toggleControl) and toggleControl.justPressed then
            self.isPressed = not self.isPressed
        end
    end

    self.justPressed = self.isPressed and not self.wasPreviouslyPressed
    self.justReleased = not self.isPressed and self.wasPreviouslyPressed
end
function Button:updateDragConditions()
    self.justMoved = self.x ~= self.previousX or self.y ~= self.previousY
    self.justDragged = self.isPressed and self.justMoved
    self.justStartedDragging = self.justDragged and not self.hasDraggedSincePress
    self.justStoppedDragging = self.justReleased and self.hasDraggedSincePress
    if self.justDragged then self.hasDraggedSincePress = true end
    if self.justReleased then self.hasDraggedSincePress = false end

    local objectsToDrag = self.objectsToDrag
    for i = 1, #objectsToDrag do
        local object = objectsToDrag[i]
        if self.justPressed and object:pointIsInside(self) then
            self.wasPressedInsideObject[object] = true
        end
        if self.justReleased then
            self.wasPressedInsideObject[object] = false
        end

        self.justDraggedObject[object] = self.wasPressedInsideObject[object] and self.justDragged
        self.justStartedDraggingObject[object] = self.wasPressedInsideObject[object] and self.justStartedDragging
        self.justStoppedDraggingObject[object] = self.wasPressedInsideObject[object] and self.justStoppedDragging
    end
end
function Button:updateGlowConditions()
    local pressControlIsInside = pressControl and self:pointIsInside(pressControl)
    local toggleControlIsInside = pressControl and self:pointIsInside(pressControl)

    self.isGlowing = self.glowWhenControlIsInside and (pressControlIsInside or toggleControlIsInside)
end
function Button:update()
    self:updatePressConditions()
    self:updateDragConditions()
    self:updateGlowConditions()
end
function Button:draw()
    local graphics = self.graphics
    local w, h = self.width, self.height

    -- Draw the body.
    graphics:setColor(self.bodyColor)
    graphics:drawRectangle(1, 1, w - 2, h - 2, true)

    -- Draw a dark outline around.
    graphics:setColor(self.outlineColor)
    graphics:drawRectangle(0, 0, w, h, false)

    -- Draw a light outline around.
    graphics:setColor(self.highlightColor)
    graphics:drawRectangle(1, 1, w - 2, h - 2, false)

    if self.isPressed then
        graphics:setColor(self.pressedColor)
        graphics:drawRectangle(1, 1, w - 2, h - 2, true)

    elseif self.isGlowing then
        graphics:setColor(self.highlightColor)
        graphics:drawRectangle(1, 1, w - 2, h - 2, true)
    end
end

return Button