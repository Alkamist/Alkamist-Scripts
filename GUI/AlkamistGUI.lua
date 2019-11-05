local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local UserControl = require("GUI.UserControl")
local TrackedNumber = require("GUI.TrackedNumber")

local function GUI()
    local self = {}

    local _title = ""
    local _x = 0
    local _y = 0
    local _width = TrackedNumber(0)
    local _height = TrackedNumber(0)
    local _dock = 0
    local _mouse = UserControl.mouse
    local _keyboard = UserControl.keyboard
    local _backgroundColor = {}
    local _elements = {}
    local _currentBuffer = -1
    local _updatesPerFrame = 3

    function self.getMouse()
        return _mouse
    end
    function self.getKeyboard()
        return _keyboard
    end
    function self.getElements()
        return _elements
    end

    function self.setColor(color)
        local mode = color[5] or 0
        gfx.set(color[1], color[2], color[3], color[4], mode)
    end
    function self.setBlendMode(mode)
        gfx.mode = mode
    end
    function self.drawRectangle(x, y, w, h, filled)
        gfx.rect(x, y, w, h, filled)
    end
    function self.drawLine(x, y, x2, y2, antiAliased)
        gfx.line(x, y, x2, y2, antiAliased)
    end
    function self.drawCircle(x, y, r, filled, antiAliased)
        gfx.circle(x, y, r, filled, antiAliased)
    end
    function self.drawPolygon(filled, ...)
        if filled then
            gfx.triangle(...)
        else
            local coords = {...}

            -- Duplicate the first pair at the end, so the last line will
            -- be drawn back to the starting point.
            table.insert(coords, coords[1])
            table.insert(coords, coords[2])

            -- Draw a line from each pair of coords to the next pair.
            for i = 1, #coords - 2, 2 do
                gfx.line(coords[i], coords[i+1], coords[i+2], coords[i+3])
            end
        end
    end
    function self.drawRoundRectangle(x, y, w, h, r, filled, antiAliased)
        local aa = antiAliased or 1
        filled = filled or 0
        w = math.max(0, w - 1)
        h = math.max(0, h - 1)

        if filled == 0 or false then
            gfx.roundrect(x, y, w, h, r, aa)
        else
            if h >= 2 * r then
                -- Corners
                gfx.circle(x + r, y + r, r, 1, aa)			-- top-left
                gfx.circle(x + w - r, y + r, r, 1, aa)		-- top-right
                gfx.circle(x + w - r, y + h - r, r , 1, aa) -- bottom-right
                gfx.circle(x + r, y + h - r, r, 1, aa)		-- bottom-left

                -- Ends
                gfx.rect(x, y + r, r, h - r * 2)
                gfx.rect(x + w - r, y + r, r + 1, h - r * 2)

                -- Body + sides
                gfx.rect(x + r, y, w - r * 2, h + 1)
            else
                r = (h / 2 - 1)

                -- Ends
                gfx.circle(x + r, y + r, r, 1, aa)
                gfx.circle(x + w - r, y + r, r, 1, aa)

                -- Body
                gfx.rect(x + r, y, w - (r * 2), h)
            end
        end
    end
    function self.setFont(font, size, flags)
        gfx.setfont(1, font, size)
    end
    function self.measureString(str)
        return gfx.measurestr(str)
    end
    function self.drawString(str, x, y, flags, right, bottom)
        gfx.x = x
        gfx.y = y
        if flags then
            gfx.drawstr(str, flags, right, bottom)
        else
            gfx.drawstr(str)
        end
    end

    function self.setUpdatesPerFrame(value)
        _updatesPerFrame = value
    end
    function self.setBackgroundColor(color)
        _backgroundColor = color
        gfx.clear = color[1] * 255 + color[2] * 255 * 256 + color[3] * 255 * 65536
    end
    function self.windowWasResized()
        return _width.justChanged() or _height.justChanged()
    end
    function self.getNewDrawBuffer()
        _currentBuffer = _currentBuffer + 1
        if _currentBuffer > 1023 then _currentBuffer = 0 end
        return _currentBuffer
    end
    function self.addElements(elements)
        for i = 1, #elements do
            local element = elements[i]
            _elements[#_elements + 1] = element
        end
        _mouse.setElements(_elements)
    end

    function self.initialize(parameters)
        _title = parameters.title or _title or ""
        _x = parameters.x or _x or 0
        _y = parameters.y or _y or 0
        _width.setValue(parameters.width or _width.getValue() or 0)
        _height.setValue(parameters.height or _height.getValue() or 0)
        _dock = parameters.dock or _dock or 0

        gfx.init(_title, _width.getValue(), _height.getValue(), _dock, _x, _y)
    end
    function self.run()
        _width.update(gfx.w)
        _height.update(gfx.h)

        _mouse.update()
        _keyboard.update()

        local char = _keyboard.getCurrentCharacter()
        if char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

        if _elements then
            local numberOfElements = #_elements
            for update = 1, _updatesPerFrame do
                for i = 1, numberOfElements do
                    local element = _elements[i]
                    local fn = element.getUpdateFunction(update)
                    if fn then fn() end
                end
            end
        end

        if char ~= "Escape" and char ~= "Close" then reaper.defer(self.run) end
        gfx.update()
    end

    return self
end

return GUI()