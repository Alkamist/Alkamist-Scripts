local reaper = reaper
local math = math
local table = table
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
local Toggle = require("GUI.Toggle")

local Widget = {}
function Widget:new(parameters)
    local parameters = parameters or {}
    local self = parameters.fromObject or {}

    local _x = parameters.x or 0
    local _y = parameters.y or 0
    local _width = parameters.width or 0
    local _height = parameters.height or 0
    local _childWidgets = {}
    local _shouldDrawDirectly = parameters.shouldDrawDirectly
    local _shouldRedraw = true
    local _shouldClear = false
    local _visibilityState = Toggle:new{ state = true, previousState = true }
    local _parentWidget = nil
    local _drawBuffer = -1
    local _keyboard = GUI:getKeyboard()
    local _mouse = GUI:getMouse()

    function self:getGUI() return GUI end
    function self:getKeyboard() return _keyboard end
    function self:getMouse() return _mouse end
    function self:getParentWidget() return _parentWidget end
    function self:setParentWidget(value) _parentWidget = value end
    function self:getChildWidgets() return _childWidgets end
    function self:setChildWidgets(value)
        _childWidgets = value
        for i = 1, #_childWidgets do
            _childWidgets[i]:setParentWidget(self)
        end
    end
    function self:getX() return _x end
    function self:setX(value) _x = value end
    function self:getY() return _y end
    function self:setY(value) _y = value end
    function self:getWidth() return _width end
    function self:setWidth(value) _width = value end
    function self:getHeight() return _height end
    function self:setHeight(value) _height = value end
    function self:getAbsoluteX()
        local parentWidget = _parentWidget
        local absolute = _x
        while true do
            if parentWidget then
                absolute = absolute + parentWidget:getX()
                parentWidget = parentWidget:getParentWidget()
            else break end
        end
        return absolute
    end
    function self:setAbsoluteX(value)
        local parentWidget = _parentWidget
        local relative = value
        while true do
            if parentWidget then
                relative = relative - parentWidget:getX()
                parentWidget = parentWidget:getParentWidget()
            else break end
        end
        self:setX(relative)
    end
    function self:getAbsoluteY()
        local parentWidget = _parentWidget
        local absolute = _y
        while true do
            if parentWidget then
                absolute = absolute + parentWidget:getY()
                parentWidget = parentWidget:getParentWidget()
            else break end
        end
        return absolute
    end
    function self:setAbsoluteY(value)
        local parentWidget = _parentWidget
        local relative = value
        while true do
            if parentWidget then
                relative = relative - parentWidget:getY()
                parentWidget = parentWidget:getParentWidget()
            else break end
        end
        self:setY(relative)
    end
    function self:getRelativeMouseX() return _mouse:getX() - self:getAbsoluteX() end
    function self:getRelativeMouseY() return _mouse:getY() - self:getAbsoluteY() end
    function self:isVisible() return _visibilityState:getState() end
    function self:setVisibility(value) _visibilityState:setState(value) end
    function self:toggleVisibility() _visibilityState:toggle() end
    function self:hide() _visibilityState:setState(false) end
    function self:show() _visibilityState:setState(true) end
    function self:queueRedraw() _shouldRedraw = true end
    function self:queueClear() _shouldClear = true end
    function self:pointIsInside(pointX, pointY)
        local x = self:getAbsoluteX()
        local y = self:getAbsoluteY()
        local width = _width
        local height = _height
        local parentWidget = _parentWidget
        local isInsideParent = true
        if parentWidget and not parentWidget:pointIsInside(pointX, pointY) then
            isInsideParent = false
        end
        if pointX and pointY then
            return isInsideParent
               and pointX >= x and pointX <= x + width
               and pointY >= y and pointY <= y + height
        end
    end
    function self:clearBuffer()
        local drawBuffer = _drawBuffer
        local width = _width
        local height = _height
        gfx.setimgdim(drawBuffer, -1, -1)
        gfx.setimgdim(drawBuffer, width, height)
    end
    function self:setColor(color)
        local mode = color[5] or 0
        gfxSet(color[1], color[2], color[3], color[4], mode)
    end
    function self:setBlendMode(mode) gfx.mode = mode end
    function self:drawRectangle(x, y, w, h, filled)
        if _shouldDrawDirectly then
            x = x + _x
            y = y + _y
        end
        gfxRect(x, y, w, h, filled)
    end
    function self:drawLine(x, y, x2, y2, antiAliased)
        if _shouldDrawDirectly then
            x = x + _x
            y = y + _y
            x2 = x2 + _x
            y2 = y2 + _y
        end
        gfxLine(x, y, x2, y2, antiAliased)
    end
    function self:drawCircle(x, y, r, filled, antiAliased)
        if _shouldDrawDirectly then
            x = x + _x
            y = y + _y
        end
        gfxCircle(x, y, r, filled, antiAliased)
    end
    --[[function self:drawPolygon(filled, ...)
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
    function self:drawRoundRectangle(x, y, w, h, r, filled, antiAliased)
        if _shouldDrawDirectly then
            x = x + _x
            y = y + _y
        end
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
    function self:setFont(font, size, flags) gfxSetFont(1, font, size) end
    function self:measureString(str) return gfxMeasureStr(str) end
    function self:drawString(str, x, y, flags, right, bottom)
        if _shouldDrawDirectly then
            x = x + _x
            y = y + _y
            right = right + _x
            bottom = bottom + _y
        end
        gfx.x = x
        gfx.y = y
        if flags then
            gfxDrawStr(str, flags, right, bottom)
        else
            gfxDrawStr(str)
        end
    end

    function self:doBeginUpdate()
        local childWidgets = _childWidgets
        if childWidgets then
            for i = 1, #childWidgets do
                childWidgets[i]:doBeginUpdate()
            end
        end

        _visibilityState:update()
        if self.beginUpdate then self:beginUpdate() end
    end
    function self:doUpdate()
        local childWidgets = _childWidgets
        if childWidgets then
            for i = 1, #childWidgets do
                childWidgets[i]:doUpdate()
            end
        end

        local char = _keyboard:getCurrentCharacter()
        local keyPressFunctions = self.keyPressFunctions
        if type(keyPressFunctions) == "table" then
            local keyPressFunction = keyPressFunctions[char]
            if keyPressFunction then keyPressFunction(self) end
        end
        if self.update then self:update() end
    end
    function self:doDrawToBuffer()
        local childWidgets = _childWidgets
        if childWidgets then
            for i = 1, #childWidgets do
                childWidgets[i]:doDrawToBuffer()
            end
        end

        if not _shouldDrawDirectly then
            if _shouldRedraw and self.draw then
                self:clearBuffer()
                gfx.a = 1.0
                gfx.mode = 0
                gfx.dest = _drawBuffer
                self:draw()
                _shouldRedraw = false
            elseif _shouldClear then
                self:clearBuffer()
                _shouldClear = false
            end
        end
    end
    function self:doDrawToParent()
        if self:isVisible() then
            local childWidgets = _childWidgets
            if childWidgets then
                for i = 1, #childWidgets do
                    childWidgets[i]:doDrawToParent()
                end
            end

            local parentWidget = _parentWidget
            if parentWidget then
                gfx.dest = parentWidget:getDrawBuffer()
            else
                gfx.dest = -1
            end
            gfx.a = 1.0
            gfx.mode = 0
            if self.draw then
                if _shouldDrawDirectly then
                    self:draw()
                else
                    local x = _x
                    local y = _y
                    local width = _width
                    local height = _height
                    gfx.blit(_drawBuffer, 1.0, 0, 0, 0, width, height, x, y, width, height, 0, 0)
                end
            end
        end
    end
    function self:doEndUpdate()
        local childWidgets = _childWidgets
        if childWidgets then
            for i = 1, #childWidgets do
                childWidgets[i]:doEndUpdate()
            end
        end

        if self.endUpdate then self:endUpdate() end
    end

    if not _shouldDrawDirectly then
        _drawBuffer = GUI:getNewDrawBuffer()
    end
    return self
end

return Widget