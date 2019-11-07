local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Rectangle = require("GUI.Rectangle")
local Drawable = require("GUI.Drawable")

local currentBuffer = -1
local function getNewDrawBuffer()
    currentBuffer = currentBuffer + 1
    if currentBuffer > 1023 then currentBuffer = 0 end
    return currentBuffer
end

local Widget = {
    x = 0,
    y = 0,
    width = 0,
    height = 0,
    shouldClear = false,
    shouldDrawDirectly = false,
    isVisible = Toggle:new(true),
    shouldRedraw = true
}

function Widget:new(initialValues)
    local instance = setmetatable({}, {
        __index = function(t, k)
            local value = Widget[k]
            if value ~= nil then
                return value:get()
            end
            return rawget(t, k)
        end,
        __newindex = function(t, k, v)
            local value = Widget[k]
            if value ~= nil then
                value:set(v)
            end
            rawset(t, k, v)
        end
    })

    return instance
end

function Widget:pointIsInside(pointX, pointY)
    local x = self.x
    local y = self.y
    local width = self.width
    local height = self.height
    return pointX >= x and pointX <= x + width
        and pointY >= y and pointY <= y + height
end

function Widget:clearBuffer()
    local drawBuffer = self.drawBuffer
    local width = self.width
    local height = self.height
    gfx.setimgdim(drawBuffer, -1, -1)
    gfx.setimgdim(drawBuffer, width, height)
end
function Widget:doBeginUpdateFunction()
    if self.beginUpdate then self:beginUpdate() end
end
function Widget:doUpdateFunction()
    if self.update then self:update() end
end
function Widget:doDrawFunction()
    if self.shouldRedraw and self.draw then
        self:clearBuffer()
        gfx.a = 1.0
        gfx.mode = 0
        gfx.dest = self.drawBuffer
        self:draw()

    elseif self.shouldClear then
        self:clearBuffer()
        self.shouldClear = false
    end

    self.shouldRedraw = false
end
function Widget:blitToMainWindow()
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
end
function Widget:doEndUpdateFunction()
    if self.endUpdate then self:endUpdate() end
end

return Widget