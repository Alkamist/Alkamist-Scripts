local Graphics = require("Graphics")

local math = math
local abs = math.abs
local min = math.min
local max = math.max

local BoxSelect = {}

function BoxSelect:new(object)
    local object = object or {}
    local defaults = {}

    defaults.x = 0
    defaults.y = 0
    defaults.width = 0
    defaults.height = 0
    defaults.isActive = false
    defaults.startingX = 0
    defaults.startingY = 0

    defaults.objectsToSelect = {}
    defaults.objectIsSelected = {}
    defaults.selectionControl = nil
    defaults.shouldAdd = false
    defaults.shouldInvert = false

    defaults.bodyColor = { 1, 1, 1, -0.04, 1 }
    defaults.outlineColor = { 1, 1, 1, 0.3, 1 }
    defaults.graphics = Graphics:new{
        x = object.x,
        y = object.y
    }

    for k, v in pairs(defaults) do if object[k] == nil then object[k] = v end end
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    return object
end

function BoxSelect:pointIsInside(point)
    return point.x >= self.x and point.x <= self.x + self.width
       and point.y >= self.y and point.y <= self.y + self.height
end
function BoxSelect:startSelection(point)
    self.startingX = point.x
    self.startingY = point.y
    self.x = self.startingX
    self.y = self.startingY
    self.width = 0
    self.height = 0
end
function BoxSelect:editSelection(point)
    self.isActive = true

    self.x = min(self.startingX, point.x)
    self.y = min(self.startingY, point.y)
    self.width = abs(self.startingX - point.x)
    self.height = abs(self.startingY - point.y)
end
function BoxSelect:makeSelection()
    if self.objectsToSelect then
        for i = 1, #self.objectsToSelect do
            local object = self.objectsToSelect[i]

            if self:pointIsInside(object) then
                if self.shouldInvert then
                    self.objectIsSelected[object] = not self.objectIsSelected[object]
                else
                    self.objectIsSelected[object] = true
                end
            else
                if not self.shouldAdd and not self.shouldInvert then
                    self.objectIsSelected[object] = false
                end
            end
        end
    end
    self.isActive = false
end
function BoxSelect:updateGraphics()
    self.graphics.x = self.x
    self.graphics.y = self.y
end
function BoxSelect:update()
    local selectionControl = self.selectionControl
    if selectionControl.justPressed then self:startSelection(selectionControl) end
    if selectionControl.isPressed then self:editSelection(selectionControl) end
    if selectionControl.justReleased then self:makeSelection() end
    self:updateGraphics()
end
function BoxSelect:draw()
    local graphics = self.graphics
    local w, h = self.width, self.height

    if self.isActive then
        -- Draw the body.
        graphics:setColor(self.bodyColor)
        graphics:drawRectangle(1, 1, w - 2, h - 2, true)

        -- Draw the outline.
        graphics:setColor(self.outlineColor)
        graphics:drawRectangle(0, 0, w, h, false)
    end
end

return BoxSelect