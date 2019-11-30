local Button = {}

function Button:new()
    local self = self or {}

    self.pressState = self.pressState

    for k, v in pairs(Button) do if self[k] == nil then self[k] = v end end
    return self
end

function Button:press() self.pressState[1] = true end
function Button:release() self.pressState[1] = false end
function Button:toggle() self.pressState[1] = not self.pressState[1] end
function Button:isPressed() return self.pressState[1] end
function Button:justPressed() return self.pressState[1] and not self.pressState[2] end
function Button:justReleased() return not self.pressState[1] and self.pressState[2] end
function Button:update() self.pressState[2] = self.pressState[1] end

return Button