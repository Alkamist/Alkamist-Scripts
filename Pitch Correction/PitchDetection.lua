local reaper = reaper
local math = math

-- The difference equation from http://audition.ens.fr/adc/pdf/2002_JASA_YIN.pdf Figure (6)
local function d(array, lag)
    local sum = 0
    for i = 1, #array - lag do
        sum = sum + (array[i] - array[i + lag]) ^ 2
    end
    return sum
end
local function average(array, lengthOfAverage)
    local sum = 0
    for i = 1, lengthOfAverage do
        sum = sum + array[i]
    end
    return sum / lengthOfAverage
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
    local minimumValue = threshold
    local indexOfMinimum = -1;

    for i = 2, #array - 1 do
        local value = array[i]
        if value < threshold then
            if value > minimumValue then break end
            minimumValue = value
            indexOfMinimum = i
        end
    end

    if indexOfMinimum == -1 then
        return -1
    else
        return parabolicInterpolationOfArray(array, indexOfMinimum)
    end
end
--local function getFrequency(array, sampleRate, minimumFrequency, maximumFrequency, threshold)
--    local minimumLookIndex = math.floor(sampleRate / maximumFrequency)
--    local maximumLookIndex = math.floor(math.min(sampleRate / minimumFrequency, #array))
--    local lookWindowLength = maximumLookIndex - minimumLookIndex
--
--    local differences = {}
--    local cmnds = {
--        [1] = 1
--    }
--
--    for i = 1, lookWindowLength do
--        differences[i] = d(array, minimumLookIndex + i - 1)
--    end
--    for i = 2, lookWindowLength do
--        cmnds[i] = differences[i] / average(differences, i - 1)
--    end
--
--    local indexOfFirstMinimum = findIndexOfFirstMinimum(cmnds, threshold)
--
--    local frequency = 0
--    if indexOfFirstMinimum > -1 then
--        frequency = sampleRate / (minimumLookIndex + indexOfFirstMinimum)
--    end
--    return frequency
--end
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

        cmnds[cmndIndex] = currentDifference * lag / sumOfDifferences
        cmndIndex = cmndIndex + 1
    end

    local indexOfFirstMinimum = findIndexOfFirstMinimum(cmnds, threshold)
    local frequency = 0
    if indexOfFirstMinimum > -1 then
        frequency = sampleRate / (minimumLookIndex + indexOfFirstMinimum)
    end
    return frequency
end

local PitchDetection = {}

function PitchDetection:getPitchPoints(take, startingTime, timeWindow, windowStep, windowOverlap, lowRMSLimitdB, minimumFrequency, maximumFrequency, threshold)
    local lowRMSLimit =   math.exp(lowRMSLimitdB * 0.11512925464970228420089957273422)
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