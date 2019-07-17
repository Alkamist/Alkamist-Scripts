function unselect_fx_bypassed_tracks()

    reaper.Undo_BeginBlock()

    selected_tracks_count = reaper.CountSelectedTracks(0)

    i = 0
    
	while i <= (selected_tracks_count - 1)  do
    
		-- GET THE TRACK
		track = reaper.GetSelectedTrack(0, i)

		--GET INFO
		value_get = reaper.GetMediaTrackInfo_Value(track, "I_FXEN")
        
        if value_get == 0 then
        
            reaper.SetTrackSelected(track, false)
            selected_tracks_count = selected_tracks_count - 1
            i = i - 1
        
        end
        
        i = i + 1
        
	end -- ENDLOOP through selected tracks
    
    reaper.Undo_EndBlock("Unselect fx bypassed tracks", 0)

end

unselect_fx_bypassed_tracks()

reaper.UpdateArrange() -- Update the arrangement (often needed)