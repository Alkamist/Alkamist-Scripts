local reaper = reaper
local type = type
local math = math
local io = io

local Reaper = {}

function Reaper.mainCommand(id)
    if type(id) == "string" then
        reaper.Main_OnCommand(reaper.NamedCommandLookup(id), 0)
    else
        reaper.Main_OnCommand(id, 0)
    end
end
function Reaper.getEELCommandID(name)
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
function Reaper.getTakePitchEnvelope(take)
    local pitchEnvelope = reaper.GetTakeEnvelopeByName(take, "Pitch")
    if not pitchEnvelope or not reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
        Reaper.mainCommand("_S&M_TAKEENV10") -- Show and unbypass take pitch envelope
        pitchEnvelope = reaper.GetTakeEnvelopeByName(take, "Pitch")
        --mainCommand("_S&M_TAKEENVSHOW8") -- Hide take pitch envelope
    end
    return pitchEnvelope
end
function Reaper.getTakeSourceTime(take, time)
    local tempMarkerIndex = reaper.SetTakeStretchMarker(take, -1, time * reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE"))
    local _, _, sourceTime = reaper.GetTakeStretchMarker(take, tempMarkerIndex)
    reaper.DeleteTakeStretchMarkers(take, tempMarkerIndex)
    return sourceTime
end
--local function clearPitchEnvelope(take)
--    local envelope = self.pitchEnvelope
--    reaper.DeleteEnvelopePointRange(envelope, -self.startOffset, self.sourceLength / self.playRate)
--    reaper.Envelope_SortPoints(envelope)
--    reaper.UpdateArrange()
--end
function Reaper.getTakeRealTime(take, sourceTime)
    if reaper.GetTakeNumStretchMarkers(take) < 1 then
        local startOffset = Reaper.getTakeSourceTime(take, 0.0)
        local playRate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
        return (sourceTime - startOffset) / playRate
    end

    local tolerance = 0.000001

    local guessTime = 0.0
    local guessSourceTime = Reaper.getTakeSourceTime(take, guessTime)
    local numberOfLoops = 0
    while true do
        local error = sourceTime - guessSourceTime
        if math.abs(error) < tolerance then break end

        local testGuessSourceTime = Reaper.getTakeSourceTime(take, guessTime + error)
        local seekRatio = math.abs( error / (testGuessSourceTime - guessSourceTime) )

        guessTime = guessTime + error * seekRatio
        guessSourceTime = Reaper.getTakeSourceTime(take, guessTime)

        numberOfLoops = numberOfLoops + 1
        if numberOfLoops > 100 then break end
    end

    return guessTime
end

return Reaper