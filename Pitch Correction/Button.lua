local GUI = require("GUI")

local Button = {}

local function mouseIsInsideButton(self)
    local x, y, w, h = self.x, self.y, self.width, self.height
    local mouseX = GUI.mouseX
    local mouseY = GUI.mouseY
    return mouseX >= x and mouseX <= x + w
       and mouseY >= y and mouseY <= y + h
end

function Button:filter()
    return self.Position and self.Button
end
function Button:getDefaults()
    local defaults = {}

    defaults.x = 0
    defaults.y = 0
    defaults.width = 0
    defaults.height = 0

    defaults.isPressed = false
    defaults.wasPreviouslyPressed = false
    defaults.justPressed = false
    defaults.justReleased = false
    defaults.justDragged = false
    defaults.hasDraggedSincePress = false
    defaults.justStartedDragging = false
    defaults.justStoppedDragging = false
    defaults.wasPressedInsideObject = {}
    defaults.justDraggedObject = {}
    defaults.justStartedDraggingObject = {}
    defaults.justStoppedDraggingObject = {}
    defaults.objectsToDrag = {}

    defaults.isGlowing = false
    defaults.bodyColor = { 0.4, 0.4, 0.4, 1, 0 }
    defaults.outlineColor = { 0.15, 0.15, 0.15, 1, 0 }
    defaults.pressedColor = { 1, 1, 1, -0.1, 1 }
    defaults.highlightColor = { 1, 1, 1, 0.1, 1 }

    return defaults
end
function Button:updatePreviousState(dt)
    self.wasPreviouslyPressed = self.isPressed
end
function Button:updateState(dt)
    self.justPressed = self.isPressed and not self.wasPreviouslyPressed
    self.justReleased = not self.isPressed and self.wasPreviouslyPressed
    self.justDragged = self.isPressed and self.justMoved
    self.justStartedDragging = self.justDragged and not self.hasDraggedSincePress
    self.justStoppedDragging = self.justReleased and self.hasDraggedSincePress
    if self.justDragged then self.hasDraggedSincePress = true end
    if self.justReleased then self.hasDraggedSincePress = false end
    self.isGlowing = mouseIsInsideButton(self)
end
function Button:draw(dt)
    local x, y, w, h = self.x, self.y, self.width, self.height

    -- Draw the body.
    GUI.setColor(self.bodyColor)
    GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

    -- Draw a dark outline around.
    GUI.setColor(self.outlineColor)
    GUI.drawRectangle(x, y, w, h, false)

    -- Draw a light outline around.
    GUI.setColor(self.highlightColor)
    GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, false)

    if self.isPressed then
        GUI.setColor(self.pressedColor)
        GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

    elseif self.isGlowing then
        GUI.setColor(self.highlightColor)
        GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)
    end
end

return Button