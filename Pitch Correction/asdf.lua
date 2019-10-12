projmt={}
item_mt={}
track_mt={}
projitems_mt={}
projtracks_mt={}

function Project(proj)
  track_mt["__index"]=function(t,key)
    if key=="name" then
	 local rv, name = reaper.GetSetMediaTrackInfo_String(t.ptr, "P_NAME", "", false)
	 if rv then return name end
    end
    return nil
  end
  track_mt["__newindex"]=function(t,key,value)
    if key=="name" then reaper.GetSetMediaTrackInfo_String(t.ptr,"P_NAME",value,true) end
  end
  item_mt["__newindex"]=function(t,key,value)
    if key=="pos" then reaper.SetMediaItemPosition(t.ptr,value,false) end
    if key=="len" then reaper.SetMediaItemLength(t.ptr,value,false) end
    if key=="snapoffs" then reaper.SetMediaItemInfo_Value(t.ptr,"D_SNAPOFFSET",value) end
    local take = reaper.GetActiveTake(t.ptr)
    if take then
		if key=="pitch" then return reaper.SetMediaItemTakeInfo_Value(take,"D_PITCH",value) end
		if key=="rate" then return reaper.SetMediaItemTakeInfo_Value(take,"D_PLAYRATE",value) end
	end
  end
  item_mt["__index"]=function(t,key)
    if key=="ptr" then return reaper.GetMediaItem(proj,key) end
    if key=="sel" then return reaper.IsMediaItemSelected(t.ptr) end
    if key=="pos" then return reaper.GetMediaItemInfo_Value(t.ptr,"D_POSITION") end
    if key=="len" then return reaper.GetMediaItemInfo_Value(t.ptr,"D_LENGTH") end
    if key=="snapoffs" then return reaper.GetMediaItemInfo_Value(t.ptr,"D_SNAPOFFSET") end
	-- Add rest of item properties...Actually, there should be a Take object
	-- But it's handy to be able to change the active take properties directly from the item too
    local take = reaper.GetActiveTake(t.ptr)
    if take then
		if key=="pitch" then return reaper.GetMediaItemTakeInfo_Value(take,"D_PITCH") end
		if key=="rate" then return reaper.GetMediaItemTakeInfo_Value(take,"D_PLAYRATE") end
	end
    return nil
  end
  projmt["__index"]=function(t,key)
    if key=="numitems" then return reaper.CountMediaItems(proj) end
    if key=="playrate" then return reaper.Master_GetPlayRate(proj) end
  end
  projmt["__newindex"]=function(t,key,value)
	if key=="playrate" then reaper.CSurf_OnPlayRateChange(value) end
  end
  projitems_mt["__index"]=function(t,key)
    if key=="count" then return reaper.CountMediaItems(t.projptr) end
    if key>=0 and key<reaper.CountMediaItems(t.projptr) then
	 itemob={}
	 itemob["ptr"]=reaper.GetMediaItem(t.projptr,key)
	 setmetatable(itemob,item_mt)
	 return itemob
    end
    return nil
  end
  projtracks_mt["__index"]=function(t,key)
    local numtracks = reaper.CountTracks(t.projptr)
    if key=="count" then return numtracks end
    if key>=0 and key<numtracks then
	 trackob={}
	 trackob["ptr"]=reaper.GetTrack(t.projptr,key)
	 setmetatable(trackob,track_mt)
	 return trackob
    end
    return nil
  end
  result = {}
  result["ptr"]=proj
  item_coll = {}
  item_coll.projptr = proj
  setmetatable(item_coll,projitems_mt)
  result["items"]= item_coll
  track_coll = {}
  track_coll.projptr = proj
  setmetatable(track_coll,projtracks_mt)
  result["tracks"] = track_coll
  setmetatable(result,projmt)
  return result
end

proj = Project(0)
local numitems = proj.numitems
function test_speed()
-- Lua probably isn't smart enough to optimize out code, but just in case
-- it behaves like C++ compilers could, we will accumulate stuff into a variable
-- within the for loop and use that variable outside the loop, so it actually has to do
-- the work inside the loop.
local numiters = numitems
acc = 0.0
t0 = reaper.time_precise()
for i=0,numiters do
  local item = proj.items[i % numitems]
  acc=acc+item.pos
  acc=acc+item.len
  acc=acc+item.snapoffs
end
t1 = reaper.time_precise()
reaper.ShowConsoleMsg("object style read access took "..t1-t0.."\n")
reaper.ShowConsoleMsg(acc.."\n")

acc = 0.0
t0 = reaper.time_precise()
for i=0,numiters do
  local item = reaper.GetMediaItem(0,i % numitems)
  acc=acc+reaper.GetMediaItemInfo_Value(item,"D_POSITION")
  acc=acc+reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
  acc=acc+reaper.GetMediaItemInfo_Value(item,"D_SNAPOFFSET")
end
t1 = reaper.time_precise()
reaper.ShowConsoleMsg("old skool read access took "..t1-t0.."\n")
reaper.ShowConsoleMsg(acc.."\n")

t0 = reaper.time_precise()
for i=0,numiters do
  local item = proj.items[i % numitems]
  item.pos=math.random()*10.0
  item.len=0.1+1.9*math.random()
  item.snapoffs=math.random()
end
t1 = reaper.time_precise()
reaper.ShowConsoleMsg("object style write access took "..t1-t0.."\n")

t0 = reaper.time_precise()
for i=0,numiters do
  local item = reaper.GetMediaItem(0,i % numitems)
  reaper.SetMediaItemPosition(item,math.random()*10.0,false)
  reaper.SetMediaItemLength(item,0.1+1.9*math.random(),false)
end
t1 = reaper.time_precise()
reaper.ShowConsoleMsg("old skool write access took "..t1-t0.."\n")

end

function test_foo1()
  for i=0,numitems-1 do
    proj.items[i].pitch=-12.0+12.0/(numitems-1)*i
    proj.items[i].len=proj.items[i].len*0.9
  end
end

function test_foo2()
  for i=0,numitems-1 do
    local item = proj.items[i]
    if item.sel then item.pitch=-12.0+24.0*math.random() end
  end
end

function test_foo3()
  proj.playrate = proj.playrate+0.1
end

function test_foo4()
  reaper.ShowConsoleMsg(proj.items.count.."\n")
  reaper.ShowConsoleMsg(proj.items[0].pos.."\n")
  proj.items[0].pos=0.0
end

function test_foo5()
  reaper.ShowConsoleMsg(proj.tracks.count.."\n")
  reaper.ShowConsoleMsg(proj.tracks[0].name.."\n")
  proj.tracks[0].name="test!"
end

test_foo5()

reaper.UpdateArrange()