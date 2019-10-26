local reaper = reaper

local PointerWrapper = require "API.Reaper Wrappers.PointerWrapper"

local Take = setmetatable({}, { __index = PointerWrapper })

function Take:new(project, pointer)
    if project == nil then return nil end
    if pointer == nil then return nil end

    local base = PointerWrapper:new(pointer, "MediaItem_Take*")
    local self = setmetatable(base, { __index = self })
    self.project = project

    return self
end

function Take:getProject()     return self.project end
function Take:getName()        return reaper.GetTakeName(self.pointer) end
function Take:getGUID()        return reaper.BR_GetMediaItemTakeGUID(self.pointer) end
function Take:getItem()        return self:getProject():wrapItem(reaper.GetMediaItemTake_Item(self.pointer)) end
function Take:getSource()      return self:getProject():wrapPCMSource(reaper.GetMediaItemTake_Source(self.pointer)) end
function Take:getPlayrate()    return reaper.GetMediaItemTakeInfo_Value(self.pointer, "D_PLAYRATE") end
function Take:getStretchMarkers()
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
function Take:getSourceTime(realTime)
    if time == nil then return nil end
    local tempMarkerIndex = reaper.SetTakeStretchMarker(self.pointer, -1, realTime * self:getPlayrate())
    local _, _, sourcePosition = reaper.GetTakeStretchMarker(self.pointer, tempMarkerIndex)
    reaper.DeleteTakeStretchMarkers(self.pointer, tempMarkerIndex)
    return sourcePosition
end
function Take:getStartOffset()
    return self:getSourceTime(0.0)
end
function Take:getRealTime(sourceTime)
    if sourceTime == nil then return nil end

    local stretchMarkers = self:getStretchMarkers()
    local startOffset = self:getStartOffset()
    local playrate = self:getPlayrate()
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
function Take:getType()
    if reaper.TakeIsMIDI(self.pointer) then
        return "midi"
    end
    return "audio"
end
function Take:createAndGetPitchEnvelope()
    local pitchEnvelope = reaper.GetTakeEnvelopeByName(self.pointer, "Pitch")
    if not pitchEnvelope or not self:getProject():validatePointer(pitchEnvelope, "TrackEnvelope*") then
        self:getProject():mainCommand("_S&M_TAKEENV10") -- Show and unbypass Take pitch envelope
        pitchEnvelope = reaper.GetTakeEnvelopeByName(self.pointer, "Pitch")
    end
    return self:getProject():wrapEnvelope(pitchEnvelope)
end

-- Setters:

function Take:setName(value)        reaper.GetSetMediaItemTakeInfo_String(self.pointer, "P_NAME", "", true) end
function Take:setSource(value)      reaper.SetMediaItemTake_Source(self.pointer, value) end
function Take:setPlayrate(value)    reaper.SetMediaItemTakeInfo_Value(self.pointer, "D_PLAYRATE", value) end
function Take:setStartOffset(value) reaper.SetMediaItemTakeInfo_Value(self.pointer, "D_STARTOFFS", value) end

return Take