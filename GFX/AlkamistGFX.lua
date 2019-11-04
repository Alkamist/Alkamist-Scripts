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

function GFX:setElements(elements)
    for i = 1, #elements do
        local element = elements[i]
        GFXElement.initializeElement(element, { GFX = GFX })
        self.elements[#self.elements + 1] = element
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
            element:updateElementStates()
        end
        for i = 1, #elements do
            local element = elements[i]
            element:updateElement()
        end
        for i = 1, #elements do
            local element = elements[i]
            element:drawElement()
        end
        for i = 1, #elements do
            local element = elements[i]
            element:blitElement()
        end
    end

    if char ~= "Escape" and char ~= "Close" then reaper.defer(self.run) end
    gfx.update()
end

return GFX