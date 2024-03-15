assert(require("core/routing"))
assert(require("core/network"))
assert(require("core/database"))



local run = true

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

local function transform(name) 
    local mask = Aliases[name]
    if mask == nil then
        return name
    else
        return mask
    end
end

local types = {
    ['storage_add'] = function (req, sender)
        table.insert(Storages, transform(req[2]))
        if Properties["Log.Info"] == "true" then
            print("Succesful!")
        end      
        if Properties["Rednet.Response"] == "true" then
            Send("Succesful!", sender)
        end
    end,
    ['storage_remove'] = function (req, sender)
        local state = "Loader not found!"
        local storage = transform(req[2])
        for i = 1, #Storages do
            if Storages[i] == storage then
                table.remove(Storages, i)
                state = "Succesful!"
                break
            end
        end
        if Properties["Log.Info"] == "true" then
            print(state)
        end      
        if Properties["Rednet.Response"] == "true" then
            Send(state, sender)
        end
    end,
    ['storage_list'] = function (req, sender)
        local data = "";
        for index, value in pairs(Storages) do
            data = data .. value .. "\n"
        end
        Send(data, sender)
        if Properties["Log.Debug"] == "true" then
            debug(data)
        end
    end,


    ['input_add'] = function (req, sender)
        table.insert(Inputs, transform(req[2]))
        if Properties["Log.Info"] == "true" then
            print("Succesful!")
        end      
        if Properties["Rednet.Response"] == "true" then
            Send("Succesful!", sender)
        end
    end,
    ['input_remove'] = function (req, sender)
        local state = "Input not found!"
        local storage = transform(req[2])
        for i = 1, #Inputs do
            if Inputs[i] == storage then
                table.remove(Inputs, i)
                state = "Succesful!"
                break
            end
        end
        if Properties["Log.Info"] == "true" then
            print(state)
        end      
        if Properties["Rednet.Response"] == "true" then
            Send(state, sender)
        end
    end,
    ['input_list'] = function (req, sender)
        local data = "";
        for name, storage in pairs(Inputs) do
            data = data .. storage .. "\n"
        end
        Send(data, sender)
        if Properties["Log.Debug"] == "true" then
            debug(data)
        end
    end,
    

    ['output_add'] = function (req, sender)
        Outputs[req[2]] = transform(req[3])
        if Properties["Log.Info"] == "true" then
            print("Succesful!")
        end      
        if Properties["Rednet.Response"] == "true" then
            Send("Succesful!", sender)
        end
    end,
    ['output_remove'] = function (req, sender)
        Outputs[req[2]] = nil
        if Properties["Log.Info"] == "true" then
            print("Succesful!")
        end      
        if Properties["Rednet.Response"] == "true" then
            Send("Succesful!", sender)
        end
    end,
    ['output_list'] = function (req, sender)
        local data = "";
        for name, storage in pairs(Outputs) do
            data = data .. name .. " " .. storage .. "\n"
        end
        Send(data, sender)
        if Properties["Log.Debug"] == "true" then
            debug(data)
        end
    end,


    ['item_add'] = function (req, sender)
        local state = AddItem(transform(req[2]), tonumber(req[3]))
        if Properties["Log.Info"] == "true" then
            print(state)
        end      
        if Properties["Rednet.Response"] == "true" then
            Send(state, sender)
        end
    end,
    ['item_add_all'] = function (req, sender)
        local state = AddAllItems()
        if Properties["Log.Info"] == "true" then
            print(state)
        end      
        if Properties["Rednet.Response"] == "true" then
            Send(state, sender)
        end
    end,
    ['item_get'] = function (req, sender)
        local state = GetItem(transform(req[2]), tonumber(req[3]), transform(req[4]))
        if Properties["Log.Info"] == "true" then
            print(state)
        end      
        if Properties["Rednet.Response"] == "true" then
            Send(state, sender)
        end
    end,
    ['item_list'] = function (req, sender)
        local data = "";
        for k, v in pairs(Items) do
            data = data .. k .. " " .. v .. "\n"
        end
        Send(data, sender)
        if Properties["Log.Debug"] == "true" then
            debug(data)
        end
    end,
    ['item_count'] = function (req, sender)
        Send(Items[transform(req[2])], sender)
        if Properties["Log.Debug"] == "true" then
            debug(Items[transform(req[2])])
        end
    end,


    ['alias_add'] = function (req, sender)
        Aliases[req[2]] = req[3]
        if Properties["Log.Info"] == "true" then
            print("Succesful!")
        end      
        if Properties["Rednet.Response"] == "true" then
            Send("Succesful!", sender)
        end
    end,
    ['alias_get'] = function (req, sender)
        local data = ""
        for alias, id in pairs(Aliases) do
            if id == req[2] then
                data = data .. alias .. "\n"
            end
        end
        Send(data, sender)
        if Properties["Log.Debug"] == "true" then
            debug(data)
        end
    end,
    ['alias_remove_item'] = function (req, sender)
        for alias, id in pairs(Aliases) do
            if id == req[2] then
                Aliases[alias] = nil
            end
        end
        if Properties["Log.Info"] == "true" then
            print("Succesful!")
        end      
        if Properties["Rednet.Response"] == "true" then
            Send("Succesful!", sender)
        end
    end,
    ['alias_remove_alias'] = function (req, sender)
        Aliases[req[2]] = nil
        if Properties["Log.Info"] == "true" then
            print("Succesful!")
        end      
        if Properties["Rednet.Response"] == "true" then
            Send("Succesful!", sender)
        end
    end,
    ['alias_list'] = function (req, sender)
        local data = "";
        for alias, id in pairs(Aliases) do
            data = data .. alias .. " " .. id .. "\n"
        end
        Send(data, sender)
        if Properties["Log.Debug"] == "true" then
            debug(data)
        end
    end,

    
    ['loader_add'] = function (req, sender)
        table.insert(Loaders, { transform(req[2]), transform(req[3]), tonumber(req[4]), transform(req[5]), tonumber(req[6]) })
        if Properties["Log.Info"] == "true" then
            print("Succesful!")
        end      
        if Properties["Rednet.Response"] == "true" then
            Send("Succesful!", sender)
        end
    end,
    ['loader_remove_s'] = function (req, sender)
        local state = "Loader not found!"
        local storage = transform(req[2])
        for i = 1, #Loaders do
            if Loaders[i][1] == storage then
                table.remove(Loaders, i)
                state = "Succesful!"
            end
        end
        if Properties["Log.Info"] == "true" then
            print(state)
        end      
        if Properties["Rednet.Response"] == "true" then
            Send(state, sender)
        end
    end,
    ['loader_remove_si'] = function (req, sender)
        local state = "Loader not found!"
        local storage = transform(req[2])
        local item = transform(req[3])
        for i = 1, #Loaders do
            if Loaders[i][1] == storage and Loaders[i][2] == item then
                table.remove(Loaders, i)
                state = "Succesful!"
                break
            end
        end
        if Properties["Log.Info"] == "true" then
            print(state)
        end      
        if Properties["Rednet.Response"] == "true" then
            Send(state, sender)
        end
    end,
    ['loader_get_si'] = function (req, sender)
        local data = ""
        local storage = transform(req[2])
        local item = transform(req[3])
        for i = 1, #Loaders do
            if Loaders[i][1] == storage and Loaders[i][2] == item then
                data = data .. Loaders
                break
            end
        end
        Send(data, sender)
        if Properties["Log.Debug"] == "true" then
            debug(data)
        end
    end,
    ['loader_get_s'] = function (req, sender)
        local data = ""
        local storage = transform(req[2])
        for i = 1, #Loaders do
            if Loaders[i][1] == storage then
                data = data .. Loaders[i][1] .. " " .. value[2] .. " " .. value[3] .. " " .. value[4] .. " " .. value[5] .. "\n"
                break
            end
        end
        Send(data, sender)
        if Properties["Log.Debug"] == "true" then
            debug(data)
        end
    end,
    ['loader_list'] = function (req, sender)
        local data = "";
        for index, value in pairs(Loaders) do
            data = data .. value[1] .. " " .. value[2] .. " " .. value[3] .. " " .. value[4] .. " " .. value[5] .. "\n"
        end
        Send(data, sender)
        if Properties["Log.Debug"] == "true" then
            debug(data)
        end
    end,


    ['unloader_add'] = function (req, sender)
        table.insert(Unloaders, transform(req[2]))
        if Properties["Log.Info"] == "true" then
            print("Succesful!")
        end      
        if Properties["Rednet.Response"] == "true" then
            Send("Succesful!", sender)
        end
    end,
    ['unloader_remove'] = function (req, sender)
        local state = "Unloader not found!"
        local storage = transform(req[2])
        for i = 1, #Unloaders do
            if Unloaders[i] == storage then
                table.remove(Unloaders, i)
                state = "Succesful!"
                break
            end
        end
        if Properties["Log.Info"] == "true" then
            print(state)
        end      
        if Properties["Rednet.Response"] == "true" then
            Send(state, sender)
        end
    end,
    ['unloader_list'] = function (req, sender)
        local data = "";
        for index, value in pairs(Unloaders) do
            data = data .. value .. "\n"
        end
        Send(data, sender)
        if Properties["Log.Debug"] == "true" then
            debug(data)
        end
    end,

    
    ['property_set'] = function (req, sender)
        Properties[req[2]] = req[3]
        SaveProperties()
        if Properties["Log.Info"] == "true" then
            print("Succesful!")
        end      
        if Properties["Rednet.Response"] == "true" then
            Send("Succesful!", sender)
        end
    end,
    ['property_remove'] = function (req, sender)
        Properties[req[2]] = nil
        if Properties["Log.Info"] == "true" then
            print("Succesful!")
        end      
        if Properties["Rednet.Response"] == "true" then
            Send("Succesful!", sender)
        end
    end,
    ['property_list'] = function (req, sender)
        local data = "";
        for key, value in pairs(Properties) do
            data = data .. key .. " " .. value .. "\n"
        end
        Send(data, sender)
        if Properties["Log.Debug"] == "true" then
            debug(data)
        end
    end,

    ['exit'] = function (req, sender)
        run = false
    end,
}

local function RunRequest(request)
    if Properties["Log.Info"] == "true" then
        print("Request: " ..  request[1] .. " From: " .. request[2])
    end
    local frag = split(request[1], " ")
    types[frag[1]](frag, request[2]);
end



Load()
RednetStart()

while run do
    local start = os.clock()
    os.queueEvent("tick")
    os.pullEvent()
    Items = GetDatabase()

    if Properties["Server.Requests"] == "true" then
        ServerUpdate()
    end
    RednetUpdate()

    local tick = tonumber(Properties["Tick"])
    if not tick then
        if Properties["Log.Warnings"] == "true" then
            warning("Tick is NaN!")
        end
        tick = 1
    end

    while #Requests ~= 0 do
        RunRequest(Requests[1])
        table.remove(Requests, 1)
    end

    local dt = os.clock() - start
    local step = math.max(tick, dt)
    local delay = math.max(0, tick - dt)

    if Properties["Log.Debug"] == "true" then
        debug(dt)
    end

    Deliver(dt)
    Save()

    sleep(delay)
end
RednetEnd()