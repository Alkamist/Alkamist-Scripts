------------------ Mouse Button ------------------

local MouseButton = {
    bitValue = 1
}

function MouseButton:new(object)
    local object = object or {}
    setmetatable(object, { __index = self })
    return object
end

function MouseButton:isPressed()
    return self.state.current.cap & self.bitValue == self.bitValue
end
function MouseButton:justPressed()
    return self.state.current.cap & self.bitValue == self.bitValue
       and self.state.previous.cap & self.bitValue == 0
end
function MouseButton:justReleased()
    return self.state.current.cap & self.bitValue == 0
       and self.state.previous.cap & self.bitValue == self.bitValue
end

------------------ Mouse ------------------

local Mouse = { state = {} }

function Mouse:new(object)
    local object = object or {}
    setmetatable(object, { __index = self })
    self.left =    MouseButton:new{ bitValue = 1  }
    self.middle =  MouseButton:new{ bitValue = 64 }
    self.right =   MouseButton:new{ bitValue = 2  }
    self.shift =   MouseButton:new{ bitValue = 8  }
    self.control = MouseButton:new{ bitValue = 4  }
    self.alt =     MouseButton:new{ bitValue = 16 }
    self.windows = MouseButton:new{ bitValue = 32 }
    return object
end

function Mouse:update()
    local newState = {
        x = gfx.mouse_x,
        y = gfx.mouse_y,
        cap = gfx.mouse_cap,
        wheel = math.floor(gfx.mouse_wheel / 120.0),
        hWheel = math.floor(gfx.mouse_hwheel / 120.0)
    }
    gfx.mouse_wheel = 0
    gfx.mouse_hwheel = 0
    self.state.previous = self.state.current or newState
    self.state.current = newState
    self.left.state =    self.state
    self.middle.state =  self.state
    self.right.state =   self.state
    self.shift.state =   self.state
    self.control.state = self.state
    self.alt.state =     self.state
    self.windows.state = self.state
end

function Mouse:justMoved()
    return self.state.current.x ~= self.state.previous.x
        or self.state.current.y ~= self.state.previous.y
end


return Mouse