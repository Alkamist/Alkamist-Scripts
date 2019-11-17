local reaper = reaper
local math = math

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")

local function mainCommand(id)
    if type(id) == "string" then
        reaper.Main_OnCommand(reaper.NamedCommandLookup(id), 0)
    else
        reaper.Main_OnCommand(id, 0)
    end
end
local function activateAndGetPitchEnvelope(pointer)
    local take = pointer
    local pitchEnvelope = reaper.GetTakeEnvelopeByName(take, "Pitch")
    if not pitchEnvelope or not reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
        mainCommand("_S&M_TAKEENV10") -- Show and unbypass take pitch envelope
        pitchEnvelope = reaper.GetTakeEnvelopeByName(take, "Pitch")
        --mainCommand("_S&M_TAKEENVSHOW8") -- Hide take pitch envelope
    end
    return pitchEnvelope
end

local Take = {}
function Take:new(parameters)
    local parameters = parameters or {}
    local self = parameters.from or {}

    self.pointer = nil
    self.item = {
        get = function(self)
            local take = self.pointer
            if take then return reaper.GetMediaItemTake_Item(self.pointer) end
        end
    }
    self.name = {
        get = function(self)
            local take = self.pointer
            if take then return reaper.GetTakeName(take) end
        end
    }
    self.GUID = {
        get = function(self)
            local take = self.pointer
            if take then return reaper.BR_GetMediaItemTakeGUID(take) end
        end
    }
    self.source = {
        get = function(self)
            local take = self.pointer
            if take then return reaper.GetMediaItemTake_Source(take) end
        end
    }
    self.fileName = {
        get = function(self)
            local source = self.source
            if source then return reaper.GetMediaSourceFileName(source, ""):match("[^/\\]+$") end
        end
    }
    self.sampleRate = {
        get = function(self)
            local source = self.source
            if source then return reaper.GetMediaSourceSampleRate(source) end
        end
    }
    self.playRate = {
        get = function(self)
            local take = self.pointer
            if take then return reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE") end
        end
    }
    self.startOffset = {
        get = function(self)
            local take = self.pointer
            if take then return self:getSourceTime(0.0) end
        end
    }
    self.track = {
        get = function(self)
            local item = self.item
            if item then return reaper.GetMediaItem_Track(item) end
        end
    }
    self.length = {
        get = function(self)
            local item = self.item
            if item then return reaper.GetMediaItemInfo_Value(item, "D_LENGTH") end
        end
    }
    self.leftTime = {
        get = function(self)
            local item = self.item
            if item then return reaper.GetMediaItemInfo_Value(item, "D_POSITION") end
        end
    }
    self.rightTime = {
        get = function(self)
            local leftTime = self.leftTime
            local rightTime = self.length
            if leftTime and rightTime then return leftTime + rightTime end
        end
    }
    self.sourceLength = {
        get = function(self)
            local source = self.source
            if source then
                local _, _, sourceLength = reaper.PCM_Source_GetSectionInfo(source)
                return sourceLength
            end
        end
    }
    self.isMIDI = {
        get = function(self)
            local take = self.pointer
            if take then return reaper.TakeIsMIDI(take) end
        end
    }
    self.pitchEnvelope = { get = function(self) return activateAndGetPitchEnvelope(self.pointer) end }

    function self:getSourceTime(time)
        if time == nil then return nil end
        local take = self.pointer
        local tempMarkerIndex = reaper.SetTakeStretchMarker(take, -1, time * reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE"))
        local _, _, sourceTime = reaper.GetTakeStretchMarker(take, tempMarkerIndex)
        reaper.DeleteTakeStretchMarkers(take, tempMarkerIndex)
        return sourceTime
    end
    function self:getRealTime(sourceTime)
        local take = self.pointer
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
        local envelope = self.pitchEnvelope
        reaper.DeleteEnvelopePointRange(envelope, -self.startOffset, self.sourceLength * self.playRate)
        reaper.Envelope_SortPoints(envelope)
        reaper.UpdateArrange()
    end

    return Proxy:new(self, parameters)
end

return Take