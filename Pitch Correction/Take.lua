local reaper = reaper
local math = math
local pairs = pairs

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local function mainCommand(id)
    if type(id) == "string" then
        reaper.Main_OnCommand(reaper.NamedCommandLookup(id), 0)
    else
        reaper.Main_OnCommand(id, 0)
    end
end
local function activateAndGetPitchEnvelope(pointer)
    local take = pointer
    if take then
        local pitchEnvelope = reaper.GetTakeEnvelopeByName(take, "Pitch")
        if not pitchEnvelope or not reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
            mainCommand("_S&M_TAKEENV10") -- Show and unbypass take pitch envelope
            pitchEnvelope = reaper.GetTakeEnvelopeByName(take, "Pitch")
            --mainCommand("_S&M_TAKEENVSHOW8") -- Hide take pitch envelope
        end
        return pitchEnvelope
    end
end

local Take = {}
function Take:new(parameters)
    local parameters = parameters or {}
    local self = parameters.fromObject or {}

    local _pointer = parameters.pointer

    function self:getPointer() return _pointer end
    function self:setPointer(pointer) _pointer = pointer end
    function self:getItem() return reaper.GetMediaItemTake_Item(_pointer) end
    function self:getName() return reaper.GetTakeName(_pointer) end
    function self:getGUID() return reaper.BR_GetMediaItemTakeGUID(_pointer) end
    function self:getPlayRate() return reaper.GetMediaItemTakeInfo_Value(_pointer, "D_PLAYRATE") end
    function self:getSource() return reaper.GetMediaItemTake_Source(_pointer) end
    function self:getFileName() return reaper.GetMediaSourceFileName(self:getSource(), ""):match("[^/\\]+$") end
    function self:getSampleRate() return reaper.GetMediaSourceSampleRate(self:getSource()) end
    function self:getStartOffset() return self:getSourceTime(0.0) end
    function self:getTrack() return reaper.GetMediaItem_Track(self:getItem()) end
    function self:getLength() return reaper.GetMediaItemInfo_Value(self:getItem(), "D_LENGTH") end
    function self:getLeftTime() return reaper.GetMediaItemInfo_Value(self:getItem(), "D_POSITION") end
    function self:getRightTime() return self:getLeftTime() + self:getLength() end
    function self:getSourceLength()
        local _, _, sourceLength = reaper.PCM_Source_GetSectionInfo(self:getSource())
        return sourceLength
    end
    function self:isMIDI() return reaper.TakeIsMIDI(_pointer) end
    function self:getPitchEnvelope() return activateAndGetPitchEnvelope(_pointer) end
    function self:getSourceTime(time)
        if time == nil then return nil end
        local take = _pointer
        local tempMarkerIndex = reaper.SetTakeStretchMarker(take, -1, time * reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE"))
        local _, _, sourceTime = reaper.GetTakeStretchMarker(take, tempMarkerIndex)
        reaper.DeleteTakeStretchMarkers(take, tempMarkerIndex)
        return sourceTime
    end
    function self:getRealTime(sourceTime)
        local sourceTime = sourceTime or 0.0
        local take = _pointer
        if take == nil then return nil end
        local getSourceTime = self.getSourceTime
        if reaper.GetTakeNumStretchMarkers(take) < 1 then
            local startOffset = getSourceTime(self, 0.0)
            local playRate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
            return (sourceTime - startOffset) / playRate
        end

        local tolerance = 0.000001

        local guessTime = 0.0
        local guessSourceTime = getSourceTime(self, guessTime)
        local numberOfLoops = 0
        while true do
            local error = sourceTime - guessSourceTime
            if math.abs(error) < tolerance then break end

            local testGuessSourceTime = getSourceTime(self, guessTime + error)
            local seekRatio = math.abs( error / (testGuessSourceTime - guessSourceTime) )

            guessTime = guessTime + error * seekRatio
            guessSourceTime = getSourceTime(self, guessTime)

            numberOfLoops = numberOfLoops + 1
            if numberOfLoops > 100 then break end
        end

        return guessTime
    end
    function self:clearPitchEnvelope()
        local envelope = self:getPitchEnvelope()
        reaper.DeleteEnvelopePointRange(envelope, -self:getStartOffset(), self:getSourceLength() * self:getPlayRate())
        reaper.Envelope_SortPoints(envelope)
        reaper.UpdateArrange()
    end

    return self
end

return Take