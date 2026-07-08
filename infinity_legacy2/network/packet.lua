--------------------------------------------------
--- packet.lua
--- A simple packet implementation
--------------------------------------------------

--- Imports
local ByteBuffer = require("byteBuffer")
local CRC16 = require("crc16")
require("constants")

--------------------------------------------------
--- @class Packet
--- @field version number The version of the packet
--- @field flags number The flags of the packet
--- @field id number The ID of the packet
--- @field type number The type of the packet (e.g., PACKET_TYPES.REQUEST, PACKET_TYPES.STATUS, etc.)
--- @field crc number The CRC of the packet
--- @field _payload ByteBuffer The payload of the packet
--------------------------------------------------
local Packet = {}
Packet.__index = Packet
Packet.VERSION = PROTOCOL_VERSION or 1 --- The version of the packet
Packet.__nextId = 0 --- The next packet ID to be assigned

---------------------------------------------------
--- Enums
---------------------------------------------------

--- Packet Types
Packet.TYPE = {
    EMPTY = 0,
    DATA = 1,
    ACK = 2,
    NACK = 3,
    PING = 4,
    PONG = 5,
    CONNECT = 6,
    DISCONNECT = 7
}

for name, value in pairs(Packet.TYPE) do
    Packet.TYPE[value] = name
end

---------------------------------------------------
--- Constructor
---------------------------------------------------

--- Constructor for a new Packet
--- @param data? table A table containing the packet data (type, flags, payload)
--- @param data.type? number The type of the packet (e.g., Packet.TYPE.DATA, Packet.TYPE.ACK, etc.)
--- @param data.flags? number The flags of the packet
--- @param data.payload? ByteBuffer The payload of the packet
--- @return Packet
function Packet.new(data)
    data = data or {}
    local packetType = data.type or Packet.TYPE.EMPTY
    local flags = data.flags or 0
    local payload = data.payload or ByteBuffer.new()
    assert(Packet.TYPE[packetType] ~= nil, "Invalid packet type")
    assert(type(flags) == "number", "Flags must be a number")
    assert(getmetatable(payload) == ByteBuffer, "Payload must be a ByteBuffer")

    return setmetatable({
        _version = Packet.VERSION,
        _flags = flags,
        _id = packetType == Packet.TYPE.EMPTY and 0 or Packet._nextId(),
        _type = packetType,
        _crc = 0, -- Placeholder for CRC, can be calculated later
        _payload = payload,
        _sealed = false, -- Indicates whether the packet is sealed (no further modifications allowed)
        _frozen = false -- Indicates whether the packet is frozen (immutable)
    }, Packet)
end

---------------------------------------------------
--- Meta Methods
---------------------------------------------------

--- Returns a string representation of the Packet for debugging purposes
--- @return string
function Packet:__tostring()
    return string.format("Packet(version=%d, flags=%d, id=%d, type=%d, crc=%d, payload=%s)", self._version, self._flags, self._id, self._type, self._crc, tostring(self._payload))
end

---------------------------------------------------
--- Private Methods
---------------------------------------------------

--- Increments the next packet ID and returns it
--- @return number
function Packet._nextId()
    Packet.__nextId = (Packet.__nextId + 1) % 0x10000 -- Wrap around at uint16 max value
    return Packet.__nextId
end

--- Asserts that the packet is mutable (not frozen) and raises an error if it is frozen
function Packet:_assertMutable()
    assert(not self._frozen, "Packet is frozen and cannot be modified")
end

--- Freezes the packet, making it immutable, and returns the packet for chaining
--- @return Packet
function Packet:_freeze()
    self._frozen = true
    return self
end

--- Seals the packet by calculating and appending the CRC16 to the payload, freezing the packet, and marking it as sealed
--- @param buffer ByteBuffer The buffer to seal
function Packet:_seal(buffer)
    if self._sealed then
        return
    end

    self:_setCRC(CRC16.append(buffer)) -- Append the buffer with the CRC16 and store the CRC value
    self:_freeze() -- Freeze the packet to prevent further modifications
    self._sealed = true -- Mark the packet as sealed
end

--- Unseals the packet, allowing modifications, and resets the CRC to 0
function Packet:_unseal()
    self._sealed = false
    self._frozen = false
    self:_setCRC(0)
end

--- Sets the version of the packet
--- @param version number The new version for the packet
function Packet:_setVersion(version)
    self:_assertMutable()
    assert(type(version) == "number", "Version must be a number")
    assert(version > 0 and version <= 0xFF, "Version must be a positive uint8 value (1-255)")
    self._version = version
end

--- Sets the ID of the packet
--- @param id number The new ID for the packet
function Packet:_setId(id)
    self:_assertMutable()
    assert(type(id) == "number", "ID must be a number")
    assert(id >= 0 and id <= 0xFFFF, "ID must be a uint16 value (0-65535)")
    if id ~= 0 and self:getType() == Packet.TYPE.EMPTY then
        id = 0
    end
    self._id = id
end

function Packet:_setCRC(crc)
    self:_assertMutable()
    assert(type(crc) == "number", "CRC must be a number")
    assert(crc >= 0 and crc <= 0xFFFF, "CRC must be a uint16 value (0-65535)")
    self._crc = crc
end

---------------------------------------------------
--- Getters
---------------------------------------------------

--- Gets the size of the payload in bytes
--- @return number
function Packet:getPayloadSize()
    return self._payload:size()
end

--- Gets the number of remaining bytes in the payload
--- @return number
function Packet:getPayloadRemainingBytes()
    return self._payload:getRemainingBytes()
end

--- Gets the version of the packet
--- @return number
function Packet:getVersion()
    return self._version
end

--- Gets the flags of the packet
--- @return number
function Packet:getFlags()
    return self._flags
end

--- Get the ID of the packet
--- @return number
function Packet:getId()
    return self._id
end

--- Gets the type of the packet
--- @return number
function Packet:getType()
    return self._type
end

--- Gets the CRC of the packet
--- @return number
function Packet:getCRC()
    return self._crc
end

--- Gets the payload of the packet
--- @return ByteBuffer
function Packet:getPayload()
    return self._payload
end

---------------------------------------------------
--- Setters
---------------------------------------------------

--- Sets the type of the packet and returns the packet for chaining
--- @param type number The new type for the packet
--- @return Packet
function Packet:setType(type)
    self:_assertMutable()
    assert(Packet.TYPE[type] ~= nil, "Invalid packet type")
    self._type = type

    if self:getId() == 0 and type ~= Packet.TYPE.EMPTY then
        self:_setId(Packet._nextId())
    end
    return self
end

--- Sets the flags of the packet and returns the packet for chaining
--- @param flags number The new flags for the packet
--- @return Packet
function Packet:setFlags(flags)
    self:_assertMutable()
    assert(type(flags) == "number", "Flags must be a number")
    self._flags = flags
    return self
end

--- Sets a flag on the packet and returns the packet for chaining
--- @param flag number The flag to set
--- @return Packet
function Packet:setFlag(flag)
    self:_assertMutable()
    assert(type(flag) == "number", "Flag must be a number")
    self:setFlags(bit32.bor(self:getFlags(), flag))
    return self
end

--- Clears a flag on the packet and returns the packet for chaining
--- @param flag number The flag to clear
--- @return Packet
function Packet:clearFlag(flag)
    self:_assertMutable()
    assert(type(flag) == "number", "Flag must be a number")
    self:setFlags(bit32.band(self:getFlags(), bit32.bnot(flag)))
    return self
end

--- Toggles a flag on the packet and returns the packet for chaining
--- @param flag number The flag to toggle
--- @return Packet
function Packet:toggleFlag(flag)
    self:_assertMutable()
    assert(type(flag) == "number", "Flag must be a number")
    self:setFlags(bit32.bxor(self:getFlags(), flag))
    return self
end

--- Sets the payload of the packet
--- @param buffer ByteBuffer The new payload for the packet and returns the packet for chaining
--- @return Packet
function Packet:setPayload(buffer)
    self:_assertMutable()
    assert(getmetatable(buffer) == ByteBuffer, "Payload must be a ByteBuffer")
    self._payload = buffer
    return self
end

---------------------------------------------------
--- Utility/Helper Methods
---------------------------------------------------

--- Clones the packet and returns a new instance with the same data
--- @return Packet
function Packet:clone()
    local packet = Packet.new({type = self:getType(), flags = self:getFlags(), payload = self:getPayload():clone()})
    packet:_setVersion(self:getVersion())
    packet:_setId(self:getId())
    packet:_setCRC(self:getCRC())
    packet:_freeze() -- Freeze the cloned packet to prevent further modifications
    packet._sealed = self._sealed -- Preserve the sealed state of the original packet
    return packet
end

--- Copies the packet and returns a new instance with the same data, but unfreezes and unseals it to allow modifications
--- @return Packet
function Packet:copy()
    local packet = self:clone()
    packet:_unseal() -- Unseal the copied packet to allow modifications
    return packet
end

--- Checks if the packet is frozen (immutable)
--- @return boolean
function Packet:isFrozen()
    return self._frozen
end

--- Checks if the packet is sealed (no further modifications allowed)
--- @return boolean
function Packet:isSealed()
    return self._sealed
end

--- Resets the payload pointer to the beginning of the buffer and returns the packet for chaining
--- @return Packet
function Packet:resetPayload()
    self:getPayload():resetPosition()
    return self
end

--------------------------------------------------
--- CRC
---------------------------------------------------

--- Verifies the CRC of the packet against the calculated CRC of its payload and returns the expected CRC, otherwise raises an error
--- @return number
function Packet:verifyCRC(buffer)
    local calculated, expected = CRC16.validate(buffer)
    assert(calculated == expected, string.format("CRC mismatch: expected 0x%04X got 0x%04X", expected, calculated))
    return expected
end

---------------------------------------------------
--- Flags
---------------------------------------------------

--- Checks if a flag exists on the packet
--- @param flag number The flag to check
--- @return boolean
function Packet:hasFlag(flag)
    assert(type(flag) == "number", "Flag must be a number")
    return bit32.band(self:getFlags(), flag) ~= 0
end

--------------------------------------------------
--- Validation
--------------------------------------------------

--- Checks if the packet is valid based on its version and type
--- @return boolean, string|nil Returns true if valid, false and an error message if invalid
function Packet:isValid()
    if self:getVersion() ~= Packet.VERSION then
        return false, "Invalid packet version"
    end

    if not Packet.TYPE[self:getType()] then
        return false, "Invalid packet type"
    end
    return true
end

--- Validates the packet and raises an error if invalid
--- @return boolean
function Packet:validate()
    assert(self:getVersion() == Packet.VERSION, "Invalid packet version")
    assert(Packet.TYPE[self:getType()], "Invalid packet type")
    return true
end

--------------------------------------------------
--- Encoding
--------------------------------------------------

--- Encodes the packet into a ByteBuffer for transmission
--- @return ByteBuffer 
function Packet:encode()
    local buffer = ByteBuffer.new()
    buffer
        :writeUInt16(PACKET_MAGIC_NUMBER) --- @type number The magic number for packet validation
        :writeUInt8(self:getVersion()) --- @type number The version of the packet
        :writeUInt8(self:getFlags()) --- @type number The flags of the packet
        :writeUInt16(self:getId()) --- @type number The ID of the packet
        :writeUInt8(self:getType()) --- @type number The type of the packet (e.g., PACKET_TYPES.REQUEST, PACKET_TYPES.STATUS, etc.)
        :writeUInt16(self:getPayloadSize()) --- @type number The size of the payload
        :writeBytes(self:getPayload():toTable()) --- @type ByteBuffer The payload of the packet

    self:_seal(buffer) -- Seal the packet by calculating and appending the CRC16 to the payload

    return buffer
end

---------------------------------------------------
--- Decoding
---------------------------------------------------

--- Decodes a ByteBuffer into a Packet
--- @param buffer ByteBuffer The buffer to decode
--- @return Packet
function Packet.decode(buffer)
    assert(getmetatable(buffer) == ByteBuffer, "Buffer must be a ByteBuffer")
    local preamble = buffer:readUInt16()
    assert(preamble == PACKET_MAGIC_NUMBER, "Invalid packet preamble")

    local packet = Packet.new({type = Packet.TYPE.EMPTY})
    packet:_setVersion(buffer:readUInt8())
    packet:setFlags(buffer:readUInt8())
    packet:_setId(buffer:readUInt16())
    packet:setType(buffer:readUInt8())

    local payloadLen = buffer:readUInt16()
    local newPayload = ByteBuffer.new(buffer:readBytes(payloadLen))
    packet:setPayload(newPayload)
    packet:validate() -- Validate the packet
    packet:_setCRC(packet:verifyCRC(buffer)) -- Verify the CRC
    packet:_freeze() -- Freeze the packet to prevent further modifications

    return packet
end

---------------------------------------------------
--- Debugging
---------------------------------------------------

--- Resets the next packet ID to 0 (useful for testing)
function Packet.resetIds()
    Packet.__nextId = 0
end

return Packet