-- sign_writer.lua
-- Usage: writeSign("Your text here", { h = true, v = true, color = "red", style = "bold" })

local monitor = peripheral.find("monitor")
if not monitor then
    print("No monitor found!")
    return
end

local colorMap = {
    black = colors.black,
    white = colors.white,
    red = colors.red,
    green = colors.green,
    blue = colors.blue,
    yellow = colors.yellow,
    cyan = colors.cyan,
    magenta = colors.magenta,
    orange = colors.orange,
    gray = colors.gray,
    lightGray = colors.lightGray,
    lime = colors.lime,
    pink = colors.pink,
    lightBlue = colors.lightBlue,
    purple = colors.purple,
    brown = colors.brown
}

-- Helper function to pad a string for center alignment
local function centerText(txt, width)
    local wrappedLines = {}
    local function wrapLine(line)
        while #line > width do
            local wrapAt = line:sub(1, width):find("%s[^%s]*$") or width
            table.insert(wrappedLines, (line:sub(1, wrapAt):gsub("%s+$", ""))) -- sometimes throws a string not a number error
            line = line:sub(wrapAt + 1):gsub("^%s+", "")
        end
        table.insert(wrappedLines, line)
    end
    
    for line in txt:gmatch("[^\n]+") do
        wrapLine(line)
    end

    for i, line in ipairs(wrappedLines) do
        local pad = math.floor((width - #line) / 2)
        if pad < 0 then 
            pad = 0
        end
        wrappedLines[i] = string.rep(" ", pad) .. line
    end

    return table.concat(wrappedLines, "\n")
end

-- Helper function to simulate a bold effect
local function boldText(monitor, txt)
    local x, y = monitor.getCursorPos()
    monitor.write(txt)
    monitor.setCursorPos(x + 1, y)
    monitor.write(txt)
end

-- Helper function to write text with underline effect
local function underlinedText(monitor, txt, width)
    local x, y = monitor.getCursorPos()
    if y + 1 <= width then
        monitor.setCursorPos(x, y + 1)
        monitor.write(string.rep("_", #txt))
    end
end

-- Helper function to write text with linethrough effect
local function lineThroughText(monitor, txt)
    local x, y = monitor.getCursorPos()
    monitor.write(txt)
    monitor.setCursorPos(x, y)
    monitor.write(string.rep("-", #txt))
end

-- Helper function to write text with strikethrough effect
local function strikethroughText(monitor, txt)
    local x, y = monitor.getCursorPos()
    monitor.write(txt)
    monitor.setCursorPos(x, y)
    monitor.write(string.rep("~", #txt))
end

-- Helper function to write text to simulate italic effect
local function italicText(monitor, txt, offset)
    local x, y = monitor.getCursorPos()
    monitor.setCursorPos(x + offset, y)
    monitor.write(txt)
end

-- Helper function to write text with shadow effect
local function shadowText(monitor, txt, sColor)
    local shadowColor = colorMap[string.lower(sColor)] or colors.gray
    local curColor = monitor.getTextColor()
    local x, y = monitor.getCursorPos()
    monitor.setCursorPos(x + 1, y + 1)
    monitor.setTextColor(shadowColor)
    monitor.write(txt)
    monitor.setCursorPos(x, y)
    monitor.setTextColor(curColor)
    monitor.write(txt)
end

-- Helper function to write text with glow effect
local function glowText(monitor, txt, gColor)
    local glowColor = colorMap[string.lower(gColor)] or colors.yellow
    local curColor = monitor.getTextColor()
    local x, y = monitor.getCursorPos()
    monitor.setCursorPos(x - 1, y - 1)
    monitor.setTextColor(glowColor)
    monitor.write(txt)
    monitor.setCursorPos(x, y)
    monitor.setTextColor(curColor)
    monitor.write(txt)
end

--Arrow drawing functions
-- Draws a right arrow at the specified position
local function drawRightArrow(x, y, color)
    paintutils.drawPixel(x, y, color)
    paintutils.drawLine(x, y-1, x+1,y, color)
    paintutils.drawLine(x, y+1, x+1,y, color)
    paintutils.drawLine(x+2, y-1, x+2,y+1, color)
end

-- Draws a left arrow at the specified position
local function drawLeftArrow(x, y, color)
    paintutils.drawPixel(x+2, y, color)
    paintutils.drawLine(x+2, y-1, x+1,y, color)
    paintutils.drawLine(x+2, y+1, x+1,y, color)
    paintutils.drawLine(x, y-1, x,y+1, color)
end

-- Draws an up arrow at the specified position
local function drawUpArrow(x, y, color)
    paintutils.drawPixel(x, y, color)
    paintutils.drawLine(x-1, y+1, x+1,y+1, color)
    paintutils.drawLine(x-2, y+2, x+2,y+2, color)
    paintutils.drawLine(x, y+3, x,y+4, color)
end

-- Draws a down arrow at the specified position
local function drawDownArrow(x, y, color)
    paintutils.drawPixel(x, y+4, color)
    paintutils.drawLine(x-1, y+3, x+1,y+3, color)
    paintutils.drawLine(x-2, y+2, x+2,y+2, color)
    paintutils.drawLine(x, y, x,y+1, color)
end

-- Scrolls text
local function scrollText(lines, startY, direction, color, delay)
    local w, _ = monitor.getSize()
    local scrollLines = {}
    delay = delay or 0.1

    -- Pad lines to monitor width
    for i, line in ipairs(lines) do
        local paddedLine = line .. string.rep(" ", w - #line)
        table.insert(scrollLines, paddedLine)
    end

    while true do
        for i, line in ipairs(scrollLines) do
            if direction == "left" then
                local firstChar = string.sub(line, 1, 1)
                line = string.sub(line, 2) .. firstChar
            else
                local lastChar = string.sub(line, -1)
                line = lastChar .. string.sub(line, 1, -2)
            end

            scrollLines[i] = line
            monitor.setCursorPos(1, startY + i - 1)
            monitor.setTextColor(color)
            monitor.write(line)
        end
        sleep(delay)
    end
end

function AnimateDrawnArrow(direction, baseY, color, backColor, delay)
    local w, h = monitor.getSize()
    local pw, ph = w * 6, h * 9 -- Assuming 6x9 pixels per character
    delay = delay or 0.1
    backColor = backColor or colors.black

    monitor.setBackgroundColor(backColor)
    if direction == "up" or direction == "down" then
        local posY = baseY * 9 -- Convert to pixel row
        local toggle = 0
        while true do
            -- Clear the area
            paintutils.drawBox(1, posY-5, pw, posY+6, backColor)

            if direction == "up" then
                drawUpArrow(math.floor(pw / 2), posY-toggle, color)
            else
                drawDownArrow(math.floor(pw / 2), posY+toggle, color)
            end

            toggle = (toggle == 0) and 2 or 0
            sleep(delay)
        end
    elseif direction == "left" or direction == "right" then
        local posX = 1
        local step = 2
        while true do
            -- Clear the area
            paintutils.drawBox(1, baseY * 9, pw, (baseY * 9) + 6, backColor)

            if direction == "right" then
                drawRightArrow(posX, baseY * 9 + 3, color)
                posX = posX + step
                if posX > pw - 3 then
                    posX = 1
                end
            else
                drawLeftArrow(posX, baseY * 9 + 3, color)
                posX = posX - step
                if posX < 1 then
                    posX = pw - 3
                end
            end
            sleep(delay)
        end
    end
end

-- Function to animate an ascii arrow
function AnimateArrow(direction, baseY, color, delay, trailLength)
    local w, h = monitor.getSize()
    local arrowChar
    delay = delay or 0.1
    trailLength = trailLength or 3

    if direction == "up" then
        local posY = baseY + 1
        arrowChar = "^^"
        while true do
            -- Clear old
            monitor.setCursorPos(math.floor(w / 2), posY)
            monitor.write("  ")
            posY = (posY == baseY) and (baseY + 1) or baseY
            monitor.setCursorPos(math.floor(w / 2), posY)
            monitor.setTextColor(color)
            monitor.write(arrowChar)
            sleep(delay)
        end
    elseif direction == "down" then
        local posY = baseY + 1
        arrowChar = "vv"
        while true do
            -- Clear old
            monitor.setCursorPos(math.floor(w / 2), posY)
            monitor.write("  ")
            posY = (posY == baseY) and (baseY + 1) or baseY
            monitor.setCursorPos(math.floor(w / 2), posY)
            monitor.setTextColor(color)
            monitor.write(arrowChar)
            sleep(delay)
        end
    elseif direction == "left" then
        local posX = w
        local trail = {}
        arrowChar = "<"
        while true do
            -- Clear the oldest arrow if the trail is full
            if #trail >= trailLength then
                local oldX = table.remove(trail, 1)
                monitor.setCursorPos(oldX, baseY)
                monitor.write(" ")
            end

            -- Move the arrow left
            posX = posX - 1
            if posX < 1 then
                posX = w
            end

            -- Draw the new arrow
            monitor.setCursorPos(posX, baseY)
            monitor.setTextColor(color)
            monitor.write(arrowChar)

            -- Record the current position in the trail
            table.insert(trail, posX)
            sleep(delay)
        end
    elseif direction == "right" then
        local posX = w
        local trail = {}
        arrowChar = ">"
        while true do
            -- Clear the oldest arrow if the trail is full
            if #trail >= trailLength then
                local oldX = table.remove(trail, 1)
                monitor.setCursorPos(oldX, baseY)
                monitor.write(" ")
            end

            -- Move the arrow right
            posX = posX + 1
            if posX > w then
                posX = 1
            end

            -- Draw the new arrow
            monitor.setCursorPos(posX, baseY)
            monitor.setTextColor(color)
            monitor.write(arrowChar)

            -- Record the current position in the trail
            table.insert(trail, posX)
            sleep(delay)
        end
    end
end

-- Main function to write text on the monitor
---@param text string The text to display
---@param opts table Options for text display
---@param opts.h boolean Center the text horizontally (default: false)
---@param opts.v boolean Center the text vertically (default: false)
---@param opts.color string Text color (default: white)
---@param opts.backColor string Background color (default: black)
---@param opts.textScale number Text scale (default: 1)
---@param opts.bold boolean Bold text (default: false)
---@param opts.italic boolean Italic text (default: false)
---@param opts.underline boolean Underlined text (default: false)
---@param opts.strikethrough boolean Strikethrough text (default: false)
---@param opts.linethrough boolean Linethrough text (default: false)
---@param opts.shadow boolean Shadow effect (default: false)
---@param opts.shadowColor string Shadow color (default: gray)
---@param opts.glow boolean Glow effect (default: false)
---@param opts.glowColor string Glow color (default: yellow)
---@param opts.direction string Direction for arrow animation (up, down, left, right)
---@param opts.animation string Animation type (simple or draw, default: simple)
---@param opts.delay number Delay for animation (default: 0.1)
---@param opts.arrowColor string Arrow color (default: textColor)
---@param opts.textScroll boolean Enable text scrolling (default: false)
---@param opts.scrollDirection string Direction for text scrolling (left or right, default: right)
---@return nil
function WriteSign(text, opts)
    if not text or #text == 0 then
        print("No text provided!")
        return
    end

    opts = opts or {}
    local w, h = monitor.getSize()

    local textScale= opts.textScale or 1
    if textScale < 0.5 then
        textScale = 0.5
    elseif textScale > 5 then
        textScale = 5
    end
    monitor.setTextScale(textScale)
    
    local backColor = opts.backColor and colorMap[string.lower(opts.backColor)] or colors.black
    monitor.setBackgroundColor(backColor)
    monitor.clear()

    local textColor = opts.color and colorMap[string.lower(opts.color)] or colors.white
    monitor.setTextColor(textColor)

    -- Split the text into lines if necessary
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    local startY = 1
    if opts.v then
        startY = math.floor((h - #lines) / 2) + 1
    end

    for i, line in ipairs(lines) do
        local out = line
        if opts.h then
            out = centerText(line, w)
        end

        local xPos = opts.h and 1 or 1
        local yPos = startY + i - 1
        monitor.setCursorPos(xPos, yPos)

        -- Italic: offset each line right by 1 extra space per line
        if opts.italic then
            italicText(monitor, out, i-1)
        else
            monitor.write(out)
        end

        -- Apply styles layered
        if opts.bold then
            monitor.setCursorPos(xPos, yPos)
            boldText(monitor, out)
        end
        if opts.underline then
            monitor.setCursorPos(xPos, yPos)
            underlinedText(monitor, out, w)
        end
        if opts.strikethrough then
            monitor.setCursorPos(xPos, yPos)
            strikethroughText(monitor, out)
        elseif opts.linethrough then
            monitor.setCursorPos(xPos, yPos)
            lineThroughText(monitor, out)
        end

        if opts.shadow then
            monitor.setCursorPos(xPos, yPos)
            shadowText(monitor, out, opts.shadowColor or "gray")
        elseif opts.glow then
            monitor.setCursorPos(xPos, yPos)
            glowText(monitor, out, opts.glowColor or "yellow")
        end
    end

    -- Draw arrows if specified
    parallel.waitForAll(
        function()
            if opts.direction then
                local arrowColor = opts.arrowColor and colorMap[string.lower(opts.arrowColor)] or textColor
                if opts.animation == "simple" then
                    AnimateArrow(opts.direction, startY + #lines + 1, arrowColor, opts.delay)
                elseif opts.animation == "draw" then
                    AnimateDrawnArrow(opts.direction, startY + #lines + 1, arrowColor, backColor, opts.delay)
                end
            else
                sleep(1)
            end
        end,
        function()
            if opts.textScroll then
                local scrollDirection = opts.scrollDirection or "right"
                scrollText(lines, startY, scrollDirection, textColor, opts.scrollDelay)
            else
                sleep(1)
            end
        end
    )
end