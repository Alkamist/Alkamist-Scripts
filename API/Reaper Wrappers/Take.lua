local PointerWrapper = require "API.Reaper Wrappers.PointerWrapper"

local function Take(project, pointer)
    if project == nil then return nil end
    if pointer == nil then return nil end

    local take = PointerWrapper(pointer, "MediaItem_Take*")

    -- Private Members:

    local _project = project

    -- Getters:

    function take:getProject()     return _project end
    function take:getName()        return reaper.GetTakeName(self:getPointer()) end
    function take:getGUID()        return reaper.BR_GetMediaItemTakeGUID(self:getPointer()) end
    function take:getItem()        return self:getProject():wrapItem(reaper.GetMediaItemTake_Item(self:getPointer())) end
    function take:getSource()      return self:getProject():wrapPCMSource(reaper.GetMediaItemTake_Source(self:getPointer())) end
    function take:getPlayrate()    return reaper.GetMediaItemTakeInfo_Value(self:getPointer(), "D_PLAYRATE") end
    function take:getStretchMarkers()
        local stretchMarkers = {}
        local numStretchMarkers = reaper.GetTakeNumStretchMarkers(self:getPointer())
        for i = 1, numStretchMarkers do
            local _, time, sourceTime = reaper.GetTakeStretchMarker(self:getPointer(), i - 1)

            stretchMarkers[i] = {
                time = time,
                sourceTime = sourceTime,
                slope = reaper.GetTakeStretchMarkerSlope(self:getPointer(), i - 1),
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
    function take:getSourceTime(realTime)
        if time == nil then return nil end
        local tempMarkerIndex = reaper.SetTakeStretchMarker(self:getPointer(), -1, realTime * self:getPlayrate())
        local _, _, sourcePosition = reaper.GetTakeStretchMarker(self:getPointer(), tempMarkerIndex)
        reaper.DeleteTakeStretchMarkers(self:getPointer(), tempMarkerIndex)
        return sourcePosition
    end
    function take:getStartOffset()
        return self:getSourceTime(0.0)
    end
    function take:getRealTime(sourceTime)
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
    function take:getType()
        if reaper.TakeIsMIDI(self:getPointer()) then
            return "midi"
        end
        return "audio"
    end
    function take:createAndGetPitchEnvelope()
        local pitchEnvelope = reaper.GetTakeEnvelopeByName(self:getPointer(), "Pitch")
        if not pitchEnvelope or not self:getProject():validatePointer(pitchEnvelope, "TrackEnvelope*") then
            self:getProject():mainCommand("_S&M_TAKEENV10") -- Show and unbypass take pitch envelope
            pitchEnvelope = reaper.GetTakeEnvelopeByName(self:getPointer(), "Pitch")
        end
        return self:getProject():wrapEnvelope(pitchEnvelope)
    end

    -- Setters:

    function take:setName(value)        reaper.GetSetMediaItemTakeInfo_String(self:getPointer(), "P_NAME", "", true) end
    function take:setSource(value)      reaper.SetMediaItemTake_Source(self:getPointer(), value) end
    function take:setPlayrate(value)    reaper.SetMediaItemTakeInfo_Value(self:getPointer(), "D_PLAYRATE", value) end
    function take:setStartOffset(value) reaper.SetMediaItemTakeInfo_Value(self:getPointer(), "D_STARTOFFS", value) end

    return take
end

return Take