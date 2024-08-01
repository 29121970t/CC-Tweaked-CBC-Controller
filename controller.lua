local lib = require("libs.lib")
local cli = require("libs.cli")
local Cannon = require("libs.Cannon")
local SHA256 = require("libs.hash.sha2_256")
local stream = require("libs.hash.util.stream")

local modems = {peripheral.find("modem", function(name, modem)
    return modem.isWireless()
end)}
if (modems[1] == nil) then
    error("No modem attached", 2)
end

peripheral.find("modem", rednet.open)


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
presets = {
    ["gun4"] = gun4
}
remoteActions = {}
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
function GetPreset()
    local str = read()
    if (presets[str] == nil) then
        printError("Format error")
        return nil
    end
    return presets[str]
end

-- presets
function gun4()
    local conf = {}
    local x, y, z = gps.locate()
    local pos = vector.new(x, y, z)
    if (x == nil or not (lib.isint(x) and lib.isint(y) and lib.isint(z))) then
        print("Please enter PC position in the following format: 'x y z' ")
        local xd = handleInput(GetMountPos)
        pos = vector.new(xd[1], xd[2], xd[3])
    end
    conf.mountPos = pos + vector.new(-1, 3, 1)
    conf.InputSpeed = -256
    conf.GunRotationRatio = 128
    conf.barrelLength = 12
    conf.useAutolisten = true
    return conf
end

-- setting up env vars
function saveConfig()
    settings.set("cannonConfig", config)
    settings.save()
end
function getSettings()
    if (not (settings.get("configured") == true)) then
        print("Autostart this programm? (y/n)")
        if (handleInput(GetBool) and not fs.exists("/startup.lua")) then
            shell.execute("cp", "/CC-Tweaked-CBC-Controller/startup.lua", "/")
        elseif fs.exists("/startup.lua") then
            shell.execute("rm", "/startup.lua")
        end

        print("Use preset? (y/n)")
        if (handleInput(GetBool)) then
            local presetsString = ""
            for i in pairs(lib.get_keys(presets)) do
                presetsString = presetsString .. i .. ", "
            end
            print("The following presets are available: " .. presetsString .. "n")
            config = handleInput(GetPreset)()

        else
            print("Please enter canon mount position in the following format: 'x y z' ")
            config.mountPos = handleInput(GetMountPos)

            print("Please enter Input speed")
            config.InputSpeed = handleInput(GetSingleNumber)
            print("Please enter rotation ratio")
            config.GunRotationRatio = handleInput(GetSingleNumber)
            print("Please enter barrel length")
            config.barrelLength = handleInput(GetSingleNumber)


            print("Always use remote mode? (y/n)")
            config.useAutolisten = handleInput(GetBool)
        end

        print("Please enter Vertical Gearshift id (number)")
        config.VerticalGearshiftId = handleInput(GetCreateBlockId, "Create_SequencedGearshift")
        print("Please enter Horizontal Gearshift id (number)")
        config.HorizontalGearshiftId = handleInput(GetCreateBlockId, "Create_SequencedGearshift")

        print("Please enter Vertical Speed Controller id (number)")
        config.VerticalSpeedControllerId = handleInput(GetCreateBlockId, "Create_RotationSpeedController")
        print("Please enter Horizontal Speed Controller id (number)")
        config.HorizontalSpeedControllerId = handleInput(GetCreateBlockId, "Create_RotationSpeedController")

        print("Please enter cannon facing ('NORTH', 'SOUTH', 'WEST' or 'EAST')")
        config.facing = handleInput(GetCannonFacing)

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

function setRotationSpeed(words)
    local num = tonumber(words[2])
    if (num == nil) then
        printError("Got not a number")
        return nil
    end
    cannon.InputSpeed = num
    config.InputSpeed = num
    saveConfig()
end

-- remote actions
function AimAtAction(message, replyChannel)
    local newPos = vector.new(message.message.x, message.message.y, message.message.z)
    cannon.AimAt(newPos)
    rednet.send(replyChannel, {
        ["type"] = "status_report",
        ["status"] = "OK"
    })
end

function listen()
    print("Listening...")
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        print(("Message received from %f blocks away. Reply to %d. "):format(replyChannel, distance))
        if (message.message.hash == nil) then
            printError("INVALID MESSAGE")
            goto continue
        end

        local hash = message.message.hash
        message.message.hash = nil

        HashFactory.init()
        HashFactory.update(stream.fromString(lib.dump(message.message) .. SECRET))
        HashFactory.finish()
        if (hash ~= HashFactory.asHex()) then
            printError("INVALID MESSAGE. HASH MISMATCH")
            goto continue
        end

        if (remoteActions[message.message.type] == nil) then
            printError("INVALID ACTION TYPE.")
            goto continue
        end
        remoteActions[message.message.type](message, replyChannel)
        ::continue::
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

remoteActions = {
    ["aim_at"] = AimAtAction
}
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
cli.addCommand("setRotationSpeed", setRotationSpeed)
parallel.waitForAll(cli.CLI)
