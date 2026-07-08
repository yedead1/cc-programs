local SIDE = "right"
local BIT_TIME = 0.05

local function sendBit(bit)
    redstone.setOutput(SIDE, bit == 1)
    sleep(BIT_TIME)
end

local function sendByte(byte)
    -- MSB first
    for i = 7, 0, -1 do
        local bit = bit32.extract(byte, i, 1)
        sendBit(bit)
    end
end

local function sendPackect(packet)
    local serialized = textutils.serialize(packet)

    -- Start byte
    sendByte(0x02)

    -- Packet length (16-bit)
    local len = #serialized
    sendByte(bit32.rshift(len, 8)) -- High bytes
    sendByte(bit32.band(len, 0xFF)) -- Low bytes

    -- Packet bytes
    for i = 1, len do
        sendByte(serialized:byte(i))
    end
    
    -- End byte
    sendByte(0x03)

    redstone.setOutput(SIDE, false)
end

while true do
    local packet = { 
        id = math.random(100000),
        type = "ping",
        data = {
            message = "Hello, World!",
            value = math.random(1000)
        }
    }

    print("Sending packet...")
    sendPackect(packet)
    sleep(5)
end