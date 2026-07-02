-- Calculates the number of solid blocks in a box of given dimensions, note: filled with air blocks
-- Also calculates the number of blocks needed to create a hollow box of given dimensions

local faceCount = 0
local faces = {}

local function calcGlassFace(width, height)
    if width < 3 or height < 3 then
        print("Face too small for glass calculation")
        return 0
    end
    local totalCount = width * height
    local glassCount = (width - 2) * (height - 2)
    local borderCount = totalCount - glassCount
    print(string.format("Calculated glass face: Total %d, Glass %d, Border %d", totalCount, glassCount, borderCount))
    return {borderCount = borderCount, glassCount = glassCount}
end

local function addFace(width, height, solid)
    solid = (solid == nil) and true or solid
    if width < 1 or height < 1 then
        print("Invalid face dimensions")
        return
    elseif faceCount > 6 then
        print("Too many faces added")
        return
    end

    local solidCount = solid and (width * height) or 0
    local glassFace = not solid and calcGlassFace(width, height) or {borderCount = 0, glassCount = 0}
    local glassCount = glassFace.glassCount
    local borderCount = glassFace.borderCount
    faceCount = faceCount + 1
    faces[faceCount] = {solidFace = solidCount, glassFace = {glassCount = glassCount, borderCount = borderCount}, width = width, height = height, isSolid = solid}

    if solid then
        print(string.format("Added solid face: %dx%d, Area: %d", width, height, solidCount))
    else
        print(string.format("Added glass face: %dx%d, Border: %d, Glass: %d", width, height, borderCount, glassCount))
    end
end

local function calculateTotals()
    local totalSolid = 0
    local totalGlass = 0
    for i = 1, faceCount do
        totalSolid = totalSolid + faces[i].solidFace + faces[i].glassFace.borderCount   -- border blocks count as solid blocks
        totalGlass = totalGlass + faces[i].glassFace.glassCount
    end
    return totalSolid, totalGlass
end

local function printSummary()
    local totalSolid, totalGlass = calculateTotals()
    print("Box Summary:")
    for i = 1, faceCount do
        local face = faces[i]
        local typeStr = face.isSolid and "Solid" or "Glass"
        local faceName = (i == 1 and "Front") or (i == 2 and "Back") or (i == 3 and "Top") or (i == 4 and "Bottom") or (i == 5 and "Left") or (i == 6 and "Right")
        if face.isSolid then
            print(string.format("%s: %s %dx%d, Area: %d", faceName, typeStr, face.width, face.height, face.solidFace))
        else
            print(string.format("%s: %s %dx%d, Border: %d, Glass: %d", faceName, typeStr, face.width, face.height, face.glassFace.borderCount, face.glassFace.glassCount))
        end
    end
    print(string.format("Total Solid Blocks needed: %d", totalSolid))
    print(string.format("Total Glass Blocks needed: %d", totalGlass))
end

-- Program console interaction loop
while true do
    print("Enter box dimensions (width height depth) or 'done' to finish:")
    local input = read()
    if input == "done" then
        printSummary()
        break
    end
    local width, height, depth = input:match("^(%d+)[,%sxX]+(%d+)[,%sxX]+(%d+)$") -- accept space, comma, x as separators
    width = tonumber(width)
    height = tonumber(height)
    depth = tonumber(depth)
    if width and height and depth then
        local faceDims = {
            {width, height},  -- front
            {width, height},  -- back
            {width, depth},   -- top
            {width, depth},   -- bottom
            {height, depth},  -- left
            {height, depth}   -- right
        }
        for i, dims in ipairs(faceDims) do
            local w, h = dims[1], dims[2]
            local faceName = (i == 1 and "Front") or (i == 2 and "Back") or (i == 3 and "Top") or (i == 4 and "Bottom") or (i == 5 and "Left") or (i == 6 and "Right")
            print(string.format("Is face %s (%dx%d) solid? (y/n)", faceName, w, h))
            local solidInput = read()
            local isSolid = (solidInput:lower() == 'y')
            addFace(w, h, isSolid)
        end
        printSummary()
    else
        print("Invalid input, please enter three numbers.")
    end
end