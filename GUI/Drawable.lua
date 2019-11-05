local reaper = reaper
local gfx = gfx
local math = math

local currentBuffer = -1
local function getNewDrawBuffer()
    currentBuffer = currentBuffer + 1
    if currentBuffer > 1023 then currentBuffer = 0 end
    return currentBuffer
end

local function Drawable(parameters)
    local self = {}

    local _drawBuffer = getNewDrawBuffer()
    local _x = parameters.x or 0
    local _y = parameters.y or 0
    local _width = parameters.width or 0
    local _height = parameters.height or 0

    local _isVisible = parameters.isVisible
    if _isVisible == nil then _isVisible = true end

    local _shouldRedraw = parameters.shouldRedraw
    if _shouldRedraw == nil then _shouldRedraw = true end

    function self.getX() return _x end
    function self.getY() return _y end
    function self.getWidth() return _width end
    function self.getHeight() return _height end
    function self.isVisible() return _isVisible end
    function self.toggleVisibility() _isVisible = not _isVisible end
    function self.setVisibility(value) _isVisible = value end
    function self.show() _isVisible = true end
    function self.hide() _isVisible = false end
    function self.queueRedraw() _shouldRedraw = true end
    function self.pointIsInsideDrawableBounds(pointX, pointY)
        return pointX >= _x and pointX <= _x + _width
           and pointY >= _y and pointY <= _y + _height
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

    function self.doDrawFunction()
        --if _shouldRedraw and self.draw then
            gfx.a = 1.0
            gfx.mode = 0
            gfx.dest = -1
            self.draw()
        --end
        --_shouldRedraw = false
    end
    function self.blitToMainWindow()
        if _isVisible then
            gfx.a = 1.0
            gfx.mode = 0
            gfx.dest = -1
            gfx.blit(_drawBuffer, 1.0, 0, 0, 0, _width, _height, _x, _y, _width, _height, 0, 0)
        end
    end

    return self
end

return Drawable