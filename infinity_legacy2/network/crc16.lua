--------------------------------------------------
--- crc16.lua
--- A simple CRC16 implementation
--------------------------------------------------

--- Imports
local ByteBuffer = require("network.byteBuffer")

--------------------------------------------------
--- CRC16 Implementation
--- @class CRC16
--- @field POLYNOMIAL number The polynomial used for CRC16 calculation
--- @field INITIAL_VALUE number The initial value for CRC16 calculation
--------------------------------------------------
local CRC16 = {}
CRC16.POLYNOMIAL = 0x1021 --- The polynomial used for CRC16 calculation
CRC16.INITIAL_VALUE = 0xFFFF --- The initial value for CRC16 calculation

--- Calculates the CRC16 of a given ByteBuffer or table of bytes and returns the CRC16 value
--- @param data ByteBuffer|table A ByteBuffer or table to calculate the CRC16 for
--- @return number
function CRC16.calculate(data)
    assert(getmetatable(data) == ByteBuffer or type(data) == "table", "Input must be a ByteBuffer or a table")

    local bytes = getmetatable(data) == ByteBuffer and data:toTable() or data
    local crc = CRC16.INITIAL_VALUE
    for i = 1, #bytes do
        assert(type(bytes[i]) == "number", ("Invalid byte at index %d: expected number, got %s"):format(i, type(bytes[i])))
        assert(bytes[i] >= 0 and bytes[i] <= 0xFF, ("Invalid byte at index %d: expected uint8, got %d"):format(i, bytes[i]))

        crc = bit32.bxor(crc, bit32.lshift(bytes[i], 8))
        for j = 1, 8 do
            if bit32.band(crc, 0x8000) ~= 0 then
                crc = bit32.bxor(bit32.lshift(crc, 1), CRC16.POLYNOMIAL)
            else
                crc = bit32.lshift(crc, 1)
            end
            crc = bit32.band(crc, 0xFFFF) -- Ensure CRC remains a 16-bit value
        end
    end
    return crc
end

--- Verifies the CRC16 of a given ByteBuffer or table of bytes against an expected CRC value and returns true if they match, false otherwise
--- @param data ByteBuffer|table A ByteBuffer or table to verify the CRC16 for
--- @param expectedCRC number The expected CRC16 value to compare against
--- @return boolean
function CRC16.verify(data, expectedCRC)
    assert(type(expectedCRC) == "number", "Expected CRC must be a number")
    return CRC16.calculate(data) == expectedCRC
end

--- Appends the CRC16 of a given ByteBuffer to the buffer and returns the CRC16 value
--- @param buffer ByteBuffer The ByteBuffer to append the CRC16 to
--- @return number
function CRC16.append(buffer)
    assert(getmetatable(buffer) == ByteBuffer, "Input must be a ByteBuffer")

    local crc = CRC16.calculate(buffer)
    buffer:writeUInt16(crc)
    return crc
end

--- Validates the CRC16 of a given ByteBuffer by checking if the last two bytes match the calculated CRC16 and returns the calculated CRC16 and the expected CRC16
--- @param buffer ByteBuffer The ByteBuffer to validate the CRC16 for
--- @return number, number
function CRC16.validate(buffer)
    assert(getmetatable(buffer) == ByteBuffer, "Input must be a ByteBuffer")

    local copy = buffer:clone()
    copy:resetPosition()

    local length = copy:size()
    assert(length >= 2, "Buffer must be at least 2 bytes long to contain a CRC16")

    local bytes = copy:readBytes(length - 2)
    local expectedCRC = copy:readUInt16()
    return CRC16.calculate(bytes), expectedCRC
end

---------------------------------------------------
--- Debugging
---------------------------------------------------

--- Calculates the CRC16 of a given hex string and returns the CRC16 value
--- @param hexStr string The hex string to calculate the CRC16 for
--- @return number
function CRC16.calculateHex(hexStr)
    return CRC16.calculate(ByteBuffer.fromHex(hexStr))
end

return CRC16