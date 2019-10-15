package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Alk = require "API.Alkamist API"

local function getWhiteKeys()
    local whiteKeyMultiples = {1, 3, 4, 6, 8, 9, 11}
    local whiteKeys = {}
    for i = 1, 11 do
        for _, value in ipairs(whiteKeyMultiples) do
            table.insert(whiteKeys, (i - 1) * 12 + value)
        end
    end
    return whiteKeys
end

local PitchEditor = {}
function PitchEditor:new(object)
    local object = object or {}
    object._base = self
    self.init(object)
    return object
end

function PitchEditor:init()
    setmetatable(self, self)
    self.pixelWidth = self.pixelWidth or 0
    self.pixelHeight = self.pixelHeight or 0
    self.whiteKeys = getWhiteKeys()

    self.pitchHeight = 128

    self:setTrack()
    self.items = self.track.selectedItems
    self:setUpFunctionalIndexes()
end

function PitchEditor:setTrack()
    local topMostSelectedItemTrackNumber = #Alk.tracks
    for _, item in ipairs(Alk.selectedItems) do
        topMostSelectedItemTrackNumber = math.min(item.track.number, topMostSelectedItemTrackNumber)
    end
    self.track = Alk.tracks[topMostSelectedItemTrackNumber]
end

function PitchEditor:setUpFunctionalIndexes()
    self.__index = function(tbl, key)
        if key == "timeWidth" then
            return self.items[#self.items].rightEdge - self.items[1].leftEdge
        end
        return self._base[key]
    end
end

function PitchEditor:getTimeFromPixels(xPixels)
    return self.timeWidth * (self.view.scroll.x / (self.pixelWidth * self.view.zoom.x))
end

function PitchEditor:getPixelsFromTime(time)
    return self.view.zoom.x * self.pixelWidth * (time / self.timeWidth - self.view.scroll.x)
end

function PitchEditor:getPitchFromPixels(yPixels)
    return self.timeWidth * (1.0 - (self.view.scroll.y / (self.pixelHeight * self.view.zoom.y))) - 0.5
end

function PitchEditor:getPixelsFromPitch(pitch)
    local pitchRatio = 1.0 - (0.5 + pitch) / self.pitchHeight
    return self.view.zoom.y * self.pixelHeight * (pitchRatio - self.view.scroll.y)
end