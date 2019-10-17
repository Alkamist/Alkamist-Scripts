package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local ReaperPointerWrapper = {}

function ReaperPointerWrapper:isValid()
    return self.project:validatePointer(self.pointer, self.pointerType)
end

function ReaperPointerWrapper:getIterator(getterFn, countFn)
    return setmetatable({}, {
        __index = function(tbl, index)
            return getterFn(self, index)
        end,

        __len = function(tbl)
            if countFn then return countFn(self) end
            return rawlen(tbl)
        end
    })
end

return ReaperPointerWrapper