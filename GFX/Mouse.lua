local MouseButton = {}

function MouseButton:new(bitValue)
    if bitValue == nil then return nil end

    local self = setmetatable({}, { __index = self })

    self._mouseCap = nil
    self._previousMouseCap = nil
    self._bitValue = bitValue

    return self
end

function MouseButton:update(mouseCap)
    self._previousMouseCap = self._mouseCap
    self._mouseCap = mouseCap
end
function MouseButton:isPressed()
    return self._mouseCap & self._bitValue == self._bitValue
end
function MouseButton:justPressed()
    return self._mouseCap & self._bitValue == self._bitValue
       and self._previousMouseCap & self._bitValue == 0
end
function MouseButton:justReleased()
    return self._mouseCap & self._bitValue == 0
       and self._previousMouseCap & self._bitValue == self._bitValue
end

local Mouse = {}

function Mouse:new()
    local self = setmetatable({}, { __index = self })

    self._x = 0
    self._previousX = 0
    self._y = 0
    self._previousY = 0
    self._cap = nil
    self._wheel = 0
    self._hWheel = 0
    self._buttons = {
        left =   MouseButton:new(1),
        middle = MouseButton:new(64),
        right =  MouseButton:new(2)
    }
    self._modifiers = {
        shift =   MouseButton:new(8),
        control = MouseButton:new(4),
        alt =     MouseButton:new(16),
        windows = MouseButton:new(32)
    }

    return self
end

-- Getters:

function Mouse:getX()         return self._x end
function Mouse:getPreviousX() return self._previousX end
function Mouse:getXChange()   return self:getX() - self:getPreviousX() end
function Mouse:getY()         return self._y end
function Mouse:getPreviousY() return self._previousY end
function Mouse:getYChange()   return self:getY() - self:getPreviousY() end
function Mouse:getWheel()     return self._wheel end
function Mouse:getHWheel()    return self._hWheel end
function Mouse:getButtons()   return self._buttons end
function Mouse:getModifiers() return self._modifiers end
function Mouse:justMoved()
    return self:getX() ~= self:getPreviousX()
        or self:getY() ~= self:getPreviousY()
end

-- Setters:

function Mouse:update()
    self._previousX = self._x
    self._x = gfx.mouse_x
    self._previousY = self._y
    self._y = gfx.mouse_y
    self._cap = gfx.mouse_cap
    self._wheel = math.floor(gfx.mouse_wheel / 120.0)
    gfx.mouse_wheel = 0
    self._hWheel = math.floor(gfx.mouse_hwheel / 120.0)
    gfx.mouse_hwheel = 0
end

return Mouse