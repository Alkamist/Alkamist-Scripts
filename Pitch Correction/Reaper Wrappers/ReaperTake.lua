package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local ReaperTake = {
    pointerType = "MediaItem_Take*",
    name = "ReaperTake"
}

local ReaperTake_mt = {

    -- Getters
    __index = function(tbl, key)
        if key == "track" then return tbl.item.track end
        if key == "project" then return tbl.track.project end
        if key == "name" then return reaper.GetTakeName(tbl.pointer) end
        if key == "type" then return tbl:getType() end
        if key == "GUID" then return reaper.BR_GetMediaItemTakeGUID(tbl.pointer) end
        if key == "item" then return tbl.factory.createNew(reaper.GetMediaItemTake_Item(tbl.pointer)) end
        return ReaperTake[key]
    end,

    -- Setters
    __newindex = function(tbl, key, value)
        if key == "track" then return end
        if key == "project" then return end
        if key == "name" then reaper.GetSetMediaItemTakeInfo_String(tbl.pointer, "P_NAME", "", true); return end
        if key == "type" then return end
        if key == "GUID" then return end
        if key == "item" then return end
        rawset(tbl, key, value)
    end

}

function ReaperTake:new(object)
    local object = object or {}
    setmetatable(object, ReaperTake_mt)
    return object
end

function ReaperTake:isValid()
    return self.pointer ~= nil and reaper.ValidatePtr2(self.project, self.pointer, self.pointerType)
end

function ReaperTake:getType()
    if reaper.TakeIsMIDI(self.pointer) then
        return "midi"
    end
    return "audio"
end

return ReaperTake