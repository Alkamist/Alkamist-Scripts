local reaper = reaper
local gfx = gfx
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Prototype = require("Prototype")
local TrackedNumber = require("GFX.TrackedNumber")

local GFXElement = {
    GFX = nil,
    mouse = nil,
    keyboard = nil,
    parent = nil,
    elements = {},
    drawBuffer = -1,
    x = 0,
    absoluteX = 0,
    y = 0,
    absoluteY = 0,
    w = 0,
    h = 0,
    xTracker = TrackedNumber:new(),
    yTracker = TrackedNumber:new(),
    wTracker = TrackedNumber:new(),
    hTracker = TrackedNumber:new(),
    relativeMouseX = 0,
    relativeMouseY = 0,
    isVisible = true,
    shouldRedraw = true,
    shouldClear = false,
    drewThisFrame = false,
    buttonWasPressedInside = {}
}

function GFXElement:getElements()
    return self.elements or {}
end
function GFXElement:addElements(elements)
    for i = 1, #elements do
        local element = elements[i]
        GFXElement.initializeElement(element, {
            GFX = self.GFX,
            parent = self
        })
        self.elements[#self.elements + 1] = element
    end
end

function GFXElement:initializeElement(parameters)
    Prototype.addPrototypes(self, { GFXElement })

    self.GFX = parameters.GFX
    self.mouse = self.GFX.mouse
    self.keyboard = self.GFX.keyboard
    self.parent = parameters.parent
    if self.parent then
        self.drawBuffer = self.parent.drawBuffer
    else
        self.drawBuffer = self.GFX:getNewDrawBuffer()
    end

    if self.initialize then self:initialize() end
end
function GFXElement:updateElementStates()
    local elements = self:getElements()

    local mouse = self.mouse
    local keyboard = self.keyboard

    self.drewThisFrame = false

    self.xTracker:update(self.x)
    self.yTracker:update(self.y)
    self.wTracker:update(self.w)
    self.hTracker:update(self.h)

    self.relativeMouseX = mouse.x - self.x
    self.relativeMouseY = mouse.y - self.y

    if self.parent then
        self.absoluteX = self.x + self.parent.absoluteX
        self.absoluteY = self.y + self.parent.absoluteY
    else
        self.absoluteX = self.x
        self.absoluteY = self.y
    end

    for name, button in pairs(mouse.buttons) do self:updateDragState(button) end
    for name, button in pairs(keyboard.modifiers) do self:updateDragState(button) end
    for name, button in pairs(keyboard.keys) do self:updateDragState(button) end

    for i = 1, #elements do
        elements[i]:updateElementStates()
    end
    if self.updateStates then self:updateStates() end
end
function GFXElement:updateElement()
    local elements = self:getElements()

    for i = 1, #elements do
        elements[i]:updateElement()
    end
    if self.update then self:update() end
end
function GFXElement:drawElement()
    local elements = self:getElements()

    gfx.a = 1.0
    gfx.mode = 0

    if self.draw then
        local shouldDrawDirectly = self:shouldDrawDirectly()
        if self.parent and self.parent.drewThisFrame and shouldDrawDirectly then
            self.shouldRedraw = true
        end
        if self.shouldRedraw then
            if shouldDrawDirectly then
                if not self.parent.drewThisFrame then
                    gfx.dest = self.parent.drawBuffer
                    self.parent:draw()
                    self.parent.drewThisFrame = true
                end
            else
                self:clearBuffer()
            end
            gfx.dest = self.drawBuffer
            self:draw()
            self.shouldRedraw = false
            self.drewThisFrame = true

        elseif self.shouldClear then
            self:clearBuffer()
            self.shouldClear = false
        end
    end

    for i = 1, #elements do
        elements[i]:drawElement()
    end
end
function GFXElement:blitElement()
    local elements = self:getElements()

    if self.isVisible then
        gfx.a = 1.0
        gfx.mode = 0
        gfx.dest = -1

        if not self:shouldDrawDirectly() then
            gfx.blit(self.drawBuffer, 1.0, 0, 0, 0, self.w, self.h, self.absoluteX, self.absoluteY, self.w, self.h, 0, 0)
        end
    end

    for i = 1, #elements do
        elements[i]:blitElement()
    end
end

function GFXElement:updateDragState(button)
    if button.releaseState.previous then
        self.buttonWasPressedInside[button] = false
    end
    if button:justPressed(self) then
        self.buttonWasPressedInside[button] = true
    end
end
function GFXElement:windowWasResized()
    return self.GFX:windowWasResized()
end
function GFXElement:absolutePointIsInside(x, y)
    return self.isVisible
       and x >= self.absoluteX and x <= self.absoluteX + self.w
       and y >= self.absoluteY and y <= self.absoluteY + self.h
end
function GFXElement:pointIsInside(x, y)
    return self.isVisible
       and x >= self.x and x <= self.x + self.w
       and y >= self.y and y <= self.y + self.h
end
function GFXElement:clearBuffer(buffer)
    local buffer = buffer or self.drawBuffer
    gfx.setimgdim(buffer, -1, -1)
    gfx.setimgdim(buffer, self.w, self.h)
end
function GFXElement:queueRedraw()
    if self:shouldDrawDirectly() then
        self.parent:queueRedraw()
    end
    if not self.shouldRedraw then
        self.shouldRedraw = true
    end
end
function GFXElement:queueClear()
    if self.shouldRedraw then
        self.shouldRedraw = false
    end
    self.shouldClear = true
end
function GFXElement:setVisibility(visibility)
    self.isVisible = visibility
end
function GFXElement:toggleVisibility()
    self.isVisible = not self.isVisible
end
function GFXElement:hide()
    self.isVisible = false
end
function GFXElement:show()
    self.isVisible = true
end

function GFXElement:setColor(color)
    self.currentColor = color
    local mode = color[5] or 0
    gfx.set(color[1], color[2], color[3], color[4], mode)
end
function GFXElement:setBlendMode(mode)
    gfx.mode = mode
end
function GFXElement:shouldDrawDirectly()
    return self.parent and self.drawBuffer == self.parent.drawBuffer
end
function GFXElement:drawRectangle(x, y, w, h, filled)
    local x = x
    local y = y
    if self:shouldDrawDirectly() then
        x = x + self.x
        y = y + self.y
    end
    gfx.rect(x, y, w, h, filled)
end
function GFXElement:drawLine(x, y, x2, y2, antiAliased)
    local x = x
    local y = y
    if self:shouldDrawDirectly() then
        x = x + self.x
        y = y + self.y
    end
    gfx.line(x, y, x2, y2, antiAliased)
end
function GFXElement:drawCircle(x, y, r, filled, antiAliased)
    local x = x
    local y = y
    if self:shouldDrawDirectly() then
        x = x + self.x
        y = y + self.y
    end
    gfx.circle(x, y, r, filled, antiAliased)
end
function GFXElement:drawPolygon(filled, ...)
    if filled then
        gfx.triangle(...)
    else
        local coords = {...}

        -- Duplicate the first pair at the end, so the last line will
        -- be drawn back to the starting point.
        table.insert(coords, coords[1])
        table.insert(coords, coords[2])

        -- Draw a line from each pair of coords to the next pair.
        for i = 1, #coords - 2, 2 do
            gfx.line(coords[i], coords[i+1], coords[i+2], coords[i+3])
        end
    end
end
function GFXElement:drawRoundRectangle(x, y, w, h, r, filled, antiAliased)
    local x = x
    local y = y
    if self:shouldDrawDirectly() then
        x = x + self.x
        y = y + self.y
    end
    local aa = antiAliased or 1
    filled = filled or 0
    w = math.max(0, w - 1)
    h = math.max(0, h - 1)

    if filled == 0 or false then
        gfx.roundrect(x, y, w, h, r, aa)
    else
        if h >= 2 * r then
            -- Corners
            gfx.circle(x + r, y + r, r, 1, aa)			-- top-left
            gfx.circle(x + w - r, y + r, r, 1, aa)		-- top-right
            gfx.circle(x + w - r, y + h - r, r , 1, aa) -- bottom-right
            gfx.circle(x + r, y + h - r, r, 1, aa)		-- bottom-left

            -- Ends
            gfx.rect(x, y + r, r, h - r * 2)
            gfx.rect(x + w - r, y + r, r + 1, h - r * 2)

            -- Body + sides
            gfx.rect(x + r, y, w - r * 2, h + 1)
        else
            r = (h / 2 - 1)

            -- Ends
            gfx.circle(x + r, y + r, r, 1, aa)
            gfx.circle(x + w - r, y + r, r, 1, aa)

            -- Body
            gfx.rect(x + r, y, w - (r * 2), h)
        end
    end
end
function GFXElement:setFont(font, size, flags)
    gfx.setfont(1, font, size)
end
function GFXElement:measureString(str)
    return gfx.measurestr(str)
end
function GFXElement:drawString(str, x, y, flags, right, bottom)
    local x = x
    local y = y
    local right = right
    local bottom = bottom
    if self:shouldDrawDirectly() then
        x = x + self.x
        y = y + self.y
        right = right + self.x
        bottom = bottom + self.y
    end
    gfx.x = x
    gfx.y = y
    if flags then
        gfx.drawstr(str, flags, right, bottom)
    else
        gfx.drawstr(str)
    end
end

return GFXElement