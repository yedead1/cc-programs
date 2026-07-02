-- === CONFIG ===
local TARGET_COUNT = 63
local MIN_COUNT = 3  -- trigger removal if below this
local ORE_WHITELIST = { 
    ["minecraft:raw_iron"] = true, 
    ["minecraft:raw_copper"] = true,
    ["minecraft:raw_gold"] = true,
    ["silentgear:raw_azure_silver"] = true,
    ["allthemodium:raw_allthemodium"] = true,
    ["allthemodium:raw_vibranium"] = true,
    ["allthemodium:raw_unobtainium"] = true,
    ["alltheores:raw_tin"] = true,
    ["alltheores:raw_lead"] = true,
    ["alltheores:raw_silver"] = true,
    ["alltheores:raw_nickel"] = true,
    ["alltheores:raw_aluminum"] = true,
    ["alltheores:raw_platinum"] = true
}
local FUEL_NAME = "minecraft:coal"

-- positions of blocks (example coords, replace with yours!)
local LOCS = {
    barrel = {x=772, y=86, z=-83, facing="north"},
    chamber = {x=769, y=84, z=-83, facing="north"},
    enderChest = {x=772, y=88, z=-83, facing="north"}
}

-- === POSITION TRACKING ===
local pos = {x=769, y=84, z=-82, facing="north"}  -- starting point
-- you can set this with gps.locate() if GPS is available!

local function face(dir)
    -- turn turtle until facing dir
    local dirs = {"north","east","south","west"}
    local idx = 1
    for i,v in ipairs(dirs) do if v==pos.facing then idx=i end end
    local target = 1
    for i,v in ipairs(dirs) do if v==dir then target=i end end
    local diff = (target - idx) % 4
    if diff == 1 then turtle.turnRight()
    elseif diff == 2 then turtle.turnRight(); turtle.turnRight()
    elseif diff == 3 then turtle.turnLeft() end
    pos.facing = dir
    print("Now facing", pos.facing)
end

local function forward()
    while not turtle.forward() do sleep(0.5) end
    if pos.facing=="north" then pos.z=pos.z-1
    elseif pos.facing=="south" then pos.z=pos.z+1
    elseif pos.facing=="east" then pos.x=pos.x+1
    elseif pos.facing=="west" then pos.x=pos.x-1 end
end

local function up() while not turtle.up() do sleep(0.5) end pos.y=pos.y+1 end
local function down() while not turtle.down() do sleep(0.5) end pos.y=pos.y-1 end

local function goTo(x,y,z)
    print("Going to", x,y,z)
    if pos.x==x and pos.y==y and pos.z==z then return end

    -- very simple pathing: vertical first, then X, then Z
    while pos.y < y do up() end
    while pos.y > y do down() end
    if pos.x < x then face("east"); while pos.x < x do forward() end
    elseif pos.x > x then face("west"); while pos.x > x do forward() end end
    if pos.z < z then face("south"); while pos.z < z do forward() end
    elseif pos.z > z then face("north"); while pos.z > z do forward() end end
end

local function goToLoc(loc)
    goTo(loc.x, loc.y, loc.z)
    face(loc.facing)
end

-- === CHAMBER FUNCTIONS ===
local function countChamberItems()
    goToLoc(LOCS.chamber)
    local chamber = peripheral.wrap("front")
    local input = chamber.getInputItem()
    local total = 0
    if input and input.count then total = input.count end
    print("Chamber input:", total)
    return total
end

local function topUpChamber()
    local current = countChamberItems()
    print("Current chamber count:", current)
    if current >= TARGET_COUNT then return end
    local need = TARGET_COUNT - current
    print("Need to add:", need)

    -- fetch ore from barrel
    goToLoc(LOCS.barrel)
    for i=1,16 do
        turtle.select(i)
        turtle.suck(need)
        local item = turtle.getItemDetail()
        if item and ORE_WHITELIST[item.name] then
            goToLoc(LOCS.chamber)
            turtle.drop(item.count)
            return
        elseif item then
            turtle.drop() -- dump non-ore back
        end
    end
end

local function emptySlots()
    goToLoc(LOCS.enderChest)
    for i=1,16 do
        turtle.select(i)
        turtle.drop()
    end
    -- if any left, wait and try again later
    local fullSlots = 0
    for i=1, 16 do
        if turtle.getItemCount(i) > 0 then
            print("Still have items left, will try again later")
            fullSlots = fullSlots + 1
        end
    end

    if fullSlots > 0 then
        print("Waiting 30s to try again")
        sleep(10)
        emptySlots()
    else
        print("All items deposited")
    end
end

local function removeExcessChamber()
    local current = countChamberItems()
    if current >= MIN_COUNT then return end
    print("Removing excess chamber items")

    -- pull out all items from chamber
    turtle.select(1)
    turtle.suck(current)
    -- go to the enderChest and try to deposit
    emptySlots()
end

-- === REFUEL ===
local function refuelIfNeeded()
    if turtle.getFuelLevel() < 100 then
        print("Refueling from inventory")
         -- try to refuel from inventory first
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.getItemCount(slot) > 0 then
                if turtle.refuel(0) then
                    turtle.refuel()
                    return
                end
            end
        end

        print("Low fuel, going to refuel")
        goToLoc(LOCS.enderChest)
        for i=1,16 do
            turtle.select(i)
            turtle.suck(1)
            local item = turtle.getItemDetail()
            if item and item.name == FUEL_NAME then
                turtle.refuel()
                return
            elseif item then
                turtle.drop()
            end
        end
    end
end

-- === MAIN LOOP ===
while true do
    refuelIfNeeded()
    --topUpChamber()
    removeExcessChamber()
    sleep(5)
end
