function copyObject(object, seen)
    if type(object) ~= "table" then return object end
    if seen and seen[object] then return seen[object] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(object))
    s[object] = res
    for k, v in pairs(object) do res[copyObject(k, s)] = copyObject(v, s) end
    return res
end

------------------- Class -------------------
PitchCorrection = {}

function PitchCorrection:new(leftTime, rightTime, leftPitch, rightPitch)
    local object = {}

    object.leftTime = leftTime or 0
    object.rightTime = rightTime or 0
    object.leftPitch = leftPitch or 0
    object.rightPitch = rightPitch or 0

    setmetatable(object, self)
    self.__index = self
    return object
end

function PitchCorrection:getLength()
    return self.rightTime - self.leftTime
end

function PitchCorrection:getInterval()
    return self.rightPitch - self.leftPitch
end

function PitchCorrection:getPitch(time)
    local length = self:getLength()
    if length ~= 0 then
        local timeRatio = (time - self.leftTime) / self:getLength()
        local rawPitch = self.leftPitch + self:getInterval() * timeRatio
        local clampedPitch = math.min(math.max(rawPitch, self.leftPitch), self.rightPitch)
        return clampedPitch
    else
        return self.leftPitch
    end
end


------------------- Sorting -------------------
function pcPairs(pitchCorrections)
    local temp = {}
    for key, correction in pairs(pitchCorrections) do
        table.insert(temp, {key, correction})
    end

    table.sort(temp, function(pc1, pc2)
        local pc1GoesFirst = pc1[2].leftTime < pc2[2].leftTime
        if pc1[2].leftTime == pc2[2].leftTime then
            pc1GoesFirst = pc1[2].rightTime > pc2[2].rightTime
        end
        return pc1GoesFirst
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

function getOverlapHandledPitchCorrections(pitchCorrections)
    local newCorrections = {}
    local overlapCorrections = {}
    local finalOverlapCorrections = {}
    local finalOverlapTime = 0
    local firstWasNotOverlapped = true

    local loopIndex = 1
    local previousKey = nil

    for key, correction in pcPairs(pitchCorrections) do
        if loopIndex == 1 then
            overlapCorrections.left = correction
            overlapCorrections.slide = correction
            overlapCorrections.right = correction
        else
            local overlapTime = overlapCorrections.slide.rightTime - correction.leftTime

            if overlapTime > 0 then
                finalOverlapTime = overlapTime

                local leftCorrection = copyObject(overlapCorrections.slide)
                leftCorrection.rightPitch = leftCorrection:getPitch(leftCorrection.rightTime - overlapTime)
                leftCorrection.rightTime = leftCorrection.rightTime - overlapTime

                local slideCorrection = PitchCorrection:new(correction.leftTime,
                                                            overlapCorrections.right.rightTime,
                                                            overlapCorrections.slide:getPitch(correction.leftTime),
                                                            correction:getPitch(overlapCorrections.right.rightTime))

                local rightCorrection = copyObject(correction)
                rightCorrection.leftTime = overlapCorrections.right.rightTime

                overlapCorrections.left = leftCorrection
                overlapCorrections.slide = slideCorrection
                overlapCorrections.right = rightCorrection

                finalOverlapCorrections.left = leftCorrection
                finalOverlapCorrections.slide = slideCorrection
                finalOverlapCorrections.right = rightCorrection

                if loopIndex == 2 then
                    firstWasNotOverlapped = false
                end
            else
                overlapCorrections.left = correction
                overlapCorrections.slide = correction
                overlapCorrections.right = correction
            end

            table.insert(newCorrections, overlapCorrections.left)
        end

        previousKey = key
        loopIndex = loopIndex + 1
    end

    if finalOverlapTime > 0 then
        table.insert(newCorrections, finalOverlapCorrections.slide)
        table.insert(newCorrections, finalOverlapCorrections.right)
    end

    if firstWasNotOverlapped and loopIndex > 1 then
        table.insert(newCorrections, pitchCorrections[1])
    end

    return newCorrections
end