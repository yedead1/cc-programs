--------------------------------------------------
--- redstoneTransport.lua
--- This defines a transport layer that uses redstone signals to send and receive data.
--------------------------------------------------

local ITransport = require("transport.ITransport")
local ByteBuffer = require("byteBuffer")

--------------------------------------------------
--- RedstoneTransport
--- @class RedstoneTransport : ITransport
--- @field _dataSide string The side of the computer where the data is sent/received
--- @field _clockSide string The side of the computer where the clock signal is received
--- @field _clockDelay number The delay in seconds for the clock signal
--------------------------------------------------
local RedstoneTransport = setmetatable({}, { __index = ITransport })
RedstoneTransport.__index = RedstoneTransport

RedstoneTransport.DEFAULT_OPTIONS = {
    dataSide = "right", -- The side of the computer where the data is sent/received
    clockSide = "back", -- The side of the computer where the clock signal is received
    clockDelay = 0.05, -- The delay in seconds for the clock signal
}

function RedstoneTransport.new(data)
    data = data or {}

    ---@class RedstoneTransport : ITransport
    local self = ITransport.new(data)
    setmetatable(self, RedstoneTransport)

    self._dataSide = data.dataSide or RedstoneTransport.DEFAULT_OPTIONS.dataSide
    self._clockSide = data.clockSide or RedstoneTransport.DEFAULT_OPTIONS.clockSide
    self._clockDelay = data.clockDelay or RedstoneTransport.DEFAULT_OPTIONS.clockDelay
    return self
end

function RedstoneTransport:__tostring()
    return string.format(
        "RedstoneTransport(local=%s, remote=%s, state=%d)",
        tostring(self:getLocalEndpoint()),
        tostring(self:getRemoteEndpoint()),
        self:getState()
    )
end

function RedstoneTransport:_pulseClock()
    redstone.setOutput(self._clockSide, true)
    os.sleep(self._clockDelay)
    redstone.setOutput(self._clockSide, false)
    os.sleep(self._clockDelay)
end

function RedstoneTransport:_writeBit(bit)
    redstone.setOutput(self._dataSide, bit ~= 0)
    self:_pulseClock()
end

function RedstoneTransport:_readBit()
    repeat
        os.sleep(0)
    until redstone.getInput(self._clockSide)

    local bit = redstone.getInput(self._dataSide) and 1 or 0

    repeat
        os.sleep(0)
    until not redstone.getInput(self._clockSide)

    return bit
end

function RedstoneTransport:_writeByte(byte)
    for i = 7, 0, -1 do
        self:_writeBit(bit32.extract(byte, i))
    end
end

function RedstoneTransport:_readByte()
    local byte = 0
    for i = 7, 0, -1 do
        if self:_readBit() == 1 then
            byte = bit32.bor(byte, bit32.lshift(1, i))
        end
    end
    return byte
end

function RedstoneTransport:open()
    ITransport.open(self)

    redstone.setOutput(self._dataSide, false)
    redstone.setOutput(self._clockSide, false)
    return self
end

function RedstoneTransport:close()
    redstone.setOutput(self._dataSide, false)
    redstone.setOutput(self._clockSide, false)
    return ITransport.close(self)
end

--- Writes a ByteBuffer to the transport. This method will block until the entire buffer is sent.
--- @param buffer ByteBuffer The buffer to write
function RedstoneTransport:write(buffer)
    assert(getmetatable(buffer) == ByteBuffer, "Invalid buffer provided")
    ITransport._updateIdleState(self, false) -- Mark transport as busy

    buffer = buffer:clone() -- Clone the buffer to avoid modifying the original
    buffer:rewind()

    while not buffer:eof() do
        self:_writeByte(buffer:readUInt8())
    end

    ITransport._updateIdleState(self, true) -- Mark transport as idle
    self:_emit("transportDataSent", buffer)
end

function RedstoneTransport:read()
    if not self:isOpen() then
        return nil
    end

    ITransport._updateIdleState(self, false) -- Mark transport as busy

    ---@type ByteBuffer
    local buffer = ByteBuffer.new()

    --- Read the first 9 bytes of the packet header
    for i = 1, PACKET_HEADER_SIZE do
        buffer:writeUInt8(self:_readByte())
    end
    buffer:rewind() --- Rewind the buffer to read from the beginning

    local magic = buffer:readUInt16()
    assert(magic == PACKET_MAGIC_NUMBER, "Invalid magic byte received")

    buffer:readUInt8() -- Version byte
    buffer:readUInt8() -- Flags byte
    buffer:readUInt16() -- Packet Id
    buffer:readUInt8() -- Packet Type

    local payloadLength = buffer:readUInt16()
    buffer:seek(buffer:size() + 1) -- Restore the buffer position ready for appending

    --- Read the payload bytes
    for i = 1, payloadLength do
        buffer:writeUInt8(self:_readByte())
    end

    --- Read the CRC16 bytes
    buffer:writeBytes({ self:_readByte(), self:_readByte() })

    ITransport._updateIdleState(self, true) -- Mark transport as idle
    self:_emit("transportDataReceived", buffer)
    return buffer
end

function RedstoneTransport:update()
    ITransport.update(self)
end

return RedstoneTransport