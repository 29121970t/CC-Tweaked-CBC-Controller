local lib = require("libs.lib")
local cli = require("libs.cli")
local Cannon = require("libs.Cannon")
local SHA256 = require("libs.hash.sha2_256")
local stream = require("libs.hash.util.stream")
-- globals
SECRET = "SECRET"
facings = {
    ["NORTH"] = 1,
    ["SOUTH"] = 1,
    ["WEST"] = 1,
    ["EAST"] = 1
}

local HashFactory = SHA256()
lib.clearConsole()
settings.load()
config = {}
cannon = {}

-- input handling
function handleInput(func, args)
    local data = nil
    while data == nil do
        os.sleep(0)
        data = func(args)
    end
    return data
end
function GetMountPos()
    local posString = read()

    local words = {}
    for word in posString:gmatch("%-?%d+") do
        local testNumber = tonumber(word)
        if (testNumber == nil) then
            printError("Got not a number")
            return nil
        end
        table.insert(words, testNumber)
    end
    if (lib.tablelength(words) < 3) then
        printError("Format error")
        return nil
    end
    return {words[1], words[2], words[3]}
end
function GetSingleNumber(testFunc)
    local id = tonumber(read())
    if (id == nil) then
        printError("Got not a number")
        return nil
    end
    if (type(testFunc) ~= 'function') then
        return id
    end
    if (testFunc(id)) then
        return id
    end
    return nil
end
function GetCreateBlockId(name)
    function test(id)
        if (peripheral.wrap(name .. "_" .. id) ~= nil) then
            return true
        else
            printError("No such Block")
            return nil
        end
    end
    local res = GetSingleNumber(test)
    if (type(res) == 'number') then
        return name .. "_" .. res
    else
        return nil
    end
end
function GetCannonFacing()
    local str = read()
    if (facings[str] ~= nil) then
        return str
    else
        printError("No such direction")
        return nil
    end
end
function GetBool()
    local str = read()
    if (str == "y") then
        return true
    elseif (str == "n") then
        return false
    end
    return nil
end

-- setting up env vars
function saveConfig()
    settings.set("cannonConfig", config)
    settings.save()
end
function getSettings()
    if (not (settings.get("configured") == true)) then
        print("Autostart this programm? (y/n)")
        config.autoStart = handleInput(GetBool)

        print("Please enter canon mount position in the following format: 'x y z' ")
        config.mountPos = handleInput(GetMountPos)

        print("Please enter Vertical Gearshift id (number)")
        config.VerticalGearshiftId = handleInput(GetCreateBlockId, "Create_SequencedGearshift")
        print("Please enter Horizontal Gearshift id (number)")
        config.HorizontalGearshiftId = handleInput(GetCreateBlockId, "Create_SequencedGearshift")

        print("Please enter Vertical Speed Controller id (number)")
        config.VerticalSpeedControllerId = handleInput(GetCreateBlockId, "Create_RotationSpeedController")
        print("Please enter Horizontal Speed Controller id (number)")
        config.HorizontalSpeedControllerId = handleInput(GetCreateBlockId, "Create_RotationSpeedController")

        print("Please enter Input speed")
        config.InputSpeed = handleInput(GetSingleNumber)
        print("Please enter rotation ratio")
        config.GunRotationRatio = handleInput(GetSingleNumber)
        print("Please enter barrel length")
        config.barrelLength = handleInput(GetSingleNumber)

        print("Please enter cannon facing ('NORTH', 'SOUTH', 'WEST' or 'EAST')")
        config.facing = handleInput(GetCannonFacing)

        print("Always use remote mode? (y/n)")
        config.useAutolisten = handleInput(GetBool)

        settings.set("configured", true)
        saveConfig()
        lib.clearConsole()
        print("Configuartion done!")
    else
        config = settings.get("cannonConfig")
    end
end

-- commands
function resetSetings()
    settings.clear()
    settings.save()
    lib.clearConsole()
    getSettings()
end
function setFacing(words)
    if (facings[words[2]] ~= nil) then
        Cannon.facing = words[2]
        config.facing = words[2]
        saveConfig()
    else
        printError("No such direction")
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

    if (not (x ~= nil and y ~= nil and z ~= nil)) then
        printError("Format error. Check you command")
    end

    local newPos = vector.new(x, y, z)
    cannon.AimAt(newPos)
end

function listen()
    print("Listening...")
    local modems = {peripheral.find("modem", function(name, modem)
        return modem.isWireless()
    end)}
    if (modems[1] == nil) then
        printError("No modem attached")
        return nil
    end

    peripheral.find("modem", rednet.open)

    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        print(("Message received from %f blocks away. Reply to %d. "):format(replyChannel, distance))
        if (message.message.hash == nil or message.message.type ~= "aim_at") then
            printError("INVALID MESSAGE")
            ::continue::
        end

        local hash = message.message.hash
        message.message.hash = nil

        HashFactory.init()
        HashFactory.update(stream.fromString(lib.dump(message.message) .. SECRET))
        HashFactory.finish()
        if (hash ~= HashFactory.asHex()) then
            printError("INVALID MESSAGE. HASH MISMATCH")
            ::continue::
        end
        local newPos = vector.new(message.message.x, message.message.y, message.message.z)
        cannon.AimAt(newPos)
        rednet.send(replyChannel, {
            ["type"] = "status_report",
            ["status"] = "OK"
        })
    end
end
function setAutolisten(words)
    if (words[2] == "true") then
        config.useAutolisten = true
        saveConfig()
        listen()
    else
        config.useAutolisten = false
        saveConfig()
    end
end

if (config.autoStart) then
    shell.execute("cp", "startup.lua", "../")
end

getSettings()
cannon = Cannon.new(peripheral.wrap(config.VerticalGearshiftId), peripheral.wrap(config.HorizontalGearshiftId),
    peripheral.wrap(config.VerticalSpeedControllerId), peripheral.wrap(config.HorizontalSpeedControllerId),
    vector.new(config.mountPos[1], config.mountPos[2], config.mountPos[3]), config.barrelLength, config.InputSpeed,
    config.GunRotationRatio, config.facing)

if (config.useAutolisten) then
    listen()
end
cli.addCommand("resetSetings", resetSetings)
cli.addCommand("setFacing", setFacing)
cli.addCommand("aimAt", aimAt)
cli.addCommand("listen", listen)
cli.addCommand("setAutolisten", setAutolisten)
parallel.waitForAll(cli.CLI)
