--- Application defaults
local APP_DEFAULT_CONFIG = {
    app = {
        sleepDelay = 600,
        autoSaveConfig = false,
        defaultMin = 10000,
        defaultMax = 15000,
        configPath = "config.txt",
        overridesPath = "overrides.txt",
        modem = {
            transmitChannel = 1,
            receiveChannel = 2
        }
    },
    resources = {
        aluminum = {
            item = "c:dusts/aluminum",
            min = 10000,
            max = 15000
        },
        copper = {
            item = "c:dusts/copper",
            min = 10000,
            max = 15000
        },
        gold = {
            item = "c:dusts/gold",
            min = 10000,
            max = 15000
        },
        iridium = {
            item = "c:dusts/iridium",
            min = 10000,
            max = 15000
        },
        iron = {
            item = "c:dusts/iron",
            min = 10000,
            max = 15000
        },
        lead = {
            item = "c:dusts/lead",
            min = 10000,
            max = 15000
        },
        nickel = {
            item = "c:dusts/nickel",
            min = 10000,
            max = 15000
        },
        osmium = {
            item = "c:dusts/osmium",
            min = 10000,
            max = 15000
        },
        platinum = {
            item = "c:dusts/platinum",
            min = 10000,
            max = 15000
        },
        silver = {
            item = "c:dusts/silver",
            min = 10000,
            max = 15000
        },
        tin = {
            item = "c:dusts/tin",
            min = 10000,
            max = 15000
        },
        uranium = {
            item = "c:dusts/uranium",
            min = 10000,
            max = 15000
        },
        zinc = {
            item = "c:dusts/zinc",
            min = 10000,
            max = 15000
        }
    }
}

local APP_DEFAULT_OVERRIDES = {
    -- Example override for aluminum
    -- aluminum = true,
}

local CONFIG_TYPES = {
    CONFIG = 0,
    OVERRIDES = 1,
}

--- Application global vars
local APP_CONFIG = {}
local APP_OVERRIDES = {}
local APP_RESOURCES = {}


--- Imports
require("bootstrap")    -- Makes sure the environment is set up correctly to import other modules
local utils = require("utils")

--- Helpers
--- Saves the configuration and overrides to their respective files
--- @param data table The data to save
--- @param type number The type of data to save (CONFIG_TYPES.CONFIG or CONFIG_TYPES.OVERRIDES)
--- @error If the type is invalid
local function saveData(data, type)
    if type == CONFIG_TYPES.CONFIG then
        utils.saveTable(APP_DEFAULT_CONFIG.app.configPath, data)
    elseif type == CONFIG_TYPES.OVERRIDES then
        utils.saveTable(APP_DEFAULT_CONFIG.app.overridesPath, data)
    else
        error("Invalid config type")
    end
end

--- Loads the configuration and overrides from their respective files
--- If the files do not exist, it will create them with default values
local function loadData()
    APP_CONFIG = utils.loadTable(APP_DEFAULT_CONFIG.app.configPath)
    APP_OVERRIDES = utils.loadTable(APP_DEFAULT_CONFIG.app.overridesPath)

    if APP_CONFIG == nil then
        APP_CONFIG = APP_DEFAULT_CONFIG
        saveData(APP_DEFAULT_CONFIG, CONFIG_TYPES.CONFIG)
    end
    if APP_OVERRIDES == nil then
        APP_OVERRIDES = APP_DEFAULT_OVERRIDES
        saveData(APP_DEFAULT_OVERRIDES, CONFIG_TYPES.OVERRIDES)
    end
end

--- Appends data to the configuration or overrides and saves it to their respective files
--- @param data table The data to append
--- @param type number The type of data to append (CONFIG_TYPES.CONFIG or CONFIG_TYPES.OVERRIDES)
--- @error If the type is invalid
local function appendData(data, type)
    if type == CONFIG_TYPES.CONFIG then
        utils.appendTable(APP_DEFAULT_CONFIG.app.configPath, data)
    elseif type == CONFIG_TYPES.OVERRIDES then
        utils.appendTable(APP_DEFAULT_CONFIG.app.overridesPath, data)
    else
        error("Invalid config type")
    end
end

--- Validation
--- Validates the resource configurations
--- @param resourceName string The name of the resource
--- @param resourceConfig table The configuration of the resource
--- @param resourceConfig.item string The item name of the resource
--- @param resourceConfig.min number The minimum amount of the resource
--- @param resourceConfig.max number The maximum amount of the resource
--- @error If the resource configuration is invalid
local function validateResource(resourceName, resourceConfig)
    assert(type(resourceConfig) == "table", string.format("Resource '%s' config must be a table", resourceName))
    assert(type(resourceConfig.item) == "string", string.format("Resource '%s' item must be a string", resourceName))
    assert(type(resourceConfig.min) == "number", string.format("Resource '%s' min must be a number", resourceName))
    assert(type(resourceConfig.max) == "number", string.format("Resource '%s' max must be a number", resourceName))
end

--- Validates the entire configuration
--- @error If any part of the configuration is invalid
local function validateConfig()
    --- Validate APP_CONFIG
    assert(type(APP_CONFIG) == "table", "APP_CONFIG must be a table")

    --- Validate APP_CONFIG.app
    assert(type(APP_CONFIG.app) == "table", "APP_CONFIG.app must be a table")
    assert(type(APP_CONFIG.app.sleepDelay) == "number", "APP_CONFIG.app.sleepDelay must be a number")
    assert(type(APP_CONFIG.app.autoSaveConfig) == "boolean", "APP_CONFIG.app.autoSaveConfig must be a boolean")
    assert(type(APP_CONFIG.app.defaultMin) == "number", "APP_CONFIG.app.defaultMin must be a number")
    assert(type(APP_CONFIG.app.defaultMax) == "number", "APP_CONFIG.app.defaultMax must be a number")
    assert(type(APP_CONFIG.app.configPath) == "string", "APP_CONFIG.app.configPath must be a string")
    assert(fs.exists(APP_CONFIG.app.configPath), "APP_CONFIG.app.configPath must exist")
    assert(type(APP_CONFIG.app.overridesPath) == "string", "APP_CONFIG.app.overridesPath must be a string")
    assert(fs.exists(APP_CONFIG.app.overridesPath), "APP_CONFIG.app.overridesPath must exist")
    assert(type(APP_CONFIG.app.modem) == "table", "APP_CONFIG.app.modem must be a table")
    assert(type(APP_CONFIG.app.modem.transmitChannel) == "number", "APP_CONFIG.app.modem.transmitChannel must be a number")
    assert(type(APP_CONFIG.app.modem.receiveChannel) == "number", "APP_CONFIG.app.modem.receiveChannel must be a number")

    --- Validate APP_CONFIG.resources
    assert(type(APP_CONFIG.resources) == "table", "APP_CONFIG.resources must be a table")
    for resourceName, resourceConfig in pairs(APP_CONFIG.resources) do
        validateResource(resourceName, resourceConfig)
    end
end

--- Validates the overrides configuration
--- @error If any part of the overrides configuration is invalid
local function validateOverrides()
    assert(type(APP_OVERRIDES) == "table", "APP_OVERRIDES must be a table")
    for resourceName, overrideValue in pairs(APP_OVERRIDES) do
        assert(type(resourceName) == "string", "Override resource name must be a string")
        assert(type(overrideValue) == "boolean", string.format("Override value for resource '%s' must be a boolean", resourceName))
    end
end

--- Application Methods
--- Initializes the application by loading data and validating configurations and overrides
local function initialize()
    loadData()
    validateConfig()
    validateOverrides()
end

--- Interface Methods
--- Finds the first available storage controller or access point
--- @return table table The peripheral object of the found storage controller or access point
--- @error If no storage controller or access point is found
local function findDrawerController()
    local controller = peripheral.find("functionalstorage:storage_controller")
    local accessPoint = peripheral.find("functionalstorage:controller_extension")
    local found = controller or accessPoint -- Use the controller if found, otherwise use the access point
    if not found then
        error("No storage controller or access point found")
    end

    return found
end

--- Scans the inventory of the storage controller or access point for items matching the specified targets
--- @param targets table|nil A table containing namespaces and tags to match against
--- @return table table A table containing the counts of matching items found in the inventory
local function scanInventory(targets)
    if not targets or type(targets) ~= "table" then
        targets = {
            combinedMatch = false,
            namespaces = {
                "c:dusts/"
            },
            tags = {}
        }
    end

    local drawerController = findDrawerController()
    local items = drawerController.list()
    local inventory = {}
    local index = 0
    for slot, item in pairs(items) do
        index = index + 1

        -- Periodically yield to prevent the computer from crashing/freezing on large drawer setups
        if index % 20 == 0 then
            os.queueEvent("yield")
            os.pullEvent("yield")
        end
        
        local details = drawerController.getItemDetail(slot, true)  -- Get the item details including NBT data
        if details and details.tags then
            -- Scan for matching tags or namespaces
            for tagName, _ in pairs(details.tags) do
                local combinedMatch = targets.combinedMatch or false
                if not combinedMatch then
                    local matched = false
                    if type(targets.tags) == "table" then
                        for _, explictTag in ipairs(targets.tags) do
                            if tagName == utils.trim(explictTag) then
                                inventory[tagName] = item.count
                                matched = true
                                break
                            end
                        end
                    end

                    if not matched and type(targets.namespaces) == "table" then
                        for _, namespace in ipairs(targets.namespaces) do
                            local pattern = "^" .. utils.trim(namespace) .. "[^/]+$"  -- Match the namespace followed by any characters except a slash
                            if tagName:match(pattern) then
                                inventory[tagName] = item.count
                                break
                            end
                        end
                    end
                else
                    -- Combined mode: match both namespace and tag, e.g., "[namespace][tag]" 
                    -- where namespace is the prefix and tag is the suffix, e.g., "c:dusts/aluminum"
                    if type(targets.namespaces) == "table" and type(targets.tags) == "table" then
                        for _, namespace in ipairs(targets.namespaces) do
                            for _, tag in ipairs(targets.tags) do
                                local pattern = "^" .. utils.trim(namespace) .. utils.trim(tag) .. "$"
                                if tagName:match(pattern) then
                                    inventory[tagName] = item.count
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return inventory
end

--- Broadcasts the current state of the resource exports to the specified transmit channel
--- @param state table A table containing the current state of the resource exports
local function broadcastState(state)
    local wirelessModem = utils.findWirelessModem()
    wirelessModem.transmit(APP_CONFIG.app.modem.transmitChannel, APP_CONFIG.app.modem.receiveChannel, state)    -- transmit can handle tables, so we can send the state table directly
end

--- Data Methods
--- Calculates the export state of each resource based on the current inventory counts and the configured min/max values
--- @param items table A table containing the current inventory counts of each resource
local function calcResources(items)
    for resourceName, resourceConfig in pairs(APP_CONFIG.resources) do
        local tagName = resourceConfig.item
        local minAmount = resourceConfig.min
        local maxAmount = resourceConfig.max
        local currentAmount = items[tagName] or 0
        if currentAmount <= minAmount then
            APP_RESOURCES[resourceName] = true
        elseif currentAmount >= maxAmount then
            APP_RESOURCES[resourceName] = false
        end
    end
end

--- List Methods
--- Lists the current state of each resource export, including the current amount, min/max values, and whether it is currently exporting or not
--- @param resources table A table containing the current state of each resource export
--- @return table table A table containing the formatted strings for each resource export state
local function listResources()
    local resourcesList = {
        header = "Resource Export States",
        lines = {}
    }
    for resourceName, resourceConfig in pairs(APP_CONFIG.resources) do
        local tagName = resourceConfig.item
        local minAmount = resourceConfig.min
        local maxAmount = resourceConfig.max
        local currentAmount = APP_RESOURCES[resourceName] and "Exporting" or "Not Exporting"
        table.insert(resourcesList.lines, string.format("%s(%s): %s (Min: %d, Max: %d)", resourceName, tagName, currentAmount, minAmount, maxAmount))
    end
    return resourcesList
end

--- Lists the current configuration values, including sleep delay, auto-save setting, default min/max values, and modem channels
--- @return table table A table containing the formatted strings for each configuration value
local function listConfig()
    local configList = {
        header = "Current Configuration",
        lines = {}
    }
    local flattenedConfig = utils.flattenTable(APP_CONFIG)
    for key, value in pairs(flattenedConfig) do
        table.insert(configList.lines, string.format("%s: %s", key, tostring(value)))
    end
    return configList
end

--- Lists the help information for available commands, including list, save, reset, update, remove, restart, and help
--- @return table table A table containing the formatted strings for each command and its description
local function listHelp()
    return{
        header = "Help - Available Commands",
        lines = {
            "list <resources|config|overrides> - Lists the current state of resources, configuration, or overrides",
            "save - Saves the current configuration and overrides to their respective files",
            "reset - Resets the configuration and overrides to their default values and saves them to their respective files",
            "update resource <name> <tag> <min> <max> - Updates an existing resource in the configuration",
            "update override <name> <on|off> - Sets an override for a specific resource",
            "update sleep <seconds> - Changes the sleep timer value in the configuration",
            "remove <resource_name> - Removes a resource from the configuration",
            "restart - Restarts the application",
            "help - Displays this help message"
        }
    }
end

--- Lists the current override values
--- @return table table A table containing the formatted strings for each override value
local function listOverrides()
    local overridesList = {
        header = "Current Overrides",
        lines = {}
    }
    for resourceName, overrideValue in pairs(APP_OVERRIDES) do
        table.insert(overridesList.lines, string.format("%s: %s", resourceName, tostring(overrideValue)))
    end
    return overridesList
end

--- Command Methods
--- Saves the current configuration and overrides to their respective files
--- @return nil
local function save()
    saveData(APP_CONFIG, CONFIG_TYPES.CONFIG)
    saveData(APP_OVERRIDES, CONFIG_TYPES.OVERRIDES)
end

--- Resets the configuration and overrides to their default values and saves them to their respective files
--- @return nil
local function reset()
    APP_CONFIG = APP_DEFAULT_CONFIG
    APP_OVERRIDES = APP_DEFAULT_OVERRIDES
    save()
end

--- Lists the current state of resources, configuration, or overrides based on the specified type
--- @param type string The type of list to display ("resources", "config", or "overrides")
--- @return nil
local function list(type)
    if type == "resources" then
        local resourcesList = listResources()
        utils.pagination(resourcesList)
    elseif type == "config" then
        local configList = listConfig()
        utils.pagination(configList)
    elseif type == "overrides" then
        local overridesList = listOverrides()
        utils.pagination(overridesList)
    else
        print("Invalid list type. Use 'resources', 'config', or 'overrides'.")
    end
end

--- Adds a new resource to the configuration
--- @param name string The name of the resource
--- @param data table The data associated with the resource
--- @return nil
local function addResource(name, data)
    validateResource(name, data)
    if APP_CONFIG.resources[name] then
        print(string.format("Resource '%s' already exists, use 'updateResource' to modify it.", name))
    else
        APP_CONFIG.resources[name] = data
        print(string.format("Resource '%s' added successfully.", name))
    end
end

--- Updates an existing resource in the configuration
--- @param name string The name of the resource
--- @param data table The data associated with the resource
--- @return nil
local function updateResource(name, data)
    validateResource(name, data)
    if APP_CONFIG.resources[name] then
        APP_CONFIG.resources[name] = data
        print(string.format("Resource '%s' updated successfully.", name))
    else
        addResource(name, data)
    end
end

--- Removes a resource from the configuration
--- @param name string The name of the resource
--- @return nil
local function removeResource(name)
    if APP_CONFIG.resources[name] then
        APP_CONFIG.resources[name] = nil
        print(string.format("Resource '%s' removed successfully.", name))
    else
        print(string.format("Resource '%s' does not exist.", name))
    end
end

--- Tells the application to start or stop exporting a specific resource based on the override value instead of the calculated state
--- @param name string The name of the resource
--- @param value boolean The override value (true to start exporting, false to stop exporting)
--- @return nil
local function setOverride(name, value)
    if type(value) ~= "boolean" then
        print("Override value must be a boolean (true or false).")
        return
    end
    APP_OVERRIDES[name] = value
    print(string.format("Override for resource '%s' set to %s.", name, tostring(value)))
end

--- Changes the sleep timer value in the configuration
--- @param value number The new sleep timer value in seconds
--- @return nil
local function setSleepTimer(value)
    if type(value) ~= "number" or value <= 0 then
        print("Sleep timer must be a positive number.")
        return
    end
    APP_CONFIG.app.sleepDelay = value
    print(string.format("Sleep timer set to %d seconds.", value))
end

--- Handles the 'update' command for resources, overrides, and sleep timer
--- @param target string The target to update ("resource", "override", or "sleep")
--- @param args table The arguments passed to the update command
--- @return nil
local function handleUpdate(target, args)
    if not target or #args < 3 then
        return
    end

    if target == "resource" then
        local name = args[3]
        local tag = args[4]
        local min = tonumber(args[5])
        local max = tonumber(args[6])
        if not (name and tag and min and max) then
            print("Usage: update resource <name> <tag> <min> <max>")
            return
        end
        updateResource(name, { item = tag, min = min, max = max })
    elseif target == "override" then
        local name = args[3]
        local value = args[4]
        if not (name and value) then
            print("Usage: update override <name> <on|off>")
            return
        end
        local boolValue = utils.parseBool(value)
        setOverride(name, boolValue)
    elseif target == "sleep" then
        local value = tonumber(args[3])
        if not value then
            print("Usage: update sleep <seconds>")
            return
        end
        setSleepTimer(value)
    else
        print(("Unknown update target: '%s'"):format(target))
    end
end

--- Executes a command based on user input, parsing the command and its arguments, and calling the appropriate function to handle the command
--- @param input string The user input command string
--- @return nil
local function execCommand(input)
    if type(input) ~= "string" or input == ""  then
        return
    end

    local args = {}
    for token in input:gmatch("%S+") do
        args[#args + 1] = token
    end

    -- Probably not needed since we already check if input is a non-empty string, but just in case, we can check if there are any arguments
    if #args == 0 then
        return
    end

    local command = args[1]:lower()
    local target = args[2] and args[2]:lower()
    if command == "list" then
        list(target)
        return
    elseif command == "save" then
        save()
        return
    elseif command == "reset" then
        reset()
        return
    elseif command == "update" then
        handleUpdate(target, args)
        return
    elseif command == "remove" then
        removeResource(target)
        return
    elseif command == "restart" then
        shell.run(shell.getRunningProgram())
        return
    elseif command == "help" then
        local helpList = listHelp()
        utils.pagination(helpList)
        return
    else
        print("Unknown command. Available commands: list, save, reset, update, remove, restart, help")
    end
end

--- Main Application Loop
--- Main loop that continuously scans the inventory, calculates resource states, broadcasts the state, and optionally saves configuration and overrides
local function main()
    initialize()
    while true do
        term.clear()
        term.setCursorPos(1, 1)

        local inventory = scanInventory(nil)    -- Use default targets if none are provided
        calcResources(inventory)
        broadcastState(APP_RESOURCES)
        print("Broadcasted current resource states.")
        print(textutils.serialize(APP_RESOURCES))

        --- Auto-save configuration and overrides if enabled
        if APP_CONFIG.app.autoSaveConfig then
            appendData(APP_CONFIG, CONFIG_TYPES.CONFIG)
            appendData(APP_OVERRIDES, CONFIG_TYPES.OVERRIDES)
        end

        sleep(APP_CONFIG.app.sleepDelay)
    end
end

--- Console Loop
local function runConsole()
    while true do
        term.write("> ")
        local input = read()
        if input then
            execCommand(input)
        end
    end
end

parallel.waitForAny(main, runConsole)