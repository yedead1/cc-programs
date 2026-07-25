--- Utility functions for the ore processor.

--- Flattens a nested table into a single-level table.
--- @param tbl table The nested table to flatten.
--- @return table table The flattened table.
local function flattenTable(tbl)
    local result = {}
    local function recursiveFlatten(t, prefix)
        for k, v in pairs(t) do
            local key = prefix and (prefix .. "." .. tostring(k)) or tostring(k)
            if type(v) == "table" then
                recursiveFlatten(v, key)
            else
                result[key] = v
            end
        end
    end
    recursiveFlatten(tbl)
    return result
end

--- Parses a value into a boolean. Accepts "true", "1", or "on" (case-insensitive) as true; everything else is false.
--- @param value any The value to parse.
--- @return boolean boolean The parsed boolean value.
local function parseBool(value)
    value = tostring(value):lower()
    return value == "true" or value == "1" or value == "on"
end

--- Loads a table from a file, or returns an empty table if the file does not exist.
--- @param path string The path to the file.
--- @return table|nil table The loaded table, or nil if the file does not exist.
local function loadTable(path)
    if not fs.exists(path) then
        return nil
    end

    local file = fs.open(path, "r")
    local content = file.readAll()
    file.close()
    return textutils.unserialize(content) or nil
end

--- Saves a table to a file, overwriting any existing content.
--- @param path string The path to the file.
--- @param tbl table table The table to save.
--- @return nil
local function saveTable(path, tbl)
    local file = fs.open(path, "w")
    file.write(textutils.serialize(tbl))
    file.close()
end

--- Appends the contents of one table to another and saves it to a file.
--- @param path string The path to the file.
--- @param tbl table The table to append.
--- @return nil
local function appendTable(path, tbl)
    local existing = loadTable(path) or {}
    local changed = false
    for k, v in pairs(tbl) do
        if v ~= existing[k] then
            existing[k] = v
            changed = true
        end
    end
    if changed then
        saveTable(path, existing)
    end
end

--- Cached modems
local cachedWiredModem = nil
local cachedWirelessModem = nil

--- Finds a wired modem peripheral and caches it for future use.
--- @return table table The wrapped wired modem peripheral.
--- @error If no wired modem is found.
local function findWiredModem()
    if cachedWiredModem and peripheral.isPresent(peripheral.getName(cachedWiredModem)) then
        return cachedWiredModem
    end

    local peripherals = peripheral.getNames()
    for _, name in ipairs(peripherals) do
        if peripheral.getType(name) == "modem" then
            local modem = peripheral.wrap(name)
            if modem and modem.isWireless() == false then
                cachedWiredModem = modem
                return cachedWiredModem
            end
        end
    end
    error("No wired modem found.")
end

--- Finds a wireless modem peripheral and caches it for future use.
--- @return table table The wrapped wireless modem peripheral.
--- @error If no wireless modem is found.
local function findWirelessModem()
    if cachedWirelessModem and peripheral.isPresent(peripheral.getName(cachedWirelessModem)) then
        return cachedWirelessModem
    end

    local peripherals = peripheral.getNames()
    for _, name in ipairs(peripherals) do
        if peripheral.getType(name) == "modem" then
            local modem = peripheral.wrap(name)
            if modem and modem.isWireless() == true then
                cachedWirelessModem = modem
                return cachedWirelessModem
            end
        end
    end
    error("No wireless modem found.")
end

--- Terminal methods
--- Pagination function to display data in a paginated format on the terminal.
--- @param data table A table containing 'header' (string) and 'lines' (table) to display.
--- @return nil
local function pagination(data)
    local oldBgColor = term.getBackgroundColor()
    local oldTextColor = term.getTextColor()
    local oldX, oldY = term.getCursorPos()

    if type(data) ~= "table" then
        print("Error: Data must be a table.")
        return
    elseif type(data.header) ~= "string" then
        print("Error: Data must have a 'header' string.")
        return
    elseif type(data.lines) ~= "table" then
        print("Error: Data must have a 'lines' table.")
        return
    end

    local header = data.header
    local lines = data.lines
    if #lines == 0 then
        lines = {"No data available."}
    end

    local curPage = 1
    while true do
        local w, h = term.getSize()
        local maxLinesPerPage = h - 3
        local totalPages = math.max(1, math.ceil(#lines / maxLinesPerPage))
        if curPage > totalPages then
            curPage = totalPages
        end

        term.clear()
        term.setCursorPos(1, 1)

        term.setTextColor(colors.yellow)
        print("---" .. header .. "---")
        term.setTextColor(colors.white)

        -- Calculate the slice bounds for the current page
        local startIdx = (curPage - 1) * maxLinesPerPage + 1
        local endIdx = math.min(startIdx + maxLinesPerPage - 1, #lines)
        for i = startIdx, endIdx do
            print(lines[i])
        end

        -- print the footer with page information
        term.setCursorPos(1, h)
        term.setTextColor(colors.lightGray)

        local navText = "<- Prev  |  Next ->"
        local pageInfo = string.format("Page %d of %d", curPage, totalPages)

        -- Align the navigation text to the left and page info to the right
        term.write(navText)
        term.setCursorPos(w - #pageInfo + 1, h)
        term.write(pageInfo)

        -- Wait for user input to navigate pages
        local event, key = os.pullEvent("key")
        if key == keys.left then
            if curPage > 1 then
                curPage = curPage - 1
            end
        elseif key == keys.right then
            if curPage < totalPages then
                curPage = curPage + 1
            end
        elseif key == keys.q then
            term.setBackgroundColor(oldBgColor)
            term.setTextColor(oldTextColor)
            term.clear()
            term.setCursorPos(oldX, oldY)
            break
        end
    end
end

return {
    flattenTable = flattenTable,
    flattern = flattenTable,  -- Alias for flattenTable
    parseBool = parseBool,
    loadTable = loadTable,
    saveTable = saveTable,
    appendTable = appendTable,
    findWiredModem = findWiredModem,
    findWirelessModem = findWirelessModem,
    pagination = pagination
}