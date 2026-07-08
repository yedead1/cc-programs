local RedstoneTransport = require("network.transport.redstoneTransport")
local Connection = require("network.connection")
local Packet = require("network.packet")

local START_FIRST_PING = true

---@type Connection
local connection = Connection.new({
    transport = RedstoneTransport.new({
        dataSide = "right",
        clockSide = "back",
        clockDelay = 0.05
    }),
    autoConnect = false,
    transmission = {
        maxRetries = 3,
        retryDelay = 1
    }
})

--- @param packet Packet The received packet
connection:on("connectionPacketReceived", function(packet)
    print(string.format("Received Packet(id=%d, type=%d, data=%s)", packet:getId(), packet:getType(), tostring(packet:getPayload())))

    if packet:getType() == Packet.TYPE.PING then
        print("Received PING, sending PONG...")
        connection:request(Packet.new({ type = Packet.TYPE.PONG }))
    elseif packet:getType() == Packet.TYPE.PONG then
        sleep(1) -- Wait for 1 second before sending the next PING
        print("Received PONG, sending PING...")
        connection:request(Packet.new({ type = Packet.TYPE.PING }))
    end
end)

connection:on("connectionPacketSent", function(packet)
    print(string.format("Sent Packet(id=%d, type=%d, data=%s)", packet:getId(), packet:getType(), tostring(packet:getPayload())))
end)

connection:on("connectionOpened", function()
    print("Connection opened")

    if START_FIRST_PING then
        print("Sending first PING...")
        connection:request(Packet.new({ type = Packet.TYPE.PING }))
    end
end)

connection:on("connectionClosed", function()
    print("Connection closed")
end)

connection:on("connectionError", function(err)
    print(string.format("Connection error: %s", tostring(err)))
end)

connection:open()