local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")
local Prototype = require("Prototype")
local Drawable = require("GUI.Drawable")
local Toggle = require("GUI.Toggle")

return Prototype:new{
    --calledWhenCreated = function(self)
    --end,
    prototypes = {
        { "drawable", Drawable:new() }
    },
    GUI = { get = function(self) return GUI end },
    parentWidget = nil,
    relativeMouseX = { get = function(self) return self.GUI.mouse.x - self.x end },
    previousRelativeMouseX = { get = function(self) return self.GUI.mouse.previousX - self.x end },
    relativeMouseY = { get = function(self) return self.GUI.mouse.y - self.y end },
    previousRelativeMouseY = { get = function(self) return self.GUI.mouse.previousY - self.y end },
    keyboard = { get = function(self) return self.GUI.keyboard end },

    x = 0,
    y = 0,
    width = 0,
    height = 0,
    shouldRedraw = true,
    shouldClear = false,
    visibilityState = Toggle:new{ currentState = true, previousState = true },
    isVisible = {
        get = function(self) return self.visibilityState.currentState end,
        set = function(self, value) self.visibilityState.currentState = value end
    },
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
    update = function(self) end,
    --doDrawFunction = function(self, drawFunction)
        --if self.shouldRedraw and drawFunction then
        --    self:clearBuffer()
        --    gfx.a = 1.0
        --    gfx.mode = 0
        --    gfx.dest = self.drawBuffer
        --    drawFunction()
        --    self.shouldRedraw = false
        --elseif self.shouldClear then
        --    self:clearBuffer()
        --    self.shouldClear = false
        --end
    --end,
    blit = function(self)
        if self.isVisible then
            local x = self.x
            local y = self.y
            local width = self.width
            local height = self.height
            gfx.a = 1.0
            local parentWidget = self.parentWidget
            if parentWidget then
                gfx.dest = parentWidget.drawBuffer
            else
                gfx.dest = -1
            end
            gfx.blit(self.drawBuffer, 1.0, 0, 0, 0, width, height, x, y, width, height, 0, 0)
        end
    end,
    endUpdate = function(self) end
}