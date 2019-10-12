local AlkWrap = require "Pitch Correction.Alkamist Wrapper Functions"

local MediaTake = {
    pointerType = "MediaTake*"
}

local MediaTake_mt = {

    -- Getters
    __index = function(tbl, key)
        if key == "name" then return AlkWrap.getTakeName(tbl.pointer) end
        if key == "type" then return AlkWrap.getTakeType(tbl.pointer) end
        if key == "GUID" then return AlkWrap.getTakeGUID(tbl.pointer) end
        return MediaTake[key]
    end,

    -- Setters
    __newindex = function(tbl, key, value)
        if key == "name" then return AlkWrap.setTakeName(tbl.pointer, value) end
        rawset(tbl, key, value)
    end

}

function MediaTake:new(object)
    local object = object or {}
    setmetatable(object, MediaTake_mt)
    return object
end

return MediaTake