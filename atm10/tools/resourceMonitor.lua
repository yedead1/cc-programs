-- Peripherals
local monitor = peripheral.find("monitor") or error("No monitor attached")
local meBridge = peripheral.find("meBridge") or error("No ME Bridge attached")

-- Constants
local REFRESH_INTERVAL = 60 -- seconds
local MONITOR_TEXTSCALE = 1
local PROJECT_NAME = "Induction Matrix"
local MONITOR_BGCOLOR = colors.black

-- Display settings
term.redirect(monitor)
monitor.setTextScale(MONITOR_TEXTSCALE)
local w, h = monitor.getSize()

-- Items to monitor
local items = {
    {
        tag = "minecraft:redstone",
        name = "Redstone",
        color = colors.red,
        needed = 11000000
    },
    {
        tag = "alltheores:gold_dust",
        name = "Gold Dust",
        color = colors.yellow,
        needed = 5000000
    },
    {
        tag = "alltheores:steel_ingot",
        name = "Steel Ingot",
        color = colors.gray,
        needed = 1000000
    },
    {
        tag = "alltheores:iron_dust",
        name = "Iron Dust",
        color = colors.lightGray,
        needed = 1500000
    },
    {
        tag = "minecraft:coal",
        name = "Coal",
        color = colors.black,
        needed = 1000000
    },
    {
        tag = "minecraft:cobblestone",
        name = "Cobblestone",
        color = colors.lightGray,
        needed = 1000000
    },
    {
        tag = "alltheores:copper_dust",
        name = "Copper Dust",
        color = colors.orange,
        needed = 4000000
    },
    {
        tag = "mekanism:dust_lithium",
        name = "Lithium Dust",
        color = colors.lightGray,
        needed = 800000
    },
    {
        tag = "alltheores:osmium_dust",
        name = "Osmium Dust",
        color = colors.lightGray,
        needed = 400000
    },
    {
        tag = "minecraft:diamond",
        name = "Diamonds",
        color = colors.lightBlue,
        needed = 200000
    }
}

-- Utility functions
local function getItemCount(itemTag)
    local list = meBridge.listItems()
    for _, item in ipairs(list) do
        if item.name == itemTag then
            return item.count
        end
    end
    return 0
end

-- Format number with suffixes
local function formatNumber(num)
    if num >= 1e9 then
        return string.format("%.1fB", num / 1e9):gsub("%.0B", "B")
    elseif num >= 1e6 then
        return string.format("%.1fM", num / 1e6):gsub("%.0M", "M")
    elseif num >= 1e3 then
        return string.format("%.1fk", num / 1e3):gsub("%.0k", "k")
    else
        return tostring(num)
    end
end

-- Helper: get the RGB hex for a computercraft color
local function getRGB(color)
    return {
        colors.packRGB(term.getPaletteColor(color))
    }
end

-- Helper: invert a color
local function invertColor(color)
    local r, g, b = term.getPaletteColor(color)
    local invR, invG, invB = 1 - r, 1 - g, 1 - b

    -- Allocate a temp custom color slot
    local tempColor = colors.white
    term.setPaletteColor(tempColor, invR, invG, invB)
    return tempColor
end

-- Draw static elements
local function drawStaticLabels()
    monitor.setBackgroundColor(MONITOR_BGCOLOR)
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.white)
    
    local title = "Resource Monitor - " .. PROJECT_NAME
    local titleX = math.floor((w - string.len(title)) / 2) + 1
    monitor.setCursorPos(titleX, 1)
    monitor.setTextColor(colors.white)
    monitor.write(title)
    monitor.setCursorPos(1, 2)
    monitor.write(string.rep("-", w))

    local row = 3
    for _, item in ipairs(items) do
        -- Draw the label in the item's color unless its the same as the background
        local textColor = item.color
        if textColor == MONITOR_BGCOLOR then
            textColor = invertColor(textColor)
        end

        monitor.setCursorPos(1, row)
        monitor.setBackgroundColor(MONITOR_BGCOLOR)
        monitor.setTextColor(textColor)
        monitor.write(item.name .. ": ")
        row = row + 1
    end
end

-- Update dynamic elements
local function updateCounts()
    local row = 3
    for _, item in ipairs(items) do
        local count = getItemCount(item.tag)
        local countText = formatNumber(count) .. " / " .. formatNumber(item.needed)

        -- Decide background color for the count based on whether we have enough
        -- Red if below needed, green if at or above
        local bgColor = colors.red
        if count >= item.needed then
            bgColor = colors.green
        end

        -- Clear the previous count
        local x = #item.name + 3 -- 3 for ": " after the name
        monitor.setCursorPos(x, row)
        monitor.setBackgroundColor(bgColor)
        monitor.setTextColor(colors.white)
        
        -- Fill the line segment with spaces to clear previous text
        local padLength = w - x + 1
        monitor.write(string.rep(" ", padLength))

        -- Write the new count text
        monitor.setCursorPos(x, row)
        monitor.write(countText)

        row = row + 1
    end
end

-- Main Loop
drawStaticLabels()
while true do
    updateCounts()
    sleep(REFRESH_INTERVAL)
end