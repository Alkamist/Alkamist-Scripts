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

local Graphics = {}

function Graphics:new(object)
    local object = object or {}
    local defaults = {
        x = 0,
        y = 0,
        alpha = 1,
        blendMode = 0
    }

    for k, v in pairs(defaults) do if object[k] == nil then object[k] = v end end
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    return object
end

function Graphics:setColor(rOrColor, g, b)
    if type(rOrColor) == "number" then
        gfxSet(rOrColor, g, b, self.alpha, self.blendMode)
    else
        local alpha = rOrColor[4] or self.alpha or 1
        local blendMode = rOrColor[5] or self.blendMode or 0
        gfxSet(rOrColor[1], rOrColor[2], rOrColor[3], alpha, blendMode)
    end
end
function Graphics:drawRectangle(x, y, w, h, filled)
    local drawX = self.x + x
    local drawY = self.y + y
    gfxRect(drawX, drawY, w, h, filled)
end
function Graphics:drawLine(x, y, x2, y2, antiAliased)
    local positionX = self.x
    local positionY = self.y
    local drawX = positionX + x
    local drawY = positionY + y
    local drawX2 = positionX + x2
    local drawY2 = positionY + y2
    gfxLine(drawX, drawY, drawX2, drawY2, antiAliased)
end
function Graphics:drawCircle(x, y, r, filled, antiAliased)
    local drawX = self.x + x
    local drawY = self.y + y
    gfxCircle(drawX, drawY, r, filled, antiAliased)
end
function Graphics:drawString(str, x, y, x2, y2, flags)
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
function Graphics:setFont(fontOrName, fontSize)
    if type(fontOrName) == "string" then
        gfxSetFont(1, fontOrName, fontSize)
    else
        gfxSetFont(1, fontOrName.name, fontOrName.size)
    end
end
function Graphics:measureString(str)
    return gfxMeasureStr(str)
end

return Graphics