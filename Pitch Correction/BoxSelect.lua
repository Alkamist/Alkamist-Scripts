local GUI = require("GUI")

local math = math
local abs = math.abs
local min = math.min
local max = math.max

local BoxSelect = {}

function BoxSelect:new(object)
    local object = object or {}
    local defaults = self:getDefaults()
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    for k, v in pairs(defaults) do if object[k] == nil then object[k] = v end end
    return object
end
function BoxSelect:getDefaults()
    local defaults = {}
    defaults.startingX = 0
    defaults.startingY = 0
    defaults.isActive = false
    defaults.objectsToSelect = {}
    defaults.bodyColor = { 1, 1, 1, -0.04, 1 }
    defaults.outlineColor = { 1, 1, 1, 0.3, 1 }
    return defaults
end

function BoxSelect:pointIsInside(pointX, pointY)
    local x, y, w, h = self.x, self.y, self.width, self.height
    return pointX >= x and pointX <= x + w
       and pointY >= y and pointY <= y + h
end

function BoxSelect:setObjectSelected(object, shouldSelect)
    object.isSelected = shouldSelect
end
function BoxSelect:objectIsSelected(object)
    return object.isSelected
end

function BoxSelect:onUpdate(dt)
    local objectsToSelect = self.objectsToSelect
    local numberOfObjectsToSelect = #objectsToSelect
    local setObjectSelected = self.setObjectSelected
    local objectIsSelected = self.objectIsSelected
    local shouldInvert = GUI.controlKeyIsPressed
    local shouldAdd = GUI.shiftKeyIsPressed

    if GUI.leftMouseButtonJustPressed then
        if objectsToSelect then
            self.editObject = nil
            self.editObjectWasSelected = nil
            for i = 1, numberOfObjectsToSelect do
                local object = objectsToSelect[i]
                if object:pointIsInside(GUI.mouseX, GUI.mouseY) then
                    self.editObject = object
                    self.editObjectWasSelected = objectIsSelected(self, object)
                end
            end

            for i = 1, numberOfObjectsToSelect do
                local object = objectsToSelect[i]

                if object == self.editObject then
                    if shouldInvert then
                        setObjectSelected(self, object, not objectIsSelected(self, object))
                    else
                        setObjectSelected(self, object, true)
                    end
                else
                    if not self.editObjectWasSelected and not shouldAdd and not shouldInvert then
                        setObjectSelected(self, object, false)
                    end
                end
            end
        end
    end

    if GUI.rightMouseButtonJustPressed then
        self.startingX = GUI.mouseX
        self.startingY = GUI.mouseY
        self.x = self.startingX
        self.y = self.startingY
        self.width = 0
        self.height = 0
    end

    if GUI.rightMouseButtonJustDragged then
        self.isActive = true
        self.x = min(self.startingX, GUI.mouseX)
        self.y = min(self.startingY, GUI.mouseY)
        self.width = abs(self.startingX - GUI.mouseX)
        self.height = abs(self.startingY - GUI.mouseY)
    end

    if GUI.rightMouseButtonJustReleased then
        local pointIsInside = self.pointIsInside
        if objectsToSelect then
            for i = 1, numberOfObjectsToSelect do
                local object = objectsToSelect[i]

                if pointIsInside(self, object.x, object.y) then
                    if shouldInvert then
                        setObjectSelected(self, object, not objectIsSelected(self, object))
                    else
                        setObjectSelected(self, object, true)
                    end
                else
                    if not shouldAdd and not shouldInvert then
                        setObjectSelected(self, object, false)
                    end
                end
            end
        end
        self.isActive = false
    end
end
function BoxSelect:onDraw(dt)
    local x, y, w, h = self.x, self.y, self.width, self.height

    if self.isActive then
        -- Draw the body.
        GUI.setColor(self.bodyColor)
        GUI.drawRectangle(x + 1, y + 1, w - 2, h - 2, true)

        -- Draw the outline.
        GUI.setColor(self.outlineColor)
        GUI.drawRectangle(x, y, w, h, false)
    end
end
function BoxSelect:onEndUpdate(dt) end

return BoxSelect