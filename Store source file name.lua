function msg(m)
  reaper.ShowConsoleMsg(tostring(m).."\n")
end

function store_take_source_filename()
  local item = reaper.GetSelectedMediaItem(0,0) -- get first selected item
  -- No selected items
  if item == nil then
    msg("No item selected")
  return end

  -- Empty item (no takes in item)
  local take = reaper.GetActiveTake(item)
  if take == nil then
    msg("Empty item?")
  return end

  -- Active take in selected item is a MIDI take
  if reaper.TakeIsMIDI(take) then
    msg("Please select an audio take")
  return end


  local take_source = reaper.GetMediaItemTake_Source(take) -- get media source
  local take_source_filename = reaper.GetMediaSourceFileName(take_source, "")
  if take_source_filename ~= "" then
    reaper.SetExtState("Take source filenames", "file name1", take_source_filename, true)
  end
end

store_take_source_filename()