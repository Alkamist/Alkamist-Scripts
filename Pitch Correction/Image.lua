local reaper = reaper
local gfx = gfx
local pairs = pairs

local usedImageBuffers = {}
local function getNewImageBuffer()
    for i = 0, 1023 do
        if usedImageBuffers[i] == nil then
            usedImageBuffers[i] = true
            return i
        end
    end
end

function Image:new(object)
    local object = object or {}
    local defaults = {}

    defaults.x = 0
    defaults.y = 0
    defaults.width = 0
    defaults.height = 0
    defaults.imageBuffer = getNewImageBuffer()
    defaults.backgroundColor = { 0, 0, 0, 1, 0 }

    for k, v in pairs(defaults) do if object[k] == nil then object[k] = v end end
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    self:clear()
    return object
end

function Image:clear()
    local imageBuffer = self.imageBuffer
    gfx.setimgdim(imageBuffer, -1, -1)
    gfx.setimgdim(imageBuffer, self.width, self.height)
end

function Image:draw()
    local x, y, w, h = self.x, self.y, self.width, self.height
    local backgroundColor = self.backgroundColor
    local graphics = self.graphics

    if backgroundColor then
        graphics:setColor(self.backgroundColor)
        graphics:drawRectangle(0, 0, w, h, true)
    end

    gfx.dest = dest
    gfx.blit(self.imageBuffer, 1.0, 0, 0, 0, w, h, x, y, w, h, 0, 0)
end

return Image