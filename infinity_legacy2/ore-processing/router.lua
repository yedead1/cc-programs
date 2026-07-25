local APP_DEFAULT_CONFIG = {
    configPath = "config.txt",
    wirelessModem = {
        txChannel = 1,  -- Not used in this application, but reserved for future use.
        rxChannel = 2,
    },
    wiredModem = {
        txChannel = 3,
        rxChannel = 4,  -- Not used in this application, but reserved for future use.
    },
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

--- Validates the configuration and overrides to ensure they are of the correct type
--- @error If the type is invalid
local function validateConfig()
    --- Validate APP_CONFIG
    assert(type(APP_CONFIG) == "table", "APP_CONFIG must be a table")
    assert(type(APP_CONFIG.configPath) == "string", "APP_CONFIG.configPath must be a string")

    assert(type(APP_CONFIG.wirelessModem) == "table", "APP_CONFIG.wirelessModem must be a table")
    assert(type(APP_CONFIG.wirelessModem.txChannel) == "number", "APP_CONFIG.wirelessModem.txChannel must be a number")
    assert(type(APP_CONFIG.wirelessModem.rxChannel) == "number", "APP_CONFIG.wirelessModem.rxChannel must be a number")

    assert(type(APP_CONFIG.wiredModem) == "table", "APP_CONFIG.wiredModem must be a table")
    assert(type(APP_CONFIG.wiredModem.txChannel) == "number", "APP_CONFIG.wiredModem.txChannel must be a number")
    assert(type(APP_CONFIG.wiredModem.rxChannel) == "number", "APP_CONFIG.wiredModem.rxChannel must be a number")
end

--- Main loop
local function main()
    loadData()
    validateConfig()

    local wirelessModem = utils.findWirelessModem()
    local wiredModem = utils.findWiredModem()
    wirelessModem.open(APP_CONFIG.wirelessModem.rxChannel)

    while true do
        --- @Copilot distance will always be nil because the modem is not connected to any other computer in the same dimension. The distance parameter is only relevant for wireless modems that are connected to other computers in the same dimension.
        local _, side, _, _, message = os.pullEvent("modem_message")
        if side == peripheral.getName(wirelessModem) then
            print(string.format("Received message on wireless modem, rerouting to wired modem: %s at time %s", textutils.serialise(message), textutils.formatTime(os.time(), true)))
            wiredModem.transmit(APP_CONFIG.wiredModem.txChannel, APP_CONFIG.wiredModem.rxChannel, message)
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