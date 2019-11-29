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
    local defaults = {
        imageBuffer = getNewImageBuffer(),
        backgroundColor = { 0, 0, 0 }
    }

    Fn.initialize(self, defaults)
    Fn.initialize(self, Image)
    Widget.new(self)
    self:clear()
    return self
end

function Image:clear()
    local imageBuffer = self.imageBuffer
    gfx.setimgdim(imageBuffer, -1, -1)
    gfx.setimgdim(imageBuffer, self.width, self.height)
end
function Image:doDraw()
    local a, mode, dest = gfx.a, gfx.mode, gfx.dest
    gfx.a = self.alpha
    gfx.mode = self.blendMode
    gfx.dest = self.imageBuffer

    local x, y, w, h = self.x, self.y, self.width, self.height
    local backgroundColor = self.backgroundColor
    if backgroundColor then
        self:setColor(self.backgroundColor)
        gfx.rect(0, 0, w, h, true)
    end
    if self.draw then self:draw() end

    gfx.dest = dest
    gfx.blit(self.imageBuffer, 1.0, 0, 0, 0, w, h, x, y, w, h, 0, 0)

    gfx.a, gfx.mode = a, mode
end

return Image