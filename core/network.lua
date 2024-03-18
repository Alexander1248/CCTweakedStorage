local connected = true

function ServerUpdate()
    local serverAddress = Properties["Server.Address"] --"http://134.0.111.91:34721"
    local data = "\n";
    for k, v in pairs(Items) do
    data = data .. k .. " " .. v .. "\n"
    end 

    -- Item sending
    local postRequest, err = http.post(serverAddress .. "/items/update", data, nil, true);
    if not postRequest then 
        if err == "Connection refused" 
        or err == "No message received" 
        or err == "Could not connect"
        or err == "Timed out" then
            if Properties["Log.Warnings"] == "true" then
                warning("Server connection error!")
            end
            connected = false 
        else
            error(err) 
        end
    else
        postRequest.close()
    end

    if connected then
        local getRequest = http.get(serverAddress .. "/requests/cc/poll")
        local data = getRequest.readAll()
        local rList = split(data, '\n')

        for i = 1, #rList do
            table.insert(Requests, {rList[i], -1})
        end
        getRequest.close()
    end
end

function IsConnected()
    return connected
end


function RednetStart()
    rednet.open(Properties["Rednet.Side"])
    rednet.host("storage", Properties["Rednet.Host"])
end

function RednetUpdate()
    timeout = tonumber(Properties["Rednet.Timeout"])
    if not timeout then 
        timeout = 3
    end
    while true do
        local senderId, message, protocol = rednet.receive("storage", timeout)
        if protocol == "storage" then
            rednet.send(senderId, "Accepted!", "storage_response")
            table.insert(Requests, {message, senderId})
        else break end
    end
end

function Send(message, senderId)
    rednet.send(senderId, message, "storage_response")
end

function RednetEnd()
    rednet.close()
end