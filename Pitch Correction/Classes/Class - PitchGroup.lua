package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

--local Lua = require "Various Functions.Lua Functions"
local Reaper = require "Various Functions.Reaper Functions"



------------------- Class -------------------

local PitchGroup = {}

function PitchGroup:new(o)
    o = o or {}

    setmetatable(o, self)
    self.__index = self

    o:setItem(o.item)

    return o
end

function PitchGroup.prepareExtStateForPitchDetection(takeGUID, settings)
    reaper.SetExtState("Alkamist_PitchCorrection", "TAKEGUID", takeGUID, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "WINDOWSTEP", settings.windowStep, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "MINFREQ", settings.minimumFrequency, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "MAXFREQ", settings.maximumFrequency, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "YINTHRESH", settings.YINThresh, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "OVERLAP", settings.overlap, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "LOWRMSLIMDB", settings.lowRMSLimitdB, false)
end

function PitchGroup:analyze(settings)
    local analyzerID = Reaper.getEELCommandID("Pitch Analyzer")

    if not analyzerID then
        reaper.MB("Pitch Analyzer.eel not found!", "Error!", 0)
        return 0
    end

    PitchGroup.prepareExtStateForPitchDetection(self.takeGUID, settings)
    Reaper.reaperCMD(analyzerID)

    local analysisString = reaper.GetExtState("Alkamist_PitchCorrection", "PITCHDATA")

    self.points = PitchGroup.getPointsFromString(analysisString)

    self:savePoints()
end

function PitchGroup:savePoints()
    --local _, extState = reaper.GetProjExtState(0, "Alkamist_PitchCorrection", self.takeName)
    local dataHeader = self:getDataHeader()
    local dataString = self:getDataString()

    local saveString = dataHeader .. dataString

    reaper.SetProjExtState(0, "Alkamist_PitchCorrection", self.takeName, saveString)
end

function PitchGroup:getSavedPoints()
    local _, extState = reaper.GetProjExtState(0, "Alkamist_PitchCorrection", self.takeName)
    local dataHeader = self:getDataHeader()

    local headerStart, headerEnd = string.find(extState, dataHeader)
    local pointString = ""

    -- Search through the ext state for any relevant points and write them to the point string.
    if headerStart and headerEnd then
        local searchIndex = headerEnd
        local recordPointData = false

        repeat

            local line = string.match(extState, "([^\r\n]+)", searchIndex)
            if line == nil then break end

            if line:match("<PITCHDATA") then
                recordPointData = true
            end

            if line:match(">") and recordPointData then
                recordPointData = false
            end

            -- Record any points that are within the bounds of the item.
            if recordPointData then
                local pointTime = tonumber( line:match("    ([%.%-%d]+) [%.%-%d]+ [%.%-%d]+") )

                if pointTime then
                    if pointTime >= self.startOffset and pointTime <= self.startOffset + self.length then
                        pointString = pointString .. line .. "\n"
                    end
                end
            end

            searchIndex = searchIndex + string.len(line) + 1

        until string.match(line, "PLAYRATE")
    end

    return PitchGroup.getPointsFromString(pointString)
end

function PitchGroup:getEnvelope()
    local pitchEnvelope = reaper.GetTakeEnvelopeByName(self.take, "Pitch")

    if not pitchEnvelope or not reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
        reaper.Main_OnCommand(41612, 0) -- Take: Toggle take pitch envelope
        pitchEnvelope = reaper.GetTakeEnvelopeByName(self.take, "Pitch")
    end

    return pitchEnvelope
end

function PitchGroup.getPointsFromString(pointString)
    local points = {}

    for line in pointString:gmatch("[^\r\n]+") do

        table.insert(points, {

            time =  tonumber( line:match("([%.%-%d]+) [%.%-%d]+ [%.%-%d]+") ),
            pitch = tonumber( line:match("[%.%-%d]+ ([%.%-%d]+) [%.%-%d]+") ),
            rms =   tonumber( line:match("[%.%-%d]+ [%.%-%d]+ ([%.%-%d]+)") )

        } )

    end

    return points
end

function PitchGroup.getPitchGroupsFromItems(items)
    local pitchGroups = {}

    for index, item in pairs(items) do
        if reaper.ValidatePtr(item, "MediaItem*") then
            table.insert( pitchGroups, PitchGroup:new( { item = item } ) )
        end
    end

    return pitchGroups
end

function PitchGroup:getDataHeader()
    local stretchMarkersString = ""

    for markerIndex, marker in ipairs(self.stretchMarkers) do
        stretchMarkersString = stretchMarkersString .. string.format("    %f %f\n", marker.pos, marker.srcPos)
    end

    local dataHeader = "PLAYRATE " .. self.playrate .. "\n" ..

                       "<STRETCHMARKERS\n" .. stretchMarkersString ..
                       ">\n"

    return dataHeader
end

function PitchGroup:getDataString()
    local pitchString = ""

    for pointIndex, point in ipairs(self.points) do
        pitchString = pitchString .. string.format("    %f %f %f\n", point.time, point.pitch, point.rms)
    end

    local dataString = "<PITCHDATA " .. string.format("%f %f\n", self.startOffset, self.startOffset + self.length) ..
                            pitchString ..
                        ">\n"

    return dataString
end

function PitchGroup:setItem(item)
    self.item = item
    self.take = reaper.GetActiveTake(self.item)
    self.takeName = reaper.GetTakeName(self.take)
    self.takeGUID = reaper.BR_GetMediaItemTakeGUID(self.take)
    self.length = reaper.GetMediaItemInfo_Value(self.item, "D_LENGTH")
    self.leftTime = reaper.GetMediaItemInfo_Value(self.item, "D_POSITION")
    self.rightTime = self.leftTime + self.length
    self.playrate = reaper.GetMediaItemTakeInfo_Value(self.take, "D_PLAYRATE")
    self.startOffset = reaper.GetMediaItemTakeInfo_Value(self.take, "D_STARTOFFS")
    self.envelope = self:getEnvelope()
    self.stretchMarkers = Reaper.getStretchMarkers(self.take)
    self.points = self:getSavedPoints()
end

return PitchGroup