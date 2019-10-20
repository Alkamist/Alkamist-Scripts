package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Switch = require("Logic.Switch")
local NumberTracker = require("Logic.NumberTracker")

local MouseButton = {}

function MouseButton:new(bitValue)
    if bitValue == nil then return nil end

    local self = setmetatable({}, { __index = self })

    self.bitValue = bitValue
    self.state = Switch:new(false)

    return self
end

function MouseButton:update(mouseCap)
    local newState = mouseCap & self.bitValue == self.bitValue
    self.state:update(newState)
end

local Mouse = {}

function Mouse:new()
    local self = setmetatable({}, { __index = self })

    self.x =      NumberTracker:new(0)
    self.y =      NumberTracker:new(0)
    self.wheel =  0
    self.hWheel = 0
    self.cap =    NumberTracker:new(0)
    self.buttons = {
        left =    MouseButton:new(1),
        middle =  MouseButton:new(64),
        right =   MouseButton:new(2)
    }
    self.modifiers = {
        shift =   MouseButton:new(8),
        control = MouseButton:new(4),
        alt =     MouseButton:new(16),
        windows = MouseButton:new(32)
    }
    self.moved = false

    return self
end

function Mouse:update()
    local mouseCap = gfx.mouse_cap

    self.x:update(gfx.mouse_x)
    self.y:update(gfx.mouse_y)
    self.wheel = math.floor(gfx.mouse_wheel / 120.0)
    gfx.mouse_wheel = 0
    self.hWheel = math.floor(gfx.mouse_hwheel / 120.0)
    gfx.mouse_hwheel = 0
    self.cap:update(mouseCap)

    for _, button   in pairs(self.buttons) do
        button:update(mouseCap)
    end
    for _, modifier in pairs(self.modifiers) do
        modifier:update(mouseCap)
    end

    self.moved = self.x.changed or self.y.changed
end

return Mouse