
local pairs = pairs

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

local function updateWidgetMouseControlState(widget, control)
    if control.justPressed and widget.mouseIsInside then
        widget._controlWasPressedInside[control] = true
    end
    if control.justReleased then
        widget._controlWasPressedInside[control] = false
    end
end

return {
    new = function(GUI, x, y, w, h, alpha, blendMode)
        local self = {}

        local _GUI = GUI
        local _x = x
        local _y = y
        local _w = w
        local _h = h
        local _a = alpha
        local _mode = blendMode

        function self.getX() return _x end
        function self.setX(v) _x = v end
        function self.getY() return _y end
        function self.setY(v) _y = v end
        function self.getWidth() return _w end
        function self.setWidth(v) _w = v end
        function self.getHeight() return _h end
        function self.setHeight(v) _h = v end

        function self.pointIsInside(point)
            local pointX, pointY = point.getX(), point.getY()
            return pointX >= _x and pointX <= _x + _w
               and pointY >= _y and pointY <= _y + _h
        end
        function self.setColor(Color)
            local alpha = Color[4] or 0
            local mode = Color[5] or 0
            gfxSet(Color[1], Color[2], Color[3], alpha, mode)
        end
        function self.setBlendMode(mode) gfx.mode = mode end
        function self.drawRectangle(x, y, w, h, filled)
            x = x + _x
            y = y + _y
            gfxRect(x, y, w, h, filled)
        end
        function self.drawLine(x, y, x2, y2, antiAliased)
            x = x + _x
            y = y + _y
            x2 = x2 + _x
            y2 = y2 + _y
            gfxLine(x, y, x2, y2, antiAliased)
        end
        function self.drawCircle(x, y, r, filled, antiAliased)
            x = x + _x
            y = y + _y
            gfxCircle(x, y, r, filled, antiAliased)
        end
        function self.drawRoundRectangle(x, y, w, h, r, filled, antiAliased)
            x = x + _x
            y = y + _y
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
        function self.setFont(Font)
            local fontName = font.getName()
            local fontSize = font.getSize()
            gfxSetFont(1, fontName, fontSize)
        end
        function self.measureString(str) return gfxMeasureStr(str) end
        function self.drawString(str, x, y, flags, right, bottom)
            x = x + _x
            y = y + _y
            right = right + _x
            bottom = bottom + _y
            gfx.x = x
            gfx.y = y
            if flags then
                gfxDrawStr(str, flags, right, bottom)
            else
                gfxDrawStr(str)
            end
        end

        return self
    end
}

--[[function Widget:controlWasPressedInside(control)
    return self._controlWasPressedInside[control]
end
function Widget:controlJustDragged(control)
    return self._controlWasPressedInside[control] and control.justDragged
end
function Widget:controlJustStartedDragging(control)
    return self._controlWasPressedInside[control] and control.justStartedDragging
end
function Widget:controlJustStoppedDragging(control)
    return self._controlWasPressedInside[control] and control.justStoppedDragging
end
local mousePoint = {}
function Widget:update()
    mousePoint.x, mousePoint.y = mouse.x, mouse.y
    self.mouseIsInside = self:pointIsInside(mousePoint)

    for k, v in pairs(mouseButtons) do updateWidgetMouseControlState(self, v) end
    for k, v in pairs(keyboardModifiers) do updateWidgetMouseControlState(self, v) end
    for k, v in pairs(keyboardKeys) do updateWidgetMouseControlState(self, v) end
end
function Widget:draw() end
function Widget:endUpdate() end]]--