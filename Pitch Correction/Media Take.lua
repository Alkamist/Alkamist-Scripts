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
        if key == "name" then AlkWrap.setTakeName(tbl.pointer, value) end
    end

}

function MediaTake:new(object)
    local object = object or {}
    setmetatable(object, MediaTake_mt)
    return object
end

------------------ Private Functions ------------------

local function prepareExtStateForPitchDetection(takeGUID, settings)
    reaper.SetExtState("Alkamist_PitchCorrection", "TAKEGUID", takeGUID, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "WINDOWSTEP", settings.windowStep, true)
    reaper.SetExtState("Alkamist_PitchCorrection", "MINFREQ", settings.minimumFrequency, true)
    reaper.SetExtState("Alkamist_PitchCorrection", "MAXFREQ", settings.maximumFrequency, true)
    reaper.SetExtState("Alkamist_PitchCorrection", "YINTHRESH", settings.YINThresh, true)
    reaper.SetExtState("Alkamist_PitchCorrection", "OVERLAP", settings.overlap, true)
    reaper.SetExtState("Alkamist_PitchCorrection", "LOWRMSLIMDB", settings.lowRMSLimitdB, true)
end

------------------ Getters ------------------

function MediaTake:getSourcePosition(time)
    if time == nil then return nil end
    local tempMarkerIndex = reaper.SetTakeStretchMarker(self.pointer, -1, time * self:getPlayrate())
    local _, pos, srcPos = reaper.GetTakeStretchMarker(self.pointer, tempMarkerIndex)
    reaper.DeleteTakeStretchMarkers(self.pointer, tempMarkerIndex)
    return srcPos
end

function MediaTake:getStretchMarkers()
    local stretchMarkers = {}
    local numStretchMarkers = reaper.GetTakeNumStretchMarkers(self.pointer)
    for i = 1, numStretchMarkers do
        local _, pos, srcPos = reaper.GetTakeStretchMarker(self.pointer, i - 1)

        stretchMarkers[i] = {
            pos = pos,
            srcPos = srcPos,
            slope = reaper.GetTakeStretchMarkerSlope(self.pointer, i - 1)
        }
    end

    for index, marker in ipairs(stretchMarkers) do
        local markerRate = 1.0
        local markerLength = 0
        if index < #stretchMarkers then
            local nextMarker = stretchMarkers[index + 1]

            markerLength = nextMarker.pos - marker.pos
            markerSourceLength = nextMarker.srcPos - marker.srcPos
            markerRate = markerSourceLength / markerLength * (1.0 - marker.slope)
        else
            markerLength = 0.0
            markerSourceLength = 0.0
            markerRate = 1.0
        end

        marker.rate = markerRate
        marker.length = markerLength
        marker.srcLength = markerSourceLength
    end

    return stretchMarkers
end

function MediaTake:getRealPosition(sourceTime)
    if sourceTime == nil then return nil end

    local stretchMarkers = self:getStretchMarkers()
    local numStretchMarkers = #stretchMarkers

    if numStretchMarkers < 1 then
        return (sourceTime - self:getStartOffset()) / self:getPlayrate()
    end

    local markerIndex = 0

    for index, marker in ipairs(stretchMarkers) do
        if sourceTime < marker.srcPos then
            markerIndex = index - 1
            break
        end

        if index == numStretchMarkers then
            markerIndex = index
        end
    end

    if markerIndex == 0 then
        return (sourceTime - self:getStartOffset()) / self:getPlayrate()
    end

    local activeMarker = stretchMarkers[markerIndex]

    local relativeSourcePosition = sourceTime - activeMarker.srcPos

    local actualSlope = 0.0
    if activeMarker.srcLength > 0 and activeMarker.length > 0 then
        actualSlope = (activeMarker.srcLength / activeMarker.length - activeMarker.rate) / (0.5 * activeMarker.srcLength)
    end

    local currentMarkerRate = activeMarker.rate + relativeSourcePosition * actualSlope
    local averageMarkerRate = (activeMarker.rate + currentMarkerRate) * 0.5
    local scaledOffset = relativeSourcePosition / averageMarkerRate

    local realTime = activeMarker.pos + scaledOffset

    return realTime / self:getPlayrate()
end

function MediaTake:getItem(refresh)
    return self:getter(refresh, "item",
                       function() return reaper.GetMediaItemTake_Item(self.pointer) end)
end

function MediaTake:getType(refresh)
    return self:getter(refresh, "type",
                       function()
                           if reaper.TakeIsMIDI(self.pointer) then
                               return "midi"
                           end

                           return "audio"
                       end)
end

function MediaTake:getName(refresh)
    return self:getter(refresh, "name",
                       function() return reaper.GetTakeName(self.pointer) end)
end

function MediaTake:getGUID(refresh)
    return self:getter(refresh, "GUID",
                       function() return reaper.BR_GetMediaItemTakeGUID(self.pointer) end)
end

function MediaTake:getSource(refresh)
    return self:getter(refresh, "source",
                       function() return reaper.GetMediaItemTake_Source(self.pointer) end)
end

function MediaTake:getFileName(refresh)
    return self:getter(refresh, "fileName",
                       function()
                           local url = reaper.GetMediaSourceFileName(self:getSource(), "")
                           return url:match("[^/\\]+$")
                       end)
end

function MediaTake:getSourceLength(refresh)
    return self:getter(refresh, "sourceLength",
                       function()
                           local _, _, takeSourceLength = reaper.PCM_Source_GetSectionInfo(self:getSource())
                           return takeSourceLength
                       end)
end

function MediaTake:getPitchEnvelope(refresh)
    return self:getter(refresh, "pitchEnvelope",
                       function()
                           local pitchEnvelope = reaper.GetTakeEnvelopeByName(self.pointer, "Pitch")

                           if not pitchEnvelope or not reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
                               Reaper.mainCommand("_S&M_TAKEENV10") -- Show and unbypass take pitch envelope
                               pitchEnvelope = reaper.GetTakeEnvelopeByName(self.pointer, "Pitch")
                           end

                           Reaper.mainCommand("_S&M_TAKEENVSHOW8") -- Hide take pitch envelope

                           return pitchEnvelope
                       end)
end

function MediaTake:getPlayrate(refresh)
    return self:getter(refresh, "playrate",
                       function() return reaper.GetMediaItemTakeInfo_Value(self.pointer, "D_PLAYRATE") end)
end

function MediaTake:getStartOffset(refresh)
    return self:getter(refresh, "startOffset",
                       function() return self:getSourcePosition(0.0) end)
end

function MediaTake:getPitchPoints(refresh)
    return self:getter(refresh, "pitchPoints",

        function()
            local analyzerID = Reaper.getEELCommandID("Pitch Analyzer")
            local leftBound = self:getStartOffset()
            local rightBound = self:getSourcePosition(self:getLength())
            local analysisLength = rightBound - leftBound
            local analysisItem = self:getItem():getTrack():addMediaItem()
            local analysisTake = analysisItem:addTake()
            analysisTake:setSource(self:getSource())
            analysisTake:setStartOffset(leftBound)
            analysisItem:setLength(analysisLength)
            analysisItem:setShouldLoop(false)

            prepareExtStateForPitchDetection(analysisTake:getGUID(), settings)
            Reaper.mainCMD(analyzerID)
            local points = PitchGroup.getPitchPointsFromExtState(self, analysisTake)
            reaper.DeleteTrackMediaItem(self:getItem():getTrack(), analysisItem)

            return points

    end)
end

------------------ Setters ------------------

function MediaTake:setSource(source)
    reaper.SetMediaItemTake_Source(self.pointer, source)
end

function MediaTake:setStartOffset(startOffset)
    reaper.SetMediaItemTakeInfo_Value(self.pointer, "D_STARTOFFS", startOffset)
end

return MediaTake