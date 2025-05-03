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
    local pad = math.floor((width - #txt) / 2)
    if pad < 0 then
        pad = 0
    end
    return string.rep(" ", pad) .. txt
end

-- Helper function to simulate a bold effect
local function boldText(monitor, txt)
    local x, y = monitor.getCursorPos()
    monitor.write(txt)
    monitor.setCursorPos(x + 1, y)
    monitor.write(txt)
end

function writeSign(text, opts)
    if not text or #text == 0 then
        print("No text provided!")
        return
    end

    opts = opts or {}
    local w, h = monitor.getSize()

    monitor.setTextScale(1)
    monitor.setBackgroundColor(colors.black)
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

        monitor.setCursorPos(opts.h and 1 or 1, startY + i - 1)

        if opts.style == "bold" then
            boldText(monitor, out)
        elseif opts.style == "underlined" then
            monitor.write(out)

            -- Simulate underline by writing a line below the text
            local x, y = monitor.getCursorPos()
            if y + 1 <= h then
                monitor.setCursorPos(1, y + 1)
                monitor.write(string.rep("_", #out))
            end
        else
            monitor.write(out)
        end
    end
end