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

function logWarning(msg)
    if msg == "" then
         return
    end
   table.insert(Lines, "[Warning]: " .. msg)
end
function logInfo(msg)
    if msg == "" then
         return
    end
    table.insert(Lines, "[Info]: " .. msg)
end
function logError(msg)
    if msg == "" then
         return
    end
    table.insert(Lines, "[Error]: " .. msg)
end

Properties = {}
Lines = {}

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
    Properties["Log.Info"] = "true"
    Properties["Log.Warnings"] = "true"
    
    Properties["Rednet.Side"] = "left"
    Properties["Rednet.Host"] = "storage"
    Properties["Rednet.AcceptTimeout"] = "10"
    Properties["Rednet.RecieveTimeout"] = "10"
    Properties["Rednet.MaxRecieveAttempts"] = "10"

    local file = fs.open(pwd .. "/config.properties", "w")
    for key, value in pairs(Properties) do
        file.writeLine(key .. ": " .. value)
    end
    file.flush()
    file.close()
end


function Send(msg, waitResponse)
    at = tonumber(Properties["Rednet.AcceptTimeout"])
    if not at then
        at = 10
    end
    rt = tonumber(Properties["Rednet.RecieveTimeout"])
    if not rt then
        rt = 10
    end
    mra = tonumber(Properties["Rednet.MaxRecieveAttempts"])
    if not mra then
        mra = 10
    end

    local state, message = pcall(rednet.open, Properties["Rednet.Side"])
    if not state then
        logError("Modem connection error!")
        return nil
    end

    local id = rednet.lookup("storage", Properties["Rednet.Host"])
    if id then
        rednet.send(id, msg, "storage")
        local senderId, message, protocol = rednet.receive("storage_response", tonumber(Properties["Rednet.AcceptTimeout"]))
        if not Verify(id, senderId, protocol) then
            rednet.close(Properties["Rednet.Side"])
            return nil
        end
        if message ~= "Accepted!" then
            if Properties["Log.Warnings"] then
                logWarning("Message delivery error!")
            end
            rednet.close(Properties["Rednet.Side"])
            return nil
        end
        logInfo("Accepted!")
        if waitResponse then
            senderId, message, protocol = rednet.receive("storage_response", rt)
            attempt = 1
            while not message and attempt < mra do
                senderId, message, protocol = rednet.receive("storage_response", rt)
                logWarning("Message recieve attempt: " .. tostring(attempt))
            end
            
            if not Verify(id, senderId, protocol) then
                rednet.close(Properties["Rednet.Side"])
                return nil
            end
    
            rednet.close(Properties["Rednet.Side"])
            logInfo(msg .. " -> " .. message)
            return message
        end
        rednet.close(Properties["Rednet.Side"])
        return nil
    end
    if Properties["Log.Warnings"] then
        logWarning("ID not found!")
    end
    rednet.close(Properties["Rednet.Side"])
    return nil
end

function Verify(rightId, senderId, protocol)
    if protocol ~= "storage_response" then
        if Properties["Log.Warnings"] then
            logWarning("Wrong protocol! " .. tostring(protocol))
        end
        return false
    end
    if senderId ~= rightId then
        if Properties["Log.Warnings"] then
            logWarning("Wrong user! " .. tostring(senderId))
        end
        return false
    end
    return true
end