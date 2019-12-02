local Button = {}

function Button:new()
    local self = self or {}
    for k, v in pairs(Button) do if self[k] == nil then self[k] = v end end
    return self
end

function Button:isPressed() end
function Button:wasPreviouslyPressed() end
function Button:justPressed() return self:isPressed() and not self:wasPreviouslyPressed() end
function Button:justReleased() return not self:isPressed() and self:wasPreviouslyPressed() end

return Button