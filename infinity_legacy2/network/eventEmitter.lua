--------------------------------------------------
--- eventEmitter.lua
--- An event emitter implementation
--------------------------------------------------

--------------------------------------------------
--- EventEmitter Implementation
--- @class EventEmitter
--- @field _events table The table of events and their listeners
--------------------------------------------------
local EventEmitter = {}
EventEmitter.__index = EventEmitter

---------------------------------------------------
--- Constructor
--- @return EventEmitter
---------------------------------------------------
function EventEmitter.new()
    return setmetatable({
        _events = {}
    }, EventEmitter)
end

--------------------------------------------------
-- Private Methods
--------------------------------------------------

--- Converts a glob pattern to a Lua pattern
--- @param glob string The glob pattern to convert
--- @return string
function EventEmitter:_globToLua(glob)
    local out = { "^" }
    for i = 1, #glob do
        local ch = glob:sub(i, i)
        if ch == "*" then
            out[#out + 1] = ".*"
        elseif ch:match("[%^%$%(%)%%%.%[%]%+%-%?]") then
            out[#out + 1] = "%" .. ch
        else
            out[#out + 1] = ch
        end
    end
    out[#out + 1] = "$"
    return table.concat(out)
end

--- Returns true if the event matches the pattern, false otherwise
--- @param event string The event name
--- @param pattern string The pattern to match against
--- @return boolean
function EventEmitter:_eventMatches(event, pattern)
    if pattern == event then
        return true
    end

    if not pattern:find("*", 1, true) then
        return false
    end

    local luaPattern = self:_globToLua(pattern)
    return event:match(luaPattern) ~= nil
end

--- Emits to a specific listener list and returns true if any listeners were invoked, false otherwise
--- @param listeners table The list of listeners to emit to
--- @param ... any Additional arguments to pass to the listeners
--- @return boolean
function EventEmitter:_emitListenerList(listeners, ...)
    local hadAny = #listeners > 0
    for i = #listeners, 1, -1 do
        local listener = listeners[i]
        listener.callback(...)
        if listener.once then
            table.remove(listeners, i)
        end
    end
    return hadAny
end

--------------------------------------------------
-- Registration
--------------------------------------------------

--- Registers a listener for the specified event and returns the EventEmitter instance for chaining
--- @param event string The name of the event
--- @param callback function The callback function to invoke when the event is emitted
--- @return EventEmitter
function EventEmitter:on(event, callback)
    assert(type(event) == "string", "Event name must be a string")
    assert(type(callback) == "function", "Callback must be a function")

    self._events[event] = self._events[event] or {}
    table.insert(self._events[event], {
        callback = callback,
        once = false
    })

    return self
end

--- Registers a one-time listener for the specified event and returns the EventEmitter instance for chaining
--- @param event string The name of the event
--- @param callback function The callback function to invoke when the event is emitted
--- @return EventEmitter
function EventEmitter:once(event, callback)
    assert(type(event) == "string", "Event name must be a string")
    assert(type(callback) == "function", "Callback must be a function")

    self._events[event] = self._events[event] or {}
    table.insert(self._events[event], {
        callback = callback,
        once = true
    })

    return self
end

--------------------------------------------------
-- Removal
--------------------------------------------------

--- Removes a listener for the specified event and returns the EventEmitter instance for chaining
--- @param event string The name of the event
--- @param callback function The callback function to remove (optional)
--- @return EventEmitter
function EventEmitter:off(event, callback)
    assert(type(event) == "string", "Event name must be a string")

    local listeners = self._events[event]
    if not listeners then
        return self
    end

    if callback == nil then
        self._events[event] = nil
        return self
    end

    assert(type(callback) == "function", "Callback must be a function")
    for i = #listeners, 1, -1 do
        if listeners[i].callback == callback then
            table.remove(listeners, i)
        end
    end

    if #listeners == 0 then
        self._events[event] = nil
    end
    return self
end

--------------------------------------------------
-- Emitting
--------------------------------------------------

--- Emits an event, invoking all registered listeners with the provided arguments and returns true if the event had listeners, false otherwise
--- @param event string The name of the event
--- @param ... any Additional arguments to pass to the listeners
--- @return boolean 
function EventEmitter:emit(event, ...)
    assert(type(event) == "string", "Event name must be a string")

    local hadListeners = false
    for eventPattern, listeners in pairs(self._events) do
        if self:_eventMatches(event, eventPattern) then
            if self:_emitListenerList(listeners, ...) then
                hadListeners = true
            end

            if #listeners == 0 then
                self._events[eventPattern] = nil
            end
        end
    end
    return hadListeners
end

--------------------------------------------------
-- Utility
--------------------------------------------------

--- Checks if there are any listeners registered for the specified event
--- @param event string The name of the event
--- @return boolean
function EventEmitter:hasListeners(event)
    assert(type(event) == "string", "Event name must be a string")

    local listeners = self._events[event]
    return listeners ~= nil and #listeners > 0
end

--- Clears all listeners for all events and returns the EventEmitter instance for chaining
--- @return EventEmitter
function EventEmitter:clearListeners()
    self._events = {}
    return self
end

return EventEmitter