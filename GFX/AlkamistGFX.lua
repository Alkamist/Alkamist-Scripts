local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local UserControl = require("GFX.UserControl")
local TrackedNumber = require("GFX.TrackedNumber")

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
function GFX:getDrawBuffer()
    currentBuffer = currentBuffer + 1
    if currentBuffer > 1023 then currentBuffer = 0 end
    return currentBuffer
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
function GFX.run()
    local self = GFX
    local elements = self.elements

    self.wTracker:update(gfx.w)
    self.hTracker:update(gfx.h)

    self.mouse:update()
    self.keyboard:update()

    local char = self.keyboard.currentCharacter

    if char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

    for i = 1, #elements do
        local element = elements[i]
        gfx.a = 1.0
        gfx.mode = 0
        element:update()
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