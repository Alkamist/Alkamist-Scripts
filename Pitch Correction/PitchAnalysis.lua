-- Based on http://recherche.ircam.fr/equipes/pcm/cheveign/pss/2002_JASA_YIN.pdf

local reaper = reaper
local math = math

-- Difference Function (YIN eq. 6)
local function d(tau, istart, iwinend)
    local sum = 0
    for i = 0, iwinend + 1 - istart - tau do
        sum = sum + sqr(istart[i] - istart[i + tau])
    end
    return sum
end
local function avg(imin, imax)
    local sum = 0
    for i = 0, imax - imin do
        sum = sum + imin[i]
    end
    return sum / (imax - imin)
end
local function parab(iclosest)
    local x1 = iclosest - 1
    local y1 = x1[0]
    local x2 = iclosest
    local y2 = iclosest[0]
    local x3 = iclosest + 1
    local y3 = x3[0]

    local denom = (x1 - x2) * (x1 - x3) * (x2 - x3)
    local a = (x3 * (y2 - y1) + x2 * (y1 - y3) + x1 * (y3 - y2)) / denom
    local b = (x3 * x3 * (y1 - y2) + x2 * x2 * (y3 - y1) + x1 * x1 * (y2 - y3)) / denom
    --local c = (x2 * x3 * (x2 - x3) * y1 + x3 * x1 * (x3 - x1) * y2 + x1 * x2 * (x1 - x2) * y3) / denom
    return -b / (2 * a)
end
local function findMin(istart, iend, threshold, sampleRate, minLook)
    local rmin = threshold
    local returnIndex = -sampleRate
    for i = 1, iend - istart - 10 do
        if istart[i] < rmin then
            rmin = istart[i]
            returnIndex = istart + i
        end
        if istart[i] > threshold then
            if rmin < threshold then
                rmin = -10
            end
        end
    end
    return minLook + parab(returnIndex) - istart;
end
local function lim(val, min0, max0)
    if min0 == 0 & max0 then
        min0 = 0
        max0 = 1
    end
    return math.max(min0, math.min(val, max0))
end
local function round(number)
    return number > 0 and math.floor(number + 0.5) or math.ceil(number - 0.5)
end
-- Cumulative Mean Normalized Difference (YIN eq. 8)
local function cmnd(tau, istart, iwinend)
    for i = 0, tau + 1 do
        dbufstart[i] = d(i, istart, iwinend)
    end
    if tau == 0 then
        return 1
    end
    return dbufstart[tau] / avg(dbufstart, dbufstart + tau + 1)
end
local function getFrequency(samplePosition, srate, winSamples, maxlen, windowStep, minFrequency, maxFrequency, YINthresh)
    local maxLook = math.floor(math.min(srate / minFrequency, winSamples))
    local minLook = math.floor(srate / maxFrequency)
    local dpos = winSamples + 100
    local cmndpos = dpos + maxLook + 100
    cmndpos[0] = 1

    for i = 0, maxLook - minLook + 1 do
        dpos[i] = d(minLook + i, samplePosition, samplePosition + winSamples)
    end
    for i = 1, maxLook - minLook + 1 do
        cmndpos[i] = dpos[i] / (avg(dpos, dpos + i + 1))
    end
    if avg(dpos, dpos + maxLook - minLook) > 0.00001 then
        freq = srate / findMin(cmndpos, cmndpos + 1 + maxLook - minLook, YINthresh, srate, minLook)
    else
        freq = 0
    end

    return math.max(freq, 0)
end

local function getPitchData(take, windowStep, overlap, minFrequency, maxFrequency, lowRMSlimitdB, YINthresh, startTime, timeWindow)
    local item =              reaper.GetMediaItemTakeInfo_Value(take, "P_ITEM")
    local startOffset =       reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local itemSource =        reaper.GetMediaItemTake_Source(take)
    local sourceSampleRate =  reaper.GetMediaSourceSampleRate(itemSource)
    local windowSamples =     math.floor(sourceSampleRate * windowStep)
    local seekPosition =      startTime
    local accessor =          reaper.CreateTakeAudioAccessor(take)
    local sampleArray =       reaper.new_array(windowSamples)

    repeat
        reaper.GetAudioAccessorSamples(accessor, sourceSampleRate, 1, seekPosition, windowSamples, sampleArray)

        -- Get RMS.
        local rms = 0
        for i = 1, windowSamples do
            rms = rms + math.abs(sampleArray[i])
        end
        rms = rms / windowSamples
        msg(rms)

--        -- Seek transient.
--        rmsdB = 20 * log10(rms * 2);
--        last_rmsdB = 20 * log10(last_rms * 2);
--
--        last_rms = rms;
--
--        -- Perform pitch detection.
--        if rms > lowRMSlimit then
--            frequency = getFrequency(samplePosition, sourceSampleRate, windowSamples, maxlen, windowStep, minFrequency, maxFrequency, YINthresh);
--            note = 69 + 12 * log(frequency / 440) / log(2);
--            note = min(max(note, 0), 127);
--
--            if frequency > 0 then
--                local time = seekPosition + startOffset
--                local note = note
--                local rms = rms
--            end
--        end
        seekPosition = seekPosition + windowStep / overlap

    until seekPosition >= startTime + timeWindow - windowStep

    reaper.DestroyAudioAccessor(accessor)
end