package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local ReaperTrack = {
    pointerType = "MediaTrack*",
    name = "ReaperTrack"
}

local ReaperTrack_mt = {

    -- Getters
    __index = function(tbl, key)
        if key == "project" then return tbl.factory.createNew(reaper.GetMediaTrackInfo_Value(tbl.pointer, "P_PROJECT")) end
        if key == "number" then return reaper.GetMediaTrackInfo_Value(tbl.pointer, "IP_TRACKNUMBER") end
        return ReaperTrack[key]
    end,

    -- Setters
    __newindex = function(tbl, key, value)
        if key == "project" then return end
        if key == "number" then return end
        rawset(tbl, key, value)
    end

}

function ReaperTrack:new(object)
    local object = object or {}
    setmetatable(object, ReaperTrack_mt)
    return object
end

function ReaperTrack:isValid()
    return self.pointer ~= nil and reaper.ValidatePtr2(self.project, self.pointer, self.pointerType)
end

return ReaperTrack