local reaper = reaper
local math = math

function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

local function getCepstralCoefficients(reaperArray, arraySize, fftLength)
    reaperArray.fft(fftLength)
    for i = 1, arraySize do
        reaperArray[i] = math.log(math.abs(reaperArray[i]))
    end
    reaperArray.ifft(fftLength)
end

local item =             reaper.GetSelectedMediaItem(0, 0)
local take =             reaper.GetActiveTake(item)
local accessor =         reaper.CreateTakeAudioAccessor(take)
local startTime =        0.0
local timeWindow =       3.0
local source =           reaper.GetMediaItemTake_Source(take)
local sampleRate =       reaper.GetMediaSourceSampleRate(source)
local numberOfSamples =  timeWindow * sampleRate
local numberOfChannels = 1
local sampleArray =      reaper.new_array(numberOfSamples)

reaper.GetAudioAccessorSamples(accessor, sampleRate, numberOfChannels, startTime, numberOfSamples, sampleArray)

--local fftLength = math.floor(timeWindow * sampleRate)
--getCepstralCoefficients(sampleArray, numberOfSamples, fftLength)
local fftSize = 8192
sampleArray.fft(fftSize, true)
sampleArray.resize(fftSize * 2)
for i = 1, fftSize * 2 do
    sampleArray[i] = math.log(math.abs(sampleArray[i]))
end
sampleArray.ifft(fftSize, true)

--fx.set(0.4, 0.4, 0.4, 1.0, 0)
--ocal drawHeight = 0.1
--ocal drawY = 300

--local sampleSkip = math.floor(numberOfSamples / 1024)

local maxValue = 0
local maxIndex = 0
for i = 1, fftSize do
    local value = math.abs(sampleArray[i])
    if value > maxValue then
        maxValue = value
        maxIndex = i
    end
end

msg(maxIndex)
--msg((sampleRate * 0.5) * 0.5 * maxIndex / fftSize)

--local function run()
--    local char = gfx.getchar()
--
--    --for i = 2, math.floor(numberOfSamples / sampleSkip) do
--    --    local index =         i * sampleSkip
--    --    local previousIndex = (i - 1) * sampleSkip
--    --    gfx.line(i - 1, drawY - sampleArray[previousIndex] * drawHeight, i, drawY - sampleArray[index] * drawHeight, true)
--    --end
--    local offset = math.max(4.0 * gfx.mouse_x, 0)
--    for i = 2, 1024 do
--        gfx.line(100 + i - 1,
--                 drawY - sampleArray[math.min(offset + i - 1, fftSize * 2)] * drawHeight,
--                 100 + i,
--                 drawY - sampleArray[math.min(offset + i, fftSize * 2)] * drawHeight,
--                 true)
--    end
--
--    if char ~= -1 then reaper.defer(run) end
--    gfx.update()
--end
--
--gfx.init("", 1024, 700, 0, 200, 200)
--run()