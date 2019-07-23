-- @description Render Tracks From Top Level
-- @version 1.0
-- @author Alkamist
-- @donate https://paypal.me/CoreyLehmanMusic
-- @about
--   This action will render the tracks you have selected up through all folders
--   they are children of. It will also include sends contained in those folders
--   in the render. You have to set up your render settings to be 'Stems (selected tracks)'
--   for it to work properly though. Also have your render settings have the filename
--   output as the $track wildcard.

label = 'Alkamist: Render Tracks From Top Level'

function msg(message)
  reaper.ShowConsoleMsg(tostring(message).."\n")
end

function reaperCMD(id)
    if type(id) == "string" then
        reaper.Main_OnCommand(reaper.NamedCommandLookup(id), 0)
    else
        reaper.Main_OnCommand(id, 0)
    end
end

function trackIsValid(track)
    local trackExists = reaper.ValidatePtr(track, "MediaTrack*")
    return track ~= nil and trackExists
end

function getSelectedTracks()
    local outputTracks = {}
    local numTracks = reaper.CountSelectedTracks(0)
    for i = 1, numTracks do
        local temporaryTrack = reaper.GetSelectedTrack(0, i - 1)
        outputTracks[i] = temporaryTrack
    end
    return outputTracks
end

function setTrackSelected(track, selected)
    if trackIsValid(track) then
        reaper.SetTrackSelected(track, selected)
    end
end

function restoreSelectedTracks(tracks)
    if tracks ~= nil then
        reaperCMD(40297) -- unselect all tracks
        for i = 1, #tracks do
            setTrackSelected(tracks[i], true)
        end
    end
end

function getTopLevelParentOfTrack(track)
    local currentParentTrack = reaper.GetParentTrack(track)
    local previousParentTrack = currentParentTrack

    while currentParentTrack ~= nil do
        previousParentTrack = currentParentTrack
        currentParentTrack = reaper.GetParentTrack(currentParentTrack)
    end

    return previousParentTrack
end

function waitSeconds(seconds)
    local startTime = reaper.time_precise()

    while reaper.time_precise() - startTime <= seconds do
    end
end

-- Make sure to lock any solo-defeated tracks. I can't seem to find a way to
-- check for that. This won't account for sends of sends so you should probably
-- lock those as well.
function muteIrrelevantTracks(track)
    local initialTrackSelection = getSelectedTracks()
    reaperCMD(40341) -- mute all tracks
    reaperCMD(40297) -- unselect all tracks
    reaperCMD(40340) -- unsolo all tracks

    reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 0)

    -- Unmute child tracks.
    setTrackSelected(track, true)
    reaperCMD("_SWS_SELCHILDREN2")
    reaperCMD(40731) -- unmute tracks

    -- Unmute sends.
    for i = 1, reaper.GetTrackNumSends(track, 0) do
        local currentTrack = reaper.GetTrackSendInfo_Value(track, 0, i - 1, "P_DESTTRACK")
        reaper.SetMediaTrackInfo_Value(currentTrack, "B_MUTE", 0)
    end

    -- Unmute receives.
    for i = 1, reaper.GetTrackNumSends(track, -1) do
        local currentTrack = reaper.GetTrackSendInfo_Value(track, -1, i - 1, "P_SRCTRACK")
        reaper.SetMediaTrackInfo_Value(currentTrack, "B_MUTE", 0)
    end

    -- Unmute parent tracks.
    local currentParentTrack = reaper.GetParentTrack(track)
    while currentParentTrack ~= nil do
        reaper.SetMediaTrackInfo_Value(currentParentTrack, "B_MUTE", 0)
        currentParentTrack = reaper.GetParentTrack(currentParentTrack)
    end

    restoreSelectedTracks(initialTrackSelection)
end



function renderTracksFromTopLevel()
    reaperCMD("_SWS_SAVETIME1")
    reaperCMD("_SWS_SAVEVIEW")
    reaperCMD("_BR_SAVE_CURSOR_POS_SLOT_1")

    -- Save the initial track selection.
    local initialTrackSelection = getSelectedTracks()

    -- Determine if we even have any tracks selected.
    if #initialTrackSelection <= 0 then
        return "no_tracks_selected"
    end

    -- Currently there is no way to check if a render is completed, so you can't do
    -- more than one track at a time. If they add that functionality you can take this
    -- part out to loop through the selected tracks and render.
    if #initialTrackSelection > 1 then
        return "more_than_one_track"
    end

    for i = 1, #initialTrackSelection do
        reaperCMD(40297) -- unselect all tracks
        reaperCMD(40340) -- unsolo all tracks

        local topLevelTrack = getTopLevelParentOfTrack(initialTrackSelection[i])

        if topLevelTrack ~= nil then
            local _, topLevelTrackName = reaper.GetSetMediaTrackInfo_String(topLevelTrack, "P_NAME", "", false)
            local _, currentTrackName = reaper.GetTrackName(initialTrackSelection[i], "")

            reaper.GetSetMediaTrackInfo_String(topLevelTrack, "P_NAME", currentTrackName, true)

            setTrackSelected(topLevelTrack, true)
            reaper.SetMediaTrackInfo_Value(initialTrackSelection[i], "I_SOLO", 1)

            reaperCMD("_BR_SAVE_SOLO_MUTE_ALL_TRACKS_SLOT_16")
            muteIrrelevantTracks(initialTrackSelection[i])

            -- You have to pause the script shortly or else the solo won't go through before the render.
            waitSeconds(0.1)
            reaperCMD(42230) -- render project, using the most recent render settings, auto-close render dialog

            reaper.GetSetMediaTrackInfo_String(topLevelTrack, "P_NAME", topLevelTrackName, true)
            reaperCMD("_BR_RESTORE_SOLO_MUTE_ALL_TRACKS_SLOT_16")
            reaperCMD(40340) -- unsolo all tracks
        else
            setTrackSelected(initialTrackSelection[i], true)
            reaperCMD(42230) -- render project, using the most recent render settings, auto-close render dialog
        end
    end

    -- Restore the initial track selection.
    restoreSelectedTracks(initialTrackSelection)

    reaperCMD("_BR_RESTORE_CURSOR_POS_SLOT_1")
    reaperCMD("_SWS_RESTOREVIEW")
    reaperCMD("_SWS_RESTTIME1")

    return 0
end



-- Check for errors and start the script.
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local errorResult = renderTracksFromTopLevel()
if errorResult == "no_tracks_selected" then
    reaper.ShowMessageBox("Please select one track.", "Error!", 0)
elseif errorResult == "more_than_one_track" then
    reaper.ShowMessageBox("Please select one track.", "Error!", 0)
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(label, -1)

reaper.UpdateArrange()