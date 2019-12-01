local Button = {}

function Button.new(input)
    local self = {}
    for k, v in pairs(Button) do if self[k] == nil then self[k] = v end end

    self.pressState = input.pressState

    return self
end

function Button:isPressed() return self.pressState[1] end
function Button:justPressed() return self.pressState[1] and not self.pressState[2] end
function Button:justReleased() return not self.pressState[1] and self.pressState[2] end
function Button:press() self.pressState[1] = true end
function Button:release() self.pressState[1] = false end
function Button:toggle() self.pressState[1] = not self.pressState[1] end

return Button