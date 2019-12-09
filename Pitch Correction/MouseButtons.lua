local GUI = require("GUI")
local Button = require("Button")

local mouseStateFns = {
    left = function() return GUI.leftMouseButtonIsPressed end,
    middle = function() return GUI.middleMouseButtonIsPressed end,
    right = function() return GUI.rightMouseButtonIsPressed end,
    shift = function() return GUI.shiftKeyIsPressed end,
    control = function() return GUI.controlKeyIsPressed end,
    windows = function() return GUI.windowsKeyIsPressed end,
    alt = function() return GUI.altKeyIsPressed end,
}



local function MouseButton(self)
    local self = self or {}
    if self.MouseButton then return self end
    self.MouseButton = true
    Button(self)
    local _buttonUpdateState = self.updateState
    local _buttonUpdatePreviousState = self.updatePreviousState

    local _buttonName
    local _objectsToTrack = {}
    local _wasPressedInsideObject = {}

    function self.trackObject(object) _objectsToTrack[#_objectsToTrack + 1] = object end
    function self.getButtonName() return _buttonName end
    function self.setButtonName(v) _buttonName = v end

    function self.wasPressedInsideObject(object) return _wasPressedInsideObject[object] end
    function self.justPressedObject(object) return self.wasPressedInsideObject(object) and self.justPressed() end
    function self.justReleasedObject(object) return self.wasPressedInsideObject(object) and self.justReleased() end
    function self.justDraggedObject(object) return self.wasPressedInsideObject(object) and self.justDragged() end
    function self.justStartedDraggingObject(object) return self.wasPressedInsideObject(object) and self.justStartedDragging() end
    function self.justStoppedDraggingObject(object) return self.wasPressedInsideObject(object) and self.justStoppedDragging() end

    function self.updateState(dt)
        self.setIsPressed(mouseStateFns[self.getButtonName()]())
        self.setX(GUI.mouseX)
        self.setY(GUI.mouseY)
        _buttonUpdateState(dt)

        if self.justPressed() then
            for i = 1, #_objectsToTrack do
                local object = _objectsToTrack[i]
                if object.mouseIsInside() then
                    _wasPressedInsideObject[object] = true
                end
            end
        end
    end
    function self.updatePreviousState(dt)
        if self.justReleased() then
            _wasPressedInsideObject = {}
        end
        _buttonUpdatePreviousState(dt)
    end

    return self
end



local listOfButtons = {}
local MouseButtons = {}
for k, v in pairs(mouseStateFns) do
    local newButton = MouseButton()
    newButton.setButtonName(k)

    MouseButtons[k] = newButton
    listOfButtons[#listOfButtons + 1] = MouseButtons[k]
end

function MouseButtons.updateState(dt)
    for i = 1, #listOfButtons do
        listOfButtons[i].updateState(dt)
    end
end
function MouseButtons.updatePreviousState(dt)
    for i = 1, #listOfButtons do
        listOfButtons[i].updatePreviousState(dt)
    end
end

return MouseButtons