local Widget = {}

function Widget:new(object)
    local object = object or {}
    local defaults = {}
    defaults.x = 0
    defaults.y = 0
    defaults.width = 0
    defaults.height = 0
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    for k, v in pairs(defaults) do if object[k] == nil then object[k] = v end end
    return object
end

function Widget:pointIsInside(pointX, pointY)
    local x, y, w, h = self.x, self.y, self.width, self.height
    return pointX >= x and pointX <= x + w
       and pointY >= y and pointY <= y + h
end

function Widget:onWindowJustResized() end

function Widget:onLeftMouseButtonJustPressed() end
function Widget:onLeftMouseButtonJustReleased() end
function Widget:onLeftMouseButtonJustDragged() end

function Widget:onMiddleMouseButtonJustPressed() end
function Widget:onMiddleMouseButtonJustReleased() end
function Widget:onMiddleMouseButtonJustDragged() end

function Widget:onRightMouseButtonJustPressed() end
function Widget:onRightMouseButtonJustReleased() end
function Widget:onRightMouseButtonJustDragged() end

function Widget:onShiftKeyJustPressed() end
function Widget:onShiftKeyJustReleased() end
function Widget:onShiftKeyJustDragged() end

function Widget:onControlKeyJustPressed() end
function Widget:onControlKeyJustReleased() end
function Widget:onControlKeyJustDragged() end

function Widget:onWindowsKeyJustPressed() end
function Widget:onWindowsKeyJustReleased() end
function Widget:onWindowsKeyJustDragged() end

function Widget:onAltKeyJustPressed() end
function Widget:onAltKeyJustReleased() end
function Widget:onAltKeyJustDragged() end

function Widget:onKeyTyped(key) end

function Widget:onKeyJustPressed(key) end
function Widget:onKeyJustReleased(key) end
function Widget:onKeyJustDragged(key) end

function Widget:onUpdate(dt) end
function Widget:onDraw(dt) end
function Widget:onEndUpdate(dt) end

return Widget