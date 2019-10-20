local MouseButton = {}

function MouseButton:new(bitValue)
    if bitValue == nil then return nil end

    local self = setmetatable({}, { __index = self })

    self.mouseCap = 0
    self.previousMouseCap = 0
    self.bitValue = bitValue

    return self
end

function MouseButton:update(mouseCap)
    self.previousMouseCap = self.mouseCap
    self.mouseCap = mouseCap
end
function MouseButton:isPressed()
    return self.mouseCap & self.bitValue == self.bitValue
end
function MouseButton:justPressed()
    return self.mouseCap & self.bitValue == self.bitValue
       and self.previousMouseCap & self.bitValue == 0
end
function MouseButton:justReleased()
    return self.mouseCap & self.bitValue == 0
       and self.previousMouseCap & self.bitValue == self.bitValue
end

local Mouse = {}

function Mouse:new()
    local self = setmetatable({}, { __index = self })

    self.x = 0
    self.previousX = 0
    self.y = 0
    self.previousY = 0
    self.wheel = 0
    self.hWheel = 0
    self.buttons = {
        left =   MouseButton:new(1),
        middle = MouseButton:new(64),
        right =  MouseButton:new(2)
    }
    self.modifiers = {
        shift =   MouseButton:new(8),
        control = MouseButton:new(4),
        alt =     MouseButton:new(16),
        windows = MouseButton:new(32)
    }

    return self
end

-- Getters:

function Mouse:getX()         return self.x end
function Mouse:getPreviousX() return self.previousX end
function Mouse:getXChange()   return self:getX() - self:getPreviousX() end
function Mouse:getY()         return self.y end
function Mouse:getPreviousY() return self.previousY end
function Mouse:getYChange()   return self:getY() - self:getPreviousY() end
function Mouse:getWheel()     return self.wheel end
function Mouse:getHWheel()    return self.hWheel end
function Mouse:getButtons()   return self.buttons end
function Mouse:getModifiers() return self.modifiers end
function Mouse:justMoved()
    return self:getX() ~= self:getPreviousX()
        or self:getY() ~= self:getPreviousY()
end

-- Setters:

function Mouse:update()
    local mouseCap = gfx.mouse_cap

    for _, button   in pairs(self:getButtons())   do button:update(mouseCap) end
    for _, modifier in pairs(self:getModifiers()) do modifier:update(mouseCap) end

    self.previousX = self.x
    self.x = gfx.mouse_x
    self.previousY = self.y
    self.y = gfx.mouse_y
    self.wheel = math.floor(gfx.mouse_wheel / 120.0)
    gfx.mouse_wheel = 0
    self.hWheel = math.floor(gfx.mouse_hwheel / 120.0)
    gfx.mouse_hwheel = 0
end

return Mouse