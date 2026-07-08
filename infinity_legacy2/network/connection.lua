--------------------------------------------------
--- connection.lua
--- A simple connection implementation
--------------------------------------------------

--- Imports
local ITransport = require("network.transport.ITransport")
local Transmission = require("network.transmission")
local Packet = require("network.packet")
local EventEmitter = require("network.eventEmitter")
local utils = require("network.utils")
local Scheduler = require("network.scheduler")

--------------------------------------------------
--- Connection Implementation
--- @class Connection
--- @field private _transport ITransport The transport layer used for sending and receiving data.
--- @field private _scheduler Scheduler The scheduler used for managing tasks.
--- @field private _events EventEmitter The event emitter used for emitting events.
--- @field private _state number The current state of the connection.
--- @field private _transmissions table A list of transmissions that have been sent or received.
--- @field private _options table The options used for configuring the connection.
--------------------------------------------------
local Connection = {}
Connection.__index = Connection

---------------------------------------------------
--- Enums
---------------------------------------------------

--- Connection states
Connection.STATE = {
    DISCONNECTED = 0, 
    CONNECTING = 1,
    CONNECTED = 2,
    DISCONNECTING = 3
}

--- Default options for the connection
Connection.DEFAULT_OPTIONS = {
    debug = {
        enabled = false,
        verbose = false,
        showPayload = false,
        showCRC = false,
        showTimings = false
    },
    transmission = {
        timeout = 5000, -- use milliseconds for compatibility across different platforms
        maxRetries = 3
    },
    clock = os.clock,
    autoConnect = false
}

---------------------------------------------------
--- Constructor
--- @param data table The data to initialize the connection with.
--- @param data.transport ITransport The transport to use for the connection.
--- @param data.options table The options to use for the connection.
--- @param data.options.debug table The debug options to use for the connection.
--- @param data.options.debug.enabled boolean Whether to enable debug logging.
--- @param data.options.debug.verbose boolean Whether to enable verbose debug logging.
--- @param data.options.debug.showPayload boolean Whether to show the payload in debug logging.
--- @param data.options.debug.showCRC boolean Whether to show the CRC in debug logging.
--- @param data.options.debug.showTimings boolean Whether to show the timings in debug logging.
--- @param data.options.transmission table The transmission options to use for the connection.
--- @param data.options.transmission.timeout number The timeout for the transmission in milliseconds.
--- @param data.options.transmission.maxRetries number The maximum number of retries for the transmission.
--- @param data.options.autoConnect boolean Whether to automatically connect when a request is made (default: false).
--- @return Connection
---------------------------------------------------
function Connection.new(data)
    data = data or {}

    ---@type ITransport
    local transport = data.transport
    local options = data.options or {}
    assert(getmetatable(transport) == ITransport, "Invalid transport provided")
    assert(type(options) == "table", "Invalid options provided")
    options = utils.deepMerge(Connection.DEFAULT_OPTIONS, options) -- Make sure the user options match the default options structure

    assert(options.autoConnect == nil or type(options.autoConnect) == "boolean", "Invalid autoConnect option provided")

    return setmetatable({
        _transport = transport,
        _scheduler = Scheduler.new({ options = { clock = transport:getClock() } }),
        _events = EventEmitter.new(),
        _state = Connection.STATE.DISCONNECTED,
        _transmissions = {},
        _autoConnect = options.autoConnect == nil and false or options.autoConnect,
        _options = options
    }, Connection)
end

---------------------------------------------------
--- Meta Methods
---------------------------------------------------

function Connection:__tostring()
    if not self._options.debug.enabled then
        return "Connection"
    end

    return string.format(
        "Connection(state=%s, transmissions=%d)",
        self._state,
        #self._transmissions
    )
end

--------------------------------------------------
-- Internal Methods
--------------------------------------------------

--- Emits an event with the given arguments.
--- @param event string The event to emit.
--- @param ... any The arguments to pass to the event listeners.
function Connection:_emit(event, ...)
    self._events:emit(event, ...)
end

--- Sends a transmission over the connection.
--- @param transmission Transmission The transmission to send.
function Connection:_sendTransmission(transmission)
    assert(getmetatable(transmission) == Transmission, "Invalid transmission provided")
    transmission:setState(Transmission.STATE.ACTIVE)

    local packet = transmission:getPacket()
    local buffer = packet:encode()
    self._transport:write(buffer)
    transmission:markTransmitted(self:_getCurrentTime())
    transmission:setState(Transmission.STATE.WAITING)
    self:_emit("connectionTransmissionSent", transmission)
    self:_emit("connectionPacketSent", packet)
end

--- Receives a transmission from the transport layer and returns the Packet object or nil if no transmission was received.
--- @return Packet|nil
function Connection:_receiveTransmission()
    local buffer = self._transport:read()
    if not buffer then
        return nil
    end

    self:_emit("connectionTransmissionReceived", buffer)
    return Packet.decode(buffer)
end

--- Processes a received packet and updates the state of the connection accordingly.
--- @param packet Packet The packet to process.
function Connection:_processPacket(packet)
    assert(getmetatable(packet) == Packet, "Invalid packet provided")

    if packet:getType() == Packet.TYPE.ACK then
        local transmission = self:_findTransmissionByPacketId(packet:getId())
        if transmission then
            transmission:setState(Transmission.STATE.COMPLETE)
            self:_emit("connectionTransmissionAcknowledged", transmission)
            return
        end
    end

    local transmission = Transmission.new({ packet = packet, direction = Transmission.DIRECTION.INCOMING })
    transmission:setState(Transmission.STATE.COMPLETE)
    table.insert(self._transmissions, transmission)
    self:_emit("connectionPacketProcessed", transmission)
    self:_emit("connectionPacketReceived", packet)
end

--- Retrieves a transmission by its packet ID from the connection's list of transmissions and returns it, or nil if no matching transmission is found.
--- @param packetId number The ID of the packet to find the transmission for.
function Connection:_findTransmissionByPacketId(packetId)
    assert(type(packetId) == "number", "Invalid packet ID provided")
    for _, transmission in ipairs(self._transmissions) do
        if transmission:getPacket():getId() == packetId then
            return transmission
        end
    end

    return nil
end

--- Processes all outgoing transmissions that are in the QUEUED state and sends them over the transport layer.
function Connection:_processOutgoing()
    for _, transmission in ipairs(self._transmissions) do
        if transmission:getDirection() ~= Transmission.DIRECTION.OUTGOING then
            goto continue
        end

        local state = transmission:getState()
        if state == Transmission.STATE.QUEUED then
            self:_sendTransmission(transmission)
        end

        ::continue::
    end
end

--- Processes all incoming transmissions from the transport layer and updates the state of the connection accordingly.
function Connection:_processIncoming()
    while true do
        local packet = self:_receiveTransmission()
        if not packet then
            break
        end

        self:_processPacket(packet)
    end
end

--- Processes all transmissions that have timed out and updates their state accordingly.
--- @param now number The current timestamp.
function Connection:_processTimeouts(now)
    assert(type(now) == "number", "Invalid timestamp provided")
    for _, transmission in ipairs(self._transmissions) do
        if transmission:getState() ~= Transmission.STATE.WAITING then
            goto continue
        end

        if now - transmission:getLastTransmit() < self._options.transmission.timeout then
            goto continue
        end

        if transmission:getRetryCount() >= self._options.transmission.maxRetries then
            transmission:setState(Transmission.STATE.FAILED, Transmission.FAILURE_REASON.TIMEOUT)
            self:_emit("connectionError", "Transmission failed due to timeout after maximum retries")
            self:_emit("connectionTimeout", transmission)
            goto continue
        end

        transmission:incrementRetryCount()
        transmission:setState(Transmission.STATE.QUEUED)
        self:_emit("connectionRetry", transmission)

        ::continue::
    end
end

--- Cleans up completed, cancelled, or failed transmissions from the connection.
function Connection:_cleanup()
    for i = #self._transmissions, 1, -1 do
        ---@type Transmission
        local transmission = self._transmissions[i]
        local state = transmission:getState()
        if state == Transmission.STATE.COMPLETE or
            state == Transmission.STATE.CANCELLED or
            state == Transmission.STATE.FAILED then
            table.remove(self._transmissions, i)
        end
    end
end

--- Gets the current time from the transport's clock function.
--- @return number
function Connection:_getCurrentTime()
    return self._transport:getCurrentTime()
end

--- Creates a scheduler task that runs the connection's main loop, processing incoming and outgoing transmissions, timeouts, and cleanup.
function Connection:_createSchedulerTask()
    self._scheduler:newTask(
        coroutine.create(
            ---@param connection Connection
            function(connection)
                while connection:getState() == Connection.STATE.CONNECTED do
                    coroutine.yield()

                    local now = connection:_getCurrentTime()
                    connection:_processIncoming()
                    connection:_processOutgoing()
                    connection:_processTimeouts(now)
                    connection:_cleanup()
                end
            end),
    self, true, self)
end

--- Updates the connection by running the scheduler's update method if the connection is in the CONNECTED state, and returns the number of tasks that were run.
--- @return number
function Connection:_update()
    if self._state ~= Connection.STATE.CONNECTED then
        return 0
    end

    return self._scheduler:update()
end

---------------------------------------------------
--- Public Methods
---------------------------------------------------

--- Opens the connection by transitioning its state to CONNECTING, opening the transport layer, creating a scheduler task, and emitting a "connectionOpened" event. Returns true if the connection was successfully opened, or false and an error message if it was already open or failed to open.
--- @return boolean, string|nil
function Connection:open()
    if self._state ~= Connection.STATE.DISCONNECTED then
        self:_emit("connectionError", "Connection is already open or in the process of opening")
        return false, "Connection is already open or in the process of opening"
    end

    self._state = Connection.STATE.CONNECTING
    self._transport:on("transportUpdate", function()
        self:_update()
    end)

    local success = self._transport:open()
    if not success then
        self._state = Connection.STATE.DISCONNECTED
        self:_emit("connectionError", "Failed to open transport")
        return false, "Failed to open transport"
    end

    self:_createSchedulerTask()
    self._state = Connection.STATE.CONNECTED
    self:_emit("connectionOpened")
    return true
end

--- Closes the connection
--- Returns true if the connection was successfully closed, or false and an error message if it was already closed.
--- @return boolean, string|nil
function Connection:close()
    if self._state == Connection.STATE.DISCONNECTED then
        self:_emit("connectionError", "Connection is already closed")
        return false, "Connection is already closed"
    end

    self._state = Connection.STATE.DISCONNECTING
    self._scheduler:clear()
    self._transmissions = {}
    self._transport:close()
    self._state = Connection.STATE.DISCONNECTED
    self:_emit("connectionClosed")
    return true
end

--- Gets the current state of the connection.
--- @return number
function Connection:getState()
    return self._state
end

--- Returns true if the connection is currently connected, false otherwise.
--- @return boolean
function Connection:isConnected()
    return self:getState() == Connection.STATE.CONNECTED
end

--- Makes a request by creating a new transmission with the provided packet.
--- If autoConnect is enabled and the connection is disconnected, it will attempt to open the connection first. 
--- Returns the Connection instance for chaining, or Connection and an error message if the connection could not be opened.
--- @param packet Packet The packet to send in the request.
--- @return Connection, string|nil
function Connection:request(packet)
    assert(getmetatable(packet) == Packet, "Invalid packet provided") --- temporary will change later

    if self._options.autoConnect and self._state == Connection.STATE.DISCONNECTED then
        local success, err = self:open()
        if not success then
            self:_emit("connectionError", "Failed to open connection: " .. err)
            return self, "Failed to open connection: " .. err
        end
    end

    local transmission = Transmission.new({ packet = packet, direction = Transmission.DIRECTION.OUTGOING })
    table.insert(self._transmissions, transmission)
    self:_emit("connectionTransmissionQueued", transmission)
    return self --- Note changed from transmission to self because transmissions should never be directly accessed outside of the connection.
end

---------------------------------------------------
--- Events
---------------------------------------------------

--- Listens for an event with the given name and callback function.
--- Returns the Connection instance for chaining.
--- @param event string The name of the event to listen for.
--- @param callback function The callback function to invoke for the event.
--- @return Connection
function Connection:on(event, callback)
    self._events:on(event, callback)
    return self
end

--- Listens for an event with the given name and callback function, but only once.
--- Returns the Connection instance for chaining.
--- @param event string The name of the event to listen for.
--- @param callback function The callback function to invoke for the event.
--- @return Connection
function Connection:once(event, callback)
    self._events:once(event, callback)
    return self
end

--- Removes a listener for the given event and callback function.
--- Returns the Connection instance for chaining.
--- @param event string The name of the event.
--- @param callback function The callback function to remove.
--- @return Connection
function Connection:off(event, callback)
    self._events:off(event, callback)
    return self
end

--- Clears all listeners for all events.
--- Returns the Connection instance for chaining.
--- @return Connection
function Connection:clearListeners()
    self._events:clearListeners()
    return self
end

return Connection