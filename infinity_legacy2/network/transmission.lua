--------------------------------------------------
--- transmission.lua
--- A simple transmission implementation
--------------------------------------------------

--- Imports
local Packet = require("packet")

--------------------------------------------------
--- Transmission Implementation
--- @class Transmission
--- @field _packet Packet The packet to be transmitted
--- @field _timeout number The timeout in seconds
--- @field _maxRetries number The maximum number of retries
--- @field _retryCount number The current retry count
--- @field _lastTransmit number The last transmit time in seconds
--- @field _acknowledged boolean Whether the transmission has been acknowledged
--------------------------------------------------
local Transmission = {}
Transmission.__index = Transmission
Transmission.DEFAULT_TIMEOUT = 2 --- Default timeout in seconds
Transmission.DEFAULT_MAX_RETRIES = 3 --- Default maximum number of retries

---------------------------------------------------
--- Enums
---------------------------------------------------

--- Transmission states
Transmission.STATE = {
    QUEUED = 0,
    ACTIVE = 1,
    WAITING = 2,
    COMPLETE = 3,
    FAILED = 4,
    CANCELLED = 5
}

--- Failure reasons
Transmission.FAILURE_REASON = {
    NONE = 0,
    TIMEOUT = 1,
    MAX_RETRIES_EXCEEDED = 2,
    CRC_ERROR = 3,
    CONNECTION_ERROR = 4,
    CANCELLED = 5
}

--- Transmission directions
Transmission.DIRECTION = {
    OUTGOING = 0,
    INCOMING = 1
}

---------------------------------------------------
--- Arrays
---------------------------------------------------

--- State names for debugging
Transmission.STATE_NAMES = {
    [Transmission.STATE.QUEUED] = "QUEUED",
    [Transmission.STATE.ACTIVE] = "ACTIVE",
    [Transmission.STATE.WAITING] = "WAITING",
    [Transmission.STATE.COMPLETE] = "COMPLETE",
    [Transmission.STATE.FAILED] = "FAILED",
    [Transmission.STATE.CANCELLED] = "CANCELLED"
}

--- Failure reason names for debugging
Transmission.FAILURE_REASON_NAMES = {
    [Transmission.FAILURE_REASON.NONE] = "NONE",
    [Transmission.FAILURE_REASON.TIMEOUT] = "TIMEOUT",
    [Transmission.FAILURE_REASON.MAX_RETRIES_EXCEEDED] = "MAX_RETRIES_EXCEEDED",
    [Transmission.FAILURE_REASON.CRC_ERROR] = "CRC_ERROR",
    [Transmission.FAILURE_REASON.CONNECTION_ERROR] = "CONNECTION_ERROR",
    [Transmission.FAILURE_REASON.CANCELLED] = "CANCELLED"
}

--- Failure reason strings for user-friendly messages
Transmission.DEFAULT_FAILURE_REASON_STRINGS = {
    [Transmission.FAILURE_REASON.NONE] = "No failure",
    [Transmission.FAILURE_REASON.TIMEOUT] = "Transmission timed out",
    [Transmission.FAILURE_REASON.MAX_RETRIES_EXCEEDED] = "Maximum retries exceeded",
    [Transmission.FAILURE_REASON.CRC_ERROR] = "CRC error detected",
    [Transmission.FAILURE_REASON.CONNECTION_ERROR] = "Connection error occurred",
    [Transmission.FAILURE_REASON.CANCELLED] = "Transmission was cancelled"
}

--- Used to override the default failure reason strings with custom messages
Transmission.FAILURE_REASON_STRINGS = Transmission.DEFAULT_FAILURE_REASON_STRINGS

---------------------------------------------------
--- Constructor
--- @param data table A table containing the packet, timeout, and maxRetries
--- @param data.packet Packet The packet to be transmitted
--- @param data.direction number The direction of the transmission (0 for outgoing, 1 for incoming)
--- @param data.timeout number The timeout in seconds (optional, default is 2)
--- @param data.maxRetries number The maximum number of retries (optional, default is 3)
--- @return Transmission
---------------------------------------------------
function Transmission.new(data)
    data = data or {}

    ---@type Packet
    local packet = data.packet
    local direction = data.direction
    local timeout = data.timeout or Transmission.DEFAULT_TIMEOUT
    local maxRetries = data.maxRetries or Transmission.DEFAULT_MAX_RETRIES
    assert(getmetatable(packet) == Packet, "Packet must be a Packet instance")
    assert(type(direction) == "number" and Transmission.DIRECTION[direction] ~= nil, "Direction must be a valid Transmission.DIRECTION value")
    assert(type(timeout) == "number" and timeout > 0, "Timeout must be a positive number")
    assert(type(maxRetries) == "number" and maxRetries >= 0, "Max retries must be a non-negative number")

    return setmetatable({
        _packet = packet,
        _direction = direction,
        _timeout = timeout,
        _maxRetries = maxRetries,
        _retryCount = 0,
        _lastTransmit = nil,
        _state = Transmission.STATE.QUEUED,
        _failureReason = Transmission.FAILURE_REASON.NONE
    }, Transmission)
end

---------------------------------------------------
--- Meta Methods
---------------------------------------------------

--- Returns a string representation of the Transmission for debugging purposes
--- @return string
function Transmission:__tostring()
    return string.format("Transmission(packet=%s, direction=%d, timeout=%d, maxRetries=%d, retryCount=%d, lastTransmit=%s, state=%d, failureReason=%d)",
        tostring(self._packet), self._direction, self._timeout, self._maxRetries, self._retryCount, tostring(self._lastTransmit), self._state, self._failureReason)
end

---------------------------------------------------
--- Getters
---------------------------------------------------

--- Gets the packet associated with this transmission
--- @return Packet
function Transmission:getPacket()
    return self._packet
end

--- Gets the direction of this transmission
--- @return number
function Transmission:getDirection()
    return self._direction
end

--- Gets the timeout for this transmission
--- @return number
function Transmission:getTimeout()
    return self._timeout
end

--- Gets the retry count for this transmission
--- @return number
function Transmission:getRetryCount()
    return self._retryCount
end

--- Gets the maximum number of retries for this transmission
--- @return number
function Transmission:getMaxRetries()
    return self._maxRetries
end

--- Gets the last transmit time for this transmission
--- @return number
function Transmission:getLastTransmit()
    return self._lastTransmit
end

--- Gets the current state of this transmission
--- @return number
function Transmission:getState()
    return self._state
end

--- Gets the name of the current state of this transmission
--- @return string
function Transmission:getStateName()
    return Transmission.STATE_NAMES[self._state] or "Unknown"
end

--- Gets the failure reason for this transmission
--- @return number
function Transmission:getFailureReason()
    return self._failureReason
end

--- Gets the name of the failure reason for this transmission
--- @return string
function Transmission:getFailureReasonName()
    return Transmission.FAILURE_REASON_NAMES[self._failureReason] or "Unknown"
end

--- Gets the user-friendly message for the failure reason of this transmission
--- @return string
function Transmission:getFailureReasonMessage()
    return Transmission.FAILURE_REASON_STRINGS[self._failureReason] or "Unknown"
end

---------------------------------------------------
--- Setters
---------------------------------------------------

--- Sets the timeout for this transmission and returns the transmission instance for chaining
--- @param value number The timeout in seconds
--- @return Transmission
function Transmission:setTimeout(value)
    assert(type(value) == "number" and value > 0, "Timeout must be a positive number")
    self._timeout = value
    return self
end

--- Sets the maximum number of retries for this transmission and returns the transmission instance for chaining
--- @param value number The maximum number of retries
--- @return Transmission
function Transmission:setMaxRetries(value)
    assert(type(value) == "number" and value >= 0, "Max retries must be a non-negative number")
    self._maxRetries = value
    return self
end

--- Sets the state of this transmission and optionally sets the failure reason if provided and returns the transmission instance for chaining
--- @param state number The new state of the transmission
--- @param reason number|nil The failure reason if the state is FAILED (optional)
--- @return Transmission
function Transmission:setState(state, reason)
    assert(self._state ~= Transmission.STATE.FAILED and self._state ~= Transmission.STATE.CANCELLED, "Transmission has already completed.")
    assert(type(state) == "number" and Transmission.STATE[state], "Invalid state")
    self._state = state
    if reason then
        assert(type(reason) == "number" and Transmission.FAILURE_REASON[reason], "Invalid failure reason")
        self._failureReason = reason
    else
        self._failureReason = Transmission.FAILURE_REASON.NONE
    end

    return self
end

---------------------------------------------------
--- State Checks
---------------------------------------------------

--- Checks if the transmission can be retried based on the current retry count and maximum retries
--- @return boolean
function Transmission:canRetry()
    return self._retryCount < self._maxRetries
end

--- Checks if the transmission has timed out based on the last transmit time and timeout value
--- @param now number The current time
--- @return boolean
function Transmission:hasTimedOut(now)
    assert(type(now) == "number" and now >= 0, "Current time must be a non-negative number")
    return self._lastTransmit ~= nil and (now - self._lastTransmit) >= self._timeout
end

--- Checks if the transmission has expired, meaning it has either failed or been cancelled
--- @return boolean
function Transmission:hasExpired()
    return self._state == Transmission.STATE.FAILED or self._state == Transmission.STATE.CANCELLED
end

---------------------------------------------------
--- Methods
---------------------------------------------------

--- Increments the retry count for this transmission and returns the transmission instance for chaining
--- @return Transmission
function Transmission:incrementRetryCount()
    self._retryCount = self._retryCount + 1
    return self
end

--- Resets the retry count for this transmission to zero
function Transmission:resetRetryCount()
    self._retryCount = 0
end

--- Marks the transmission as transmitted by updating the last transmit time to the current time and returns the transmission instance for chaining
--- @param now number The current time
--- @return Transmission
function Transmission:markTransmitted(now)
    assert(type(now) == "number" and now >= 0, "Time must be a non-negative number")
    self._lastTransmit = now
    return self
end

--------------------------------------------------
-- Utility
--------------------------------------------------

--- Resets the transmission state, including retry count, last transmit time, and acknowledged state
function Transmission:reset()
    self:resetRetryCount()
    self._lastTransmit = nil
    self:setState(Transmission.STATE.QUEUED, Transmission.FAILURE_REASON.NONE)
end

--- Overrides the failure message for a specific failure reason with a custom message
--- @param reasonNum number The failure reason number to override
--- @param message string The custom failure message
function Transmission.overrideFailureMessage(reasonNum, message)
    assert(type(reasonNum) == "number" and Transmission.FAILURE_REASON[reasonNum], "Invalid failure reason")
    assert(type(message) == "string", "Failure message must be a string")
    Transmission.FAILURE_REASON_STRINGS[reasonNum] = message
end

return Transmission