local reaper = reaper

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
local GUI = require("GUI.AlkamistGUI")
local Proxy = require("Proxy")
local Toggle = require("GUI.Toggle")

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
function Widget:new(initialValues)
    local self = {}

    self.GUI = { get = function(self) return GUI end }
    self.drawBuffer = GUI:getNewDrawBuffer()
    self.relativeMouseX = { get = function(self) return self.GUI.mouse.x - self.absoluteX end }
    self.previousRelativeMouseX = { get = function(self) return self.GUI.mouse.previousX - self.absoluteX end }
    self.relativeMouseY = { get = function(self) return self.GUI.mouse.y - self.absoluteY end }
    self.previousRelativeMouseY = { get = function(self) return self.GUI.mouse.previousY - self.absoluteY end }
    self.keyboard = { get = function(self) return self.GUI.keyboard end }
    self.widgets = {
        value = {},
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            for i = 1, #value do
                value[i].parentWidget = self
            end
            field.value = value
        end
    }
    self.parentWidget = {
        get = function(self, field) return field.value end,
        set = function(self, value, field) field.value = value end
    }
    self.absoluteX = generateAbsoluteCoordinateGetterAndSetter("x")
    self.absoluteY = generateAbsoluteCoordinateGetterAndSetter("y")
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.shouldRedraw = true
    self.shouldClear = false
    self.mouseWasPressedInside = false
    self.visibilityState = Toggle:new{ currentState = true, previousState = true }
    self.isVisible = {
        get = function(self) return self.visibilityState.currentState end,
        set = function(self, value) self.visibilityState.currentState = value end
    }
    function self:pointIsInside(pointX, pointY)
        local x = self.absoluteX
        local y = self.absoluteY
        local width = self.width
        local height = self.height
        local parentWidget = self.parentWidget
        local isInsideParent = true
        if parentWidget and not parentWidget:pointIsInside(pointX, pointY) then
            isInsideParent = false
        end
        return isInsideParent
            and pointX >= x and pointX <= x + width
            and pointY >= y and pointY <= y + height
    end
    function self:clearBuffer()
        local drawBuffer = self.drawBuffer
        local width = self.width
        local height = self.height
        gfx.setimgdim(drawBuffer, -1, -1)
        gfx.setimgdim(drawBuffer, width, height)
    end
    function self:setColor(color)
        local mode = color[5] or 0
        gfxSet(color[1], color[2], color[3], color[4], mode)
    end
    function self:setBlendMode(mode)
        gfx.mode = mode
    end
    function self:drawRectangle(x, y, w, h, filled)
        gfx.dest = self.drawBuffer
        gfxRect(x, y, w, h, filled)
    end
    function self:drawLine(x, y, x2, y2, antiAliased)
        gfx.dest = self.drawBuffer
        gfxLine(x, y, x2, y2, antiAliased)
    end
    function self:drawCircle(x, y, r, filled, antiAliased)
        gfx.dest = self.drawBuffer
        gfxCircle(x, y, r, filled, antiAliased)
    end
    function self:drawPolygon(filled, ...)
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
    end
    function self:drawRoundRectangle(x, y, w, h, r, filled, antiAliased)
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
    end
    function self:setFont(font, size, flags)
        gfxSetFont(1, font, size)
    end
    function self:measureString(str)
        return gfxMeasureStr(str)
    end
    function self:drawString(str, x, y, flags, right, bottom)
        gfx.dest = self.drawBuffer
        gfx.x = x
        gfx.y = y
        if flags then
            gfxDrawStr(str, flags, right, bottom)
        else
            gfxDrawStr(str)
        end
    end
    function self:prepareBeginUpdate()
        self.visibilityState:update()
    end
    function self:prepareUpdate() end
    function self:prepareDraw()
        self:clearBuffer()
    end
    function self:blit()
        if self.isVisible then
            local x = self.x
            local y = self.y
            local width = self.width
            local height = self.height
            gfx.a = 1.0
            gfx.mode = 0
            local parentWidget = self.parentWidget
            if parentWidget then
                gfx.dest = parentWidget.drawBuffer
            else
                gfx.dest = -1
            end
            gfx.blit(self.drawBuffer, 1.0, 0, 0, 0, width, height, x, y, width, height, 0, 0)
        end
    end
    function self:prepareEndUpdate() end
    --doDrawFunction = function(self, drawFunction)
    --    if self.shouldRedraw and drawFunction then
    --        self:clearBuffer()
    --        gfx.a = 1.0
    --        gfx.mode = 0
    --        gfx.dest = self.drawBuffer
    --        drawFunction()
    --        self.shouldRedraw = false
    --    elseif self.shouldClear then
    --        self:clearBuffer()
    --        self.shouldClear = false
    --    end
    --end,

    return Proxy:new(self, initialValues)
end

return Widget