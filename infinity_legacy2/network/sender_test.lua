local transport = require("transport")

while true do
    transport.writeByte(0x55)
    transport.writeByte(0xAA)
    sleep(1)
end