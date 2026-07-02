local Transport = {}

-- Configuration
Transport.DATA = "right" -- The side to send data on
Transport.CLOCK = "left" -- The side to read clock signal from

-- Delay between transactions (in seconds)
Transport.CLOCK_DELAY = 0.05

--------------------------------------------------
-- Clock
--------------------------------------------------
function Transport.clock()
    redstone.setOutput(Transport.CLOCK, true)
    sleep(Transport.CLOCK_DELAY)
    redstone.setOutput(Transport.CLOCK, false)
    sleep(Transport.CLOCK_DELAY)
end

--------------------------------------------------
-- Write Bit
--------------------------------------------------
function Transport.writeBit(bit)
    redstone.setOutput(Transport.DATA, bit == 1)
    Transport.clock()
end

--------------------------------------------------
-- Read Bit
--------------------------------------------------
function Transport.readBit()
    repeat
        sleep(0)
    until redstone.getInput(Transport.CLOCK)

    local bit = redstone.getInput(Transport.DATA) and 1 or 0

    repeat
        sleep(0)
    until not redstone.getInput(Transport.CLOCK)

    return bit
end

--------------------------------------------------
-- Write Byte
--------------------------------------------------
function Transport.writeByte(byte)
    for i = 7, 0, -1 do
        local bit = bit32.extract(byte, i, 1)
        Transport.writeBit(bit)
    end
end

--------------------------------------------------
-- Read Byte
--------------------------------------------------
function Transport.readByte()
    local value = 0

    for i = 7, 0, -1 do
        local bit = Transport.readBit()
        if bit == 1 then
            value = bit32.bor(value, bit32.lshift(1, i))
        end
    end

    return value
end

return Transport