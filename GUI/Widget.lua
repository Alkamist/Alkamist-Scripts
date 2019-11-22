local reaper = reaper
local math = math
local table = table
local type = type
local pairs = pairs
local ipairs = ipairs
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
local Proxy = require("Proxy")
local GUI = require("GUI.AlkamistGUI")

local function generateAbsoluteCoordinateGetterAndSetter(coordinateName)
    return {
        get = function(self)
            local parentWidget = self.parentWidget
            local absolute = self[coordinateName]
            while true do
                if parentWidget then
                    absolute = absolute + parentWidget[coordinateName]
                    parentWidget = parentWidget.parentWidget
                else break end
            end
            return absolute
        end,
        set = function(self, value)
            local parentWidget = self.parentWidget
            local relative = value
            while true do
                if parentWidget then
                    relative = relative - parentWidget[coordinateName]
                    parentWidget = parentWidget.parentWidget
                else break end
            end
            self[coordinateName] = relative
        end
    }
end

local Widget = {}
function Widget:new(object)
    local self = Proxy:new(self)

    self.GUI = GUI
    self.x = 0
    self.y = 0
    self.absoluteX = generateAbsoluteCoordinateGetterAndSetter("x")
    self.absoluteY = generateAbsoluteCoordinateGetterAndSetter("y")
    self.drawX = { get = function(self) return self.absoluteX end }
    self.drawY = { get = function(self) return self.absoluteY end }
    self.width = 0
    self.height = 0
    self.drawBuffer = -1
    self.isVisible = true
    self.shouldRedraw = true
    self.shouldClear = false
    self.previousRelativeMouseX = 0
    self.previousRelativeMouseY = 0
    self.relativeMouseX = { get = function(self) return self.GUI.mouseX - self.absoluteX end }
    self.relativeMouseY = { get = function(self) return self.GUI.mouseY - self.absoluteY end }
    self.parentWidget = nil
    self.childWidgets = {
        value = {},
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            if type(value) ~= "table" then return end
            for _, widget in ipairs(value) do
                widget.parentWidget = self
            end
            field.value = value
        end
    }

    if object then for k, v in pairs(object) do self[k] = v end end
    return self
end

function Widget:queueRedraw() self.shouldRedraw = true end
function Widget:queueClear() self.shouldClear = true end
function Widget:hide() self.isVisible = false end
function Widget:show() self.isVisible = true end
function Widget:absolutePointIsInside(pointX, pointY)
    local parentWidget = self.parentWidget
    local isInsideParent = true
    if parentWidget and not parentWidget:absolutePointIsInside(pointX, pointY) then
        isInsideParent = false
    end
    if pointX and pointY then
        local absoluteX = self.absoluteX
        local absoluteY = self.absoluteY
        return isInsideParent
            and pointX >= absoluteX and pointX <= absoluteX + self.width
            and pointY >= absoluteY and pointY <= absoluteY + self.height
    end
end
function Widget:relativePointIsInside(pointX, pointY)
    local parentWidget = self.parentWidget
    local isInsideParent = true
    if parentWidget and not parentWidget:relativePointIsInside(pointX + self.x, pointY + self.y) then
        isInsideParent = false
    end
    if pointX and pointY then
        return isInsideParent
            and pointX >= 0 and pointX <= self.width
            and pointY >= 0 and pointY <= self.height
    end
end
function Widget:clearBuffer()
    local drawBuffer = self.drawBuffer
    local width = self.width
    local height = self.height
    gfx.setimgdim(drawBuffer, -1, -1)
    gfx.setimgdim(drawBuffer, width, height)
end
function Widget:setColor(color)
    local mode = color[5] or 0
    gfxSet(color[1], color[2], color[3], color[4], mode)
end
function Widget:setBlendMode(mode) gfx.mode = mode end
function Widget:drawRectangle(x, y, w, h, filled)
    x = x + self.drawX
    y = y + self.drawY
    gfxRect(x, y, w, h, filled)
end
function Widget:drawLine(x, y, x2, y2, antiAliased)
    x = x + self.drawX
    y = y + self.drawY
    x2 = x2 + self.drawX
    y2 = y2 + self.drawY
    gfxLine(x, y, x2, y2, antiAliased)
end
function Widget:drawCircle(x, y, r, filled, antiAliased)
    x = x + self.drawX
    y = y + self.drawY
    gfxCircle(x, y, r, filled, antiAliased)
end
--[[function Widget:drawPolygon(filled, ...)
    if filled then
        gfxTriangle(...)
    else
        local coords = {...}

        -- Duplicate the first pair at the end, so the last line will
        -- be drawn back to the starting point.
        table.insert(coords, coords[1])
        table.insert(coords, coords[2])

        -- Draw a line from each pair of coords to the next pair.
        for i = 1, #coords - 2, 2 do
            gfxLine(coords[i], coords[i+1], coords[i+2], coords[i+3])
        end
    end
end]]--
function Widget:drawRoundRectangle(x, y, w, h, r, filled, antiAliased)
    x = x + self.drawX
    y = y + self.drawY
    local aa = antiAliased or 1
    filled = filled or 0
    w = math.max(0, w - 1)
    h = math.max(0, h - 1)

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
function Widget:setFont(font, size, flags) gfxSetFont(1, font, size) end
function Widget:measureString(str) return gfxMeasureStr(str) end
function Widget:drawString(str, x, y, flags, right, bottom)
    x = x + self.drawX
    y = y + self.drawY
    right = right + self.drawX
    bottom = bottom + self.drawY
    gfx.x = x
    gfx.y = y
    if flags then
        gfxDrawStr(str, flags, right, bottom)
    else
        gfxDrawStr(str)
    end
end
function Widget:doBeginUpdate()
    local childWidgets = self.childWidgets
    if childWidgets then
        for i = 1, #childWidgets do
            childWidgets[i]:doBeginUpdate()
        end
    end

    if self.beginUpdate then self:beginUpdate() end
end
function Widget:doUpdate()
    local childWidgets = self.childWidgets
    if childWidgets then
        for i = 1, #childWidgets do
            childWidgets[i]:doUpdate()
        end
    end

    local keyPressFunctions = self.keyPressFunctions
    if type(keyPressFunctions) == "table" then
        local char = GUI.currentCharacter
        local keyPressFunction = keyPressFunctions[char]
        if keyPressFunction then keyPressFunction(self) end
    end

    if self.update then self:update() end
end
function Widget:doDraw()
    --if self.shouldRedraw then
        gfx.a = 1.0
        gfx.mode = 0
        gfx.dest = self.drawBuffer
        if self.draw then self:draw() end
        self.shouldRedraw = false
    --end

    local childWidgets = self.childWidgets
    if childWidgets then
        for i = 1, #childWidgets do
            childWidgets[i]:doDraw()
        end
    end
end
function Widget:doEndUpdate()
    local childWidgets = self.childWidgets
    if childWidgets then
        for i = 1, #childWidgets do
            childWidgets[i]:doEndUpdate()
        end
    end

    self.previousRelativeMouseX = self.relativeMouseX
    self.previousRelativeMouseY = self.relativeMouseY
    if self.endUpdate then self:endUpdate() end
end

return Widget