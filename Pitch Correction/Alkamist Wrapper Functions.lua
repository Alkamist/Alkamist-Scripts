local AlkWrap = {}

-------------------- MediaItem* --------------------

-- Getters.
function AlkWrap.itemIsEmpty(item)
    return AlkWrap.getTakeType(AlkWrap.getItemActiveTake(item)) == nil
end
function AlkWrap.getItemName(item)
    if AlkWrap.itemIsEmpty(item) then
        return reaper.ULT_GetMediaItemNote(item)
    end
    return AlkWrap.getTakeName(AlkWrap.getItemActiveTake(item))
end

-------------------- MediaItem_Take* --------------------

-- Getters.
function AlkWrap.getTakeSource(take)
    return reaper.GetMediaItemTake_Source(take)
end
function AlkWrap.getTakePlayrate(take)
    return reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
end
function AlkWrap.getTakePitchEnvelope(take)
    return reaper.GetTakeEnvelopeByName(take, "Pitch")
end
function AlkWrap.createAndGetTakePitchEnvelope(take)
    local pitchEnvelope = AlkWrap.getTakePitchEnvelope(take)
    if not pitchEnvelope or not reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
        AlkWrap.mainCommand("_S&M_TAKEENV10") -- Show and unbypass take pitch envelope
        pitchEnvelope = AlkWrap.getTakePitchEnvelope(take)
    end
    AlkWrap.mainCommand("_S&M_TAKEENVSHOW8") -- Hide take pitch envelope
    return pitchEnvelope
end
function AlkWrap.getTakeSourceTime(take, realTime)
    if time == nil then return nil end
    local tempMarkerIndex = reaper.SetTakeStretchMarker(take, -1, realTime * AlkWrap.getTakePlayrate(take))
    local _, _, sourcePosition = reaper.GetTakeStretchMarker(take, tempMarkerIndex)
    reaper.DeleteTakeStretchMarkers(take, tempMarkerIndex)
    return sourcePosition
end
function AlkWrap.getTakeStartOffset(take)
    return AlkWrap.getTakeSourceTime(take, 0.0)
end
function AlkWrap.getTakeStretchMarkers(take)
    local stretchMarkers = {}
    local numStretchMarkers = reaper.GetTakeNumStretchMarkers(take)
    for i = 1, numStretchMarkers do
        local _, time, sourceTime = reaper.GetTakeStretchMarker(take, i - 1)

        stretchMarkers[i] = {
            time = time,
            sourceTime = sourceTime,
            slope = reaper.GetTakeStretchMarkerSlope(take, i - 1),
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
function AlkWrap.getTakeRealTime(take, sourceTime)
    if sourceTime == nil then return nil end

    local stretchMarkers = AlkWrap.getTakeStretchMarkers(take)
    local startOffset = AlkWrap.getTakeStartOffset(take)
    local playrate = AlkWrap.getTakePlayrate(take)
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

-- Setters.
function AlkWrap.setTakeSource(take, value)
    reaper.SetMediaItemTake_Source(take, value)
end
function AlkWrap.setTakeStartOffset(take, value)
    reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", value)
end

-------------------- PCM_Source* --------------------

-- Getters.
function AlkWrap.getSourceFileName(source)
    local url = reaper.GetMediaSourceFileName(source, "")
    return url:match("[^/\\]+$")
end
function AlkWrap.getSourceLength(source)
    local _, _, sourceLength = reaper.PCM_Source_GetSectionInfo(source)
    return sourceLength
end

return AlkWrap