--------------------------------------------------
--- byteBuffer.lua
--- A simple byte buffer implementation for reading and writing binary data.
--- @class ByteBuffer
--- @field data table The underlying byte array
--- @field position number The current read/write position in the buffer
--- @field endian string The endianness of the buffer (ByteBuffer.BIG_ENDIAN or ByteBuffer.LITTLE_ENDIAN)
--------------------------------------------------
local ByteBuffer = {}
ByteBuffer.__index = ByteBuffer
ByteBuffer.VERSION = 1

--- Endianness Constants
ByteBuffer.BIG_ENDIAN = "big"
ByteBuffer.LITTLE_ENDIAN = "little"

--- Constructor
--- @param bytes? table A table of bytes to initialize the buffer with (optional)
--- @param options? table A table of options (optional)
--- @return ByteBuffer
function ByteBuffer.new(bytes, options)
    bytes = bytes or {}
    options = options or {}

    assert(
        options.endian == nil or
        options.endian == ByteBuffer.BIG_ENDIAN or
        options.endian == ByteBuffer.LITTLE_ENDIAN,
        "Invalid endian option. Must be 'big' or 'little'."
    )
    return setmetatable(
        {
            data = bytes,
            position = 1,
            endian = options.endian or ByteBuffer.BIG_ENDIAN
        }, ByteBuffer)
end

---------------------------------------------------
--- Meta Methods
---------------------------------------------------

--- Returns a string representation of the ByteBuffer for debugging purposes
--- @return string
function ByteBuffer:__tostring()
    return string.format("ByteBuffer(size=%d, position=%d, endian=%s)", #self.data, self.position, self.endian)
end

---------------------------------------------------
--- Private Methods
---------------------------------------------------

--- Appends a byte to the buffer
--- @param value number The byte value to append (0-255)
--- @return nil
function ByteBuffer:_append(value)
    assert(type(value) == "number", "Value must be a number")

    self.data[#self.data + 1] = bit32.band(value, 0xFF)
end

---------------------------------------------------
--- Internal Methods
---------------------------------------------------

--- Checks if a read operation can be performed without exceeding the buffer size
--- @param self ByteBuffer The ByteBuffer instance
--- @param count number The number of bytes to read
--- @return nil
--- @error if the read operation exceeds the buffer size
local function checkRead(self, count)
    if self.position + count - 1 > #self.data then
        error("ByteBuffer: Attempt to read beyond the end of the buffer")
    end
end

---------------------------------------------------
--- Utility/Helper Methods
---------------------------------------------------

--- Resets the position to the beginning of the buffer
--- @return nil
function ByteBuffer:resetPosition()
    self.position = 1
end

--- Clears the buffer and resets the position
--- @return nil
function ByteBuffer:clear()
    self.data = {}
    self:resetPosition()
end

--- Returns the size of the buffer
--- @return number
function ByteBuffer:size()
    return #self.data
end

--- Returns the number of remaining bytes in the buffer
--- @return number
function ByteBuffer:getRemainingBytes()
    return #self.data - self.position + 1
end

--- Sets the position in the buffer
---@param position number The new position in the buffer
---@return nil
function ByteBuffer:seek(position)
    assert(type(position) == "number", "Position must be a number")
    assert(position >= 1, "Position must be greater than or equal to 1")
    assert(position <= #self.data + 1, "Position must be less than or equal to the buffer size")

    self.position = position
end

--- Returns the current position in the buffer
--- @return number
function ByteBuffer:getCurrentPosition()
    return self.position
end

--- Advances the position in the buffer by a specified number of bytes
--- @param count number The number of bytes to skip (default is 1)
--- @return nil
function ByteBuffer:skip(count)
    count = count or 1

    assert(type(count) == "number", "Count must be a number")
    checkRead(self, count)
    self:seek(self.position + count)
end

--- Rewinds the buffer to the beginning and returns the ByteBuffer instance for method chaining
--- @return ByteBuffer
function ByteBuffer:rewind()
    self:resetPosition()
    return self
end

--- Checks if the end of the buffer has been reached
--- @return boolean
function ByteBuffer:eof()
    return self.position > #self.data
end

--- Clones the current ByteBuffer instance
--- @return ByteBuffer
function ByteBuffer:clone()
    local copy = {};
    for i = 1, #self.data do
        copy[i] = self.data[i]
    end

    ---@class ByteBuffer
    local newBuffer = ByteBuffer.new(copy, { endian = self.endian })
    newBuffer.position = self.position
    return newBuffer
end

--- Checks if the buffer is empty
--- @return boolean
function ByteBuffer:isEmpty()
    return #self.data == 0
end

--- Returns a copy of the underlying byte array
--- @return table
function ByteBuffer:toTable()
    return self:clone().data
end

--------------------------------------------------
--- Write Methods
--------------------------------------------------
--- Unsigned Integer Methods
--------------------------------------------------

--- Writes a UInt8 to the buffer and returns the ByteBuffer instance for method chaining
--- @param value number The UInt8 value to write
--- @return ByteBuffer
function ByteBuffer:writeUInt8(value)
    assert(type(value) == "number", "Value must be a number")
    assert(value >= 0 and value <= 0xFF, "Value must be between 0 and 255")
    self:_append(value)

    return self
end

--- Writes a UInt16 to the buffer and returns the ByteBuffer instance for method chaining
--- @param value number The UInt16 value to write
--- @return ByteBuffer
function ByteBuffer:writeUInt16(value)
    assert(type(value) == "number", "Value must be a number")
    assert(value >= 0 and value <= 0xFFFF, "Value must be between 0 and 65535")
    if self.endian == ByteBuffer.BIG_ENDIAN then
        self:_append(bit32.rshift(value, 8))
        self:_append(value)
    else
        self:_append(value)
        self:_append(bit32.rshift(value, 8))
    end

    return self
end

--- Writes a UInt32 to the buffer and returns the ByteBuffer instance for method chaining
--- @param value number The UInt32 value to write
--- @return ByteBuffer
function ByteBuffer:writeUInt32(value)
    assert(type(value) == "number", "Value must be a number")
    assert(value >= 0 and value <= 0xFFFFFFFF, "Value must be between 0 and 4294967295")
    if self.endian == ByteBuffer.BIG_ENDIAN then
        self:_append(bit32.rshift(value, 24))
        self:_append(bit32.rshift(value, 16))
        self:_append(bit32.rshift(value, 8))
        self:_append(value)
    else
        self:_append(value)
        self:_append(bit32.rshift(value, 8))
        self:_append(bit32.rshift(value, 16))
        self:_append(bit32.rshift(value, 24))
    end

    return self
end

--------------------------------------------------
--- Signed Integer Methods
--------------------------------------------------

--- Writes an Int8 to the buffer and returns the ByteBuffer instance for method chaining
--- @param value number The Int8 value to write
--- @return ByteBuffer
function ByteBuffer:writeInt8(value)
    if value < 0 then
        value = value + 0x100
    end

    self:writeUInt8(value)

    return self
end

--- Writes an Int16 to the buffer and returns the ByteBuffer instance for method chaining
--- @param value number The Int16 value to write
--- @return ByteBuffer
function ByteBuffer:writeInt16(value)
    if value < 0 then
        value = value + 0x10000
    end

    self:writeUInt16(value)

    return self
end

--- Writes an Int32 to the buffer and returns the ByteBuffer instance for method chaining
--- @param value number The Int32 value to write
--- @return ByteBuffer
function ByteBuffer:writeInt32(value)
    if value < 0 then
        value = value + 0x100000000
    end

    self:writeUInt32(value)

    return self
end

--------------------------------------------------
--- Booleans
--------------------------------------------------

--- Writes a boolean to the buffer and returns the ByteBuffer instance for method chaining
--- @param value boolean The boolean value to write
--- @return ByteBuffer
function ByteBuffer:writeBool(value)
    assert(type(value) == "boolean", "Value must be a boolean")

    self:writeUInt8(value and 1 or 0)

    return self
end

--------------------------------------------------
--- Strings
--------------------------------------------------

--- Writes a string to the buffer and returns the ByteBuffer instance for method chaining
--- @param str string The string to write
--- @return ByteBuffer
function ByteBuffer:writeString(str)
    assert(type(str) == "string", "Value must be a string")

    self:writeUInt16(#str)
    for i = 1, #str do
        self:writeUInt8(str:byte(i))
    end

    return self
end

--------------------------------------------------
--- Buffers
--------------------------------------------------

--- Writes another ByteBuffer to the current buffer and returns the ByteBuffer instance for method chaining
--- @param buffer ByteBuffer The ByteBuffer to write
--- @return ByteBuffer
function ByteBuffer:writeBuffer(buffer)
    assert(getmetatable(buffer) == ByteBuffer, "Input must be a ByteBuffer")
    return self:writeBytes(buffer:toTable())
end

--------------------------------------------------
--- Raw Bytes
--------------------------------------------------

--- Writes bytes to the buffer and returns the ByteBuffer instance for method chaining
--- @param bytes table A table of bytes to write
--- @return ByteBuffer
function ByteBuffer:writeBytes(bytes)
    assert(type(bytes) == "table", "Bytes must be a table")

    for i = 1, #bytes do
        self:_append(bytes[i])
    end

    return self
end

--------------------------------------------------
--- Read Methods
--------------------------------------------------
--- Unsigned Integer Methods
--------------------------------------------------

--- Reads in a UInt8 from the buffer
--- @return number
function ByteBuffer:readUInt8()
    checkRead(self, 1)

    local value = self.data[self.position]
    self.position = self.position + 1
    return value
end

--- Reads in a UInt16 from the buffer
--- @return number
function ByteBuffer:readUInt16()
    if self.endian == ByteBuffer.BIG_ENDIAN then
        return bit32.bor(
            bit32.lshift(self:readUInt8(), 8),
            self:readUInt8()
        )
    else
        return bit32.bor(
            self:readUInt8(),
            bit32.lshift(self:readUInt8(), 8)
        )
    end
end

--- Reads in a UInt32 from the buffer
--- @return number
function ByteBuffer:readUInt32()
    if self.endian == ByteBuffer.BIG_ENDIAN then
        return bit32.bor(
            bit32.lshift(self:readUInt8(), 24),
            bit32.lshift(self:readUInt8(), 16),
            bit32.lshift(self:readUInt8(), 8),
            self:readUInt8()
        )
    else
        return bit32.bor(
            self:readUInt8(),
            bit32.lshift(self:readUInt8(), 8),
            bit32.lshift(self:readUInt8(), 16),
            bit32.lshift(self:readUInt8(), 24)
        )
    end
end

--- Peeks at a UInt8 from the buffer without advancing the position
--- @param count number The number of bytes to peek ahead (default is 1)
--- @return number
function ByteBuffer:peekUInt8(count)
    count = count or 1
    checkRead(self, count)

    local position = count > 1 and self.position + count - 1 or self.position
    return self.data[position]
end

--- Peeks at a UInt16 from the buffer without advancing the position
--- @return number
function ByteBuffer:peekUInt16()
    if self.endian == ByteBuffer.BIG_ENDIAN then
        return bit32.bor(
            bit32.lshift(self:peekUInt8(1), 8),
            self:peekUInt8(2)
        )
    else
        return bit32.bor(
            self:peekUInt8(1),
            bit32.lshift(self:peekUInt8(2), 8)
        )
    end
end

--- Peeks at a UInt32 from the buffer without advancing the position
--- @return number
function ByteBuffer:peekUInt32()
    if self.endian == ByteBuffer.BIG_ENDIAN then
        return bit32.bor(
            bit32.lshift(self:peekUInt8(1), 24),
            bit32.lshift(self:peekUInt8(2), 16),
            bit32.lshift(self:peekUInt8(3), 8),
            self:peekUInt8(4)
        )
    else
        return bit32.bor(
            self:peekUInt8(1),
            bit32.lshift(self:peekUInt8(2), 8),
            bit32.lshift(self:peekUInt8(3), 16),
            bit32.lshift(self:peekUInt8(4), 24)
        )
    end
end

--------------------------------------------------
--- Signed Integer Methods
--------------------------------------------------

--- Returns the signed value of a UInt8
--- @return number
function ByteBuffer:readInt8()
    local value = self:readUInt8()

    if value >= 0x80 then
        value = value - 0x100
    end

    return value
end

--- Returns the signed value of a UInt16
--- @return number
function ByteBuffer:readInt16()
    local value = self:readUInt16()

    if value >= 0x8000 then
        value = value - 0x10000
    end

    return value
end

--- Returns the signed value of a UInt32
--- @return number
function ByteBuffer:readInt32()
    local value = self:readUInt32()

    if value >= 0x80000000 then
        value = value - 0x100000000
    end

    return value
end

--------------------------------------------------
--- Booleans
--------------------------------------------------

--- Reads in a boolean from the buffer
--- @return boolean
function ByteBuffer:readBool()
    return self:readUInt8() ~= 0
end

--------------------------------------------------
--- Strings
--------------------------------------------------

--- Reads in a string from the buffer
--- @return string
function ByteBuffer:readString()
    local length = self:readUInt16()
    local chars = {}
    for i = 1, length do
        chars[i] = string.char(self:readUInt8())
    end

    return table.concat(chars)
end

--------------------------------------------------
--- Raw Bytes
--------------------------------------------------

--- Reads in bytes from the buffer
---@param length number The number of bytes to read
---@return table
function ByteBuffer:readBytes(length)
    assert(type(length) == "number", "Length must be a number")
    assert(length >= 0, "Length must be non-negative")

    local bytes = {}
    for i = 1, length do
        bytes[i] = self:readUInt8()
    end

    return bytes
end

---------------------------------------------------
--- Debugging Methods
---------------------------------------------------

--- Returns a hex representation of the buffer
--- @return string
function ByteBuffer:toHex()
    local output = {}
    for i = 1, #self.data do
        output[#output + 1] = string.format("%02X", self.data[i])
    end

    return table.concat(output, " ")
end

--- Creates a ByteBuffer from a hex string
--- @param hexStr string The hex string to convert
--- @return ByteBuffer
function ByteBuffer.fromHex(hexStr)
    assert(type(hexStr) == "string", "Value must be a string")
    hexStr = hexStr:gsub("%s+", "")
    assert(#hexStr % 2 == 0, "Hex string must contain an even number of characters")

    local bytes = {}
    local index = 1
    for i = 1, #hexStr, 2 do
        local byte = tonumber(hexStr:sub(i, i + 1), 16)

        assert(byte, string.format("Invalid hex character at position %d", i))
        bytes[index] = byte
        index = index + 1
    end
    return ByteBuffer.new(bytes)
end

---@type ByteBuffer
return ByteBuffer