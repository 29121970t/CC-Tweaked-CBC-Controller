local completion = require "cc.completion"
local lib = require("libs.lib")

mod = {}
local init = function()
    
end
local loop = function()
    
end
local commands = {
    ["test"] = function() print("Hey! It works!") end,
    ["clear"] = function() term.clear() term.setCursorPos(1,1) end,
    ["help"] = function() print("Commands: " .. table.concat(lib.get_keys(mod.commands), ", ")) end,
}
mod.commands = commands

function mod.addCommand(name, func)
    mod.commands[name] = func
end
function mod.setInitFunction(func)
    init = func
end
function mod.setLoopFunction(func)
    loop = func
end
function compl(text)
    return completion.choice(text, lib.get_keys(mod.commands))
end
function mod.CLI()
    init()
    while true do
        sleep(0)
        loop()
        io.write(">")
        local command = read(nil, nil, compl)
        local words = lib.splitString(command)
        if (not lib.tableHasKey(mod.commands, words[1])) then
            printError("No such command")
        else
            mod.commands[words[1]](words)
        end
    end
end
return mod
