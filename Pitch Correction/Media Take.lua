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

------------------ Getters ------------------

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

return MediaTake