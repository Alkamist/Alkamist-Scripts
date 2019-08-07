------------------- Class -------------------
PitchPoint = {}

function PitchPoint:new(takeGUID, index, time, pitch, rms)
    local object = {}

    object.takeGUID = takeGUID or nil
    local take = reaper.GetMediaItemTakeByGUID(0, takeGUID) or nil

    object.index = index or 0
    object.time = time - reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS") or 0
    object.pitch = pitch or 0
    object.rms = rms or 0

    object.correctedPitch = pitch or 0

    setmetatable(object, self)
    self.__index = self
    return object
end



function PitchPoint:getTake()
    return reaper.GetMediaItemTakeByGUID(0, self.takeGUID)
end

function PitchPoint:getPlayrate()
    return reaper.GetMediaItemTakeInfo_Value(self:getTake(), "D_PLAYRATE")
end

function PitchPoint:getEnvelope()
    local pitchEnvelope = reaper.GetTakeEnvelopeByName(self:getTake(), "Pitch")
    if not pitchEnvelope or not reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
        reaper.Main_OnCommand(41612, 0) -- Take: Toggle take pitch envelope
        pitchEnvelope = reaper.GetTakeEnvelopeByName(self:getTake(), "Pitch")
    end

    return pitchEnvelope
end



------------------- Sorting -------------------
function ppPairs(pitchPoints)
    local temp = {}
    for key, correction in pairs(pitchPoints) do
        table.insert(temp, {key, correction})
    end

    table.sort(temp, function(pp1, pp2)
        return pp1[2].index < pp2[2].index
    end)

    local i = 0
    local iterator = function()
        i = i + 1

        if temp[i] == nil then
            return nil
        else
            return temp[i][1], temp[i][2]
        end
    end

    return iterator
end



------------------- Helpful Functions -------------------
function getAveragePitch(pitchPoints)
    local pitchAverage = 0

    for key, point in ppPairs(pitchPoints) do
        pitchAverage = pitchAverage + point.correctedPitch
    end

    return pitchAverage / #pitchPoints
end

function getPitchPointsInTimeRange(pitchPoints, leftTime, rightTime)
    local newPoints = {}
    local dataIndex = 1
    for key, point in ppPairs(pitchPoints) do
        if point.time >= leftTime and point.time <= rightTime then
            newPoints[dataIndex] = point
            dataIndex = dataIndex + 1
        end
    end

    return newPoints
end

function getPitchPoints(takeGUID)
    local _, extState = reaper.GetProjExtState(0, "Alkamist_PitchCorrection", takeGUID)

    local takePitchPoints = {}
    for line in extState:gmatch("[^\r\n]+") do
        if line:match("PT") then
            local stat = {}
            for value in line:gmatch("[%.%-%d]+") do
                stat[#stat + 1] = tonumber(value)
            end
            takePitchPoints[stat[1]] = PitchPoint:new(takeGUID, stat[1], stat[2], stat[3], stat[4])
        end
    end

    return takePitchPoints
end