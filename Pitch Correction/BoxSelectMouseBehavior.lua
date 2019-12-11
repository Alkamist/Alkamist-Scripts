local GUI = require("GUI")

local math = math
local abs = math.abs
local min = math.min
local max = math.max

local function objectIsInside(self, object)
    local x, y, w, h = self.x, self.y, self.width, self.height
    local objectX, objectY = object.x, object.y
    return objectX >= x and objectX <= x + w
       and objectY >= y and objectY <= y + h
end
local function startSelection(self)
    self.startingX = GUI.mouseX
    self.startingY = GUI.mouseY
    self.x = self.startingX
    self.y = self.startingY
    self.width = 0
    self.height = 0
end
local function editSelection(self)
    self.isActive = true
    self.x = min(self.startingX, GUI.mouseX)
    self.y = min(self.startingY, GUI.mouseY)
    self.width = abs(self.startingX - GUI.mouseX)
    self.height = abs(self.startingY - GUI.mouseY)
end
local function makeSelection(self)
    local objectsToSelect = self.objectsToSelect
    local numberOfObjectsToSelect = #objectsToSelect
    local shouldInvert = GUI.controlKeyIsPressed
    local shouldAdd = GUI.shiftKeyIsPressed

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

local BoxSelectMouseBehavior = {}

function BoxSelectMouseBehavior:requires()
    return self.BoxSelectMouseBehavior
end
function BoxSelectMouseBehavior:getDefaults()
    local defaults = {}
    defaults.startingX = 0
    defaults.startingY = 0
    defaults.isActive = false
    defaults.objectsToSelect = {}
    defaults.bodyColor = { 1, 1, 1, -0.04, 1 }
    defaults.outlineColor = { 1, 1, 1, 0.3, 1 }
    return defaults
end
function BoxSelectMouseBehavior:update(dt)
    if GUI.rightMouseButtonJustPressed then startSelection(self) end
    if GUI.rightMouseButtonJustDragged then editSelection(self) end
    if GUI.rightMouseButtonJustReleased then makeSelection(self) end
end

return BoxSelectMouseBehavior