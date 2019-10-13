package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local ReaperEnvelope = {
    pointerType = "TrackEnvelope*",
    name = "ReaperEnvelope"
}

local ReaperEnvelope_mt = {

    -- Getters
    __index = function(tbl, key)
        if key == "track" then return tbl.factory.createNew(tbl:getTrack()) end
        if key == "project" then return tbl.track.project end
        return ReaperEnvelope[key]
    end,

    -- Setters
    __newindex = function(tbl, key, value)
        if key == "track" then return end
        if key == "project" then return end
        rawset(tbl, key, value)
    end

}

function ReaperEnvelope:new(object)
    local object = object or {}
    setmetatable(object, ReaperEnvelope_mt)
    return object
end

function ReaperEnvelope:isValid()
    return self.pointer ~= nil and reaper.ValidatePtr2(self.project, self.pointer, self.pointerType)
end

function ReaperEnvelope:getTrack()
    local parentTrack, _, _ = reaper.Envelope_GetParentTrack(self.pointer)
    return parentTrack
end

return ReaperEnvelope