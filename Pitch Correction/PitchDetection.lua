local reaper = reaper
local math = math

-- The difference equation from http://audition.ens.fr/adc/pdf/2002_JASA_YIN.pdf Figure (6)
local function d(array, lag)
    local sum = 0
    for i = 1, #array - lag do
        sum = sum + (array[i] * array[i + lag]) ^ 2
    end
    return sum
end
local function parabolicInterpolationOfArray(array, index)
    local x1 = index - 1
    local y1 = array[x1]
    local x2 = index
    local y2 = array[x2]
    local x3 = index + 1
    local y3 = array[x3]

    local denominator = (x1 - x2) * (x1 - x3) * (x2 - x3)
    local a = (x3 * (y2 - y1) + x2 * (y1 - y3) + x1 * (y3 - y2)) / denominator
    local b = (x3 * x3 * (y1 - y2) + x2 * x2 * (y3 - y1) + x1 * x1 * (y2 - y3)) / denominator
    --c = (x2 * x3 * (x2 - x3) * y1 + x3 * x1 * (x3 - x1) * y2 + x1 * x2 * (x1 - x2) * y3) / denominator
    return -b / (2.0 * a)
end
local function findIndexOfFirstMinimum(array, threshold)
    local indexOfFirstMinimumBelowThreshold
    local indexOfGlobalMinimum = 1
    local minimumValue = array[1]
    for i = 1, #array do
        local value = array[i]
        -- Find the global minimum in the case that there are no minimums below the threshold.
        if value < minimumValue then
            minimumValue = value
            indexOfGlobalMinimum = i
        end
        -- If there exists a minimum below the threshold, use the first one you find.
        if value < threshold then
            indexOfFirstMinimumBelowThreshold = i
            break
        end
    end

    if indexOfFirstMinimumBelowThreshold == nil then
        return indexOfGlobalMinimum
    end

    return parabolicInterpolationOfArray(array, indexOfFirstMinimumBelowThreshold)
end
local function getFrequency(array, sampleRate, minimumFrequency, maximumFrequency, threshold)
    local minimumLookIndex =  math.floor(sampleRate / maximumFrequency)
    local maximumLookIndex =  math.floor(math.min(sampleRate / minimumFrequency, #array))

    -- Calculate the cumulative mean normalized differences of the lag values between the indices
    -- that were determined by the minimum and maximum frequencies.
    local cmnds = {}
    local cmndIndex = 1
    local sumOfDifferences = 0
    for lag = minimumLookIndex, maximumLookIndex do
        local currentDifference = d(array, lag)
        sumOfDifferences = sumOfDifferences + currentDifference

        if lag >= minimumLookIndex then
            cmnds[cmndIndex] = currentDifference * lag / sumOfDifferences
            cmndIndex = cmndIndex + 1
        end
    end

    local relativeIndexOfMinimum = minimumLookIndex + findIndexOfFirstMinimum(cmnds, threshold)
    return sampleRate / relativeIndexOfMinimum
end

local PitchDetection = {}

function PitchDetection:getPitchPoints(take, startingTime, timeWindow, windowStep, windowOverlap, lowRMSLimitdB, minimumFrequency, maximumFrequency, threshold)
    local lowRMSLimit =   math.exp(lowRMSLimitdB * 0.11512925464970228420089957273422)
    local item =          reaper.GetMediaItemTakeInfo_Value(take, "P_ITEM")
    --local startOffset =   reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local source =        reaper.GetMediaItemTake_Source(take)
    local sampleRate =    reaper.GetMediaSourceSampleRate(source)
    local windowSamples = math.floor(sampleRate * windowStep)
    local seekPosition =  startingTime
    local accessor =      reaper.CreateTakeAudioAccessor(take)
    local sampleArray =   reaper.new_array(windowSamples)

    local pitchPoints = {}

    repeat
        reaper.GetAudioAccessorSamples(accessor, sampleRate, 1, seekPosition, windowSamples, sampleArray)

        -- Get RMS.
        local rms = 0
        for i = 1, windowSamples do
            rms = rms + math.abs(sampleArray[i])
        end
        rms = rms / windowSamples

        -- Perform pitch detection.
        if rms > lowRMSLimit then
            local frequency = getFrequency(sampleArray, sampleRate, minimumFrequency, maximumFrequency, threshold)

            if frequency > 0.0 then
                local pitch = 69 + 12 * math.log(frequency / 440.0) / math.log(2)
                pitch = math.min(math.max(pitch, 0), 127)

                local point = {
                    time = seekPosition,
                    pitch = pitch,
                    rms = rms
                }
                pitchPoints[#pitchPoints + 1] = point
            end
        end

        seekPosition = seekPosition + windowStep / windowOverlap

    until seekPosition >= startingTime + timeWindow

    reaper.DestroyAudioAccessor(accessor)

    return pitchPoints
end

return PitchDetection