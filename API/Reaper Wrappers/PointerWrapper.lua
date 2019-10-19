local PointerWrapper = {}

function PointerWrapper:new(pointer, pointerType)
    local instance = {}
    instance._pointer = pointer
    instance._pointerType = pointerType

    return setmetatable(instance, { __index = self })
end

function PointerWrapper:getPointer()     return self._pointer end
function PointerWrapper:getPointerType() return self._pointerType end
function PointerWrapper:validatePointer(projectPointer)
    if projectPointer then
        return reaper.ValidatePtr2(projectPointer, self:getPointer(), self:getPointerType())
    else
        return reaper.ValidatePtr(self:getPointer(), self:getPointerType())
    end
end

return PointerWrapper