local leftBitValue = 1
local middleBitValue = 64
local rightBitValue = 2
local shiftBitValue = 8
local controlBitValue = 4
local windowsBitValue = 32
local altBitValue = 16

local function getMouseButtonState(mouseCap, bitValue)
    return mouseCap & bitValue == bitValue
end

local MouseButton = {}

function MouseButton.new(input)
    local self = {}
    for k, v in pairs(MouseButton) do if self[k] == nil then self[k] = v end end
    for k, v in pairs(input.button) do if self[k] == nil then self[k] = v end end

    return self
end

function MouseButton:update()
end