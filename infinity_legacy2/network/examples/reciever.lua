local SIDE = "left"
local BIT_TIME = 0.05

local function readBit()
    sleep(BIT_TIME)

    if redstone.getInput(SIDE) then
        return 1
    end
    return 0
end

local function readByte()
    local value = 0
    
    for i = 7, 0, -1 do
        local bit = readBit()
        if bit == 1 then
            value = bit32.bor(value, bit32.lshift(1, i))
        end
    end
    return value
end

while true do
    -- Wait for start byte
    local byte
    repeat
        byte = readByte()
    until byte == 0x02

    local length = bit32.lshift(readByte(), 8) + readByte()
    local chars = {}

    for i = 1, length do
        chars[i] = string.char(readByte())
    end

    local endByte = readByte()
    if endByte ~= 0x03 then
        print("Error: Invalid packet")
    else
        local serialized = table.concat(chars)
        local packet = textutils.unserialize(serialized)

        print("----- Packet -----")
        print(textutils.serialize(packet))
        print("------------------")
    end
end