local transport = require("transport")

while true do
    local byte = transport.readByte()
    print(string.format("Received byte: 0x%02X", byte))
end