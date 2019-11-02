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
    wTracker = TrackedNumber:new(0),
    hTracker = TrackedNumber:new(0),
    elements = {},
    mouse = UserControl.mouse,
    keyboard = UserControl.keyboard
}

function GFX:setBackgroundColor(color)
    self.backgroundColor = color
    gfx.clear = color[1] * 255 + color[2] * 255 * 256 + color[3] * 255 * 65536
end
function GFX:windowWasResized()
    return self.w.justChanged or self.h.justChanged
end
local currentBuffer = -1
function GFX:getNewDrawBuffer()
    currentBuffer = currentBuffer + 1
    if currentBuffer > 1023 then currentBuffer = 0 end
    return currentBuffer
end
function GFX:bindElement(element)
    local baseOfElement
    while true do
        local mt = getmetatable(element)
        if mt == nil then break end
        baseOfElement = mt.__index
    end
    baseOfElement.GFX = GFX
    if self ~= GFX then baseOfElement.parent = self end
    GFXElement:new(baseOfElement)

    local elementsOfElement = element.elements
    for i = 1, #elementsOfElement do
        self:bindElement(elementsOfElement[i])
    end
end
function GFX:setElements(elements)
    for i = 1, #elements do
        self.elements[#self.elements + 1] = self:bindElement(elements[i])
    end
end
function GFX:init(title, x, y, w, h, dock)
    gfx.init(title, w, h, dock, x, y)

    self.title = title
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.dock = dock
end
function GFX:drawElement(element)
    if element.draw then
        if element.shouldRedraw then
            element:clearBuffer()
            gfx.dest = element.drawBuffer
            element:draw()
            element.shouldRedraw = false
        elseif element.shouldClearBuffer then
            element:clearBuffer()
            element.shouldClearBuffer = false
        end
    end
end
function GFX:renderElement(element)
    local elementsOfElement = element.elements
    for i = 1, #elementsOfElement do
        local elementOfElement = elementsOfElement[i]
        GFX:renderElement(elementOfElement)
    end

    if element.isVisible then
        if element.parent then
            gfx.dest = element.parent.drawBuffer
        else
            gfx.dest = -1
        end
        --gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs])
        gfx.blit(element.drawBuffer, 1.0, 0, 0, 0, element.w, element.h, element.x, element.y, element.w, element.h, 0, 0)
    end
end

function GFX.run()
    local self = GFX
    local elements = self.elements

    self.wTracker:update(gfx.w)
    self.hTracker:update(gfx.h)
    self.w = self.wTracker.current
    self.h = self.hTracker.current

    self.mouse:update()
    self.keyboard:update()

    local char = self.keyboard.currentCharacter
    if char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

    for i = 1, #elements do
        local element = elements[i]
        gfx.a = 1.0
        gfx.mode = 0
        GFXElement.updateStates(element)
        element:update()
        GFX:drawElement(element)
    end
    for i = 1, #elements do
        local element = elements[i]
        gfx.dest = -1
        gfx.a = 1.0
        gfx.mode = 0
        GFX:renderElement(element)
    end

    if char ~= "Escape" and char ~= "Close" then reaper.defer(self.run) end
    gfx.update()
end

return GFX