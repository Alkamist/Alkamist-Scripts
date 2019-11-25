local reaper = reaper
local gfx = gfx
local pairs = pairs
local math = math
local min = math.min
local abs = math.abs

local Fn = require("Fn")
local Widget = require("Widget")
local GUI = require("GUI")
local mouse = GUI.mouse
local keyboard = GUI.keyboard

local BoxSelect = {}
function BoxSelect.new(object)
    local self = {}

    self.x1 = 0
    self.x2 = 0
    self.y1 = 0
    self.y2 = 0
    self.isActive = false
    self.thingsToSelect = {}
    self.selectionControl = mouse.buttons.right
    self.additiveControl = keyboard.modifiers.shift
    self.inversionControl = keyboard.modifiers.control

    return Widget.new(Fn.makeNew(self, BoxSelect, object))
end

function BoxSelect:thingIsInside(thing)
    return self:pointIsInside(thing.x, thing.y)
end
function BoxSelect:setThingSelected(thing, shouldSelect)
    thing.isSelected = shouldSelect
end
function BoxSelect:thingIsSelected(thing)
    return thing.isSelected
end
function BoxSelect:startSelection(startingX, startingY)
    self.x1 = startingX
    self.x2 = startingX
    self.y1 = startingY
    self.y2 = startingY
    self.x = startingX
    self.y = startingY
    self.width = 0
    self.height = 0
end
function BoxSelect:editSelection(editX, editY)
    self.isActive = true
    self.x2 = editX
    self.y2 = editY
    self.x = min(self.x1, self.x2)
    self.y = min(self.y1, self.y2)
    self.width = abs(self.x1 - self.x2)
    self.height = abs(self.y1 - self.y2)
end
function BoxSelect:makeSelection()
    local thingsToSelect = self.thingsToSelect
    local thingIsInside = self.thingIsInside
    local setThingSelected = self.setThingSelected
    local thingIsSelected = self.thingIsSelected
    local shouldAdd = self.additiveControl.isPressed
    local shouldInvert = self.inversionControl.isPressed
    if thingsToSelect then
        for i = 1, #thingsToSelect do
            local thing = thingsToSelect[i]

            if thingIsInside(self, thing) then
                if shouldInvert then
                    setThingSelected(self, thing, not thingIsSelected(self, thing))
                else
                    setThingSelected(self, thing, true)
                end
            else
                if not shouldAdd and not shouldInvert then
                    setThingSelected(self, thing, false)
                end
            end
        end
    end
    self.isActive = false
end
function BoxSelect:update()
    Widget.update(self)

    if self.selectionControl.justPressed then self:startSelection(mouse.x, mouse.y) end
    if self.selectionControl.isPressed then self:editSelection(mouse.x, mouse.y) end
    if self.selectionControl.justReleased then self:makeSelection() end
end
function BoxSelect:draw()
    local alpha, blendMode = gfx.a, gfx.mode
    local x, y, w, h = self.x, self.y, self.width, self.height

    if self.isActive then
        gfx.set(1, 1, 1, 0.3, 1)
        gfx.rect(x, y, w, h, false)

        gfx.set(1, 1, 1, -0.04, 1)
        gfx.rect(x + 1, y + 1, w - 2, h - 2, true)
    end

    gfx.a, gfx.mode = alpha, blendMode
end
function BoxSelect:endUpdate()
    Widget.endUpdate(self)
end

return BoxSelect