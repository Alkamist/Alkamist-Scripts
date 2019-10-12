local ReaperPointerWrapper = {}
function ReaperPointerWrapper:new(object)
    local object = object or {}
    setmetatable(object, { __index = self })
    object:init()
    return object
end

function ReaperPointerWrapper:init()
    self:set(self.pointer, self.pointerType)
end

function ReaperPointerWrapper:set(pointer, pointerType)
    self.pointer = pointer
    self.pointerType = pointerType
end

function ReaperPointerWrapper:isValid()
    return self.pointer ~= nil and reaper.ValidatePtr(self.pointer, self.pointerType)
end

function ReaperPointerWrapper:getter(memberName, getterFunction)
    if self:isValid() then
        self[memberName] = getterFunction()
        return self[memberName]
    end
    self[memberName] = nil
    return self[memberName]
end

return ReaperPointerWrapper