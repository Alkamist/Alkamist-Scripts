local reaper = reaper
local math = math
local pairs = pairs

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Widget = require("GUI.Widget")

local RectangularImage = {}
function RectangularImage:new(object)
    local self = Widget:new(self)

    self.imageBuffer = self.GUI:getNewImageBuffer()

    if object then for k, v in pairs(object) do self[k] = v end end
    self:clear()
    return self
end

function RectangularImage:clear()
    local imageBuffer = self.imageBuffer
    gfx.setimgdim(imageBuffer, -1, -1)
    gfx.setimgdim(imageBuffer, self.width, self.height)
end
function RectangularImage:draw()
    local x = self.x
    local y = self.y
    local width = self.width
    local height = self.height
    --gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs])
    gfx.blit(self.imageBuffer, 1.0, 0, 0, 0, width, height, x, y, width, height, 0, 0)
end

return RectangularImage