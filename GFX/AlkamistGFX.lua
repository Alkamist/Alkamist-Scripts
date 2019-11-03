local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local UserControl = require("GFX.UserControl")
local TrackedNumber = require("GFX.TrackedNumber")
local GFXElement = require("GFX.GFXElement")

local GFX = {
    title = "",
    backgroundColor = {},
    x = 0,
    y = 0,
    w = 0,
    h = 0,
    wChange = 0,
    hChange = 0,
    wTracker = TrackedNumber:new(),
    hTracker = TrackedNumber:new(),
    elements = {},
    mouse = UserControl.mouse,
    keyboard = UserControl.keyboard
}

function GFX:setBackgroundColor(color)
    self.backgroundColor = color
    gfx.clear = color[1] * 255 + color[2] * 255 * 256 + color[3] * 255 * 65536
end
function GFX:windowWasResized()
    return self.wTracker:justChanged() or self.hTracker:justChanged()
end
local currentBuffer = -1
function GFX:getNewDrawBuffer()
    currentBuffer = currentBuffer + 1
    if currentBuffer > 1023 then currentBuffer = 0 end
    return currentBuffer
end
function GFX:bindElement(element, parent)
    element.GFX = GFX
    element.mouse = GFX.mouse
    element.keyboard = GFX.keyboard
    element.parent = parent
    if parent then
        element.drawBuffer = parent.drawBuffer
    else
        element.drawBuffer = GFX:getNewDrawBuffer()
    end
    GFXElement:new(element)

    local elementsOfElement = element.elements
    if elementsOfElement then
        for i = 1, #elementsOfElement do
            GFX:bindElement(elementsOfElement[i], element)
        end
    end

    return element
end
function GFX:setElements(elements)
    for i = 1, #elements do
        self.elements[#self.elements + 1] = self:bindElement(elements[i])
    end
end
function GFX:initialize(title, x, y, w, h, dock)
    gfx.init(title, w, h, dock, x, y)

    self.title = title
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.wTracker:update(w)
    self.hTracker:update(h)
    self.dock = dock
end
function GFX:updateElement(element)
    GFXElement.updateStates(element)
    if element.update then element:update() end

    local elementsOfElement = element.elements
    if elementsOfElement then
        for i = 1, #elementsOfElement do
            GFX:updateElement(elementsOfElement[i])
        end
    end
end
function GFX:drawElement(element)
    gfx.a = 1.0
    gfx.mode = 0

    if element.draw then
        local shouldDrawDirectly = element:shouldDrawDirectly()
        if element.parent and element.parent.drewThisFrame and shouldDrawDirectly then
            element.shouldRedraw = true
        end
        if element.shouldRedraw then
            if shouldDrawDirectly then
                if not element.parent.drewThisFrame then
                    gfx.dest = element.parent.drawBuffer
                    element.parent:draw()
                    element.parent.drewThisFrame = true
                end
            else
                element:clearBuffer()
            end
            gfx.dest = element.drawBuffer
            element:draw()
            element.shouldRedraw = false
            element.drewThisFrame = true

        elseif element.shouldClearBuffer then
            element:clearBuffer()
            element.shouldClearBuffer = false
        end
    end

    local elementsOfElement = element.elements
    if elementsOfElement then
        for i = 1, #elementsOfElement do
            GFX:drawElement(elementsOfElement[i])
        end
    end
end
function GFX:blitElement(element)
    if element.isVisible then
        gfx.a = 1.0
        gfx.mode = 0
        gfx.dest = -1

        if not element:shouldDrawDirectly() then
            gfx.blit(element.drawBuffer, 1.0, 0, 0, 0, element.w, element.h, element.absoluteX, element.absoluteY, element.w, element.h, 0, 0)
        end
    end

    local elementsOfElement = element.elements
    if elementsOfElement then
        for i = 1, #elementsOfElement do
            GFX:blitElement(elementsOfElement[i])
        end
    end
end

function GFX.run()
    local self = GFX
    local elements = self.elements

    self.wTracker:update(gfx.w)
    self.hTracker:update(gfx.h)
    self.w = self.wTracker.current
    self.h = self.hTracker.current
    self.wChange = self.wTracker:getChange()
    self.hChange = self.hTracker:getChange()

    self.mouse:update()
    self.keyboard:update()

    local char = self.keyboard.currentCharacter
    if char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

    if elements then
        for i = 1, #elements do
            local element = elements[i]
            element.drewThisFrame = false
            GFX:updateElement(element)
            GFX:drawElement(element)
            GFX:blitElement(element)
        end
    end

    if char ~= "Escape" and char ~= "Close" then reaper.defer(self.run) end
    gfx.update()
end

return GFX