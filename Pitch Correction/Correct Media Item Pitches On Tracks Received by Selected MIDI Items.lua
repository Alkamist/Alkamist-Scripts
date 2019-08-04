local label = "Pitch Test.lua"

local edgePointSpacing = 0.01

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

function getPitchAnalyzerCommandID()
    local kbini = reaper.GetResourcePath() .. '/reaper-kb.ini'
    local file = io.open(kbini, 'r')
    local cont = file:read('a')

    if not file then
        return
    else
        file:close()
    end

    local nameString

    for line in cont:gmatch('[^\r\n]+') do
        if line:match('Pitch Analyzer') then nameString = line:match('SCR %d+ %d+ ([%a%_%d]+)') break end
    end

    local commandID =  reaper.NamedCommandLookup('_' .. nameString)

    if commandID ~= 0 then
        return true, commandID
    end
end

function correctTakePitchToMIDINotes(take, midiNotes)
    local takeGUID = reaper.BR_GetMediaItemTakeGUID(take)
    local _, extState = reaper.GetProjExtState(0, "Alkamist_PitchCorrection", takeGUID)

    local pitchData = {}

    for line in extState:gmatch("[^\r\n]+") do
        if line:match("PT") then
            local stat = {}
            for value in line:gmatch("[%.%-%d]+") do
                stat[#stat + 1] = tonumber(value)
            end
            pitchData[stat[1]] = {}
            pitchData[stat[1]].position = stat[2]
            pitchData[stat[1]].note = stat[3]
            pitchData[stat[1]].rms = stat[4]
        end
    end

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

    for i = 1, #midiNotes do
        local relativeMIDINotePosition = midiNotes[i].position - itemPosition
        local relativeMIDINoteEnd = relativeMIDINotePosition + midiNotes[i].length

        local clearStart = takePlayrate * relativeMIDINotePosition
        local clearEnd = takePlayrate * relativeMIDINoteEnd

        if midiNotes[i].overlaps == false then
            reaper.InsertEnvelopePoint(pitchEnvelope, relativeMIDINotePosition * takePlayrate - edgePointSpacing, 0, 0, 0, false, true)
        end

        if midiNotes[i].isOverlapped == false then
            reaper.InsertEnvelopePoint(pitchEnvelope, relativeMIDINoteEnd * takePlayrate + edgePointSpacing, 0, 0, 0, false, true)
        end

        for j = 1, #pitchData do
            local relativePitchPointPosition = pitchData[j].position - takeSourceOffset
            local pitchPointIsInBoundsOfMIDINote = relativePitchPointPosition >= relativeMIDINotePosition and relativePitchPointPosition <= relativeMIDINoteEnd

            if pitchPointIsInBoundsOfMIDINote then
                local noteOffset = midiNotes[i].note - pitchData[j].note

                reaper.InsertEnvelopePoint(pitchEnvelope, relativePitchPointPosition * takePlayrate, noteOffset, 0, 0, false, true)
            end
        end
    end

    reaper.Envelope_SortPointsEx(pitchEnvelope, -1)
end

function main()
    local ret, analyzerCommandID = getPitchAnalyzerCommandID()
    if ret and analyzerCommandID and analyzerCommandID ~= 0 then
    else
        msg("Pitch Analyzer.eel not found!")
        return
    end

    local midiItem = reaper.GetSelectedMediaItem(0, 0)
    local midiItemTake = reaper.GetActiveTake(midiItem)
    local midiItemTrack = reaper.GetMediaItemTrack(midiItem)
    local midiItemPosition = reaper.GetMediaItemInfo_Value(midiItem, "D_POSITION")
    local midiItemLength = reaper.GetMediaItemInfo_Value(midiItem, "D_LENGTH")
    local midiItemEnd = midiItemPosition + midiItemLength
    local midiItemStartOffset = reaper.GetMediaItemTakeInfo_Value(midiItemTake, "D_STARTOFFS")
    local _, numMIDINotes, _, _ = reaper.MIDI_CountEvts(midiItemTake)

    if reaper.TakeIsMIDI(midiItemTake) then
        local midiItemTrackNumSends =  reaper.GetTrackNumSends(midiItemTrack, 0)

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

                if itemShouldBeProcessed and getItemType(currentItem) == "audio" then
                    reaperCMD(40289) -- Unselect all items.
                    reaper.SetMediaItemSelected(currentItem, true)

                    local take = reaper.GetActiveTake(currentItem)
                    local takeGUID = reaper.BR_GetMediaItemTakeGUID(take)

                    reaper.SetProjExtState(0, "Alkamist_PitchCorrection", "currentTakeGUID", takeGUID)

                    local pitchEnvelope = reaper.GetTakeEnvelopeByName(take, "Pitch")
                    if pitchEnvelope and reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
                        local clearStart = currentItemTakePlayrate * (midiItemPosition - currentItemPosition)
                        local clearLength = currentItemTakePlayrate * midiItemLength
                        local clearEnd = clearStart + clearLength

                        local leftEdgePointPosition = clearStart - edgePointSpacing * currentItemTakePlayrate
                        local rightEdgePointPosition = clearEnd + edgePointSpacing * currentItemTakePlayrate
                        local _, leftEdgePointValue = reaper.Envelope_Evaluate(pitchEnvelope, leftEdgePointPosition, 44100, 0)
                        local _, rightEdgePointValue = reaper.Envelope_Evaluate(pitchEnvelope, rightEdgePointPosition, 44100, 0)

                        reaper.InsertEnvelopePoint(pitchEnvelope, leftEdgePointPosition, leftEdgePointValue, 0, 0, false, true)
                        reaper.InsertEnvelopePoint(pitchEnvelope, rightEdgePointPosition, rightEdgePointValue, 0, 0, false, true)

                        reaper.DeleteEnvelopePointRange(pitchEnvelope, clearStart, clearStart + clearLength)

                        reaper.InsertEnvelopePoint(pitchEnvelope, clearStart, 0, 0, 0, false, true)
                        reaper.InsertEnvelopePoint(pitchEnvelope, clearEnd, 0, 0, 0, false, true)
                        reaper.Envelope_SortPointsEx(pitchEnvelope, -1)

                        reaperCMD(analyzerCommandID)
                    else
                        reaperCMD(41612) -- Take: Toggle take pitch envelope
                        reaperCMD(analyzerCommandID)
                        pitchEnvelope = reaper.GetTakeEnvelopeByName(take, "Pitch")
                    end

                    local inputNotes = {}
                    local noteIndex = 1
                    for k = 1, numMIDINotes do
                        local _, _, noteIsMuted, notePPQStart, notePPQEnd, noteChannel, notePitch, noteVelocity = reaper.MIDI_GetNote(midiItemTake, k - 1)

                        if not noteIsMuted then
                            inputNotes[noteIndex] = {}
                            inputNotes[noteIndex].position = math.max(reaper.MIDI_GetProjTimeFromPPQPos(midiItemTake, notePPQStart), midiItemPosition)
                            inputNotes[noteIndex].rightBound = math.min(reaper.MIDI_GetProjTimeFromPPQPos(midiItemTake, notePPQEnd), midiItemEnd)
                            inputNotes[noteIndex].length = inputNotes[noteIndex].rightBound - inputNotes[noteIndex].position
                            inputNotes[noteIndex].note = notePitch

                            if noteIndex > 1 then
                                inputNotes[noteIndex - 1].isOverlapped = inputNotes[noteIndex].position <= inputNotes[noteIndex - 1].rightBound + edgePointSpacing
                                inputNotes[noteIndex].overlaps = inputNotes[noteIndex - 1].isOverlapped

                                if inputNotes[noteIndex - 1].isOverlapped then
                                    inputNotes[noteIndex - 1].rightBound = inputNotes[noteIndex].position
                                    inputNotes[noteIndex - 1].length = inputNotes[noteIndex - 1].rightBound - inputNotes[noteIndex - 1].position
                                end
                            end

                            -- Handle the edge cases at the end.
                            if k == numMIDINotes then
                                inputNotes[1].overlaps = false
                                inputNotes[#inputNotes].isOverlapped = false
                            end

                            noteIndex = noteIndex + 1
                        end
                    end

                    correctTakePitchToMIDINotes(take, inputNotes)
                end
            end
        end
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(label, -1)
reaper.UpdateArrange()