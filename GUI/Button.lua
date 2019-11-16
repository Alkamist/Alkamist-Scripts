local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")
local Widget = require("GUI.Widget")
local Toggle = require("GUI.Toggle")

local Button = {}
function Button:new(initialValues)
    local self = Widget:new(initialValues)

    self.label = ""
    self.labelFont = "Arial"
    self.labelFontSize = 14
    self.labelColor = { 1.0, 1.0, 1.0, 0.4, 1 }
    self.color = { 0.3, 0.3, 0.3, 1.0, 0 }
    self.outlineColor = { 0.15, 0.15, 0.15, 1.0, 0 }
    self.edgeColor = { 1.0, 1.0, 1.0, 0.1, 1 }
    self.glowColor = { 1.0, 1.0, 1.0, 0.15, 1 }
    self.pressedColor = { 1.0, 1.0, 1.0, -0.15, 1 }
    self.glowOnMouseOver = true
    self.pressOnClick = {
        value = true,
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            field.value = value
            if field.value == true then self.toggleOnClick = false end
        end
    }
    self.toggleOnClick = {
        value = false,
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            field.value = value
            if field.value == true then self.pressOnClick = false end
        end
    }
    self.pressState = Toggle:new()
    self.isPressed = {
        get = function(self, field) return self.pressState.currentState end,
        set = function(self, value, field)
            self.pressState.currentState = value
            self.shouldRedraw = true
        end
    }
    self.justPressed = { get = function(self) return self.pressState.justTurnedOn end }
    self.justReleased = { get = function(self) return self.pressState.justTurnedOff end }
    self.isGlowing = {
        value = false,
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            field.value = value
            self.shouldRedraw = true
        end
    }

    function self:beginUpdate()
        self.pressState:update()
    end
    function self:update()
        local mouse = self.GUI.mouse
        local mouseLeftButton = mouse.leftButton

        if self.glowOnMouseOver then
            if mouse:justEnteredWidget(self) then self.isGlowing = true end
            if mouse:justLeftWidget(self) then self.isGlowing = false end
        end
        if self.pressOnClick then
            if mouseLeftButton:justPressedWidget(self) then self.isPressed = true end
            if mouseLeftButton:justReleasedWidget(self) then self.isPressed = false end
        end
        if self.toggleOnClick then
            if mouseLeftButton:justPressedWidget(self) then self.isPressed = not self.isPressed end
        end
    end
    function self:draw()
        local width = self.width
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

    return Proxy:new(self, initialValues)
end

return Button