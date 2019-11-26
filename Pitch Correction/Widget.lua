local reaper = reaper
local pairs = pairs

local Fn = require("Fn")
local GUI = require("GUI")
local mouse = GUI.mouse
local mouseButtons = mouse.buttons
local keyboard = GUI.keyboard
local keyboardModifiers = keyboard.modifiers
local keyboardKeys = GUI.keyboard.keys

local Widget = {}
function Widget.new(init)
    local self = {}

    self.x = Fn.makeGetSet(init.x, 0)
    self.y = Fn.makeGetSet(init.y, 0)
    self.width = Fn.makeGetSet(init.width, 0)
    self.height = Fn.makeGetSet(init.height, 0)
    self.alpha = Fn.makeGetSet(init.alpha, 1.0)
    self.blendMode = Fn.makeGetSet(init.blendMode, 0)
    self.mouseIsInside = Fn.makeGetSet(false)
    self.mouseWasPreviouslyInside = Fn.makeGetSet(false)

    function self:mouseJustEntered() return self:mouseIsInside() and not self:mouseWasPreviouslyInside() end
    function self:mouseJustLeft() return not self:mouseIsInside() and self:mouseWasPreviouslyInside() end
    function self:justDraggedBy(control) return control.justDragged and self:controlWasPressedInside(control) end
    function self:justStartedDraggingBy(control) return control.justStartedDragging and self:controlWasPressedInside(control) end
    function self:justStoppedDraggingBy(control) return control.justStoppedDragging and self:controlWasPressedInside(control) end

    self._controlWasPressedInside = {}
    function self:controlWasPressedInside(control) return self._controlWasPressedInside[control] end

    function self:pointIsInside(pointX, pointY)
        local x, y, w, h = self:x(), self:y(), self:width(), self:height()
        return pointX >= x and pointX <= x + w
           and pointY >= y and pointY <= y + h
    end

    function self:update(updateFn)
        self:mouseIsInside(self:pointIsInside(mouse.x, mouse.y))

        local function updateWidgetMouseControl(control)
            if self:mouseIsInside() and control.justPressed then
                self._controlWasPressedInside[control] = true
            end
            if control.justReleased then
                self._controlWasPressedInside[control] = false
            end
        end

        for _, button in pairs(mouseButtons) do
            updateWidgetMouseControl(button)
        end
        for _, modifier in pairs(keyboardModifiers) do
            updateWidgetMouseControl(modifier)
        end
        for _, key in pairs(keyboardKeys) do
            updateWidgetMouseControl(key)
        end

        if updateFn then updateFn() end
    end
    function self:draw(drawFn)
        local a, mode, dest = gfx.a, gfx.mode, gfx.dest
        gfx.a = self:alpha()
        gfx.mode = self:blendMode()

        if drawFn then drawFn() end

        gfx.a, gfx.mode, gfx.dest = a, mode, dest
    end
    function self:endUpdate(endUpdateFn)
        self:mouseWasPreviouslyInside(self:mouseIsInside())
        if endUpdateFn then endUpdateFn() end
    end

    return self
end

return Widget