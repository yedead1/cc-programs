-- Peripherals
local monitor = peripheral.find("monitor") or error("No monitor found")
local meBridge = peripheral.find("meBridge") or error("No ME Bridge found")
local modem = peripheral.find("modem") or error("No modem found")

-- Modem vars
local MODEM_CHANNEL = 1000

-- Display Config
term.redirect(monitor)  -- Redirect terminal output to the monitor
monitor.setTextScale(1)  -- Set text scale for better visibility
local w, h = monitor.getSize()

-- Self Check vars
local selfCheckSleep = 30

-- Items to track
local items = {
    {
        name = "allthemodium:unobtainium_dust",
        label = "Unobtainium Dust",
        color = colors.purple,
        maxAmount = 50000,
        overrideOreControl = false, -- Whether to override ore control for this item
        miner = {
            operational = false,
            id = "end_miner",
            cableColor = colors.black,
        },
    },
    {
        name = "allthemodium:vibranium_dust",
        label = "Vibranium Dust",
        color = colors.green,
        maxAmount = 50000,
        overrideOreControl = false, -- Whether to override ore control for this item
        miner = {
            operational = false,
            id = "nether_miner_b",
            cableColor = colors.green,
        },
    },
    {
        name = "allthemodium:allthemodium_dust",
        label = "Allthemodium Dust",
        color = colors.orange,
        maxAmount = 50000,
        overrideOreControl = false, -- Whether to override ore control for this item
        miner = {
            operational = false,
            id = "overworld_miner",
            cableColor = colors.orange,
        },
    },
    {
        name = "minecraft:ancient_debris",
        label = "Ancient Debris",
        color = colors.brown,
        maxAmount = 100000,
        overrideOreControl = false, -- Whether to override ore control for this item
        miner = {
            operational = false,
            id = "nether_miner_a",
            cableColor = colors.red,
        },
    },
    {
        name = "alltheores:gold_dust",
        label = "Gold Dust",
        color = colors.yellow,
        maxAmount = 7000000,
        overrideOreControl = false, -- Whether to override ore control for this item
        miner = {
            operational = false,
            id = "nether_miner_a",
            cableColor = colors.red,
        },
    },
    {
        name = "alltheores:gold_dust",
        label = "Gold Dust",
        color = colors.yellow,
        maxAmount = 7000000,
        overrideOreControl = false, -- Whether to override ore control for this item
        miner = {
            operational = false,
            id = "mining_dimension_miner",
            cableColor = colors.blue,
        },
    },
    {
        name = "alltheores:iron_dust",
        label = "Iron Dust",
        color = colors.lightGray,
        maxAmount = 500000,
        overrideOreControl = false, -- Whether to override ore control for this item
        miner = {
            operational = false,
            id = "mining_dimension_miner",
            cableColor = colors.blue,
        },
    },
    {
        name = "alltheores:tin_dust",
        label = "Tin Dust",
        color = colors.yellow,
        maxAmount = 50000,
        overrideOreControl = false, -- Whether to override ore control for this item
        miner = {
            operational = false,
            id = "mining_dimension_miner",
            cableColor = colors.blue,
        },
    },
    {
        name = "alltheores:copper_dust",
        label = "Copper Dust",
        color = colors.orange,
        maxAmount = 5000000,
        overrideOreControl = false, -- Whether to override ore control for this item
        miner = {
            operational = false,
            id = "mining_dimension_miner",
            cableColor = colors.blue,
        }, 
    },
    {
        name = "alltheores:osmium_dust",
        label = "Osmium Dust",
        color = colors.lightGray,
        maxAmount = 500000,
        overrideOreControl = false, -- Whether to override ore control for this item
        miner = {
            operational = false,
            id = "mining_dimension_miner",
            cableColor = colors.blue,
        },
    },
}

-- Bar Graph Settings
local displayTime = 10 -- Time to display the item in seconds
local graphTop = 2 -- Top position for the graph
local graphBottom = h - 4 -- Bottom position for the graph
local graphHeight = graphBottom - graphTop -- Height of the graph area
local yAxisLineX = -1 -- X position for the Y-axis line, will be calculated dynamically
--local maxItemCount = 700000000 -- Scale upper limit for the bar graph

-- Utility Functions
local function getItemCount(itemName)
    local list = meBridge.listItems()
    for _, item in ipairs(list) do
        if item.name == itemName then
            return item.count
        end
    end
    return 0
end

local function getStep(x)
    if x <= 1000 then
        return 100
    elseif x <= 10000 then
        return 1000
    elseif x <= 100000 then
        return 10000
    elseif x <= 1000000 then
        return 100000
    elseif x <= 10000000 then
        return 1000000
    elseif x <= 100000000 then
        return 10000000
    else
        return 100000000
    end
end

local function getRawOreTag(tag)
    local rawList = {
        ["allthemodium:allthemodium_dust"] = "allthemodium:raw_allthemodium",
        ["allthemodium:unobtainium_dust"] = "allthemodium:raw_unobtainium",
        ["allthemodium:vibranium_dust"] = "allthemodium:raw_vibranium",
        ["alltheores:osmium_dust"] = "alltheores:raw_osmium",
        ["alltheores:iron_dust"] = "minecraft:raw_iron",
        ["alltheores:gold_dust"] = "minecraft:raw_gold",
        ["alltheores:copper_dust"] = "minecraft:raw_copper",
        ["alltheores:zinc_dust"] = "allthemodium:raw_zinc",
        ["alltheores:iridium_dust"] = "alltheores:raw_iridium",
        ["alltheores:lead_dust"] = "alltheores:raw_lead",
        ["alltheores:nickel_dust"] = "alltheores:raw_nickel",
        ["alltheores:uranium_dust"] = "alltheores:raw_uranium",
        ["alltheores:tin_dust"] = "alltheores:raw_tin",
        ["alltheores:platinum_dust"] = "alltheores:raw_platinum",
        ["alltheores:silver_dust"] = "alltheores:raw_silver",
        ["alltheores:aluminum_dust"] = "alltheores:raw_aluminum",
        ["minecraft:ancient_debris"] = "minecraft:ancient_debris",
        ["silentgear:azure_silver_dust"] = "silentgear:raw_azure_silver",
    }
    return rawList[tag]
end

-- Ore Control Management
local function sendOreControlMessage(item, off)
    local oreTag = getRawOreTag(item.name)
    if not oreTag then return end -- No corresponding raw ore found skip sending
    
    local message = {
        tag = oreTag,
        minerId = item.miner.id,
        off = off
    }
    modem.transmit(MODEM_CHANNEL, MODEM_CHANNEL, message)
end

local function setOreSignals(items)
     -- Handle ore-specific control messages
    for _, item in ipairs(items) do
        local itemCount = getItemCount(item.name)
        local isFull = (itemCount >= item.maxAmount)
        local off = isFull or item.overrideOreControl
        
        -- Init cached state if not present
        if item.lastOffState == nil then
            item.lastOffState = not off -- Force initial send
        end

        -- Only send message if state has changed
        if off ~= item.lastOffState then
            sendOreControlMessage(item, off)
            item.lastOffState = off
        end
    end
end

-- Miner Power Management
local function updateBundledOutput(items, side)
    local colorMask = 0

    -- Track which miner IDs we've already processed
    local processedMiners = {}
    for _, item in ipairs(items) do
        local miner = item.miner
        local minerId = miner.id
        if not processedMiners[minerId] then
            processedMiners[minerId] = true

            local color = miner.cableColor
            if color then
                if miner.operational then
                    colorMask = colors.combine(colorMask, color) -- Set bit for the color
                else
                    colorMask = colors.subtract(colorMask, color) -- Clear bit for the color
                end
            end
        end
    end

    -- Set the bundled output on the specified side
    redstone.setBundledOutput(side, colorMask)
end

local function powerMiners(items)
    -- Group items by miner ID
    local minerGroups = {}
    for _, item in ipairs(items) do
        local minerId = item.miner.id
        if not minerGroups[minerId] then
            minerGroups[minerId] = {}
        end
        table.insert(minerGroups[minerId], item)
    end

    -- Determine if each miner should be operational
    for minerId, group in pairs(minerGroups) do
        local shouldBeOperational = false
        for _, item in ipairs(group) do
            local itemCount = getItemCount(item.name)
            if itemCount < item.maxAmount then
                shouldBeOperational = true
                break
            end
        end
        
        -- Set all items in the group to the same operational status
        for _, item in ipairs(group) do
            item.miner.operational = shouldBeOperational
        end
    end
end

-- Graphics Functions
local function drawGraph(maxCount)
    local step = getStep(maxCount)  -- Determine the step size for the Y-axis labels
    local labelCount = math.floor(maxCount / step)
    local pixelsPerStep = graphHeight / labelCount
    for i = 0, labelCount do
        local value = i * step
        local y = graphBottom - math.floor(i * pixelsPerStep)
        monitor.setCursorPos(1, y)
        monitor.setTextColor(colors.white)
        monitor.write(string.format("%5d", value))

        -- Calculate the position for the vertical line by text width
        local lineX = 1 + string.len(tostring(value)) + 2 -- 2 spaces after the number
        if lineX > yAxisLineX then
            yAxisLineX = lineX
        end
    end


    -- Draw vertical line for Y-axis
    paintutils.drawLine(yAxisLineX, graphTop, yAxisLineX, graphBottom, colors.white)

    -- Draw horizontal line for X-axis
    local xBarWidth = (w - 2) -- Adjust for monitor width
    paintutils.drawLine(yAxisLineX, graphBottom,  xBarWidth, graphBottom, colors.white)
end

local function drawBar(value, maxCount, color)
    local percentage = math.min(value / maxCount, 1)
    local filledHeight = math.floor(percentage * graphHeight)

    if value > 0 and filledHeight < 1 then
        filledHeight = 1
    end
    if filledHeight > graphHeight then
        filledHeight = graphHeight
    end

    local yStart = (graphBottom - 1) - filledHeight + 1 -- +1 to adjust for 1-based index
    local yEnd = graphBottom - 1 -- Bottom of the graph area
    local barX = yAxisLineX + 3 -- Start bar after the Y-axis line
    local barWidth = (w - 2) - barX - 3 -- Width of the bar based on monitor width
    paintutils.drawFilledBox(barX, yStart, barX + barWidth, yEnd, color)
end

local function drawScreen(item, value) 
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    monitor.setCursorPos(1, 1)

    drawGraph(item.maxAmount)
    drawBar(value, item.maxAmount, item.color)

    local posY = graphBottom + 2
    monitor.setCursorPos(1, posY)
    monitor.setTextColor(colors.white)
    monitor.write(item.label .. " (" .. value .. ")")

    posY = posY + 2
    monitor.setCursorPos(1, posY)
    if item.miner.operational then
        monitor.setBackgroundColor(colors.green)
        monitor.write("Status: Online")
    else
        monitor.setBackgroundColor(colors.red)
        monitor.write("Status: Offline")
    end
end

-- Self check functions
local function bootCounter()
    local msg = "Booting in:"
    local count = selfCheckSleep
    local x = #msg + 2
    monitor.setCursorPos(1, 2)
    monitor.write(msg)
    while count > 0 do
        -- clear previous count
        local padLen = w - x + 1
        monitor.write(string.rep(" ", padLen))
        
        monitor.setCursorPos(x, 2)
        monitor.write(count .. " secs")
        count = count -1
        sleep(1)
    end
    
    -- Show booting msg
    monitor.setCursorPos(1, 2)
    monitor.clearLine()
    monitor.write("Booting up!")

    -- Open modem on the specified channel
    modem.open(MODEM_CHANNEL)
    sleep(1)  -- Give it a moment to open
end

local function selfCheck()
    monitor.setBackgroundColor(colors.black)
    monitor.setCursorPos(1,1)
    monitor.clear()
    monitor.write("Waiting for ae2 to init!")
    bootCounter()
end

-- Main Loop
selfCheck()  -- Perform self-check on startup
while true do
    powerMiners(items)  -- Update all miners' operational status based on their items
    updateBundledOutput(items, "back")  -- Update the bundled output on the back side
    setOreSignals(items)  -- Send ore control messages based on item counts

    -- Display each item on the monitor
    for _, item in ipairs(items) do
        local count = getItemCount(item.name)
        drawScreen(item, count)
        sleep(displayTime)
    end
end