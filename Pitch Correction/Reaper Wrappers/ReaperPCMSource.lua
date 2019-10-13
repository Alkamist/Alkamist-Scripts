package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local ReaperPCMSource = {
    pointerType = "PCM_source*",
    name = "ReaperPCMSource"
}

local ReaperPCMSource_mt = {

    -- Getters
    __index = function(tbl, key)
        return ReaperPCMSource[key]
    end,

    -- Setters
    __newindex = function(tbl, key, value)
        rawset(tbl, key, value)
    end

}

function ReaperPCMSource:new(object)
    local object = object or {}
    setmetatable(object, ReaperPCMSource_mt)
    return object
end

function ReaperPCMSource:isValid()
    return self.pointer ~= nil and reaper.ValidatePtr(self.pointer, self.pointerType)
end

return ReaperPCMSource