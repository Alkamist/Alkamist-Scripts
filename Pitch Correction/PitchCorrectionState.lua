local PitchCorrectionState = {}

function PitchCorrectionState:requires()
    return self.PitchCorrectionState
end
function PitchCorrectionState:getDefaults()
    local defaults = {}
    defaults.x = 0
    defaults.y = 0
    defaults.isActive = true
    defaults.nextPoint = nil
    defaults.glowPoint = false
    defaults.glowLine = false
    return defaults
end
function PitchCorrectionState:update(dt)
end

return PitchCorrectionState