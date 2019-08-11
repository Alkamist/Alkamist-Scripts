-------------- Reaper Functions --------------

local Reaper = {}

function Reaper.msg(m)
  reaper.ShowConsoleMsg(tostring(m).."\n")
end

function Reaper.reaperCMD(id)
    if type(id) == "string" then
        reaper.Main_OnCommand(reaper.NamedCommandLookup(id), 0)
    else
        reaper.Main_OnCommand(id, 0)
    end
end

function Reaper.copyTable(source, base)
    if type(source) ~= "table" then return source end

    local meta = getmetatable(source)
    local new = base or {}
    for k, v in pairs(source) do
        if type(v) == "table" then
            if base then
                new[k] = GUI.table_copy(v, base[k])
            else
                new[k] = GUI.table_copy(v, nil)
            end

        else
            if not base or (base and new[k] == nil) then

                new[k] = v
            end
        end
    end
    setmetatable(new, meta)

    return new
end

function Reaper.getTableLength(t)
    local len = 0
    for k in pairs(t) do
        len = len + 1
    end

    return len
end

function Reaper.getItemType(item)
    local _, selectedChunk =  reaper.GetItemStateChunk(item, "", 0)
    local itemType = string.match(selectedChunk, "<SOURCE%s(%P%P%P).*\n")

    if itemType == nil then
        return "empty"
    elseif itemType == "MID" then
        return "midi"
    else
        return "audio"
    end
end

function Reaper.itemIsValid(item)
    local itemExists = reaper.ValidatePtr(item, "MediaItem*")
    return item ~= nil and itemExists
end

function Reaper.setItemSelected(item, selected)
    if itemIsValid(item) then
        reaper.SetMediaItemSelected(item, selected)
    end
end

function Reaper.getSelectedItems()
    local outputItems = {}
    local numSelectedItems = reaper.CountSelectedMediaItems(0)
    for i = 1, numSelectedItems do
        local temporaryItem = reaper.GetSelectedMediaItem(0, i - 1)
        outputItems[i] = temporaryItem
    end
    return outputItems
end

function Reaper.restoreSelectedItems(items)
    if items ~= nil then
        reaperCMD(40289) -- unselect all items
        for i = 1, #items do
            setItemSelected(items[i], true)
        end
    end
end

return Reaper