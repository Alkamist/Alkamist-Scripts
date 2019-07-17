function msg(m)
  reaper.ShowConsoleMsg(tostring(m).."\n")
end

function equateItemLengthsVertically()
  reaper.Undo_BeginBlock()

  local numSelectedItems = reaper.CountSelectedMediaItems(0)
  if numSelectedItems == 0 then
    return
  end

  reaper.Main_OnCommand(41173, 0) -- Move cursor to start of items

  for i = 1, numSelectedItems do
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELITEMSUNDEDCURSELTX"), 0) -- Select items under cursor on selected tracks
    reaper.Main_OnCommand(41174, 0) -- Move cursor to end of items
    reaper.Main_OnCommand(40611, 0) -- Set item ends to cursor
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELNEXTITEM"), 0) -- Select next item (across tracks)
    reaper.Main_OnCommand(40319, 0) -- Move cursor right to edge of items
  end

  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Equate Item Lengths Vertically", -1)
end

equateItemLengthsVertically()