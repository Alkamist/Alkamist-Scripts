local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Widget = require("GUI.Widget")

local Button = {}
function Button:new(object)
    local self = Widget:new(self)

    self.label = ""
    self.labelFont = "Arial"
    self.labelFontSize = 14
    self.labelColor = { 1.0, 1.0, 1.0, 0.4, 1 }
    self.color = { 0.3, 0.3, 0.3, 1.0, 0 }
    self.outlineColor = { 0.15, 0.15, 0.15, 1.0, 0 }
    self.edgeColor = { 1.0, 1.0, 1.0, 0.1, 1 }
    self.pressedColor = { 1.0, 1.0, 1.0, -0.15, 1 }
    self.glowColor = { 1.0, 1.0, 1.0, 0.15, 1 }
    self.glowOnMouseOver = true
    self.isPressed = false
    self.previousPressState = false
    self.isGlowing = false
    self.justPressed = { get = function(self) return self.isPressed and not self.previousPressState end }
    self.justReleased = { get = function(self) return not self.isPressed and self.previousPressState end }
    self.toggleOnClick = {
        value = false,
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            field.value = value
            if value then self.pressOnClick = false end
        end,
    }
    self.pressOnClick = {
        value = true,
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            field.value = value
            if value then self.toggleOnClick = false end
        end,
    }

    if object then for k, v in pairs(object) do self[k] = v end end
    return self
end

function Button:press()
    self.isPressed = true
    self:queueRedraw()
end
function Button:release()
    self.isPressed = false
    self:queueRedraw()
end
function Button:toggle()
    self.isPressed = not self.isPressed
    self:queueRedraw()
end
function Button:glow()
    self.isGlowing = true
    self:queueRedraw()
end
function Button:unGlow()
    self.isGlowing = false
    self:queueRedraw()
end
function Button:toggleGlow()
    self.isGlowing = not self.isGlowing
    self:queueRedraw()
end

function Button:beginUpdate()
    self.previousPressState = self.isPressed
end
function Button:update()
    local GUI = self.GUI
    local leftMouseButton = GUI.leftMouseButton

    if self.glowOnMouseOver then
        if GUI:mouseJustEnteredWidget(self) then self:glow() end
        if GUI:mouseJustLeftWidget(self) then self:unGlow() end
    end
    if self.pressOnClick then
        if leftMouseButton:justPressedWidget(self) then self:press() end
        if leftMouseButton:justReleasedWidget(self) then self:release() end
    end
    if self.toggleOnClick then
        if leftMouseButton:justPressedWidget(self) then self:toggle() end
    end
end
function Button:draw()
    local width =  self.width
    local height = self.height

    -- Draw the body.
    self:setColor(self.color)
    self:drawRectangle(0, 0, width, height, true)

    -- Draw a dark outline around.
    self:setColor(self.outlineColor)
    self:drawRectangle(0, 0, width, height, false)

    -- Draw a light outline around.
    self:setColor(self.edgeColor)
    self:drawRectangle(1, 1, width - 2, height - 2, false)

    -- Draw the label.
    self:setColor(self.labelColor)
    self:setFont(self.labelFont, self.labelFontSize)
    self:drawString(self.label, 0, 0, 5, width, height)

    if self.isPressed then
        self:setColor(self.pressedColor)
        self:drawRectangle(1, 1, width - 2, height - 2, true)

    elseif self.isGlowing then
        self:setColor(self.glowColor)
        self:drawRectangle(1, 1, width - 2, height - 2, true)
    end
end

return Button