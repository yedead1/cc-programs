--Peripherals
local monitor = peripheral.find("monitor")
assert(monitor, "No monitor found")

local detector = peripheral.find("playerDetector")
assert(detector, "No player detector found")

monitor.setTextScale(0.5)
monitor.setBackgroundColor(colors.black)
monitor.setTextColor(colors.white)

-- Global Variables
local PROGRAM_NAME = "Player Stalker"
local NAME_COL_WIDTH = 20
local STATUS_COL_WIDTH = 8
local DIMENSION_COL_WIDTH = 15
local LOCATION_COL_WIDTH = 25
local HP_COL_WIDTH = 10
local AIR_COL_WIDTH = 15

--Player state players[name] = {dimension=dim, location=loc, online=status}
local players = {}

-- Helper function to pad a string for center alignment
local function centerText(txt, width)
    local wrappedLines = {}
    local function wrapLine(line)
        while #line > width do
            local s, _ = line:sub(1, width):find("%s[^%s]*$")
            local wrapAt = s or width
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

-- Helper to make the table fit the monitor
local function adjustColumnWidths()
    local monitorWidth, _ = monitor.getSize()
    local totalFixedWidth = NAME_COL_WIDTH + STATUS_COL_WIDTH + DIMENSION_COL_WIDTH + LOCATION_COL_WIDTH + HP_COL_WIDTH + AIR_COL_WIDTH
    if totalFixedWidth > monitorWidth then
        -- Reduce column widths proportionally
        local excess = totalFixedWidth - monitorWidth
        local reductionFactor = excess / 6
        NAME_COL_WIDTH = math.max(20, NAME_COL_WIDTH - math.floor(reductionFactor))
        STATUS_COL_WIDTH = math.max(8, STATUS_COL_WIDTH - math.floor(reductionFactor))
        DIMENSION_COL_WIDTH = math.max(15, DIMENSION_COL_WIDTH - math.floor(reductionFactor))
        LOCATION_COL_WIDTH = math.max(25, LOCATION_COL_WIDTH - math.floor(reductionFactor))
        HP_COL_WIDTH = math.max(10, HP_COL_WIDTH - math.floor(reductionFactor))
        AIR_COL_WIDTH = math.max(15, AIR_COL_WIDTH - math.floor(reductionFactor))
    end
end

local function drawHeader()
    local width, _ = monitor.getSize()
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write(centerText(PROGRAM_NAME, width))
    
    adjustColumnWidths()    -- Adjust column widths to fit monitorWidth
    monitor.setCursorPos(1, 2)
    monitor.write(string.format("%-" .. NAME_COL_WIDTH .. "s", "Name"))
    monitor.write(string.format("%-" .. STATUS_COL_WIDTH .. "s", "| Status"))
    monitor.write(string.format("%-" .. DIMENSION_COL_WIDTH .. "s", "| Dimension"))
    monitor.write(string.format("%-" .. LOCATION_COL_WIDTH .. "s", "| Location"))
    monitor.write(string.format("%-" .. HP_COL_WIDTH .. "s", "| HP/Max"))
    monitor.write(string.format("%-" .. AIR_COL_WIDTH .. "s", "| Air Supply"))
    monitor.setCursorPos(1, 3)
    monitor.write(string.rep("-", NAME_COL_WIDTH + STATUS_COL_WIDTH + DIMENSION_COL_WIDTH + LOCATION_COL_WIDTH + HP_COL_WIDTH + AIR_COL_WIDTH))
end

local function drawPlayers()
    local row = 4
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)
    for name, stat in pairs(players) do
        monitor.setCursorPos(1, row)
        monitor.write(string.format("%-" .. NAME_COL_WIDTH .. "s", name))
        if stat.online then
            monitor.setBackgroundColor(colors.green)
            monitor.write(string.format("%-" .. STATUS_COL_WIDTH .. "s", "Online"))
        else
            monitor.setBackgroundColor(colors.red)
            monitor.write(string.format("%-" .. STATUS_COL_WIDTH .. "s", "Offline"))
        end

        monitor.setBackgroundColor(colors.black)
        monitor.write(string.format("%-" .. DIMENSION_COL_WIDTH .. "s", stat.dimension))
        monitor.write(string.format("%-" .. LOCATION_COL_WIDTH .. "s", string.format("X: %d Y: %d Z: %d", stat.location.x, stat.location.y, stat.location.z)))

        -- HP with color coding
        local maxHp = math.max(stat.maxHp, 1) -- Prevent division by zero
        local hpRatio = stat.hp / maxHp
        if hpRatio <= 0.5 then
            monitor.setBackgroundColor(colors.orange)
        elseif hpRatio <= 0.25 then
            monitor.setBackgroundColor(colors.red)
        else
            monitor.setBackgroundColor(colors.green)
        end
        monitor.write(string.format("%-" .. HP_COL_WIDTH .. "s", string.format("%d/%d", stat.hp, stat.maxHp)))

        -- Air Supply with color coding
        local airRatio = stat.air / 300 -- 300 is full air supply (hopefully no mods change this)
        if airRatio <= 0.5 then
            monitor.setBackgroundColor(colors.orange)
        elseif airRatio <= 0.25 then
            monitor.setBackgroundColor(colors.red)
        else
            monitor.setBackgroundColor(colors.green)
        end
        monitor.write(string.format("%-" .. AIR_COL_WIDTH .. "s", string.format("%d", stat.air)))
        row = row + 1
    end
end

-- Initial Sync
local onlineNow = detector.getOnlinePlayers()
for _, name in ipairs(onlineNow) do
    local player = detector.getPlayer(name)
    local coords = {
        x = player.x,
        y = player.y,
        z = player.z
    }
    players[name] = {dimension = player.dimension, location = coords, online = true, hp = player.health, maxHp = player.maxHealth, air = player.airSupply}
end

drawHeader()    -- Draw header once

-- Main Loop
local updateInterval = 2
local timer = os.startTimer(updateInterval)

while true do
    local event, param1, param2 = os.pullEvent()
    if event == "playerJoin" then
        local username, dimension = param1, param2
        if not players[username] then
            players[username] = {dimension = dimension, location = {x=0, y=0, z=0}, online = true, hp = 0, maxHp = 0, air = 0}
        else
            players[username].online = true
        end
        drawPlayers()
    elseif event == "playerLeave" then
        local username = param1
        if players[username] then
            players[username].online = false
            drawPlayers()
        end
    elseif event == "timer" and param1 == timer then
        -- Update player stats
        for name, stat in pairs(players) do
            if stat.online then
                local player = detector.getPlayer(name)
                if player then
                    stat.dimension = player.dimension
                    stat.location = {x = player.x, y = player.y, z = player.z}
                    stat.hp = player.health
                    stat.maxHp = player.maxHealth
                    stat.air = player.airSupply
                end
            end
        end
        drawPlayers()
        timer = os.startTimer(updateInterval)
    end
end