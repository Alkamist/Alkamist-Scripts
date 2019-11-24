local reaper = reaper
local pairs = pairs
local math = math
local min = math.min
local abs = math.abs

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Boundary = require("GUI.Boundary")
local GUI = require("GUI.AlkamistGUI")
local mouse = GUI.mouse
local graphics = GUI.graphics

local BoxSelect = {}
function BoxSelect.new(object)
    local self = {}

    self.x1 = 0
    self.x2 = 0
    self.y1 = 0
    self.y2 = 0
    self.insideColor = { 1, 1, 1, -0.04, 1 }
    self.edgeColor = { 1, 1, 1, 0.4, 1 }
    self.isActive = false
    self.thingsToSelect = {}
    self.selectionControl = nil
    self.additiveControl = nil
    self.inversionControl = nil

    local object = Boundary.new(object)
    for k, v in pairs(self) do if not object[k] then object[k] = v end end
    return object
end

function BoxSelect.thingIsInside(self, thing)
    return Boundary.pointIsInside(self, thing.x, thing.y)
end
function BoxSelect.setThingSelected(self, thing, shouldSelect)
    thing.isSelected = shouldSelect
end
function BoxSelect.thingIsSelected(self, thing)
    return thing.isSelected
end
function BoxSelect.startSelection(self, startingX, startingY)
    self.x1 = startingX
    self.x2 = startingX
    self.y1 = startingY
    self.y2 = startingY
    self.x = startingX
    self.y = startingY
    self.width = 0
    self.height = 0
end
function BoxSelect.editSelection(self, editX, editY)
    self.isActive = true
    self.x2 = editX
    self.y2 = editY
    self.x = min(self.x1, self.x2)
    self.y = min(self.y1, self.y2)
    self.width = abs(self.x1 - self.x2)
    self.height = abs(self.y1 - self.y2)
end
function BoxSelect.makeSelection(self, parameters)
    local parameters = parameters or {}
    local thingsToSelect = parameters.thingsToSelect or self.thingsToSelect
    local thingIsInside = parameters.thingIsInside or self.thingIsInside
    local setThingSelected = parameters.setThingSelected or self.setThingSelected
    local thingIsSelected = parameters.thingIsSelected or self.thingIsSelected
    local shouldAdd = parameters.shouldAdd or self.additiveControl.isPressed
    local shouldInvert = parameters.shouldInvert or self.inversionControl.isPressed
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
function BoxSelect.update(self)
    if self.selectionControl.justPressed then BoxSelect.startSelection(self, mouse.x, mouse.y) end
    if self.selectionControl.isPressed then BoxSelect.editSelection(self, mouse.x, mouse.y) end
    if self.selectionControl.justReleased then BoxSelect.makeSelection(self) end
end
function BoxSelect.draw(self)
    local x, y, w, h = self.x, self.y, self.width, self.height
    local a, mode, dest = gfx.a, gfx.mode, gfx.dest
    gfx.a = 1
    gfx.mode = 0

    if self.isActive then
        graphics.setColor(self.edgeColor)
        graphics.drawRectangle(x, y, w, h, false)

        graphics.setColor(self.insideColor)
        graphics.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)
    end

    gfx.a, gfx.mode, gfx.dest = a, mode, dest
end

return BoxSelect