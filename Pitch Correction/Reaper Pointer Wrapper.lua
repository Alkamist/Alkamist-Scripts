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

function ReaperPointerWrapper:getter(shouldRefresh, memberName, getterFunction)
    if self[memberName] == nil or shouldRefresh then
        if self:isValid() then
            msg("refreshed")
            self[memberName] = getterFunction()
        end
    end
    return self[memberName]
end

return ReaperPointerWrapper