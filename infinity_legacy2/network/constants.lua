PROTOCOL_VERSION = 1

---------------------------------------------------
--- Packet constants
---------------------------------------------------

--- Magic Number
--- @type number
PACKET_MAGIC_NUMBER = 0x55AA

--- Flags
--- @type table
PACKET_FLAGS = {}

PACKET_HEADER_SIZE = 9 -- 2 bytes for magic, 1 byte for version, 1 byte for flags, 2 bytes for packet ID, 1 byte for type and 2 bytes for payload length