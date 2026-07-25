local APP_DEFAULT_CONFIG = {
    configPath = "config.txt",
    wiredModem = {
        txChannel = 1,  -- Not used in this application, but reserved for future use.
        rxChannel = 2
    },
    outputs = {
        aluminum = "left",
        copper = "right",
        gold = "back",
        iridium = "top"
    }
}

local APP_CONFIG = {}

--- Imports
require("bootstrap")    -- Makes sure the environment is set up correctly to import other modules
local utils = require("utils")

--- Helpers
--- Saves the configuration and overrides to their respective files
--- @param data table The data to save
--- @error If the type is invalid
local function saveData(data)
    utils.saveTable(APP_DEFAULT_CONFIG.configPath, data)
end

--- Loads the configuration and overrides from their respective files
--- If the files do not exist, it will create them with default values
local function loadData()
    APP_CONFIG = utils.loadTable(APP_DEFAULT_CONFIG.configPath)

    if APP_CONFIG == nil then
        APP_CONFIG = APP_DEFAULT_CONFIG
        saveData(APP_CONFIG)
    end
end

--- Returns a list of valid outputs for the program
--- @return table table A list of valid outputs
local function validOutputs()
    return {
        "left",
        "right",
        "top",
        "back"
    }
end

--- Validates the configuration and overrides to ensure they are of the correct type
--- @error If the type is invalid
local function validateConfig()
    --- Validate APP_CONFIG
    assert(type(APP_CONFIG) == "table", "APP_CONFIG must be a table")
    assert(type(APP_CONFIG.configPath) == "string", "APP_CONFIG.configPath must be a string")

    assert(type(APP_CONFIG.wiredModem) == "table", "APP_CONFIG.wiredModem must be a table")
    assert(type(APP_CONFIG.wiredModem.txChannel) == "number", "APP_CONFIG.wiredModem.txChannel must be a number")
    assert(type(APP_CONFIG.wiredModem.rxChannel) == "number", "APP_CONFIG.wiredModem.rxChannel must be a number")

    assert(type(APP_CONFIG.outputs) == "table", "APP_CONFIG.outputs must be a table")

    local validOutputsList = validOutputs()
    for key, value in pairs(APP_CONFIG.outputs) do
        assert(type(value) == "string", "APP_CONFIG.outputs." .. key .. " must be a string")
        local isValid = false
        for _, validOutput in ipairs(validOutputsList) do
            if value == validOutput then
                isValid = true
                break
            end
        end
        assert(isValid, "APP_CONFIG.outputs." .. key .. " must be one of " .. table.concat(validOutputsList, ", "))
    end
end

local function main()
    loadData()
    validateConfig()

    local wiredModem = utils.findWiredModem()
    wiredModem.open(APP_CONFIG.wiredModem.rxChannel)

    while true do
        local _, _, _, _, message = os.pullEvent("modem_message")

        print(string.format("Received message: %s at time %s", textutils.serialize(message), textutils.formatTime(os.time(), true)))
        if type(message) == "table" then
            for material, side in pairs(APP_CONFIG.outputs) do
                if message[material] then
                    print(string.format("Setting redstone output for %s on side %s enabled=%s", material, side, tostring(message[material])))
                    redstone.setOutput(side, message[material])
                end
            end
        end
    end
end

local function commandLoop()
    while true do
        local input = read()
        if input == "restart" then
            shell.run(shell.getRunningProgram())
            return
        end
    end
end

parallel.waitForAny(main, commandLoop)