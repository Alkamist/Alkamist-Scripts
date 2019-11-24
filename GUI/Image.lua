local reaper = reaper
local math = math
local pairs = pairs
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Boundary = require("GUI.Boundary")
local GUI = require("GUI.AlkamistGUI")
local mouse = GUI.mouse
local graphics = GUI.graphics

local Image = {}
function Image.new(object)
    local self = {}

    self.imageBuffer = graphics.getNewImageBuffer()
    self.backgroundColor = { 0, 0, 0, 1, 0 }

    local object = Boundary.new(object)
    for k, v in pairs(self) do if not object[k] then object[k] = v end end
    Image.clear(object)
    return object
end

Image.pointIsInside = Boundary.pointIsInside
Image.endUpdate = Boundary.endUpdate
function Image.clear(self)
    local imageBuffer = self.imageBuffer
    gfx.setimgdim(imageBuffer, -1, -1)
    gfx.setimgdim(imageBuffer, self.width, self.height)
end
function Image.draw(self, drawingOperation)
    local x, y, w, h = self.x, self.y, self.width, self.height
    local a, mode, dest = gfx.a, gfx.mode, gfx.dest

    gfx.dest = self.imageBuffer
    gfx.a = 1
    gfx.mode = 0

    local backgroundColor = self.backgroundColor
    if backgroundColor then
        graphics.setColor(self.backgroundColor)
        graphics.drawRectangle(0, 0, w, h, true)
    end

    if drawingOperation then
        drawingOperation()
    end

    gfx.dest = dest
    --gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs])
    gfx.blit(self.imageBuffer, 1.0, 0, 0, 0, w, h, x, y, w, h, 0, 0)
    gfx.a, gfx.mode = a, mode
end

return Image