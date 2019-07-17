function msg(m)
  reaper.ShowConsoleMsg(tostring(m).."\n")
end

function replace_take_sources()
  if not reaper.HasExtState("Take source filenames", "file name1") then
    return
  end

  local file_name = reaper.GetExtState("Take source filenames", "file name1")
  if file_name == "" then
    return
  end
  reaper.Undo_BeginBlock()
  local get_act_take = reaper.GetActiveTake
  local get_sel_item = reaper.GetSelectedMediaItem
  local sel_item_count = reaper.CountSelectedMediaItems(0)

  for i=1, sel_item_count do
    take = get_act_take(get_sel_item(0, i-1))
    source_added_ok = reaper.BR_SetTakeSourceFromFile(take, file_name, false)
    --msg("Source added: " .. tostring(source_added_ok)) -- debug
  end
  reaper.UpdateArrange()
  reaper.Main_OnCommand(40441, 0) -- rebuild peaks for selected items
  reaper.Main_OnCommand(40612, 0) -- Set items length to source length (comment out if not needed)
  reaper.Undo_EndBlock("Replace take source(s)", -1)
end

replace_take_sources()