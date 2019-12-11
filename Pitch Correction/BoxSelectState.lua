local GUI = require("GUI")

local math = math
local abs = math.abs
local min = math.min
local max = math.max

local BoxSelectState = {}

function BoxSelectState:getDefaults()
    local defaults = {}
    defaults.startingX = 0
    defaults.startingY = 0
    defaults.isActive = false
    defaults.objectsToSelect = {}
    defaults.bodyColor = { 1, 1, 1, -0.04, 1 }
    defaults.outlineColor = { 1, 1, 1, 0.3, 1 }
    return defaults
end

function BoxSelectState:pointIsInside(entity, pointX, pointY)
    local x, y, w, h = entity.x, entity.y, entity.width, entity.height
    return pointX >= x and pointX <= x + w
       and pointY >= y and pointY <= y + h
end

function BoxSelectState:setObjectSelected(object, shouldSelect)
    object.isSelected = shouldSelect
end
function BoxSelectState:objectIsSelected(object)
    return object.isSelected
end

function BoxSelectState:update(entity, dt)
    local objectsToSelect = entity.objectsToSelect
    local numberOfObjectsToSelect = #objectsToSelect
    local setObjectSelected = entity.setObjectSelected
    local objectIsSelected = entity.objectIsSelected
    local shouldInvert = GUI.controlKeyIsPressed
    local shouldAdd = GUI.shiftKeyIsPressed

    if GUI.leftMouseButtonJustPressed then
        if objectsToSelect then
            entity.editObject = nil
            entity.editObjectWasSelected = nil
            for i = 1, numberOfObjectsToSelect do
                local object = objectsToSelect[i]
                if object:pointIsInside(GUI.mouseX, GUI.mouseY) then
                    entity.editObject = object
                    entity.editObjectWasSelected = objectIsSelected(entity, object)
                end
            end

            for i = 1, numberOfObjectsToSelect do
                local object = objectsToSelect[i]

                if object == entity.editObject then
                    if shouldInvert then
                        setObjectSelected(entity, object, not objectIsSelected(entity, object))
                    else
                        setObjectSelected(entity, object, true)
                    end
                else
                    if not entity.editObjectWasSelected and not shouldAdd and not shouldInvert then
                        setObjectSelected(entity, object, false)
                    end
                end
            end
        end
    end

    if GUI.rightMouseButtonJustPressed then
        entity.startingX = GUI.mouseX
        entity.startingY = GUI.mouseY
        entity.x = entity.startingX
        entity.y = entity.startingY
        entity.width = 0
        entity.height = 0
    end

    if GUI.rightMouseButtonJustDragged then
        entity.isActive = true
        entity.x = min(entity.startingX, GUI.mouseX)
        entity.y = min(entity.startingY, GUI.mouseY)
        entity.width = abs(entity.startingX - GUI.mouseX)
        entity.height = abs(entity.startingY - GUI.mouseY)
    end

    if GUI.rightMouseButtonJustReleased then
        local pointIsInside = entity.pointIsInside
        if objectsToSelect then
            for i = 1, numberOfObjectsToSelect do
                local object = objectsToSelect[i]

                if pointIsInside(entity, object.x, object.y) then
                    if shouldInvert then
                        setObjectSelected(entity, object, not objectIsSelected(entity, object))
                    else
                        setObjectSelected(entity, object, true)
                    end
                else
                    if not shouldAdd and not shouldInvert then
                        setObjectSelected(entity, object, false)
                    end
                end
            end
        end
        entity.isActive = false
    end
end
function BoxSelectState:onDraw(dt)
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
function BoxSelectState:onEndUpdate(dt) end

return BoxSelectState