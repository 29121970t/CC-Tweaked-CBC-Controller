local lib = {}
function lib.tablelength(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

function lib.clearConsole()
    term.clear()
    term.setCursorPos(1, 1)
end

function lib.get_keys(t)
    local keys = {}
    for key, _ in pairs(t) do
        table.insert(keys, key)
    end
    return keys
end

function lib.splitString(str)
    local words = {}
    for word in str:gmatch("%S+") do
        table.insert(words, word)
    end
    return words
end

function lib.tableHasKey(table, key)
    return table[key] ~= nil
end

function lib.round(a)
    return math.floor(a + 0.5)
end

function lib.sign(x)
    return x > 0 and 1 or x < 0 and -1 or 0
end
function lib.dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. lib.dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end
function lib.isint(n)
    return n == math.floor(n)
end
return lib
