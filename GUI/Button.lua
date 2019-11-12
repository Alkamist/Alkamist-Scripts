local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Prototype = require("Prototype")
local Widget = require("GUI.Widget")
local Toggle = require("GUI.Toggle")

return Prototype:new{
    prototypes = {
        { "widget", Widget:new() }
    },
    label = "",
    labelFont = "Arial",
    labelFontSize = 14,
    labelColor = { 1.0, 1.0, 1.0, 0.4, 1 },
    color = { 0.3, 0.3, 0.3, 1.0, 0 },
    edgeColor = { 1.0, 1.0, 1.0, 0.1, 1 },
    glowColor = { 1.0, 1.0, 1.0, 0.15, 1 },
    pressedColor = { 1.0, 1.0, 1.0, -0.15, 1 },
    glowOnMouseOver = true,
    pressOnClick = {
        value = true,
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            field.value = value
            if field.value == true then self.toggleOnClick = false end
        end
    },
    toggleOnClick = {
        value = false,
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            field.value = value
            if field.value == true then self.pressOnClick = false end
        end
    },
    pressState = Toggle:new(),
    isPressed = {
        get = function(self, field) return self.pressState.currentState end,
        set = function(self, value, field)
            self.pressState.currentState = value
            self:queueRedraw()
        end
    },
    justPressed = { from = { "pressState", "justTurnedOn" } },
    justReleased = { from = { "pressState", "justTurnedOff" } },
    isGlowing = {
        value = false,
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            field.value = value
            self:queueRedraw()
        end
    },

    beginUpdate = function(self)
        self.pressState:update()
    end,
    update = function(self)
        local mouse = self.mouse
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
    end,
    draw = function(self)
        local width = self.width
        local height = self.height

        -- Draw the main self.
        self:setColor(self.color)
        self:drawRectangle(0, 0, width, height, true)

        -- Draw a light outline around the self.
        self:setColor(self.edgeColor)
        self:drawRectangle(0, 0, width, height, false)

        -- Draw the self's label.
        self:setColor(self.labelColor)
        self:setFont(self.labelFont, self.labelFontSize)
        self:drawString(self.label, 0, 0, 5, width, height)

        if self.isPressed then
            self:setColor(self.pressedColor)
            self:drawRectangle(0, 0, width, height, true)

        elseif _glowState then
            self:setColor(self.glowColor)
            self:drawRectangle(0, 0, width, height, true)
        end
    end
}