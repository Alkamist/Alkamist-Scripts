local reaper = reaper
local math = math

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

local function meanOfArray(array, startingIndex, windowSamples)
    local sum = 0
    for i = startingIndex, startingIndex + windowSamples - 1 do
        sum = sum + array[i]
    end
    return sum / windowSamples
end
local function autocovariance(array, startingIndex, windowSamples, mean, lag)
    local endingIndex = startingIndex + windowSamples - 1 - lag
    local output = 0
    for i = startingIndex, endingIndex do
        output = output + (array[i] - mean) * (array[i + lag] - mean)
    end
    return output / windowSamples
end
local function autocorrelation(array, startingIndex, windowSamples, lag)
    local mean = meanOfArray(array, startingIndex, windowSamples)
    return autocovariance(array, startingIndex, windowSamples, mean, lag)
         / autocovariance(array, startingIndex, windowSamples, mean, 0)
end

local item =         reaper.GetSelectedMediaItem(0, 0)
local take =         reaper.GetActiveTake(item)
local accessor =     reaper.CreateTakeAudioAccessor(take)
local source =       reaper.GetMediaItemTake_Source(take)
local sampleRate =   reaper.GetMediaSourceSampleRate(source)

local windowStep =   0.04
local overlap =      2.0
local minFrequency = 80
local maxFrequency = 1000
local YINThreshold = 0.2
local rmsLimitdB =   -60.0

local startingTime =     0.0
local timeWindow =       3.0
local numberOfSamples =  math.floor(timeWindow * sampleRate)
local numberOfChannels = 1

local sampleArray =      reaper.new_array(numberOfSamples)
reaper.GetAudioAccessorSamples(accessor, sampleRate, numberOfChannels, startingTime, numberOfSamples, sampleArray)

msg(getFrequency(sampleArray, sampleRate, 1, 500, 80, 1000))

