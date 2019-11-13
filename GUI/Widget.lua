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
    prototypes = {
        { "drawable", Drawable:new() }
    },
    mouse = {},
    x = 0,
    y = 0,
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
    doBeginUpdateFunction = function(self)
        if self.beginUpdate then self:beginUpdate() end
    end,
    doUpdateFunction = function(self)
        if self.update then self:update() end
    end,
    doDrawFunction = function(self)
--        if self.shouldRedraw and self.draw then
--            self:clearBuffer()
            gfx.a = 1.0
            gfx.mode = 0
            gfx.dest = self.drawBuffer
            self:draw()
--
--        elseif self.shouldClear then
--            self:clearBuffer()
--            self.shouldClear = false
--        end
--
--        self.shouldRedraw = false
    end,
    blitToMainWindow = function(self)
        if self.isVisible then
            local x = self.x
            local y = self.y
            local width = self.width
            local height = self.height
            gfx.a = 1.0
            gfx.mode = 0
            gfx.dest = -1
            gfx.blit(self.drawBuffer, 1.0, 0, 0, 0, width, height, x, y, width, height, 0, 0)
        end
    end,
    doEndUpdateFunction = function(self)
        if self.endUpdate then self:endUpdate() end
    end,
}