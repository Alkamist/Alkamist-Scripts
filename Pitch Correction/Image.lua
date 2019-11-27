local reaper = reaper
local gfx = gfx
local pairs = pairs

local Fn = require("Fn")
local Widget = require("Widget")
local GUI = require("GUI")
local mouse = GUI.mouse
local mouseButtons = mouse.buttons
local keyboard = GUI.keyboard
local keyboardModifiers = keyboard.modifiers
local keyboardKeys = GUI.keyboard.keys

local usedImageBuffers = {}
local function getNewImageBuffer()
    for i = 0, 1023 do
        if usedImageBuffers[i] == nil then
            usedImageBuffers[i] = true
            return i
        end
    end
end

local Image = {}
function Image:new()
    local states = {}

    states.imageBuffer = getNewImageBuffer()
    states.backgroundColor = { 0, 0, 0 }
    states.oldChildPointIsInsideFns = {}

    local self = Widget.new(Fn.initialize(self, Image, states))
    Image.clear(self)
    return self
end

function Image:clear()
    local imageBuffer = self.imageBuffer
    gfx.setimgdim(imageBuffer, -1, -1)
    gfx.setimgdim(imageBuffer, self.width, self.height)
end
function Image:giveChildWidgetPointIsInsideFn(childWidget)
    self.oldChildPointIsInsideFns[childWidget] = childWidget.pointIsInside
    childWidget.pointIsInside = function(child, pointX, pointY)
        return self:pointIsInside(pointX, pointY) and self.oldChildPointIsInsideFns[child](child, pointX, pointY)
    end

    local childWidgets2 = childWidget.widgets
    if childWidgets2 then
        for i = 1, #childWidgets2 do
            local childWidget2 = childWidgets2[i]
            self:giveChildWidgetPointIsInsideFn(childWidget2)
        end
    end
end
function Image:restoreOldChildWidgetPointIsInsideFn(childWidget)
    childWidget.pointIsInside = self.oldChildPointIsInsideFns[childWidget]

    local childWidgets2 = childWidget.widgets
    if childWidgets2 then
        for i = 1, #childWidgets2 do
            local childWidget2 = childWidgets2[i]
            self:restoreOldChildWidgetPointIsInsideFn(childWidget2)
        end
    end
end
function Image:doChildWidgetUpdates()
    local childWidgets = self.widgets
    if childWidgets then
        for i = 1, #childWidgets do
            local childWidget = childWidgets[i]

            self:giveChildWidgetPointIsInsideFn(childWidget)
            childWidget.x = childWidget.x + self.x
            childWidget.y = childWidget.y + self.y

            childWidget:doUpdate()

            self:restoreOldChildWidgetPointIsInsideFn(childWidget)
            childWidget.x = childWidget.x - self.x
            childWidget.y = childWidget.y - self.y
        end
    end
end
function Image:doChildWidgetDraws()
    local childWidgets = self.widgets
    if childWidgets then
        for i = 1, #childWidgets do
            local childWidget = childWidgets[i]
            gfx.dest = self.imageBuffer
            childWidget:doDraw()
        end
    end
end
function Image:doDraw()
    local a, mode, dest = gfx.a, gfx.mode, gfx.dest
    gfx.a = self.alpha
    gfx.mode = self.blendMode
    gfx.dest = self.imageBuffer

    local x, y, w, h = self.x, self.y, self.width, self.height
    local backgroundColor = self.backgroundColor
    if backgroundColor then
        Fn.setColor(self.backgroundColor)
        gfx.rect(0, 0, w, h, true)
    end
    if self.draw then self:draw() end

    self:doChildWidgetDraws()

    gfx.dest = dest
    gfx.blit(self.imageBuffer, 1.0, 0, 0, 0, w, h, x, y, w, h, 0, 0)

    gfx.a, gfx.mode, gfx.dest = a, mode, dest
end

return Image