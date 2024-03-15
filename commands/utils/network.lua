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

function warning(msg)
    local col = term.getTextColor()
    term.setTextColor(colors.orange)
    print(msg)
    term.setTextColor(col)
end

Properties = {}

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

    local file = fs.open(pwd .. "/config.properties", "w")
    for key, value in pairs(Properties) do
        file.writeLine(key .. ": " .. value)
    end
    file.flush()
    file.close()
end


function Send(msg, waitResponse)
    rednet.open(Properties["Rednet.Side"])
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
                warning("Message delivery error!")
            end
            rednet.close(Properties["Rednet.Side"])
            return nil
        end
        print("Accepted!")
        if waitResponse then
            senderId, message, protocol = rednet.receive("storage_response", tonumber(Properties["Rednet.RecieveTimeout"]))
            while not message do
                senderId, message, protocol = rednet.receive("storage_response", tonumber(Properties["Rednet.RecieveTimeout"]))
            end
            
            if not Verify(id, senderId, protocol) then
                rednet.close(Properties["Rednet.Side"])
                return nil
            end
    
            rednet.close(Properties["Rednet.Side"])
            return message
        end
        rednet.close(Properties["Rednet.Side"])
        return nil
    end
    if Properties["Log.Warnings"] then
        warning("ID not found!")
    end
    rednet.close(Properties["Rednet.Side"])
    return nil
end

function Verify(rightId, senderId, protocol)
    if protocol ~= "storage_response" then
        if Properties["Log.Warnings"] then
            warning("Wrong protocol! " .. protocol)
        end
        return false
    end
    if senderId ~= rightId then
        if Properties["Log.Warnings"] then
            warning("Wrong user! " .. senderId)
        end
        return false
    end
    return true
end