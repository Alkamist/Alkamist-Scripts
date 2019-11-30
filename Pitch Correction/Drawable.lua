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

function Drawable.new(x, y, alpha, blendMode)
    local self = {}

    self.x = x
    self.y = y
    self.alpha = alpha
    self.blendMode = blendMode

    function self:setColor(rOrColor, g, b)
        if type(rOrColor) == "number" then
            gfxSet(rOrColor, g, b, self.alpha, self.blendMode)
        else
            local alpha = rOrColor[4] or self.alpha or 1
            local blendMode = rOrColor[5] or self.blendMode or 0
            gfxSet(rOrColor[1], rOrColor[2], rOrColor[3], alpha, blendMode)
        end
    end
    function self:drawRectangle(x, y, w, h, filled)
        local drawX = self.x + x
        local drawY = self.y + y
        gfxRect(drawX, drawY, w, h, filled)
    end
    function self:drawLine(x, y, x2, y2, antiAliased)
        local drawX = self.x + x
        local drawY = self.y + y
        local drawX2 = self.x + x2
        local drawY2 = self.y + y2
        gfxLine(drawX, drawY, drawX2, drawY2, antiAliased)
    end
    function self:drawCircle(x, y, r, filled, antiAliased)
        local drawX = self.x + x
        local drawY = self.y + y
        gfxCircle(drawX, drawY, r, filled, antiAliased)
    end
    function self:drawString(str, x, y, x2, y2, flags)
        local drawX = self.x + x
        local drawY = self.y + y
        local drawX2 = self.x + x2
        local drawY2 = self.y + y2
        gfx.x = drawX
        gfx.y = drawY
        if flags then
            gfxDrawStr(str, flags, drawX2, drawY2)
        else
            gfxDrawStr(str)
        end
    end
    function self.setFont(fontOrName, fontSize)
        if type(fontOrName) == "string" then
            gfxSetFont(1, fontOrName, fontSize)
        else
            gfxSetFont(1, fontOrName.name, fontOrName.size)
        end
    end
    function self.measureString(str)
        return gfxMeasureStr(str)
    end

    return self
end

return Drawable