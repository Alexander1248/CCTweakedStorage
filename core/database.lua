Inputs = {}
Storages = {}
Outputs = {}

Aliases = {}
Unloaders = {}
Loaders = {}

Items = {}

Requests = {}

Properties = {}


function debug(msg)
    local col = term.getTextColor()
    term.setTextColor(colors.green)
    print(msg)
    term.setTextColor(col)
end

function warning(msg)
    local col = term.getTextColor()
    term.setTextColor(colors.orange)
    print(msg)
    term.setTextColor(col)
end

local function split(pString, pPattern)
    local Table = {}  
    local fpat = "(.-)" .. pPattern
    local last_end = 1
    local s, e, cap = pString:find(fpat, 1)
    while s do
       if s ~= 1 or cap ~= "" then
      table.insert(Table,cap)
       end
       last_end = e+1
       s, e, cap = pString:find(fpat, last_end)
    end
    if last_end <= #pString then
       cap = pString:sub(last_end)
       table.insert(Table, cap)
    end
    return Table
end

function Save()
    local pwd = fs.getDir(shell.getRunningProgram())

    if not fs.exists(pwd .. "/data") then fs.makeDir(pwd .. "/data") end
    local file = fs.open(pwd .. "/data/inputs.db", "w")
    for index, storage in pairs(Inputs) do
        file.writeLine(storage)
    end
    file.flush()
    file.close()
    
    file = fs.open(pwd .. "/data/storages.db", "w")
    for i = 1, #Storages do 
        file.writeLine(Storages[i])
    end
    file.flush()
    file.close()
    
    file = fs.open(pwd .. "/data/outputs.db", "w")
    for name, storage in pairs(Outputs) do
        file.writeLine(name .. " " .. storage)
    end
    file.flush()
    file.close()
    
    file = fs.open(pwd .. "/data/aliases.db", "w")
    for alias, id in pairs(Aliases) do
        file.writeLine(alias .. " " .. id)
    end
    file.flush()
    file.close()
    
    file = fs.open(pwd .. "/data/unloaders.db", "w")
    for index, data in pairs(Unloaders) do
        file.writeLine(data)
    end
    file.flush()
    file.close()
    
    file = fs.open(pwd .. "/data/loaders.db", "w")
    for index, data in pairs(Loaders) do
        file.writeLine(data[1] .. " " .. data[2] .. " " .. data[3] .. " " .. data[4] .. " " .. data[5])
    end
    file.flush()
    file.close()
    
    file = fs.open(pwd .. "/data/requests.db", "w")
    for index, data in pairs(Requests) do
        file.writeLine(data[1] .. " " .. data[2])
    end
    file.flush()
    file.close()
end

function SaveProperties()
    local pwd = fs.getDir(shell.getRunningProgram())
    local file = fs.open(pwd .. "/config.properties", "w")
    for key, value in pairs(Properties) do
        file.writeLine(key .. ": " .. value)
    end
    file.flush()
    file.close()
end

function Load()
    local pwd = fs.getDir(shell.getRunningProgram())
    if fs.exists(pwd .. "/config.properties") then
        local file = fs.open(pwd .. "/config.properties", "r")
        while true do
            local line = file.readLine()
          
            if not line then break end
          
            local frags = split(line, ": ")
            if frags and frags[1] and frags[2] then
                Properties[frags[1]] = frags[2]
            end
        end
        file.close()
    else
        Properties["Tick"] = "1"
        Properties["Log.Info"] = "true"
        Properties["Log.Warnings"] = "true"
        Properties["Log.Debug"] = "false"

        Properties["Server.Requests"] = "false"
        Properties["Server.Address"] = ""
        
        Properties["Rednet.Side"] = "left"
        Properties["Rednet.Host"] = "storage"
        Properties["Rednet.Response"] = "true"
        Properties["Rednet.Timeout"] = "3"

        SaveProperties()
    end

    if fs.exists(pwd .. "/data/inputs.db") then
        local file = fs.open(pwd .. "/data/inputs.db", "r")
        while true do
            local line = file.readLine()
          
            if not line then break end
          
            local frags = split(line, " ")
            table.insert(Inputs, frags[1])
        end
        file.close()
    elseif Properties["Log.Warnings"] == "true" then
        warning("Inputs file not found!")
    end
    
    if fs.exists(pwd .. "/data/storages.db") then
        local file = fs.open(pwd .. "/data/storages.db", "r")
        while true do
            local line = file.readLine()
          
            if not line then break end

            table.insert(Storages, line)
        end
        file.close()
    elseif Properties["Log.Warnings"] == "true" then
        warning("Storages file not found!")
    end
    
    if fs.exists(pwd .. "/data/outputs.db") then
        local file = fs.open(pwd .. "/data/outputs.db", "r")
        while true do
            local line = file.readLine()
          
            if not line then break end
          
            local frags = split(line, " ")
            Outputs[frags[1]] = frags[2]
        end
        file.close()
    elseif Properties["Log.Warnings"] == "true" then
        warning("Outputs file not found!")
    end
    
    if fs.exists(pwd .. "/data/aliases.db") then
        local file = fs.open(pwd .. "/data/aliases.db", "r")
        while true do
            local line = file.readLine()
          
            if not line then break end
          
            local frags = split(line, " ")
            Aliases[frags[1]] = frags[2]
        end
        file.close()
    elseif Properties["Log.Warnings"] == "true" then
        warning("Aliases file not found!")
    end
    
    if fs.exists(pwd .. "/data/unloaders.db") then
        local file = fs.open(pwd .. "/data/unloaders.db", "r")
        while true do
            local line = file.readLine()
          
            if not line then break end

            table.insert(Unloaders, line)
        end
        file.close()
    elseif Properties["Log.Warnings"] == "true" then
        warning("Pushers file not found!")
    end
    
    if fs.exists(pwd .. "/data/loaders.db") then
        local file = fs.open(pwd .. "/data/loaders.db", "r")
        while true do
            local line = file.readLine()
          
            if not line then break end
          
            local frags = split(line, " ")
            table.insert(Loaders, { frags[1], frags[2], tonumber(frags[3]), frags[4], tonumber(frags[5]) })
        end
        file.close()
    elseif Properties["Log.Warnings"] == "true" then
        warning("Pollers file not found!")
    end
    
    if fs.exists(pwd .. "/data/requests.db") then
        local file = fs.open(pwd .. "/data/requests.db", "r")
        while true do
            local line = file.readLine()
          
            if not line then break end

            local frags = split(line, " ")
            table.insert(Requests, {frags[1], frags[2]})
        end
        file.close()
    elseif Properties["Log.Warnings"] == "true" then
        warning("Requests file not found!")
    end
end