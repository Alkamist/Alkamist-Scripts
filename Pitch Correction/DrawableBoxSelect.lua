local math = math
local abs = math.abs
local min = math.min

local DrawableBoxSelect = {}

function DrawableBoxSelect.new(boxSelect)
    local self = {}
    for k, v in pairs(boxSelect) do self[k] = v end

    function self:draw()
        local bounds = self.bounds
    end

    return self
end

return DrawableBoxSelect