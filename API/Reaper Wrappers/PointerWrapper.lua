local function PointerWrapper(pointer, pointerType)
    local pointerWrapper = {}

    local _pointer = pointer
    local _pointerType = pointerType

    function pointerWrapper:getPointer()     return _pointer end
    function pointerWrapper:getPointerType() return _pointerType end
    function pointerWrapper:validatePointer(projectPointer)
        if projectPointer then
            return reaper.ValidatePtr2(projectPointer, self:getPointer(), self:getPointerType())
        else
            return reaper.ValidatePtr(self:getPointer(), self:getPointerType())
        end
    end

    return pointerWrapper
end

return PointerWrapper