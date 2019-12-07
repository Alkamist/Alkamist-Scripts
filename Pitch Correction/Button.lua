local function GetSet(privateName)
    return function(self, v)
        if v == nil then
            return self[privateName]
        else
            self[privateName] = v
        end
    end
end

local Button = {}

Button.isPressed = GetSet("Button_isPressed")
Button.wasPreviouslyPressed = GetSet("Button_wasPreviouslyPressed")
Button.hasDraggedSincePress = GetSet("Button_hasDraggedSincePress")
Button.wasPressedInsideObject = GetSet("Button_wasPressedInsideObject")
Button.isGlowing = GetSet("Button_isGlowing")
Button.glowWhenControlIsInside = GetSet("Button_glowWhenControlIsInside")
Button.bodyColor = GetSet("Button_bodyColor")
Button.outlineColor = GetSet("Button_outlineColor")
Button.highlightColor = GetSet("Button_highlightColor")
Button.pressedColor = GetSet("Button_pressedColor")
Button.pressControl = GetSet("Button_pressControl")
Button.toggleControl = GetSet("Button_toggleControl")
Button.objectsToDrag = GetSet("Button_objectsToDrag")

function Button:justPressed() return Button.isPressed(self) and not Button.wasPreviouslyPressed(self) end
function Button:justReleased() return not Button.isPressed(self) and Button.wasPreviouslyPressed(self) end
function Button:justDragged() return Button.isPressed(self) and Position.justMoved(self) end
function Button:justStartedDragging() return Button.justDragged(self) and not Button.hasDraggedSincePress(self) end
function Button:justStoppedDragging() return Button.justReleased(self) and Button.hasDraggedSincePress(self) end
function Button:justDraggedObject(object) return Button.wasPressedInsideObject(self, object) and Button.justDragged(self) end
function Button:justStartedDraggingObject(object) return Button.wasPressedInsideObject(self, object) and Button.justStartedDragging(self) end
function Button:justStoppedDraggingObject(object) return Button.wasPressedInsideObject(self, object) and Button.justStoppedDragging(self) end

function Button:initialize()
    Button.isPressed(self, false)
    Button.wasPreviouslyPressed(self, false)
    Button.hasDraggedSincePress(self, false)
    Button.wasPressedInsideObject(self, {})
    Button.isGlowing(self, false)
    Button.glowWhenControlIsInside(self, true)
    Button.bodyColor(self, { 0.4, 0.4, 0.4, 1, 0 })
    Button.outlineColor(self, { 0.15, 0.15, 0.15, 1, 0 })
    Button.highlightColor(self, { 1, 1, 1, 0.1, 1 })
    Button.pressedColor(self, { 1, 1, 1, -0.15, 1 })
    Button.pressControl(self, MouseButtons.left)
    Button.toggleControl(self, nil)
    Button.objectsToDrag(self, nil)
end

function Button.update(e)
    local pressControl = e.pressControl
    local toggleControl = e.toggleControl

    if pressControl then
        if Button.pointIsInside(self, pressControl) and Button.justPressed(pressControl) then
            Button.isPressed(self, true)
        end
        if pressControl:justReleased() then
            Button.isPressed(self, false)
        end
    end

    if toggleControl then
        if Button.pointIsInside(self, toggleControl) and Button.justPressed(toggleControl) then
            Button.isPressed(self, not Button.isPressed(self))
        end
    end

    if Button.justDragged(self) then Button.hasDraggedSincePress(self, true) end
    if Button.justReleased(self) then Button.hasDraggedSincePress(self, false) end

    local objectsToDrag = Button.objectsToDrag(self)
    for i = 1, #objectsToDrag do
        local object = objectsToDrag[i]

        if Button.justPressed(self) and Button.pointIsInside(object, self) then
            Button.wasPressedInsideObject(self, object, true)
        end

        if Button.justReleased(self) then
            Button.wasPressedInsideObject(self, object, false)
        end
    end

    local pressControlIsInside = pressControl and Button.pointIsInside(pressControl, self)
    local toggleControlIsInside = toggleControl and Button.pointIsInside(toggleControl, self)

    Button.isGlowing(self, Button.glowWhenControlIsInside(self) and (pressControlIsInside or toggleControlIsInside))
end

function Button.draw(e, GUI)
    local w, h = e.w, e.h

    -- Draw the body.
    GUI.setColor(e.bodyColor)
    GUI.drawRectangle(e, 1, 1, w - 2, h - 2, true)

    -- Draw a dark outline around.
    GUI.setColor(e.outlineColor)
    GUI.drawRectangle(e, 0, 0, w, h, false)

    -- Draw a light outline around.
    GUI.setColor(e.highlightColor)
    GUI.drawRectangle(e, 1, 1, w - 2, h - 2, false)

    if e.isPressed then
        GUI.setColor(e.pressedColor)
        GUI.drawRectangle(e, 1, 1, w - 2, h - 2, true)

    elseif e.isGlowing then
        GUI.setColor(e.highlightColor)
        GUI.drawRectangle(e, 1, 1, w - 2, h - 2, true)
    end
end

return Button