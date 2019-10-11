local Alk = {}

local function apiFn(fn, refresh)
    local state = nil
    return function()
        if state == nil or refresh then
            state = fn()
        end
        return state
    end
end

-- This is the idea, but it doesn't work.
-- I don't know how to pass refresh into the function.
Alk.getSelectedMediaItems = apiFn(function()
    local items = {}
    for i = 1, reaper.CountSelectedMediaItems(0) do
        table.insert(items, reaper.GetSelectedMediaItem(0, i - 1))
    end
    return items
end,
refresh)

-- This ends up returning a function, which is clunky.
--function Alk.getSelectedMediaItems(refresh)
--    return apiFn(function()
--        local items = {}
--        for i = 1, reaper.CountSelectedMediaItems(0) do
--            table.insert(items, reaper.GetSelectedMediaItem(0, i - 1))
--        end
--        return items
--    end,
--    refresh)
--end

-- If you return a resolved function, the closure doesn't preserve
-- the data properly across calls.
--function Alk.getSelectedMediaItems(refresh)
--    return apiFn(function()
--        local items = {}
--        for i = 1, reaper.CountSelectedMediaItems(0) do
--            table.insert(items, reaper.GetSelectedMediaItem(0, i - 1))
--        end
--        return items
--    end,
--    refresh)()
--end

return Alk