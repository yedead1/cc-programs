--------------------------------------------------
--- scheduler.lua
--- A simple scheduler implementation
--------------------------------------------------

--- Imports
local utils = require("utils")

--------------------------------------------------
---Enums
--------------------------------------------------

--- Task states
local TASK_STATE = {
    READY = 0,
    RUNNING = 1,
    PAUSED = 2,
    STOPPED = 3,
    FINISHED = 4,
    FAILED = 5
}

--------------------------------------------------
-- Task Definition (private)
--------------------------------------------------

--- Creates a new task with the given data, including the code to execute, the owner of the task, whether the task is enabled, and any arguments to pass to the task code. Returns a table representing the task.
--- @param data table A table containing the task data.
--- @param data.code function|thread The code to execute for the task.
--- @param data.owner table The owner of the task (optional).
--- @param data.enabled boolean Whether the task is enabled (optional, defaults to true).
--- @param data.args table A table of arguments to pass to the task code (optional).
--- @return table
local function createTask(data)
    data = data or {}
    assert(type(data) == "table", "Task data must be a table")
    assert(type(data.code) == "function" or type(data.code) == "thread", "Task code must be a function or a coroutine")
    if data.owner then
        assert(type(data.owner) == "table", "Task owner must be a table")
    end
    return {
        owner = data.owner,
        code = data.code,
        args = {table.unpack(data.args or {})},
        enabled = data.enabled ~= false, -- default to true if not specified
        lastError = nil,
        lastRunTime = 0,
        nextRunTime = 0,
        state = TASK_STATE.READY
    }
end

--- Checks if an object is a task by verifying that it is a table and has a 'code' field and returns true if it is a task, or false otherwise.
--- @param obj any The object to check.
--- @return boolean
local function isTask(obj)
    return type(obj) == "table" and obj.code ~= nil
end

--------------------------------------------------
--- Scheduler Implementation
--- @class Scheduler
--- @field _tasks table<string, table> A table of tasks managed by the scheduler.
--- @field _clock function The clock function used to get the current time.
--- @field _autoRemove number The auto-remove flags for the scheduler.
--- @field _nextTid number The next task ID to assign to a new task.
--------------------------------------------------
local Scheduler = {}
Scheduler.__index = Scheduler

--------------------------------------------------
--- Objects
--------------------------------------------------
--- Scheduler removal flags for automatic task removal
Scheduler.REMOVAL_FLAGS = {
    NONE = 0,
    FINISHED = bit32.lshift(1, 0),
    FAILED = bit32.lshift(1, 1),
    STOPPED = bit32.lshift(1, 2),
    ALL = bit32.bor(bit32.lshift(1, 0), bit32.lshift(1, 1), bit32.lshift(1, 2))
}

--- Scheduler default options
Scheduler.DEFAULT_OPTIONS = {
    clock = os.clock,
    autoRemove = Scheduler.REMOVAL_FLAGS.NONE
}

--------------------------------------------------
--- Constructor
--- @param data table The data to initialize the scheduler with.
--- @param data.options table The options to use for the scheduler.
--- @param data.options.clock function The clock function to use for the scheduler.
--- @param data.options.autoRemove number The auto-remove flags for the scheduler.
--- @return Scheduler
--------------------------------------------------
function Scheduler.new(data)
    data = data or {}
    local options = data.options or {}
    options = utils.deepMerge(Scheduler.DEFAULT_OPTIONS, options)

    assert(type(options.clock) == "function", "Clock must be a function")
    assert(type(options.autoRemove) == "number", "AutoRemove must be a number")

    return setmetatable({
        _tasks = {},
        _clock = options.clock,
        _autoRemove = options.autoRemove,
        _nextTid = 1
    }, Scheduler)
end

---------------------------------------------------
--- Private Methods
---------------------------------------------------

--- Checks if a task is ready to run based on its state, enabled and nextRunTime.
--- @param task table The task to check.
--- @param now number The current time.
function Scheduler:_isTaskReady(task, now)
    assert(isTask(task), "Task must be a task table")
    assert(type(now) == "number", "Current time must be a number")
    if not task.enabled then
        return false
    end

    if task.state == TASK_STATE.PAUSED
        or task.state == TASK_STATE.STOPPED
        or task.state == TASK_STATE.FINISHED
        or task.state == TASK_STATE.FAILED then
        return false
    end

    return task.nextRunTime == 0 or task.nextRunTime <= now
end

--- Executes a task and updates its state based on the result of the execution.
--- @param task table The task to execute.
--- @param now number The current time.
function Scheduler:_executeTask(task, now)
    assert(isTask(task), "Task must be a task table")
    assert(type(now) == "number", "Current time must be a number")

    task.state = TASK_STATE.RUNNING
    task.lastRunTime = now

    local success, err
    if type(task.code) == "thread" then
        success, err = coroutine.resume(task.code, table.unpack(task.args))
        if success then
            local status = coroutine.status(task.code)
            if status == "dead" then
                task.state = TASK_STATE.FINISHED
            else
                if status == "normal" then
                    task.state = TASK_STATE.PAUSED
                elseif status == "suspended" then
                    task.state = TASK_STATE.READY
                end
                return
            end
        end
    else
        success, err = pcall(task.code, table.unpack(task.args))
        if success then
            task.state = TASK_STATE.FINISHED
        end
    end

    if not success then
        task.state = TASK_STATE.FAILED
        task.lastError = err
    end
end

--- Checks if a task should be automatically removed based on its state and the scheduler's autoRemove flags, and returns true if the task should be removed, or false otherwise.
--- @param task table The task to check.
--- @return boolean
function Scheduler:_shouldAutoRemove(task)
    assert(isTask(task), "Task must be a task table")

    local flags = self._autoRemove
    if task.state == TASK_STATE.FINISHED then
        return bit32.band(flags, Scheduler.REMOVAL_FLAGS.FINISHED) ~= 0
    end

    if task.state == TASK_STATE.FAILED then
        return bit32.band(flags, Scheduler.REMOVAL_FLAGS.FAILED) ~= 0
    end

    if task.state == TASK_STATE.STOPPED then
        return bit32.band(flags, Scheduler.REMOVAL_FLAGS.STOPPED) ~= 0
    end

    return false
end

--- Finds a task by its task ID in the scheduler's task list and returns it, or nil if no matching task is found.
--- @param tid number|string The task ID of the task to find.
--- @return table|nil
function Scheduler:_findTaskById(tid)
    assert(type(tid) == "number" or type(tid) == "string", "Task ID must be a number or a string")
    return self._tasks[tostring(tid)]
end

--- Removes a task from the scheduler's task list by its index, and returns true if the task was successfully removed, or false if the index was invalid.
--- @param index number|string The index of the task to remove.
--- @return boolean
function Scheduler:_removeTask(index)
    assert(type(index) == "number" or type(index) == "string", "Index must be a number or a string")

    local task = self:_findTaskById(index)
    if not task then
        return false
    end

    self._tasks[tostring(index)] = nil
    return true
end

--------------------------------------------------
--- Public Methods
--------------------------------------------------
--- Creates a new task with the given code, owner, enabled state, and arguments, adds it to the scheduler's task list, and returns the task ID.
--- @param code function|thread The code to execute for the task.
--- @param owner table The owner of the task (optional).
--- @param enabled boolean Whether the task is enabled (optional, defaults to true).
--- @param ... any The arguments to pass to the task code (optional).
--- @return number
function Scheduler:newTask(code, owner, enabled, ...)
    assert(type(code) == "function" or type(code) == "thread", "Task code must be a function or a coroutine")
    assert(owner == nil or type(owner) == "table", "Task owner must be a table or nil")
    assert(enabled == nil or type(enabled) == "boolean", "Task enabled must be a boolean or nil")
    local task = createTask({
        code = code,
        owner = owner,
        enabled = enabled ~= false,
        args = {...}
    })
    
    local tid = self._nextTid
    self._tasks[tostring(tid)] = task
    self._nextTid = tid + 1
    return tid
end

--- Removes a task from the scheduler's task list by its task ID, and returns true if the task was successfully removed, or false if the task ID was invalid.
--- @param tid number The task ID of the task to remove.
--- @return boolean
function Scheduler:removeTask(tid)
    assert(type(tid) == "number", "Task ID must be a number or a string")
    return self:_removeTask(tid)
end

--- Enables a task by its task ID, and returns true if the task was successfully enabled, or false if the task ID was invalid.
--- @param tid number The task ID of the task to enable.
--- @return boolean
function Scheduler:enableTask(tid)
    local task = self:_findTaskById(tid)
    if not task then
        return false
    end

    task.enabled = true
    return true
end

--- Disables a task by its task ID, and returns true if the task was successfully disabled, or false if the task ID was invalid.
--- @param tid number The task ID of the task to disable.
--- @return boolean
function Scheduler:disableTask(tid)
    local task = self:_findTaskById(tid)
    if not task then
        return false
    end

    task.enabled = false
    return true
end

--- Pauses a task by its task ID, and returns true if the task was successfully paused, or false if the task ID was invalid.
--- @param tid number The task ID of the task to pause.
--- @return boolean
function Scheduler:pauseTask(tid)
    local task = self:_findTaskById(tid)
    if not task then
        return false
    end

    task.state = TASK_STATE.PAUSED
    return true
end

--- Resumes a task by its task ID, and returns true if the task was successfully resumed, or false if the task ID was invalid.
--- @param tid number The task ID of the task to resume.
--- @return boolean
function Scheduler:resumeTask(tid)
    local task = self:_findTaskById(tid)
    if not task then
        return false
    end

    if task.state == TASK_STATE.PAUSED then
        task.state = TASK_STATE.READY
    end
    return true
end

--- Stops a task by its task ID, and returns true if the task was successfully stopped, or false if the task ID was invalid.
--- @param tid number The task ID of the task to stop.
--- @return boolean
function Scheduler:stopTask(tid)
    local task = self:_findTaskById(tid)
    if not task then
        return false
    end

    task.state = TASK_STATE.STOPPED
    return true
end

--- Removes all tasks owned by the specified owner, and returns the number of tasks that were removed.
--- @param owner table The owner of the tasks to remove.
--- @return number
function Scheduler:removeTasksByOwner(owner)
    assert(type(owner) == "table", "Task owner must be a table")
    local removedCount = 0
    for tid, task in pairs(self._tasks) do
        if task.owner == owner then
            self:_removeTask(tid)
            removedCount = removedCount + 1
        end
    end
    return removedCount
end

--- Clears all tasks from the scheduler's task list, effectively resetting the scheduler.
function Scheduler:clear()
    self._tasks = {}
    self._nextTid = 1
end

--- Updates the scheduler, executing any tasks that are ready to run.
--- @return number The number of tasks that were executed.
function Scheduler:update()
    local now = self._clock()
    local executedTasks = 0
    for tid, task in pairs(self._tasks) do
        if self:_isTaskReady(task, now) then
            self:_executeTask(task, now)
            executedTasks = executedTasks + 1

            if self:_shouldAutoRemove(task) then
                self:_removeTask(tid)
            end
        end
    end
    return executedTasks
end

--- Gets the total number of tasks currently managed by the scheduler.
--- @return number
function Scheduler:getTaskCount()
    local count = 0
    for _ in pairs(self._tasks) do
        count = count + 1
    end
    return count
end

--- Gets the number of enabled tasks currently managed by the scheduler.
--- @return number
function Scheduler:getEnabledTaskCount()
    local count = 0
    for _, task in pairs(self._tasks) do
        if task.enabled then
            count = count + 1
        end
    end
    return count
end

--- Gets the number of tasks that are ready to run, based on their state and nextRunTime.
--- @return number
function Scheduler:getScheduledTaskCount()
    local count = 0
    local now = self._clock()
    for _, task in pairs(self._tasks) do
        if self:_isTaskReady(task, now) then
            count = count + 1
        end
    end
    return count
end

return Scheduler