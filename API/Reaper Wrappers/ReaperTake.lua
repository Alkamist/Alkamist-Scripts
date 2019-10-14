package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "API.Reaper Wrappers.ReaperPointerWrapper"

local ReaperTake = { pointerType = "MediaItem_Take*" }
setmetatable(ReaperTake, { __index = ReaperPointerWrapper })

ReaperTake._members = {
    { key = "track",
        getter = function(self) return self.item.track end },

    { key = "name",
        getter = function(self) return reaper.GetTakeName(self.pointer) end,
        setter = function(self, value) reaper.GetSetMediaItemTakeInfo_String(self.pointer, "P_NAME", "", true) end },

    { key = "type",
        getter = function(self) return self:getType() end },

    { key = "GUID",
        getter = function(self) return reaper.BR_GetMediaItemTakeGUID(self.pointer) end },

    { key = "item",
        getter = function(self) return self.factory.createNew(reaper.GetMediaItemTake_Item(self.pointer), self.project) end },

    { key = "source",
        getter = function(self) return reaper.GetMediaItemTake_Source(self.pointer) end,
        setter = function(self, value) reaper.SetMediaItemTake_Source(self.pointer, value) end },

    { key = "playrate",
        getter = function(self) return reaper.GetMediaItemTakeInfo_Value(self.pointer, "D_PLAYRATE") end,
        setter = function(self, value) reaper.SetMediaItemTakeInfo_Value(self.pointer, "D_PLAYRATE") end },

    { key = "startOffset",
        getter = function(self) return self:getSourceTime(0.0) end,
        setter = function(self, value) reaper.SetMediaItemTakeInfo_Value(self.pointer, "D_STARTOFFS", value) end },

    { key = "stretchMarkers",
        getter = function(self) return self:getStretchMarkers() end },

    { key = "pitchEnvelope",
        getter = function(self) return self:createAndGetPitchEnvelope() end },
}

function ReaperTake:new(object)
    local object = object or {}
    object._base = self
    setmetatable(object, object)
    ReaperPointerWrapper.init(object)
    return object
end

--------------------- Unique Functions  ---------------------

function ReaperTake:getSourceTime(realTime)
    if time == nil then return nil end
    local tempMarkerIndex = reaper.SetTakeStretchMarker(self.pointer, -1, realTime * self.playrate)
    local _, _, sourcePosition = reaper.GetTakeStretchMarker(self.pointer, tempMarkerIndex)
    reaper.DeleteTakeStretchMarkers(self.pointer, tempMarkerIndex)
    return sourcePosition
end

function ReaperTake:getRealTime(sourceTime)
    if sourceTime == nil then return nil end

    local stretchMarkers = self.stretchMarkers
    local startOffset = self.startOffset
    local playrate = self.playrate
    local numStretchMarkers = #stretchMarkers

    if numStretchMarkers < 1 then
        return (sourceTime - startOffset) / playrate
    end

    local markerIndex = 0

    for index, marker in ipairs(stretchMarkers) do
        if sourceTime < marker.sourceTime then
            markerIndex = index - 1
            break
        end

        if index == numStretchMarkers then
            markerIndex = index
        end
    end

    if markerIndex == 0 then
        return (sourceTime - startOffset) / playrate
    end

    local activeMarker = stretchMarkers[markerIndex]

    local relativeSourcePosition = sourceTime - activeMarker.sourceTime

    local actualSlope = 0.0
    if activeMarker.sourceLength > 0 and activeMarker.length > 0 then
        actualSlope = (activeMarker.sourceLength / activeMarker.length - activeMarker.rate) / (0.5 * activeMarker.sourceLength)
    end

    local currentMarkerRate = activeMarker.rate + relativeSourcePosition * actualSlope
    local averageMarkerRate = (activeMarker.rate + currentMarkerRate) * 0.5
    local scaledOffset = relativeSourcePosition / averageMarkerRate

    local realTime = activeMarker.time + scaledOffset

    return realTime / playrate
end

--------------------- Member Helper Functions  ---------------------

function ReaperTake:getType()
    if reaper.TakeIsMIDI(self.pointer) then
        return "midi"
    end
    return "audio"
end

function ReaperTake:getStretchMarkers()
    local stretchMarkers = {}
    local numStretchMarkers = reaper.GetTakeNumStretchMarkers(self.pointer)
    for i = 1, numStretchMarkers do
        local _, time, sourceTime = reaper.GetTakeStretchMarker(self.pointer, i - 1)

        stretchMarkers[i] = {
            time = time,
            sourceTime = sourceTime,
            slope = reaper.GetTakeStretchMarkerSlope(self.pointer, i - 1),
            rate = 1.0,
            length = 0.0,
            sourceLength = 0.0
        }
    end

    for index, marker in ipairs(stretchMarkers) do
        local markerRate = 1.0
        local markerLength = 0.0
        if index < #stretchMarkers then
            local nextMarker = stretchMarkers[index + 1]

            markerLength = nextMarker.time - marker.time
            markerSourceLength = nextMarker.sourceTime - marker.sourceTime
            markerRate = markerSourceLength / markerLength * (1.0 - marker.slope)
        else
            markerLength = 0.0
            markerSourceLength = 0.0
            markerRate = 1.0
        end

        marker.rate = markerRate
        marker.length = markerLength
        marker.sourceLength = markerSourceLength
    end

    return stretchMarkers
end

function ReaperTake:createAndGetPitchEnvelope()
    local pitchEnvelope = reaper.GetTakeEnvelopeByName(self.pointer, "Pitch")
    if not pitchEnvelope or not self.project:validatePointer(pitchEnvelope, "TrackEnvelope*") then
        self.project:mainCommand("_S&M_TAKEENV10") -- Show and unbypass take pitch envelope
        pitchEnvelope = reaper.GetTakeEnvelopeByName(self.pointer, "Pitch")
    end
    return self.factory.createNew(pitchEnvelope, self.project)
end

return ReaperTake