package.path = reaper.GetResourcePath().. package.config:sub(1,1) .. "?.lua;" .. package.path

require "Scripts.Alkamist Scripts.Pitch Correction.Classes.Class - PitchCorrection"

local label = "Correct Pitch of Audio Items on Tracks Received by Selected MIDI Items.lua"

-- Pitch correction settings:
local edgePointSpacing = 0.01
local averageCorrection = 1.0
local modCorrection = 0.4
local driftCorrection = 1.0
local driftCorrectionSpeed = 0.17
local zeroPointThreshold = 0.1

-- Pitch detection settings:
local settings = {}
settings.maximumLength = 300
settings.windowStep = 0.04
settings.overlap = 2.0
settings.minimumFrequency = 60
settings.maximumFrequency = 1000
settings.YINThresh = 0.2
settings.lowRMSLimitdB = -60

local timePerPoint = settings.windowStep / settings.overlap
local driftCorrectionNumPoints = math.max(math.floor(driftCorrectionSpeed / timePerPoint), 1)

function msg(m)
  reaper.ShowConsoleMsg(tostring(m).."\n")
end

function reaperCMD(id)
    if type(id) == "string" then
        reaper.Main_OnCommand(reaper.NamedCommandLookup(id), 0)
    else
        reaper.Main_OnCommand(id, 0)
    end
end

function getItemType(item)
    local _, selectedChunk =  reaper.GetItemStateChunk(item, "", 0)
    local itemType = string.match(selectedChunk, "<SOURCE%s(%P%P%P).*\n")

    if itemType == nil then
        return "empty"
    elseif itemType == "MID" then
        return "midi"
    else
        return "audio"
    end
end

function itemIsValid(item)
    local itemExists = reaper.ValidatePtr(item, "MediaItem*")
    return item ~= nil and itemExists
end

function setItemSelected(item, selected)
    if itemIsValid(item) then
        reaper.SetMediaItemSelected(item, selected)
    end
end

function getSelectedItems()
    local outputItems = {}
    local numSelectedItems = reaper.CountSelectedMediaItems(0)
    for i = 1, numSelectedItems do
        local temporaryItem = reaper.GetSelectedMediaItem(0, i - 1)
        outputItems[i] = temporaryItem
    end
    return outputItems
end

function restoreSelectedItems(items)
    if items ~= nil then
        reaperCMD(40289) -- unselect all items
        for i = 1, #items do
            setItemSelected(items[i], true)
        end
    end
end

function getEELCommandID(name)
    local kbini = reaper.GetResourcePath() .. '/reaper-kb.ini'
    local file = io.open(kbini, 'r')

    local content = nil
    if file then
        content = file:read('a')
        file:close()
    end

    if content then
        local nameString = nil
        for line in content:gmatch('[^\r\n]+') do
            if line:match(name) then
                nameString = line:match('SCR %d+ %d+ ([%a%_%d]+)')
                break
            end
        end

        local commandID = nil
        if nameString then
            commandID = reaper.NamedCommandLookup('_' .. nameString)
        end

        if commandID and commandID ~= 0 then
            return commandID
        end
    end

    return nil
end

function analyzePitch()
    local analyzerID = getEELCommandID("Pitch Analyzer")

    if analyzerID then
        reaperCMD(analyzerID)
    else
        reaper.MB("Pitch Analyzer.eel not found!", "Error!", 0)
        return 0
    end
end

function getPitchData(takeGUID)
    local _, extState = reaper.GetProjExtState(0, "Alkamist_PitchCorrection", takeGUID)

    local takePitchData = {}
    for line in extState:gmatch("[^\r\n]+") do
        if line:match("PT") then
            local stat = {}
            for value in line:gmatch("[%.%-%d]+") do
                stat[#stat + 1] = tonumber(value)
            end
            takePitchData[stat[1]] = {}
            takePitchData[stat[1]].index = stat[1]
            takePitchData[stat[1]].position = stat[2]
            takePitchData[stat[1]].note = stat[3]
            takePitchData[stat[1]].rms = stat[4]
        end
    end

    return takePitchData
end

function correctTakePitchToPitchCorrections(take, pitchCorrections)
    local takeGUID = reaper.BR_GetMediaItemTakeGUID(take)
    local takePitchData = getPitchData(takeGUID)

    local takeItem = reaper.GetMediaItemTakeInfo_Value(take, "P_ITEM")
    local takeSourceOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local takePlayrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local itemPosition = reaper.GetMediaItemInfo_Value(takeItem, "D_POSITION")
    local itemLength = reaper.GetMediaItemInfo_Value(takeItem, "D_LENGTH")

    local pitchEnvelope = reaper.GetTakeEnvelopeByName(take, "Pitch")
    if not pitchEnvelope or not reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
        reaperCMD(41612) -- Take: Toggle take pitch envelope
        pitchEnvelope = reaper.GetTakeEnvelopeByName(take, "Pitch")
    end

    local previousPointIndex = 1
    for key, correction in pcPairs(pitchCorrections) do
        local clearStart = takePlayrate * correction.leftTime
        local clearEnd = takePlayrate * correction.rightTime

        if not correction.overlaps then
            reaper.InsertEnvelopePoint(pitchEnvelope, correction.leftTime * takePlayrate - edgePointSpacing, 0, 0, 0, false, true)
        end
        if not correction.isOverlapped then
            reaper.InsertEnvelopePoint(pitchEnvelope, correction.rightTime * takePlayrate + edgePointSpacing, 0, 0, 0, false, true)
        end

        local pitchData = {}
        local noteAverage = 0
        local dataIndex = 1
        for j = 1, #takePitchData do
            local relativePitchPointPosition = takePitchData[j].position - takeSourceOffset
            local pitchPointIsInPitchCorrection = relativePitchPointPosition >= correction.leftTime and relativePitchPointPosition <= correction.rightTime

            if pitchPointIsInPitchCorrection then
                pitchData[dataIndex] = takePitchData[j]
                noteAverage = noteAverage + takePitchData[j].note
                dataIndex = dataIndex + 1
            end
        end
        noteAverage = noteAverage / #pitchData

        -- Add edge points just before and after the beginning and end of pitch content.
        local firstEdgePointTime = (takePitchData[1].position - takeSourceOffset) - edgePointSpacing
        reaper.InsertEnvelopePoint(pitchEnvelope, firstEdgePointTime * takePlayrate, 0, 0, 0, false, true)
        local lastEdgePointTime = (takePitchData[#takePitchData].position - takeSourceOffset) + edgePointSpacing
        reaper.InsertEnvelopePoint(pitchEnvelope, lastEdgePointTime * takePlayrate, 0, 0, 0, false, true)

        for j = 1, #pitchData do
            -- Record the time passed since the last point.
            local timePassedSinceLastPoint = pitchData[j].position - takePitchData[previousPointIndex].position
            if j > 1 then timePassedSinceLastPoint = pitchData[j].position - pitchData[j - 1].position end

            local relativePitchPointPosition = pitchData[j].position - takeSourceOffset

            -- If a certain amount of time has passed since the last point, add zero value edge points in that space.
            if j > 1 and zeroPointThreshold then
                if timePassedSinceLastPoint >= zeroPointThreshold then
                    local zeroPoint1Time = (pitchData[j - 1].position - takeSourceOffset) + edgePointSpacing
                    reaper.InsertEnvelopePoint(pitchEnvelope, zeroPoint1Time * takePlayrate, 0, 0, 0, false, true)
                    local zeroPoint2Time = relativePitchPointPosition - edgePointSpacing
                    reaper.InsertEnvelopePoint(pitchEnvelope, zeroPoint2Time * takePlayrate, 0, 0, 0, false, true)
                end
            end

            local targetNote = correction:getPitch(pitchData[j].position - takeSourceOffset)
            --local targetNote = correction.rightPitch

            local averageDeviation = noteAverage - targetNote
            local pitchCorrection = -averageDeviation * averageCorrection

            -- Process the pitch drift.
            local pitchDrift = 0
            local driftEndIndex = 0
            for k = 1, driftCorrectionNumPoints do
                local driftIndex = j + k - math.floor(driftCorrectionNumPoints * 0.5)
                if driftIndex > 0 and driftIndex < #pitchData then
                    local pointIsInDriftTime = math.abs(pitchData[driftIndex].position - pitchData[j].position) <= driftCorrectionSpeed / 2.0
                    if pointIsInDriftTime then
                        pitchDrift = pitchDrift + (pitchData[driftIndex].note + pitchCorrection - targetNote)
                        driftEndIndex = driftEndIndex + 1
                    end
                end
            end
            if driftEndIndex > 0 then
                pitchDrift = pitchDrift / driftEndIndex
            end

            -- Apply the pitch drift to the pitch correction.
            local scaledPitchDrift = pitchDrift * driftCorrection
            pitchCorrection = pitchCorrection - scaledPitchDrift

            -- Apply mod correction to the pitch correction.
            local modDeviation = pitchData[j].note + pitchCorrection - targetNote
            pitchCorrection = pitchCorrection - modDeviation * modCorrection

            -- Add envelope points with the correction value.
            reaper.InsertEnvelopePoint(pitchEnvelope, relativePitchPointPosition * takePlayrate, pitchCorrection, 0, 0, false, true)

            previousPointIndex = pitchData[j].index
        end
    end

    reaper.Envelope_SortPointsEx(pitchEnvelope, -1)
end

function itemPitchesNeedRecalculation(currentItem, settings)
    local changeTolerance = 0.000001

    local currentItemPosition = reaper.GetMediaItemInfo_Value(currentItem, "D_POSITION")
    local currentItemLength = reaper.GetMediaItemInfo_Value(currentItem, "D_LENGTH")
    local currentItemTake = reaper.GetActiveTake(currentItem)
    local currentItemTakePlayrate = reaper.GetMediaItemTakeInfo_Value(currentItemTake, "D_PLAYRATE")
    local currentItemStartOffset = reaper.GetMediaItemTakeInfo_Value(currentItemTake, "D_STARTOFFS")
    local currentItemEnd = currentItemPosition + currentItemLength
    local currentNumStretchMarkers = reaper.GetTakeNumStretchMarkers(currentItemTake)
    local takeGUID = reaper.BR_GetMediaItemTakeGUID(currentItemTake)
    local _, extState = reaper.GetProjExtState(0, "Alkamist_PitchCorrection", takeGUID)

    local itemNeedsRecalculation = false

    local previousItemLength = extState:match("LENGTH ([%.%-%d]+)")
    local previousStartOffset = extState:match("STARTOFFSET ([%.%-%d]+)")
    local previousPlayrate = extState:match("PLAYRATE ([%.%-%d]+)")
    local previousNumStretchMarkers = extState:match("NUMSTRETCHMARKERS ([%.%-%d]+)")

    local previousWindow = extState:match("WINDOW ([%.%-%d]+)")
    local previousMinF = extState:match("MINF ([%.%-%d]+)")
    local previousMaxF = extState:match("MAXF ([%.%-%d]+)")
    local previousLowRMSLim = extState:match("LOWRMSLIM ([%.%-%d]+)")
    local previousOverlap = extState:match("OVERLAP ([%.%-%d]+)")
    local previousYINThresh = extState:match("YINTHRESH ([%.%-%d]+)")

    local extStateIsProper = previousItemLength and previousStartOffset and previousPlayrate and previousNumStretchMarkers
    if not extStateIsProper then
        return true
    end

    local previousStretchMarkers = {}
    for line in extState:gmatch("[^\r\n]+") do
        if line:match("SM") then
            local stat = {}
            for value in line:gmatch("[%.%-%d]+") do
                stat[#stat + 1] = tonumber(value)
            end
            previousStretchMarkers[stat[1]] = {}
            previousStretchMarkers[stat[1]].position = stat[2]
            previousStretchMarkers[stat[1]].sourcePosition = stat[3]
        end
    end

    if math.abs(previousItemLength - currentItemLength) > changeTolerance then itemNeedsRecalculation = true end
    if math.abs(previousStartOffset - currentItemStartOffset) > changeTolerance  then itemNeedsRecalculation = true end
    if math.abs(previousPlayrate - currentItemTakePlayrate) > changeTolerance  then itemNeedsRecalculation = true end
    if math.abs(previousNumStretchMarkers - currentNumStretchMarkers) > changeTolerance then itemNeedsRecalculation = true end

    if math.abs(previousWindow - settings.windowStep) > changeTolerance then itemNeedsRecalculation = true end
    if math.abs(previousMinF - settings.minimumFrequency) > changeTolerance then itemNeedsRecalculation = true end
    if math.abs(previousMaxF - settings.maximumFrequency) > changeTolerance then itemNeedsRecalculation = true end
    if math.abs(previousLowRMSLim - settings.lowRMSLimitdB) > changeTolerance then itemNeedsRecalculation = true end
    if math.abs(previousOverlap - settings.overlap) > changeTolerance then itemNeedsRecalculation = true end
    if math.abs(previousYINThresh - settings.YINThresh) > changeTolerance then itemNeedsRecalculation = true end

    if not itemNeedsRecalculation then
        for i = 1, currentNumStretchMarkers do
            local _, stretchPos, stretchSourcePos = reaper.GetTakeStretchMarker(currentItemTake, i - 1)

            if math.abs(previousStretchMarkers[i].position - stretchPos) > changeTolerance then itemNeedsRecalculation = true end
            if math.abs(previousStretchMarkers[i].sourcePosition - stretchSourcePos) > changeTolerance then itemNeedsRecalculation = true end
        end
    end

    return itemNeedsRecalculation
end

function saveSettingsInExtState(settings)
    reaper.SetExtState("Alkamist_PitchCorrection", "MAXLENGTH", settings.maximumLength, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "WINDOWSTEP", settings.windowStep, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "OVERLAP", settings.overlap, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "MINFREQ", settings.minimumFrequency, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "MAXFREQ", settings.maximumFrequency, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "YINTHRESH", settings.YINThresh, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "LOWRMSLIMDB", settings.lowRMSLimitdB, false)
end

function correctPitchBasedOnMIDIItem(midiItem, settings)
    if midiItem == nil then
        return
    end

    local midiItemTake = reaper.GetActiveTake(midiItem)
    local midiItemTrack = reaper.GetMediaItemTrack(midiItem)
    local midiItemPosition = reaper.GetMediaItemInfo_Value(midiItem, "D_POSITION")
    local midiItemLength = reaper.GetMediaItemInfo_Value(midiItem, "D_LENGTH")
    local midiItemEnd = midiItemPosition + midiItemLength
    local midiItemStartOffset = reaper.GetMediaItemTakeInfo_Value(midiItemTake, "D_STARTOFFS")
    local _, numMIDINotes, _, _ = reaper.MIDI_CountEvts(midiItemTake)

    -- Only proceed if you are selecting a MIDI item.
    if reaper.TakeIsMIDI(midiItemTake) then
        local midiItemTrackNumSends =  reaper.GetTrackNumSends(midiItemTrack, 0)

        -- Go through all of the track sends and process any audio items on those tracks that should be processed.
        for i = 1, midiItemTrackNumSends do
            local currentTrack = reaper.GetTrackSendInfo_Value(midiItemTrack, 0, i - 1, "P_DESTTRACK")

            for j = 1, reaper.GetTrackNumMediaItems(currentTrack) do
                local currentItem = reaper.GetTrackMediaItem(currentTrack, j - 1)
                local currentItemPosition = reaper.GetMediaItemInfo_Value(currentItem, "D_POSITION")
                local currentItemLength = reaper.GetMediaItemInfo_Value(currentItem, "D_LENGTH")
                local currentItemTake = reaper.GetActiveTake(currentItem)
                local currentItemTakePlayrate = reaper.GetMediaItemTakeInfo_Value(currentItemTake, "D_PLAYRATE")
                local currentItemEnd = currentItemPosition + currentItemLength
                local currentItemStartsInMIDIItem = currentItemPosition >= midiItemPosition and currentItemPosition <= midiItemEnd
                local currentItemEndsInMIDIItem = currentItemEnd >= midiItemPosition and currentItemEnd <= midiItemEnd
                local currentItemStartsBeforeMIDIItem = currentItemPosition < midiItemPosition
                local currentItemEndsAfterMIDIItem = currentItemEnd > midiItemEnd
                local itemShouldBeProcessed = currentItemStartsInMIDIItem or currentItemEndsInMIDIItem or (currentItemStartsBeforeMIDIItem and currentItemEndsAfterMIDIItem)

                -- An item has to be an audio item and also be within the bounds of the
                -- MIDI item that is influencing the pitch.
                if itemShouldBeProcessed and getItemType(currentItem) == "audio" then
                    reaperCMD(40289) -- Unselect all items.
                    reaper.SetMediaItemSelected(currentItem, true)

                    -- Save the current GUID of the item take we are processing in the ext state.
                    -- Since there is no way to pass arguments to the external EEL script, we need
                    -- to do this so it knows which item to process.
                    local takeGUID = reaper.BR_GetMediaItemTakeGUID(currentItemTake)
                    reaper.SetProjExtState(0, "Alkamist_PitchCorrection", "currentTakeGUID", takeGUID)

                    -- If a take pitch envelope already exists, then we need to clean the content in it
                    -- that exists within the bounds of the MIDI item.
                    local pitchEnvelope = reaper.GetTakeEnvelopeByName(currentItemTake, "Pitch")
                    if pitchEnvelope and reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
                        local clearStart = currentItemTakePlayrate * (midiItemPosition - currentItemPosition)
                        local clearLength = currentItemTakePlayrate * midiItemLength
                        local clearEnd = clearStart + clearLength

                        local leftEdgePointPosition = clearStart - edgePointSpacing * currentItemTakePlayrate
                        local rightEdgePointPosition = clearEnd + edgePointSpacing * currentItemTakePlayrate
                        local _, leftEdgePointValue = reaper.Envelope_Evaluate(pitchEnvelope, leftEdgePointPosition, 44100, 0)
                        local _, rightEdgePointValue = reaper.Envelope_Evaluate(pitchEnvelope, rightEdgePointPosition, 44100, 0)

                        -- Add some edgepoints so there aren't any slanted lines running into the processing area.
                        reaper.InsertEnvelopePoint(pitchEnvelope, leftEdgePointPosition, leftEdgePointValue, 0, 0, false, true)
                        reaper.InsertEnvelopePoint(pitchEnvelope, rightEdgePointPosition, rightEdgePointValue, 0, 0, false, true)

                        -- Clean up the envelope within the bounds of the MIDI item.
                        reaper.DeleteEnvelopePointRange(pitchEnvelope, clearStart, clearStart + clearLength)

                        -- Insert 0 value points at the start and end of where we are processing.
                        reaper.InsertEnvelopePoint(pitchEnvelope, clearStart, 0, 0, 0, false, true)
                        reaper.InsertEnvelopePoint(pitchEnvelope, clearEnd, 0, 0, 0, false, true)
                        reaper.Envelope_SortPointsEx(pitchEnvelope, -1)
                    else
                        reaperCMD(41612) -- Take: Toggle take pitch envelope
                        pitchEnvelope = reaper.GetTakeEnvelopeByName(currentItemTake, "Pitch")
                    end

                    -- Calculating the pitches of items takes a long time. Only do it if we need to.
                    if itemPitchesNeedRecalculation(currentItem, settings) then
                        -- Document the previous pitch, and then change the pitch to 0.0 for processing.
                        local currentTakePitch = reaper.GetMediaItemTakeInfo_Value(currentItemTake, "D_PITCH")
                        reaper.SetMediaItemTakeInfo_Value(currentItemTake, "D_PITCH", 0.0)
                        -- Hide and bypass the take pitch envelope, so the EEL script process the pure audio.
                        reaperCMD("_S&M_TAKEENV11")
                        -- Analyze the audio to determine its pitches.
                        if analyzePitch() == 0 then return 0 end
                        -- Set the pitch back to what it once was after the processing.
                        reaper.SetMediaItemTakeInfo_Value(currentItemTake, "D_PITCH", currentTakePitch)
                        -- Show and unbypass the take pitch envelope.
                        reaperCMD("_S&M_TAKEENV10")
                    end

                    local pitchCorrections = {}
                    for k = 1, numMIDINotes do
                        local _, _, noteIsMuted, notePPQStart, notePPQEnd, noteChannel, notePitch, noteVelocity = reaper.MIDI_GetNote(midiItemTake, k - 1)

                        -- Only use notes that are not muted for processing.
                        if not noteIsMuted then
                            local pitchCorrection = PitchCorrection:new()
                            pitchCorrection.leftTime = math.max(reaper.MIDI_GetProjTimeFromPPQPos(midiItemTake, notePPQStart), midiItemPosition) - currentItemPosition
                            pitchCorrection.rightTime = math.min(reaper.MIDI_GetProjTimeFromPPQPos(midiItemTake, notePPQEnd), midiItemEnd) - currentItemPosition
                            pitchCorrection.leftPitch = notePitch
                            pitchCorrection.rightPitch = notePitch

                            table.insert(pitchCorrections, pitchCorrection)
                        end
                    end

                    local overlapHandledCorrections = getOverlapHandledPitchCorrections(pitchCorrections)

                    correctTakePitchToPitchCorrections(currentItemTake, overlapHandledCorrections)
                end
            end
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

saveSettingsInExtState(settings)
local selectedItems = getSelectedItems()

for i = 1, #selectedItems do
    local item = selectedItems[i]
    correctPitchBasedOnMIDIItem(item, settings)
end

restoreSelectedItems(selectedItems)

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(label, -1)
reaper.UpdateArrange()