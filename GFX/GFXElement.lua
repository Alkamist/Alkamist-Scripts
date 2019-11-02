local reaper = reaper
local gfx = gfx
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local TrackedNumber = require("GFX.TrackedNumber")

local GFXElement = {}

function GFXElement:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.GFX = init.GFX
    self.parent = init.parent
    self.elements = init.elements
    self.mouse = self.GFX.mouse
    self.keyboard = self.GFX.keyboard

    self.x = TrackedNumber:new(init.x or 0)
    self.y = TrackedNumber:new(init.y or 0)
    self.w = TrackedNumber:new(init.w or 0)
    self.h = TrackedNumber:new(init.h or 0)
    self.drawBuffer = self.GFX:getDrawBuffer()

    self.isVisible = true
    self.shouldRedraw = true
    self.shouldClear = false

    return self
end

function GFXElement:update()
    self.x:update()
    self.y:update()
    self.w:update()
    self.h:update()
end
function GFXElement:draw()
    if self.draw then
        if self.shouldRedraw then
            self:clearBuffer()
            gfx.dest = self.drawBuffer
            self:draw()
            self.shouldRedraw = false
        elseif self.shouldClear then
            self:clearBuffer()
            self.shouldClear = false
        end
    end
end

function GFXElement:windowWasResized()
    return GFX:windowWasResized()
end
function GFXElement:pointIsInside(x, y)
    return self.isVisible
       and x >= self.x and x <= self.x + self.w
       and y >= self.y and y <= self.y + self.h
end
function GFXElement:setColor(color)
    self.currentColor = color
    local mode = color[5] or 0
    gfx.set(color[1], color[2], color[3], color[4], mode)
end
function GFXElement:setBlendMode(mode)
    gfx.mode = mode
end
function GFXElement:drawRectangle(x, y, w, h, filled)
    gfx.rect(x, y, w, h, filled)
end
function GFXElement:drawLine(x, y, x2, y2, antiAliased)
    gfx.line(x, y, x2, y2, antiAliased)
end
function GFXElement:drawCircle(x, y, r, filled, antiAliased)
    gfx.circle(x, y, r, filled, antiAliased)
end
function GFXElement:drawPolygon(filled, ...)
    if filled then
        gfx.triangle(...)
    else
        local coords = {...}

        -- Duplicate the first pair at the end, so the last line will
        -- be drawn back to the starting point.
        table.insert(coords, coords[1])
        table.insert(coords, coords[2])

        -- Draw a line from each pair of coords to the next pair.
        for i = 1, #coords - 2, 2 do
            gfx.line(coords[i], coords[i+1], coords[i+2], coords[i+3])
        end
    end
end
function GFXElement:drawRoundRectangle(x, y, w, h, r, filled, antiAliased)
    local aa = antiAliased or 1
    filled = filled or 0
    w = math.max(0, w - 1)
    h = math.max(0, h - 1)

    if filled == 0 or false then
        gfx.roundrect(x, y, w, h, r, aa)
    else
        if h >= 2 * r then
            -- Corners
            gfx.circle(x + r, y + r, r, 1, aa)			-- top-left
            gfx.circle(x + w - r, y + r, r, 1, aa)		-- top-right
            gfx.circle(x + w - r, y + h - r, r , 1, aa) -- bottom-right
            gfx.circle(x + r, y + h - r, r, 1, aa)		-- bottom-left

            -- Ends
            gfx.rect(x, y + r, r, h - r * 2)
            gfx.rect(x + w - r, y + r, r + 1, h - r * 2)

            -- Body + sides
            gfx.rect(x + r, y, w - r * 2, h + 1)
        else
            r = (h / 2 - 1)

            -- Ends
            gfx.circle(x + r, y + r, r, 1, aa)
            gfx.circle(x + w - r, y + r, r, 1, aa)

            -- Body
            gfx.rect(x + r, y, w - (r * 2), h)
        end
    end
end
function GFXElement:setFont(font, size, flags)
    gfx.setfont(1, font, size)
end
function GFXElement:measureString(str)
    return gfx.measurestr(str)
end
function GFXElement:drawString(str, x, y, flags, right, bottom)
    if x then gfx.x = x end
    if y then gfx.y = y end
    if flags then
        gfx.drawstr(str, flags, right, bottom)
    else
        gfx.drawstr(str)
    end
end
function GFXElement:clearBuffer()
    gfx.setimgdim(self.drawBuffer, -1, -1)
    gfx.setimgdim(self.drawBuffer, self.w, self.h)
end
function GFXElement:queueRedraw()
    if not self.shouldRedraw then
        self.shouldRedraw = true
    end
end
function GFXElement:queueClear()
    if self.shouldRedraw then
        self.shouldRedraw = false
    end
    self.shouldClear = true
end
function GFXElement:setVisibility(visibility)
    self.isVisible = visibility
end
function GFXElement:toggleVisibility()
    self.isVisible = not self.isVisible
end
function GFXElement:hide()
    self.isVisible = false
end
function GFXElement:show()
    self.isVisible = true
end

return GFXElement