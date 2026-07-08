--------------------------------------------------
--- utils.lua
--- Generic utility function implementations
--------------------------------------------------

--- Merges two tables recursively, with the source table taking precedence over the target table and returns a new table containing the merged values. 
--- This function does not modify the original tables.
--- @param target table The target table to merge into.
--- @param source table The source table to merge from.
--- @return table
local function deepMerge(target, source)
    target = target or {}
    source = source or {}
    assert(type(target) == "table", "Target must be a table")
    assert(type(source) == "table", "Source must be a table")

    local result = {}

    --- Merge the target table into the result
    for k, v in pairs(target) do
        if type(v) == "table" then
            local src = type(source[k]) == "table" and source[k] or {}
            result[k] = deepMerge(v, src)
        else
            result[k] = v
        end
    end

    --- Merge the source table into the result
    for k, v in pairs(source) do
        if result[k] == nil then
            if type(v) == "table" then
                result[k] = deepMerge({}, v)
            else
                result[k] = v
            end
        end
    end

    return result
end

return {
    deepMerge = deepMerge
}