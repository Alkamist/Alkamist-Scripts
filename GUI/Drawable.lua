local math = math
local mathMax = math.max

local table = table
local tableInsert = table.insert

local gfx = gfx
local gfxSet = gfx.set
local gfxRect = gfx.rect
local gfxLine = gfx.line
local gfxCircle = gfx.circle
local gfxTriangle = gfx.triangle
local gfxRoundRect = gfx.roundrect
local gfxSetFont = gfx.setfont
local gfxMeasureStr = gfx.measurestr
local gfxDrawStr = gfx.drawstr

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Prototype = require("Prototype")

return Prototype:new{
    x = 0,
    y = 0,
    drawBuffer = -1,
    clearBuffer = function(self)
        local drawBuffer = self.drawBuffer
        local width = self.width
        local height = self.height
        gfx.setimgdim(drawBuffer, -1, -1)
        gfx.setimgdim(drawBuffer, width, height)
    end,
    setColor = function(self, color)
        local mode = color[5] or 0
        gfxSet(color[1], color[2], color[3], color[4], mode)
    end,
    setBlendMode = function(self, mode)
        gfx.mode = mode
    end,
    drawRectangle = function(self, x, y, w, h, filled)
        local x = x + self.x
        local y = y + self.y
        gfx.dest = self.drawBuffer
        gfxRect(x, y, w, h, filled)
    end,
    drawLine = function(self, x, y, x2, y2, antiAliased)
        local _x = self.x
        local _y = self.y
        local x = x + _x
        local y = y + _y
        local x2 = x2 + _x
        local y2 = y2 + _y
        gfx.dest = self.drawBuffer
        gfxLine(x, y, x2, y2, antiAliased)
    end,
    drawCircle = function(self, x, y, r, filled, antiAliased)
        local x = x + self.x
        local y = y + self.y
        gfx.dest = self.drawBuffer
        gfxCircle(x, y, r, filled, antiAliased)
    end,
    drawPolygon = function(self, filled, ...)
        gfx.dest = self.drawBuffer
        if filled then
            gfxTriangle(...)
        else
            local coords = {...}

            -- Duplicate the first pair at the end, so the last line will
            -- be drawn back to the starting point.
            tableInsert(coords, coords[1])
            tableInsert(coords, coords[2])

            -- Draw a line from each pair of coords to the next pair.
            for i = 1, #coords - 2, 2 do
                gfxLine(coords[i], coords[i+1], coords[i+2], coords[i+3])
            end
        end
    end,
    drawRoundRectangle = function(self, x, y, w, h, r, filled, antiAliased)
        local x = x + self.x
        local y = y + self.y
        gfx.dest = self.drawBuffer
        local aa = antiAliased or 1
        filled = filled or 0
        w = mathMax(0, w - 1)
        h = mathMax(0, h - 1)

        if filled == 0 or false then
            gfxRoundRect(x, y, w, h, r, aa)
        else
            if h >= 2 * r then
                -- Corners
                gfxCircle(x + r, y + r, r, 1, aa)		   -- top-left
                gfxCircle(x + w - r, y + r, r, 1, aa)	   -- top-right
                gfxCircle(x + w - r, y + h - r, r , 1, aa) -- bottom-right
                gfxCircle(x + r, y + h - r, r, 1, aa)	   -- bottom-left

                -- Ends
                gfxRect(x, y + r, r, h - r * 2)
                gfxRect(x + w - r, y + r, r + 1, h - r * 2)

                -- Body + sides
                gfxRect(x + r, y, w - r * 2, h + 1)
            else
                r = (h / 2 - 1)

                -- Ends
                gfxCircle(x + r, y + r, r, 1, aa)
                gfxCircle(x + w - r, y + r, r, 1, aa)

                -- Body
                gfxRect(x + r, y, w - (r * 2), h)
            end
        end
    end,
    setFont = function(self, font, size, flags)
        gfxSetFont(1, font, size)
    end,
    measureString = function(self, str)
        return gfxMeasureStr(str)
    end,
    drawString = function(self, str, x, y, flags, right, bottom)
        local x = x + self.x
        local y = y + self.y
        local right = right + self.x
        local bottom = bottom + self.y
        gfx.dest = self.drawBuffer
        gfx.x = x
        gfx.y = y
        if flags then
            gfxDrawStr(str, flags, right, bottom)
        else
            gfxDrawStr(str)
        end
    end,
}