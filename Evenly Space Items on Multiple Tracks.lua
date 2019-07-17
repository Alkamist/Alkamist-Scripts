function msg(m)
  reaper.ShowConsoleMsg(tostring(m).."\n")
end

function evenlySpaceSelectedItems()
  local numSelectedItems = reaper.CountSelectedMediaItems(0)
  if numSelectedItems == 0 then
    return
  end

  reaper.Main_OnCommand(41173, 0) -- Move cursor to start of items

  -- Unselect the first item
  local firstItem = reaper.GetSelectedMediaItem(0, 0)
  reaper.SetMediaItemSelected(firstItem, false)

  for i = 1, numSelectedItems do
    local currentItem = reaper.GetSelectedMediaItem(0, 0)

    if currentItem == nil then
      break
    end

    reaper.Main_OnCommand(40647, 0) -- Move cursor right to grid division
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_FNG_MOVE_TO_EDIT"), 0) -- Move selected items to cursor
    reaper.SetMediaItemSelected(currentItem, false)
  end
end

function evenlySpaceItemsOnSpecificSelectedTrack(trackIndex)
  local numMediaItemsOnTrack = reaper.CountTrackMediaItems(trackIndex)

  for i = 1, numMediaItemsOnTrack do
    local itemToSelect = reaper.GetTrackMediaItem(trackIndex, i - 1)

    reaper.SetMediaItemSelected(itemToSelect, true)
  end

  evenlySpaceSelectedItems()
end

function evenlySpaceItemsOnSelectedTracks()
  reaper.Undo_BeginBlock()

  local numSelectedTracks = reaper.CountSelectedTracks(0)
  if numSelectedTracks == 0 then
    return
  end

  for i = 1, numSelectedTracks do
    local currentTrack = reaper.GetSelectedTrack(0, i - 1)

    reaper.SelectAllMediaItems(0, false)
    evenlySpaceItemsOnSpecificSelectedTrack(currentTrack)
  end

  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Evenly Space Items on Multiple Tracks", -1)
end

evenlySpaceItemsOnSelectedTracks()