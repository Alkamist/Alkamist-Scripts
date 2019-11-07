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

local Drawable = {}

function Drawable:new(parameters)
    local self = setmetatable({}, { __index = self })
    self:initialize(parameters)
    return self
end
function Drawable:initialize(parameters)
    self:setX(parameters.x or 0)
    self:setY(parameters.y or 0)
    self:setDrawBuffer(parameters.drawBuffer or -1)
end

function self:getX() return self._x end
function self:getY() return self._y end
function self:getDrawBuffer() return self._drawBuffer end

function self:setX(value) self._x = value end
function self:setY(value) self._y = value end
function self:setDrawBuffer(value) self._drawBuffer = value end

function Drawable:setColor(color)
    local mode = color[5] or 0
    gfxSet(color[1], color[2], color[3], color[4], mode)
end
function Drawable:setBlendMode(mode)
    gfx.mode = mode
end
function Drawable:drawRectangle(x, y, w, h, filled)
    local x = x + self:getX()
    local y = y + self:getY()
    gfx.dest = self:getDrawBuffer()
    gfxRect(x, y, w, h, filled)
end
function Drawable:drawLine(x, y, x2, y2, antiAliased)
    local _x = self:getX()
    local _y = self:getY()
    local x = x + _x
    local y = y + _y
    local x2 = x2 + _x
    local y2 = y2 + _y
    gfx.dest = self:getDrawBuffer()
    gfxLine(x, y, x2, y2, antiAliased)
end
function Drawable:drawCircle(x, y, r, filled, antiAliased)
    local x = x + self:getX()
    local y = y + self:getY()
    gfx.dest = self:getDrawBuffer()
    gfxCircle(x, y, r, filled, antiAliased)
end
function Drawable:drawPolygon(filled, ...)
    gfx.dest = self:getDrawBuffer()
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
end
function Drawable:drawRoundRectangle(x, y, w, h, r, filled, antiAliased)
    local x = x + self:getX()
    local y = y + self:getY()
    gfx.dest = self:getDrawBuffer()
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
end
function Drawable:setFont(font, size, flags)
    gfxSetFont(1, font, size)
end
function Drawable:measureString(str)
    return gfxMeasureStr(str)
end
function Drawable:drawString(str, x, y, flags, right, bottom)
    local x = x + self:getX()
    local y = y + self:getY()
    local right = right + self:getX()
    local bottom = bottom + self:getY()
    gfx.dest = self:getDrawBuffer()
    gfx.x = x
    gfx.y = y
    if flags then
        gfxDrawStr(str, flags, right, bottom)
    else
        gfxDrawStr(str)
    end
end

return Drawable