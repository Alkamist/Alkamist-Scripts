package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Mouse = require "GFX.Mouse"
local Keyboard = require "GFX.Keyboard"

local function AlkamistGFX(title, x, y, w, h, dock)
    gfx.init(title, w, h, dock, x, y)

    local graphics = {}

    local _title = title
    local _x = x
    local _previousX = x
    local _y = y
    local _previousY = y
    local _width = w
    local _previousWidth = w
    local _height = h
    local _previousHeight = h
    local _dock = dock
    local _playKey
    local _preHookFn
    local _postHookFn
    local _focus

    local _children = {}
    local _mouse = Mouse:new()
    local _keyboard = Keyboard:new()

    local function updateGFXVariables()
        _previousX =      _x
        _previousY =      _y
        _previousWidth =  _width
        _previousHeight = _height
        _x =              gfx.x
        _y =              gfx.y
        _width =          gfx.w
        _height =         gfx.h
    end
    local function passThroughPlayKey(char, playKey)
        if playKey and char == playKey then reaper.Main_OnCommandEx(40044, 0, 0) end
    end
    local function flagLoopForRepeat(fn, char)
        if char ~= "Escape" and char ~= "Close" then reaper.defer(fn) end
        gfx.update()
    end

    function graphics:getTitle()              return _title end
    function graphics:getX()                  return _x end
    function graphics:getY()                  return _y end
    function graphics:getWidth()              return _width end
    function graphics:getPreviousWidth()      return _previousWidth end
    function graphics:getWidthChange()        return self:getWidth() - self:getPreviousWidth() end
    function graphics:getHeight()             return _height end
    function graphics:getPreviousHeight()     return _previousHeight end
    function graphics:getHeightChange()       return self:getHeight() - self:getPreviousHeight() end
    function graphics:windowWasResized(color)
        return self:getWidth() ~= self:getPreviousWidth() or self:getHeight() ~= self:getPreviousHeight()
    end
    function graphics:getMouse()              return _mouse end
    function graphics:getKeyboard()           return _keyboard end
    function graphics:getChildren()           return _children end
    function graphics:getPlayKey()            return _playKey end
    function graphics:getFocus()              return _focus end

    function graphics:setColor(color)         gfx.set(color[1], color[2], color[3], color[4]) end
    function graphics:setPlayKey(playKey)     _playKey = playKey end
    function graphics:setFocus(focus)         _focus = focus end

    function graphics:processChildren()
        local keyboard = self:getKeyboard()
        local char = keyboard:getChar()
        local mouse = self:getMouse()
        local mouseMoved = mouse:justMoved()
        local leftClick = mouse:getButtons().left
        local middleClick = mouse:getButtons().middle
        local rightClick = mouse:getButtons().right
        local wheel = self:getMouse():getWheel()
        local wheelMoved = wheel > 0 or wheel < 0
        local hWheel = self:getMouse():getHWheel()
        local hWheelMoved = hWheel > 0 or hWheel < 0

        for _, child in pairs(self:getChildren()) do
            local shouldLeftDrag = false
            local shouldMiddleDrag = false
            local shouldRightDrag = false

            self:setFocus(self:getFocus() or child)

            child:onUpdate()

            if GFX.windowWasResized()            then child:onResize() end
            if self:getFocus() == child and char then child:onChar(char) end

            if child:mouseJustEntered()          then child:onMouseEnter() end
            if child:mouseJustLeft()             then child:onMouseLeave() end

            if child:mouseIsInside() then
                if leftClick:justPressed() then
                    shouldLeftDrag = true
                    child:onMouseLeftButtonDown()
                end
                if middleClick:justPressed() then
                    shouldMiddleDrag = true
                    child:onMouseMiddleButtonDown()
                end
                if rightClick:justPressed() then
                    shouldRightDrag = true
                    child:onMouseRightButtonDown()
                end

                if wheelMoved then child:onMouseWheel(wheel) end
                if hWheelMoved then child:onMouseHWheel(hWheel) end
            end

            if mouseMoved and shouldLeftDrag then   child:onMouseLeftButtonDrag() end
            if mouseMoved and shouldMiddleDrag then child:onMouseMiddleButtonDrag() end
            if mouseMoved and shouldRightDrag then  child:onMouseRightButtonDrag() end

            if leftClick:justReleased() then
                shouldLeftDrag = false
                child:onMouseLeftButtonUp()
            end
            if middleClick:justReleased() then
                shouldMiddleDrag = false
                child:onMouseMiddleButtonUp()
            end
            if rightClick:justReleased() then
                shouldRightDrag = false
                child:onMouseRightButtonUp()
            end

            child:onDraw()
        end
    end

    function graphics:run()
        updateGFXVariables()
        self:getMouse():update()
        self:getKeyboard():update()
        passThroughPlayKey(self:getKeyboard():getChar(), self:getPlayKey())
        if _preHookFn then _preHookFn() end
        self:processChildren()
        if _postHookFn then _postHookFn() end
        flagLoopForRepeat(self:run(), self:getKeyboard():getChar())
    end

    return graphics
end

return AlkamistGFX