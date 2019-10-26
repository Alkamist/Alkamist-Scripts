local reaper = reaper

local PointerWrapper = {}

function PointerWrapper:new(pointer, pointerType)
    local self = setmetatable({}, { __index = self })

    self.pointer = pointer
    self.pointerType = pointerType

    return self
end

function PointerWrapper:validatePointer(projectPointer)
    if projectPointer then
        return reaper.ValidatePtr2(projectPointer, self.pointer, self.pointerType)
    else
        return reaper.ValidatePtr(self.pointer, self.pointerType)
    end
end
function PointerWrapper:getIterator(getterFn, countFn)
    return setmetatable({}, {
        __index = function(tbl, index)
            return getterFn(self, index)
        end,
        __len = function(tbl)
            if countFn then return countFn(self) end
        end
    })
end

return PointerWrapper