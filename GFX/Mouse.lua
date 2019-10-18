local function MouseButton(bitValue)
    local mouseButton = {}

    local _mouseCap = nil
    local _previousMouseCap = nil
    local _bitValue = bitValue

    function mouseButton:update(mouseCap)
        _previousMouseCap = _mouseCap
        _mouseCap = mouseCap
    end
    function mouseButton:isPressed()
        return _mouseCap & _bitValue == _bitValue
    end
    function mouseButton:justPressed()
        return _mouseCap & _bitValue == _bitValue
           and _previousMouseCap & _bitValue == 0
    end
    function mouseButton:justReleased()
        return _mouseCap & _bitValue == 0
           and _previousMouseCap & _bitValue == _bitValue
    end

    return mouseButton
end

local function Mouse()
    local mouse = {}

    -- Private Members:

    local _x = 0
    local _previousX = 0
    local _y = 0
    local _previousY = 0
    local _cap
    local _wheel = 0
    local _hWheel = 0

    local _buttons = {
        left = MouseButton(1),
        middle = MouseButton(64),
        right = MouseButton(2)
    }
    local _modifiers = {
        shift = MouseButton(8),
        control = MouseButton(4),
        alt = MouseButton(16),
        windows = MouseButton(32)
    }

    -- Getters:

    function mouse:getX()         return _x end
    function mouse:getPreviousX() return _previousX end
    function mouse:getXChange()   return self:getX() - self:getPreviousX() end
    function mouse:getY()         return _y end
    function mouse:getPreviousY() return _previousY end
    function mouse:getYChange()   return self:getY() - self:getPreviousY() end
    function mouse:getWheel()     return _wheel end
    function mouse:getHWheel()    return _hWheel end
    function mouse:getButtons()   return _buttons end
    function mouse:getModifiers() return _modifiers end
    function mouse:justMoved()
        return self:getX() ~= self:getPreviousX()
            or self:getY() ~= self:getPreviousY()
    end

    -- Setters:

    function mouse:update()
        _previousX = _x
        _x = gfx.mouse_x
        _previousY = _y
        _y = gfx.mouse_y
        _cap = gfx.mouse_cap
        _wheel = math.floor(gfx.mouse_wheel / 120.0)
        gfx.mouse_wheel = 0
        _hWheel = math.floor(gfx.mouse_hwheel / 120.0)
        gfx.mouse_hwheel = 0
    end

    return mouse
end

return Mouse