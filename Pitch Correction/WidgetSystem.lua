local tiny = require("tiny")

local WidgetSystem = tiny.processingSystem()
widgetSystem.filter = tiny.requireAll("x", "y", "w", "h", "drawX", "drawY")