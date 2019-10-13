package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local factory = require "Pitch Correction.Reaper Wrapper Factory"

local AlkAPI = {}

-- Project number can be omitted for current project.
function AlkAPI.wrap(pointer, projectNumber)
    return factory.createNew(pointer, projectNumber)
end








function AlkAPI.get(typeToGet, projectNumber)
    if projectNumber == nil then projectNumber = 1 end
    local output = {}
    for index = 1, AlkWrap.getNumSelectedItems(projectNumber) do
        table.insert(output, nil)
    end
    return output
end

return AlkAPI