local GUI = require("GUI")
local setColor = GUI.setColor
local drawRectangle = GUI.drawRectangle

local pairs = pairs
local math = math
local abs = math.abs
local min = math.min
local max = math.max

local BoxSelect = {}

function BoxSelect:new()
    local self = self or {}

    local defaults = {}
    defaults.x = 0
    defaults.y = 0
    defaults.width = 0
    defaults.height = 0
    defaults.startingX = 0
    defaults.startingY = 0
    defaults.isActive = false
    defaults.objectsToSelect = {}
    defaults.bodyColor = { 1, 1, 1, -0.04, 1 }
    defaults.outlineColor = { 1, 1, 1, 0.3, 1 }

    for k, v in pairs(defaults) do if self[k] == nil then self[k] = v end end
    for k, v in pairs(BoxSelect) do if self[k] == nil then self[k] = v end end
    return self
end
function BoxSelect:objectIsInside(object)
    local x, y, w, h = self.x, self.y, self.width, self.height
    local objectX, objectY = object.x, object.y
    return objectX >= x and objectX <= x + w
       and objectY >= y and objectY <= y + h
end
function BoxSelect:startSelection()
    self.startingX = GUI.mouseX
    self.startingY = GUI.mouseY
    self.x = self.startingX
    self.y = self.startingY
    self.width = 0
    self.height = 0
end
function BoxSelect:editSelection()
    self.isActive = true
    self.x = min(self.startingX, GUI.mouseX)
    self.y = min(self.startingY, GUI.mouseY)
    self.width = abs(self.startingX - GUI.mouseX)
    self.height = abs(self.startingY - GUI.mouseY)
end
function BoxSelect:makeSelection()
    local objectIsInside = self.objectIsInside
    local objectsToSelect = self.objectsToSelect
    local numberOfObjectsToSelect = #objectsToSelect
    local shouldInvert = GUI.controlKey.isPressed
    local shouldAdd = GUI.shiftKey.isPressed

    if objectsToSelect then
        for i = 1, numberOfObjectsToSelect do
            local object = objectsToSelect[i]

            if objectIsInside(self, object) then
                if shouldInvert then
                    object.isSelected = not object.isSelected
                else
                    object.isSelected = true
                end
            else
                if not shouldAdd and not shouldInvert then
                    object.isSelected = false
                end
            end
        end
    end
    self.isActive = false
end
function BoxSelect:update(dt)
    if GUI.rightMouseButton.justPressed then self:startSelection() end
    if GUI.rightMouseButton.justDragged then self:editSelection() end
    if GUI.rightMouseButton.justReleased then self:makeSelection() end
end
function BoxSelect:draw(dt)
    if self.isActive then
        local x, y, w, h = self.x, self.y, self.width, self.height

        -- Draw the body.
        setColor(self.bodyColor)
        drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

        -- Draw the outline.
        setColor(self.outlineColor)
        drawRectangle(x, y, w, h, false)
    end
end

return BoxSelect