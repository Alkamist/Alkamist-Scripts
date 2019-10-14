package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local ReaperPointerWrapper = {}

function ReaperPointerWrapper:init()
    -- Getters
    self.__index = function(tbl, key)
        for _, member in ipairs(tbl._base._members) do
            if key == member.key then
                return member.getter(self)
            end
        end
        return tbl._base[key]
    end

    -- Setters
    self.__newindex = function(tbl, key, value)
        for _, member in ipairs(tbl._base._members) do
            if key == member.key then
                if type(member.setter) == "function" then
                    member.setter(self, value)
                end
                return
            end
        end
        rawset(tbl, key, value)
    end
end

function ReaperPointerWrapper:isValid()
    local project = self.project or 0
    return self.pointer ~= nil and reaper.ValidatePtr2(project, self.pointer, self.pointerType)
end

function ReaperPointerWrapper:getIterator(fn)
    local output = {
        __index = function(tbl, key)
            return fn(self, key)
        end
    }
    setmetatable(output, output)
    return output
end

return ReaperPointerWrapper