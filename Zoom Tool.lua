function msg(m)
  reaper.ShowConsoleMsg(tostring(m).."\n")
end

local initialMousePos = {}
local previousMousePos = {}
local currentMousePos = {}
local startingTrackHeights = {}

local trackCount
local hotkey = 97
local charHotkey

-- This is called when the script starts
function zoomTool_init()
  trackCount = reaper.CountTracks(0)

  initialMousePos.x, initialMousePos.y = reaper.GetMousePosition()
  previousMousePos.x, previousMousePos.y = reaper.GetMousePosition()

  for i = 1, trackCount do
    local currentTrack = reaper.GetTrack(0, i - 1)
    startingTrackHeights[i - 1] = reaper.GetMediaTrackInfo_Value(currentTrack, "I_HEIGHTOVERRIDE")
  end

  reaper.defer(zoomTool_update)
end

function zoomTool_update()
  charHotkey = gfx.getchar(hotkey)

  currentMousePos.x, currentMousePos.y = reaper.GetMousePosition()

  local xAdjustment = (currentMousePos.x - previousMousePos.x) / 5.0
  --local yAdjustment = currentMousePos.y - initialMousePos.y
  local yAdjustment = currentMousePos.y - previousMousePos.y

  previousMousePos.x = currentMousePos.x
  previousMousePos.y = currentMousePos.y

  reaper.adjustZoom(xAdjustment, 0, true, -1)

--  for i = 1, trackCount do
--    local currentTrack = reaper.GetTrack(0, i - 1)
--    local trackHeight = startingTrackHeights[i - 1] + yAdjustment
--
--    if trackHeight < 1 then
--      trackHeight = 1
--    end
--
--    reaper.SetMediaTrackInfo_Value(currentTrack, "I_HEIGHTOVERRIDE", trackHeight);
--  end

  if yAdjustment > 0 then
    reaper.Main_OnCommand(40111, 0)
  elseif yAdjustment < 0 then
    reaper.Main_OnCommand(40112, 0)
  end

  if charHotkey == 0 then
    reaper.defer(zoomTool_update)
  end

  reaper.TrackList_AdjustWindows(0)
  gfx.update()
  reaper.UpdateArrange()
end

gfx.init("test", 0, 0, 0, 0, 0)
zoomTool_init()