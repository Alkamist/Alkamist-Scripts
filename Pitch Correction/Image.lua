local reaper = reaper
local gfx = gfx
local pairs = pairs

local Fn = require("Fn")
local Widget = require("Widget")
local GUI = require("GUI")
local mouse = GUI.mouse

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
function Image.new(self)
    local states = {}

    states.imageBuffer = getNewImageBuffer()
    states.backgroundColor = { 0, 0, 0 }

    local self = Widget.new(Fn.initialize(self, states))
    Image.clear(self)
    return self
end

function Image.clear(self)
    local imageBuffer = self.imageBuffer
    gfx.setimgdim(imageBuffer, -1, -1)
    gfx.setimgdim(imageBuffer, self.width, self.height)
end
function Image.update(self)
    Widget.update(self, function() end)
end
function Image.draw(self, drawFn)
    Widget.draw(self, function()
        local dest = gfx.dest
        local x, y, w, h = self.x, self.y, self.width, self.height

        gfx.dest = self.imageBuffer
        gfx.a = 1
        gfx.mode = 0

        local backgroundColor = self.backgroundColor
        if backgroundColor then
            Fn.setColor(self.backgroundColor)
            gfx.rect(0, 0, w, h, true)
        end

        if drawFn then
            drawFn()
        end

        gfx.dest = dest
        gfx.blit(self.imageBuffer, 1.0, 0, 0, 0, w, h, x, y, w, h, 0, 0)
    end)
end
function Image.endUpdate(self)
    Widget.endUpdate(self, function() end)
end

return Image