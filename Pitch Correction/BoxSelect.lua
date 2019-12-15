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
function BoxSelect:pointIsInside(pointX, pointY)
    local x, y, w, h = self.x, self.y, self.width, self.height
    return pointX >= x and pointX <= x + w
       and pointY >= y and pointY <= y + h
end
function BoxSelect:objectIsInside(object)
    return self:pointIsInside(object.x, object.y)
end
function BoxSelect:startSelection(x, y)
    self.startingX = x
    self.startingY = y
    self.x = self.startingX
    self.y = self.startingY
    self.width = 0
    self.height = 0
end
function BoxSelect:editSelection(x, y)
    self.isActive = true
    self.x = min(self.startingX, x)
    self.y = min(self.startingY, y)
    self.width = abs(self.startingX - x)
    self.height = abs(self.startingY - y)
end
function BoxSelect:makeSelection()
    local objectIsInside = self.objectIsInside
    local objectsToSelect = self.objectsToSelect
    local numberOfObjectsToSelect = #objectsToSelect
    local shouldInvert = self.keyboard.modifiers.control.isPressed
    local shouldAdd = self.keyboard.modifiers.shift.isPressed

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
function BoxSelect:update()
    local mouseX = self.mouse.x
    local mouseY = self.mouse.y
    if self.mouse.buttons.right.justPressed then self:startSelection(mouseX, mouseY) end
    if self.mouse.buttons.right.justDragged then self:editSelection(mouseX, mouseY) end
    if self.mouse.buttons.right.justReleased then self:makeSelection() end
end
function BoxSelect:draw()
    if self.isActive then
        local setColor = self.setColor
        local drawRectangle = self.drawRectangle
        local x, y, w, h = self.x, self.y, self.width, self.height

        -- Draw the body.
        setColor(self, self.bodyColor)
        drawRectangle(self, x + 1, y + 1, w - 2, h - 2, true)

        -- Draw the outline.
        setColor(self, self.outlineColor)
        drawRectangle(self, x, y, w, h, false)
    end
end

return BoxSelect