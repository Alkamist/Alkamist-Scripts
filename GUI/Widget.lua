local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Prototype = require("Prototype")
local Drawable = require("GUI.Drawable")
local Toggle = require("GUI.Toggle")

local currentBuffer = -1
local function getNewDrawBuffer()
    currentBuffer = currentBuffer + 1
    if currentBuffer > 1023 then currentBuffer = 0 end
    return currentBuffer
end

return Prototype:new{
    calledWhenCreated = function(self)
        if not self.shouldDrawDirectly then
            self.drawBuffer = getNewDrawBuffer()
        end
    end,
    prototypes = {
        { "drawable", Drawable:new() }
    },
    GUI = {},
    mouse = { from = { "GUI", "mouse" } },
    keyboard = { from = { "GUI", "keyboard" } },
    x = {
        value = 0,
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            if self.shouldDrawDirectly then
                self.drawable.x = value
            end
            field.value = value
        end
    },
    y = {
        value = 0,
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            if self.shouldDrawDirectly then
                self.drawable.y = value
            end
            field.value = value
        end
    },
    width = 0,
    height = 0,
    shouldRedraw = true,
    shouldClear = false,
    shouldDrawDirectly = false,
    visibilityState = Toggle:new{ currentState = true, previousState = true },
    isVisible = { from = { "visibilityState", "currentState" } },
    pointIsInside = function(self, pointX, pointY)
        local x = self.x
        local y = self.y
        local width = self.width
        local height = self.height
        return pointX >= x and pointX <= x + width
            and pointY >= y and pointY <= y + height
    end,
    clearBuffer = function(self)
        local drawBuffer = self.drawBuffer
        local width = self.width
        local height = self.height
        gfx.setimgdim(drawBuffer, -1, -1)
        gfx.setimgdim(drawBuffer, width, height)
    end,
    beginUpdate = function(self)
        self.visibilityState:update()
    end,
}