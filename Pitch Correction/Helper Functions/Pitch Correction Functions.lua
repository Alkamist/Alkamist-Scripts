package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Reaper = require "Various Functions.Reaper Functions"
local PitchCorrection = require "Pitch Correction.Classes.Class - PitchCorrection"
local PitchPoint = require "Pitch Correction.Classes.Class - PitchPoint"



local PCFunc = {}



local edgePointSpacing = 0.01

function PCFunc.prepareExtStateForPitchCorrection(takeGUID, settings)
    reaper.SetExtState("Alkamist_PitchCorrection", "TAKEGUID", takeGUID, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "WINDOWSTEP", settings.windowStep, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "MINFREQ", settings.minimumFrequency, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "MAXFREQ", settings.maximumFrequency, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "YINTHRESH", settings.YINThresh, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "OVERLAP", settings.overlap, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "LOWRMSLIMDB", settings.lowRMSLimitdB, false)
end

function PCFunc.getEELCommandID(name)
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

function PCFunc.getPitchDataGroupsFromPitchDataString(takeName, pitchDataString)
    local pitchDataGroups = {}
    local pitchRanges = {}

    for line in pitchDataString:gmatch("[^\r\n]+") do
        if line:match("<PITCHDATA") then
            local range = {}
            range.leftTime = tonumber(line:match("<PITCHDATA (%d+.%d+)"))
            range.rightTime = tonumber(line:match("<PITCHDATA %d+.%d+ (%d+.%d+)"))

            table.insert(pitchRanges, range)
        end
    end

    for index, range in pairs(pitchRanges) do
        pitchDataGroups[index] = {}

        pitchDataGroups[index].leftTime = range.leftTime
        pitchDataGroups[index].rightTime = range.rightTime
        pitchDataGroups[index].points = PitchPoint.getRawPointsByPitchDataStringInTimeRange(pitchDataString, range.leftTime, range.rightTime)
    end

    return pitchDataGroups
end

function PCFunc.getPreviousPitchDataGroups(takeName)
    local _, extState = reaper.GetProjExtState(0, "Alkamist_PitchCorrection", takeName)

    return PCFunc.getPitchDataGroupsFromPitchDataString(takeName, extState)
end

function PCFunc.getCombinedPitchDataGroup(favoredGroup, secondaryGroup)
    local groupsAreOverlapping = favoredGroup.leftTime >= secondaryGroup.leftTime and favoredGroup.leftTime <= secondaryGroup.rightTime
                              or favoredGroup.rightTime >= secondaryGroup.leftTime and favoredGroup.rightTime <= secondaryGroup.rightTime

                              or secondaryGroup.leftTime >= favoredGroup.leftTime and secondaryGroup.leftTime <= favoredGroup.rightTime
                              or secondaryGroup.rightTime >= favoredGroup.leftTime and secondaryGroup.rightTime <= favoredGroup.rightTime

    if groupsAreOverlapping then
        local outputGroup = {}

        outputGroup.points = {}
        outputGroup.leftTime = math.min(favoredGroup.leftTime, secondaryGroup.leftTime)
        outputGroup.rightTime = math.max(favoredGroup.rightTime, secondaryGroup.rightTime)

        local favoredPointsWereInserted = false
        for secondaryIndex, secondaryPoint in ipairs(secondaryGroup.points) do

            if secondaryPoint.time < favoredGroup.leftTime or secondaryPoint.time > favoredGroup.rightTime then
                table.insert(outputGroup.points, secondaryPoint)
            end

            if not favoredPointsWereInserted then

                if secondaryPoint.time >= favoredGroup.leftTime then

                    for favoredIndex, favoredPoint in ipairs(favoredGroup.points) do
                        table.insert(outputGroup.points, favoredPoint)
                    end

                    favoredPointsWereInserted = true

                end

            end

        end

        return outputGroup, true

    end

    return favoredGroup, false
end

function PCFunc.getAnalysisStringFromDataGroups(dataGroups)
    local analysisString = ""

    for dataGroupIndex, dataGroup in pairs(dataGroups) do
        local dataString = ""

        for pointIndex, point in pairs(dataGroup.points) do
            dataString = dataString .. string.format("    %f %f %f\n", point.time, point.pitch, point.rms)
        end

        analysisString = analysisString .. "<PITCHDATA " .. string.format("%f %f\n", dataGroup.leftTime, dataGroup.rightTime) ..
                                               dataString ..
                                           ">\n"
    end

    return analysisString
end

function PCFunc.analyzePitch(takeGUID, settings)
    local analyzerID = PCFunc.getEELCommandID("Pitch Analyzer")

    if not analyzerID then
        reaper.MB("Pitch Analyzer.eel not found!", "Error!", 0)
        return 0
    end

    local take = reaper.GetMediaItemTakeByGUID(0, takeGUID)
    local takeName = reaper.GetTakeName(take)
    local item = reaper.GetMediaItemTakeInfo_Value(take, "P_ITEM")
    local startOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

--    local stretchMarkersString = ""
--    local numStretchMarkers = reaper.GetTakeNumStretchMarkers(take)
--    for i = 1, numStretchMarkers do
--        local _, pos, srcPos = reaper.GetTakeStretchMarker(take, i - 1)
--
--        stretchMarkersString = stretchMarkersString .. string.format("    %i %f %f\n", i, pos, srcPos)
--    end


    PCFunc.prepareExtStateForPitchCorrection(takeGUID, settings)
    Reaper.reaperCMD(analyzerID)


    --local prevPitchPoints = PitchPoint.getPitchPointsFromTakeName(takeName)
    --local dataPitchPoints = PCFunc.getPitchPointsFromDataString(takeGUID)

--    local analysisString = "PLAYRATE " .. playrate .. "\n" ..
--
--                           "<STRETCHMARKERS\n" .. stretchMarkersString ..
--                           ">\n" ..
--
--                           "STARTOFFSET " .. startOffset .. "\n" ..
--                           "LENGTH " .. length .. "\n" ..
--
--                           "<PITCHDATA\n" .. pitchData ..
--                           ">\n"

    local prevPitchDataGroups = PCFunc.getPreviousPitchDataGroups(takeName)

    local pitchDataString = reaper.GetExtState("Alkamist_PitchCorrection", "PITCHDATA")
    local pitchDataGroup = PCFunc.getPitchDataGroupsFromPitchDataString(takeName, pitchDataString)[1]

    local outputDataGroups = {}

    if #prevPitchDataGroups > 0 then

        for index, prevDataGroup in pairs(prevPitchDataGroups) do
            local dataGroupCombined = false
            pitchDataGroup, dataGroupCombined = PCFunc.getCombinedPitchDataGroup(pitchDataGroup, prevDataGroup)

            if not dataGroupCombined then
                table.insert(outputDataGroups, prevDataGroup)
            end

            if index == #prevPitchDataGroups then
                table.insert(outputDataGroups, pitchDataGroup)
            end
        end

    else

        table.insert(outputDataGroups, pitchDataGroup)

    end

    local analysisString = PCFunc.getAnalysisStringFromDataGroups(outputDataGroups)

    --msg(analysisString)

    reaper.SetProjExtState(0, "Alkamist_PitchCorrection", takeName, analysisString)
end

function PCFunc.itemPitchesNeedRecalculation(currentItem, settings)
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

    if math.abs(previousItemLength - currentItemLength) > changeTolerance then return true end
    if math.abs(previousStartOffset - currentItemStartOffset) > changeTolerance  then return true end
    if math.abs(previousPlayrate - currentItemTakePlayrate) > changeTolerance  then return true end
    if math.abs(previousNumStretchMarkers - currentNumStretchMarkers) > changeTolerance then return true end

    if math.abs(previousWindow - settings.windowStep) > changeTolerance then return true end
    if math.abs(previousMinF - settings.minimumFrequency) > changeTolerance then return true end
    if math.abs(previousMaxF - settings.maximumFrequency) > changeTolerance then return true end
    if math.abs(previousLowRMSLim - settings.lowRMSLimitdB) > changeTolerance then return true end
    if math.abs(previousOverlap - settings.overlap) > changeTolerance then return end
    if math.abs(previousYINThresh - settings.YINThresh) > changeTolerance then return end

    for i = 1, currentNumStretchMarkers do
        local _, stretchPos, stretchSourcePos = reaper.GetTakeStretchMarker(currentItemTake, i - 1)

        if math.abs(previousStretchMarkers[i].position - stretchPos) > changeTolerance then return true end
        if math.abs(previousStretchMarkers[i].sourcePosition - stretchSourcePos) > changeTolerance then return true end
    end

    return false
end

function PCFunc.savePitchCorrectionsInExtState(takeGUID, pitchCorrections)
    --local _, extState = reaper.GetProjExtState(0, "Alkamist_PitchCorrection", takeGUID .. "_corrections")

    local pitchCorrectionsString = ""
    for key, correction in PitchCorrection.pairs(pitchCorrections) do
        pitchCorrectionsString = pitchCorrectionsString .. "LEFTTIME " .. tostring(correction.leftTime) .. "\n" ..
                                                           "RIGHTTIME " .. tostring(correction.rightTime) .. "\n" ..
                                                           "LEFTPITCH " .. tostring(correction.leftPitch) .. "\n" ..
                                                           "RIGHTPITCH " .. tostring(correction.rightPitch) .. "\n" ..
                                                           "OVERLAPS " .. tostring(correction.overlaps) .. "\n" ..
                                                           "ISOVERLAPPED " .. tostring(correction.isOverlapped) .. "\n"
    end
    reaper.SetProjExtState(0, "Alkamist_PitchCorrection", takeGUID .. "_corrections", pitchCorrectionsString)
end

function PCFunc.correctPitchBasedOnMIDIItem(midiItem, settings)
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
                    Reaper.reaperCMD(40289) -- Unselect all items.
                    reaper.SetMediaItemSelected(currentItem, true)

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
                        Reaper.reaperCMD(41612) -- Take: Toggle take pitch envelope
                        pitchEnvelope = reaper.GetTakeEnvelopeByName(currentItemTake, "Pitch")
                    end

                    -- Calculating the pitches of items takes a long time. Only do it if we need to.
                    if itemPitchesNeedRecalculation(currentItem, settings) then
                        -- Document the previous pitch, and then change the pitch to 0.0 for processing.
                        local currentTakePitch = reaper.GetMediaItemTakeInfo_Value(currentItemTake, "D_PITCH")
                        reaper.SetMediaItemTakeInfo_Value(currentItemTake, "D_PITCH", 0.0)
                        -- Hide and bypass the take pitch envelope, so the EEL script process the pure audio.
                        Reaper.reaperCMD("_S&M_TAKEENV11")
                        -- Analyze the audio to determine its pitches.
                        if PCFunc.analyzePitch(currentItemTake) == 0 then return 0 end
                        -- Set the pitch back to what it once was after the processing.
                        reaper.SetMediaItemTakeInfo_Value(currentItemTake, "D_PITCH", currentTakePitch)
                        -- Show and unbypass the take pitch envelope.
                        Reaper.reaperCMD("_S&M_TAKEENV10")
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

                    --savePitchCorrectionsInExtState(reaper.BR_GetMediaItemTakeGUID(currentItemTake), overlapHandledCorrections)
                    PitchCorrection.correctTakePitchToPitchCorrections(currentItemTake, pitchCorrections)
                end
            end
        end
    end
end

return PCFunc