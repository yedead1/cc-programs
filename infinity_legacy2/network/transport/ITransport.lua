--------------------------------------------------
--- ITransport.lua
--- This interface defines the methods that a transport layer must implement for sending and receiving data.
--------------------------------------------------

--- Imports
local EventEmitter = require("eventEmitter")

--------------------------------------------------
--- ITransport Interface
--- @class ITransport
--- @field _localEndpoint string The local endpoint of the transport
--- @field _remoteEndpoint string The remote endpoint of the transport
--- @field _state number The current state of the transport
--- @field _clock function A function that returns the current time
--- @field _events EventEmitter An instance of EventEmitter for handling events
--------------------------------------------------
local ITransport = {}
ITransport.__index = ITransport

--- Transport state enumeration
ITransport.STATE = {
    CLOSED = 0,
    OPEN = 1
}

---------------------------------------------------
--- Constructor
--- @param data table A table containing the local and/or remote endpoints
--- @param data.localEndpoint string The local endpoint (optional)
--- @param data.remoteEndpoint string The remote endpoint (optional)
--- @param data.clock function A function that returns the current time (required)
--- @return ITransport
---------------------------------------------------
function ITransport.new(data)
    data = data or {}

    local localEndpoint = data.localEndpoint
    local remoteEndpoint = data.remoteEndpoint
    local clock = data.clock
    assert(type(clock) == "function", "Clock function must be provided")

    return setmetatable({
        _localEndpoint = type(localEndpoint) == "string" and #localEndpoint > 0 and localEndpoint or nil,
        _remoteEndpoint = type(remoteEndpoint) == "string" and #remoteEndpoint > 0 and remoteEndpoint or nil,
        _state = ITransport.STATE.CLOSED,
        _clock = clock,
        ---@type EventEmitter
        _events = EventEmitter.new(),
        _isIdle = true  --- Indicates whether the transport is idle (no ongoing transmissions)
    }, ITransport)
end

---------------------------------------------------
--- Meta Methods
---------------------------------------------------

--- Returns a string representation of the ITransport for debugging purposes
--- @return string
function ITransport:__tostring()
    error("ITransport:__tostring() method not implemented")
end

---------------------------------------------------
--- Private Methods
---------------------------------------------------

--- Emits an event with the given arguments.
--- @param event string The event to emit.
--- @param ... any The arguments to pass to the event listeners.
function ITransport:_emit(event, ...)
    self._events:emit(event, ...)
end

--- Updates the idle state of the transport and emits the corresponding event.
--- @param value boolean The new idle state (true for idle, false for busy).
function ITransport:_updateIdleState(value)
    assert(type(value) == "boolean", "Idle state must be a boolean")
    if self._isIdle == value then
        return
    end

    self._isIdle = value
    if value then
        self:_emit("transportReady")
    else
        self:_emit("transportBusy")
    end
end

---------------------------------------------------
--- Getters
---------------------------------------------------

--- Returns whether the transport is idle (no ongoing transmissions)
--- @return boolean
function ITransport:isIdle()
    return self._isIdle
end

--- Gets the local endpoint of the transport
--- @return string
function ITransport:getLocalEndpoint()
    return self._localEndpoint
end

--- Gets the remote endpoint of the transport
--- @return string
function ITransport:getRemoteEndpoint()
    return self._remoteEndpoint
end

--- Gets the current state of the transport
--- @return number
function ITransport:getState()
    return self._state
end

---------------------------------------------------
--- Setters
---------------------------------------------------

--- Sets the local endpoint of the transport and returns the transport instance for chaining
--- @param endpoint string The local endpoint
--- @return ITransport
function ITransport:setLocalEndpoint(endpoint)
    assert(type(endpoint) == "string", "Local endpoint must be a string")
    self._localEndpoint = endpoint
    return self
end

--- Sets the remote endpoint of the transport and returns the transport instance for chaining
--- @param endpoint string The remote endpoint
--- @return ITransport
function ITransport:setRemoteEndpoint(endpoint)
    assert(type(endpoint) == "string", "Remote endpoint must be a string")
    self._remoteEndpoint = endpoint
    return self
end

---------------------------------------------------
--- State Checks
---------------------------------------------------

--- Checks if the transport is open
--- @return boolean
function ITransport:isOpen()
    return self._state == ITransport.STATE.OPEN
end

--- Checks if the transport is closed
--- @return boolean
function ITransport:isClosed()
    return self._state == ITransport.STATE.CLOSED
end

---------------------------------------------------
--- Methods
---------------------------------------------------

--- Opens the transport and returns the transport instance for chaining
--- @return ITransport
function ITransport:open()
    self._state = ITransport.STATE.OPEN
    self:_emit("transportOpened")
    return self
end

--- Closes the transport and returns the transport instance for chaining
--- @return ITransport
function ITransport:close()
    self._state = ITransport.STATE.CLOSED
    self:_emit("transportClosed")
    return self
end

--- Gets the clock function associated with the transport
--- @return function
function ITransport:getClock()
    return self._clock
end

--- Gets the current time from the transport's clock function
--- @return number
function ITransport:getCurrentTime()
    return self:getClock()()
end

--------------------------------------------------
-- Events
--------------------------------------------------

--- Listens for an event with the given name and callback function, and returns the transport instance for chaining
--- @param event string The name of the event to listen for
--- @param callback function The callback function to invoke for the event
--- @return ITransport
function ITransport:on(event, callback)
    self._events:on(event, callback)
    return self
end

--------------------------------------------------
-- Abstract Methods
--------------------------------------------------

--- Writes data to the hardware
--- @param data any The data to write
function ITransport:write(data)
    assert(self:isOpen(), "Transport is not open")
    error("write method not implemented")

    self:_emit("transportDataSent", data)
end

--- Reads data from the hardware
--- @return any
function ITransport:read()
    assert(self:isOpen(), "Transport is not open")
    error("read method not implemented")

    self:_emit("transportDataReceived")
end

--- Update
function ITransport:update()
    local now = self:getCurrentTime()

    --- Implementation-specific update logic goes here

    self:_emit("transportUpdate", now)
end

return ITransport