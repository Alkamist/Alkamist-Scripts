local TrackedNumber = {}

function TrackedNumber:new(value)
    local self = setmetatable({}, { __index = self })

    self:setValue(value)
    self:setPreviousValue(value)

    return self
end

function TrackedNumber:getValue() return self._value end
function TrackedNumber:setValue(value) self._value = value end
function TrackedNumber:getPreviousValue() return self._previousValue end
function TrackedNumber:setPreviousValue(value) self._previousValue = value end

function TrackedNumber:getChange() return self:getValue() - self:getPreviousValue() end
function TrackedNumber:justChanged() return self:getValue() ~= self:getPreviousValue() end
function TrackedNumber:update(value)
    self:setPreviousValue(self:getValue())
    if value ~= nil then self:setValue(value) end
end

return TrackedNumber
