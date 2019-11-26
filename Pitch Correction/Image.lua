local reaper = reaper
local gfx = gfx
local pairs = pairs

local Fn = require("Fn")
local Widget = require("Widget")
local GUI = require("GUI.AlkamistGUI")
local mouse = GUI.mouse

local Image = {}
function Image.new(object)
    local self = {}

    self.imageBuffer = graphics.getNewImageBuffer()
    self.backgroundColor = { 0, 0, 0 }

    return Widget.new(Fn.makeNew(self, Image, object))
end

function Image:clear()
    local imageBuffer = self.imageBuffer
    gfx.setimgdim(imageBuffer, -1, -1)
    gfx.setimgdim(imageBuffer, self.width, self.height)
end
function Image:draw(drawingOperation)
    local alpha, blendMode, dest = gfx.a, gfx.mode, gfx.dest
    local x, y, w, h = self.x, self.y, self.width, self.height

    gfx.dest = self.imageBuffer
    gfx.a = 1
    gfx.mode = 0

    local backgroundColor = self.backgroundColor
    if backgroundColor then
        Fn.setColor(self.backgroundColor)
        gfx.rect(x, y, w, h, true)
    end

    if drawingOperation then
        drawingOperation()
    end

    gfx.dest = dest
    --gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs])
    gfx.blit(self.imageBuffer, 1.0, 0, 0, 0, w, h, x, y, w, h, 0, 0)

    gfx.a, gfx.mode = alpha, blendMode
end

return Image