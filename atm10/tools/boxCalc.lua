-- Calculates the number of solid blocks in a box of given dimensions, note: filled with air blocks
-- Also calculates the number of blocks needed to create a hollow box of given dimensions

local faceCount = 0
local faces = {}

local function calcGlassFace(width, height)
    if width < 3 or height < 3 then
        print("Face too small for glass calculation")
        return 0
    end
    return (width * height) - ((width - 2) * (height - 2))
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
    faceCount = faceCount + 1
    if solid then
        print("Adding solid face")
    else
        print("Adding hollow face")
    end
    local solidCount = solid and (width * height) or 0
    local hollowCount = not solid and 0 or calcGlassFace(width, height)
    faces[faceCount] = {solidCount = solidCount, hollowCount = hollowCount, width = width, height = height, isSolid = solid}
    print("Added face " .. faceCount .. ": " .. width .. "x" .. height)
end

local function calculateTotals()
    local totalSolid = 0
    local totalHollow = 0
    for i = 1, faceCount do
        totalSolid = totalSolid + faces[i].solidCount
        totalHollow = totalHollow + faces[i].hollowCount
    end
    return totalSolid, totalHollow
end

local function printSummary()
    local totalSolid, totalHollow = calculateTotals()
    print("Box Summary:")
    for i = 1, faceCount do
        local face = faces[i]
        local typeStr = face.isSolid and "Solid" or "Hollow"
        print(string.format("Face %d: %s %dx%d - Solid Blocks: %d, Hollow Blocks: %d", i, typeStr, face.width, face.height, face.solidCount, face.hollowCount))
    end
    print(string.format("Total Solid Blocks: %d", totalSolid))
    print(string.format("Total Hollow Blocks (for glass): %d", totalHollow))
end

-- Program console interaction loop
while true do
    print("Enter face dimensions (width height) or 'done' to finish:")
    local input = read()
    if input == "done" then
        printSummary()
        break
    end
    local width, height = input:match("^(%d+)%s+(%d+)$") -- expects two numbers, example: "3 4"
    width = tonumber(width)
    height = tonumber(height)
    if width and height then
        print("Is this face solid? (y/n):")
        local solidInput = read()
        local isSolid = (solidInput:lower() == 'y')
        addFace(width, height, isSolid)
    else
        print("Invalid input, please enter two numbers.")
    end
end