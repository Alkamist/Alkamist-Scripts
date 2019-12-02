local type = type

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

function Drawable:new()
    local self = self or {}
    for k, v in pairs(Drawable) do if self[k] == nil then self[k] = v end end
    return self
end

function Drawable:getX() end
function Drawable:getY() end
function Drawable:getAlpha() end
function Drawable:getBlendMode() end

function Drawable:setColor(rOrColor, g, b)
    if type(rOrColor) == "number" then
        gfxSet(rOrColor, g, b, self:getAlpha(), self:getBlendMode())
    else
        local alpha = rOrColor[4] or self:getAlpha() or 1
        local blendMode = rOrColor[5] or self:getBlendMode() or 0
        gfxSet(rOrColor[1], rOrColor[2], rOrColor[3], alpha, blendMode)
    end
end
function Drawable:drawRectangle(x, y, w, h, filled)
    local drawX = self:getX() + x
    local drawY = self:getY() + y
    gfxRect(drawX, drawY, w, h, filled)
end
function Drawable:drawLine(x, y, x2, y2, antiAliased)
    local positionX = self:getX()
    local positionY = self:getY()
    local drawX = positionX + x
    local drawY = positionY + y
    local drawX2 = positionX + x2
    local drawY2 = positionY + y2
    gfxLine(drawX, drawY, drawX2, drawY2, antiAliased)
end
function Drawable:drawCircle(x, y, r, filled, antiAliased)
    local drawX = self:getX() + x
    local drawY = self:getY() + y
    gfxCircle(drawX, drawY, r, filled, antiAliased)
end
function Drawable:drawString(str, x, y, x2, y2, flags)
    local positionX = self:getX()
    local positionY = self:getY()
    local drawX = positionX + x
    local drawY = positionY + y
    local drawX2 = positionX + x2
    local drawY2 = positionY + y2
    gfx.x = drawX
    gfx.y = drawY
    if flags then
        gfxDrawStr(str, flags, drawX2, drawY2)
    else
        gfxDrawStr(str)
    end
end
function Drawable:setFont(fontOrName, fontSize)
    if type(fontOrName) == "string" then
        gfxSetFont(1, fontOrName, fontSize)
    else
        gfxSetFont(1, fontOrName.name, fontOrName.size)
    end
end
function Drawable:measureString(str)
    return gfxMeasureStr(str)
end

return Drawable