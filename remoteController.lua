local SHA256 = require("libs.hash.sha2_256")
local stream = require("libs.hash.util.stream")
local lib = require("libs.lib")
local cli = require("libs.cli")

local A = SHA256()

local SECRET = "SECRET"


local modem = peripheral.find("modem") or error("No modem attached")
peripheral.find("modem", rednet.open)

function handleResponse()
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        if (message.message.type == "status_report" and message.message.status == "OK") then
            print("Ready to fire!")
        end
    end
end

function aimAt(words)
    if (lib.tablelength(words) < 4) then
        printError("Format error. Check you command")
        return nil
    end
    local x = tonumber(words[2])
    local y = tonumber(words[3])
    local z = tonumber(words[4])

    local requastTable = {
        ["x"] = x,
        ["y"] = y,
        ["z"] = z,
        ["type"] = "aim_at",
        ["time"] = textutils.formatTime(os.time())
    }
    A.init()
    A.update(stream.fromString(lib.dump(requastTable) .. SECRET))
    A.finish()
    requastTable.hash = A.asHex()
    rednet.broadcast(requastTable)

end

cli.addCommand("aimAt", aimAt)
parallel.waitForAny(cli.CLI, handleResponse)
