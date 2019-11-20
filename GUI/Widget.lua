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

local Widget = {}
function Widget:new(parameters)
    local parameters = parameters or {}
    local self = setmetatable({}, { __index = self })

    if parameters.isVisible == nil then parameters.isVisible = true end
    if parameters.shouldRedraw == nil then parameters.shouldRedraw = true end

    self._visibilityState = parameters.isVisible
    self._previousVisibilityState = parameters.isVisible

    self:setX(parameters.x or 0)
    self:setY(parameters.y or 0)
    self:setWidth(parameters.width or 0)
    self:setHeight(parameters.height or 0)
    self:setShouldDrawDirectly(parameters.shouldDrawDirectly)
    self:setChildWidgets(parameters.childWidgets)
    self:setShouldRedraw(parameters.shouldRedraw)
    self:setShouldClear(parameters.shouldClear)
    self:setParentWidget(parameters.parentWidget)
    self:setPreviousRelativeMouseX(0)
    self:setPreviousRelativeMouseY(0)

    if self:shouldDrawDirectly() then
        local parentWidget = self:getParentWidget()
        if parentWidget then
            self:setDrawBuffer(parentWidget:getDrawBuffer())
        else
            self:setDrawBuffer(-1)
        end
    else
        self:setDrawBuffer(self:getGUI():getNewDrawBuffer())
    end
    return self
end

function Widget:getGUI() return GUI end
function Widget:getX() return self._x end
function Widget:setX(value) self._x = value end
function Widget:getY() return self._y end
function Widget:setY(value) self._y = value end
function Widget:getWidth() return self._width end
function Widget:setWidth(value) self._width = value end
function Widget:getHeight() return self._height end
function Widget:setHeight(value) self._height = value end
function Widget:getDrawBuffer() return self._drawBuffer end
function Widget:setDrawBuffer(value) self._drawBuffer = value end
function Widget:getParentWidget() return self._parentWidget end
function Widget:setParentWidget(value) self._parentWidget = value end
function Widget:getPreviousRelativeMouseX() return self._previousRelativeMouseX end
function Widget:setPreviousRelativeMouseX(value) self._previousRelativeMouseX = value end
function Widget:getPreviousRelativeMouseY() return self._previousRelativeMouseY end
function Widget:setPreviousRelativeMouseY(value) self._previousRelativeMouseY = value end
function Widget:isVisible() return self._visibilityState end
function Widget:setVisibility(value) self._visibilityState = value end
function Widget:toggleVisibility() self._visibilityState = not self._visibilityState end
function Widget:queueRedraw() self._shouldRedraw = true end
function Widget:queueClear() self._shouldClear = true end
function Widget:shouldDrawDirectly() return self._shouldDrawDirectly end
function Widget:setShouldDrawDirectly(value) self._shouldDrawDirectly = value end
function Widget:shouldRedraw() return self._shouldRedraw end
function Widget:setShouldRedraw(value) self._shouldRedraw = value end
function Widget:shouldClear() return self._shouldClear end
function Widget:setShouldClear(value) self._shouldClear = value end
function Widget:getChildWidgets() return self._childWidgets end
function Widget:setChildWidgets(value)
    local value = value or {}
    self._childWidgets = value
    for i = 1, #self._childWidgets do
        self._childWidgets[i]:setParentWidget(self)
    end
end

Widget.getMouse = GUI.getMouse
function Widget:getRelativeMouseX() return self:getMouse():getX() - self:getAbsoluteX() end
function Widget:getRelativeMouseY() return self:getMouse():getY() - self:getAbsoluteY() end
Widget.getKeyboard = GUI.getKeyboard

function Widget:getAbsoluteX()
    local parentWidget = self:getParentWidget()
    local absolute = self:getX()
    while true do
        if parentWidget then
            absolute = absolute + parentWidget:getX()
            parentWidget = parentWidget:getParentWidget()
        else break end
    end
    return absolute
end
function Widget:setAbsoluteX(value)
    local parentWidget = self:getParentWidget()
    local relative = value
    while true do
        if parentWidget then
            relative = relative - parentWidget:getX()
            parentWidget = parentWidget:getParentWidget()
        else break end
    end
    self:setX(relative)
end
function Widget:getAbsoluteY()
    local parentWidget = self:getParentWidget()
    local absolute = self:getY()
    while true do
        if parentWidget then
            absolute = absolute + parentWidget:getY()
            parentWidget = parentWidget:getParentWidget()
        else break end
    end
    return absolute
end
function Widget:setAbsoluteY(value)
    local parentWidget = self:getParentWidget()
    local relative = value
    while true do
        if parentWidget then
            relative = relative - parentWidget:getY()
            parentWidget = parentWidget:getParentWidget()
        else break end
    end
    self:setY(relative)
end
function Widget:hide() self:setVisibility(false) end
function Widget:show() self:setVisibility(true) end
function Widget:pointIsInside(pointX, pointY)
    local x = self:getAbsoluteX()
    local y = self:getAbsoluteY()
    local width = self:getWidth()
    local height = self:getHeight()
    local parentWidget = self:getParentWidget()
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
function Widget:clearBuffer()
    local drawBuffer = self:getDrawBuffer()
    local width = self:getWidth()
    local height = self:getHeight()
    gfx.setimgdim(drawBuffer, -1, -1)
    gfx.setimgdim(drawBuffer, width, height)
end
function Widget:setColor(color)
    local mode = color[5] or 0
    gfxSet(color[1], color[2], color[3], color[4], mode)
end
function Widget:setBlendMode(mode) gfx.mode = mode end
function Widget:drawRectangle(x, y, w, h, filled)
    if _shouldDrawDirectly then
        x = x + self:getX()
        y = y + self:getY()
    end
    gfxRect(x, y, w, h, filled)
end
function Widget:drawLine(x, y, x2, y2, antiAliased)
    if self:shouldDrawDirectly() then
        x = x + self:getX()
        y = y + self:getY()
        x2 = x2 + self:getX()
        y2 = y2 + self:getY()
    end
    gfxLine(x, y, x2, y2, antiAliased)
end
function Widget:drawCircle(x, y, r, filled, antiAliased)
    if self:shouldDrawDirectly() then
        x = x + self:getX()
        y = y + self:getY()
    end
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
    if self:shouldDrawDirectly() then
        x = x + self:getX()
        y = y + self:getY()
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
function Widget:setFont(font, size, flags) gfxSetFont(1, font, size) end
function Widget:measureString(str) return gfxMeasureStr(str) end
function Widget:drawString(str, x, y, flags, right, bottom)
    if self:shouldDrawDirectly() then
        x = x + self:getX()
        y = y + self:getY()
        right = right + self:getX()
        bottom = bottom + self:getY()
    end
    gfx.x = x
    gfx.y = y
    if flags then
        gfxDrawStr(str, flags, right, bottom)
    else
        gfxDrawStr(str)
    end
end

function Widget:doBeginUpdate()
    local childWidgets = self:getChildWidgets()
    if childWidgets then
        for i = 1, #childWidgets do
            childWidgets[i]:doBeginUpdate()
        end
    end

    self:setPreviousRelativeMouseX(self:getRelativeMouseX())
    self:setPreviousRelativeMouseY(self:getRelativeMouseY())
    self._previousVisibilityState = self._visibilityState
    if self.beginUpdate then self:beginUpdate() end
end
function Widget:doUpdate()
    local childWidgets = self:getChildWidgets()
    if childWidgets then
        for i = 1, #childWidgets do
            childWidgets[i]:doUpdate()
        end
    end

    if self.getKeyPressFunctions then
        local char = self:getKeyboard():getCurrentCharacter()
        local keyPressFunctions = self:getKeyPressFunctions()
        if type(keyPressFunctions) == "table" then
            local keyPressFunction = keyPressFunctions[char]
            if keyPressFunction then keyPressFunction(self) end
        end
    end

    if self.update then self:update() end
end
function Widget:doDrawToBuffer()
    local childWidgets = self:getChildWidgets()
    if childWidgets then
        for i = 1, #childWidgets do
            childWidgets[i]:doDrawToBuffer()
        end
    end

    if not self:shouldDrawDirectly() then
        if self:shouldRedraw() and self.draw then
            self:clearBuffer()
            gfx.a = 1.0
            gfx.mode = 0
            gfx.dest = self:getDrawBuffer()
            self:draw()
            self:setShouldRedraw(false)
        elseif self:shouldClear() then
            self:clearBuffer()
            self:setShouldClear(false)
        end
    end
end
function Widget:doDrawToParent()
    if self:isVisible() then
        local childWidgets = self:getChildWidgets()
        if childWidgets then
            for i = 1, #childWidgets do
                childWidgets[i]:doDrawToParent()
            end
        end

        local parentWidget = self:getParentWidget()
        if parentWidget then
            gfx.dest = parentWidget:getDrawBuffer()
        else
            gfx.dest = -1
        end
        gfx.a = 1.0
        gfx.mode = 0
        if self.draw then
            if self:shouldDrawDirectly() then
                self:draw()
            else
                local x = self:getX()
                local y = self:getY()
                local width = self:getWidth()
                local height = self:getHeight()
                gfx.blit(self:getDrawBuffer(), 1.0, 0, 0, 0, width, height, x, y, width, height, 0, 0)
            end
        end
    end
end
function Widget:doEndUpdate()
    local childWidgets = self:getChildWidgets()
    if childWidgets then
        for i = 1, #childWidgets do
            childWidgets[i]:doEndUpdate()
        end
    end

    if self.endUpdate then self:endUpdate() end
end

return Widget