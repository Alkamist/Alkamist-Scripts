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

-- x, y, alpha, blendMode
local Drawable = {}

function Drawable:setColor(rOrColor, g, b)
    if type(rOrColor) == "number" then
        gfxSet(rOrColor, g, b, self.alpha, self.blendMode)
    else
        local alpha = rOrColor[4] or self.alpha or 1
        local blendMode = rOrColor[5] or self.blendMode or 0
        gfxSet(rOrColor[1], rOrColor[2], rOrColor[3], alpha, blendMode)
    end
end
function Drawable:drawRectangle(x, y, w, h, filled)
    local drawX = self.x + x
    local drawY = self.y + y
    gfxRect(drawX, drawY, w, h, filled)
end
function Drawable:drawLine(x, y, x2, y2, antiAliased)
    local positionX = self.x
    local positionY = self.y
    local drawX = positionX + x
    local drawY = positionY + y
    local drawX2 = positionX + x2
    local drawY2 = positionY + y2
    gfxLine(drawX, drawY, drawX2, drawY2, antiAliased)
end
function Drawable:drawCircle(x, y, r, filled, antiAliased)
    local drawX = self.x + x
    local drawY = self.y + y
    gfxCircle(drawX, drawY, r, filled, antiAliased)
end
function Drawable:drawString(str, x, y, x2, y2, flags)
    local positionX = self.x
    local positionY = self.y
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