assert(require("utils/network"))
local args = { ... }

if #args < 1 or args[1] == "help" then 
    textutils.pagedPrint(
    [[
    loader help - print this text
    loader list - returns list of loaders
    loaders list <path> - returns list of loaders and saves it to file
    loader add <storage> <item> <count> <condition_item> <condition_count> - loader adding
    loader get <storage> - get all loaders of <storage>
    loader get <storage> <item> - get loader of <storage> for <item>
    loader remove <storage> - delete all loaders of <storage>
    loader remove <storage> <item> - delete loader of <storage> for <item>
    ]], 15)

elseif args[1] == "list" then
    -- List of pollers
    local data = Send("alias_list", true)
    if #args == 1 then 
        textutils.pagedPrint(data, 15)
    elseif #args == 2 then
        if data then
            local file = fs.open(args[2], "w")
            file.write(data)
            file.flush()
        end
    else
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end

elseif args[1] == "add" then
    if #args ~= 6 then 
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end

    local response = Send("loader_add " .. args[2] .. " " .. args[3] .. " " .. args[4] .. " " .. args[5] .. " " .. args[6], true)
    if Properties["Log.Info"] == "true" then
        print(response)
    end

elseif args[1] == "get" then
    if #args == 2 then 
        local response = Send("loader_get_s " .. args[2], true)
        textutils.pagedPrint(response, 15)
    elseif #args == 3 then
        local response = Send("loader_get_si " .. args[2] .. " " .. args[3], true)
        print(response)
    else
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end
elseif args[1] == "remove" then
    if #args == 2 then 
        local response = Send("loader_remove_s " .. args[2], true)
        if Properties["Log.Info"] == "true" then
            print(response)
        end
    elseif #args == 3 then
        local response = Send("loader_remove_si " .. args[2] .. " " .. args[3], true)
        if Properties["Log.Info"] == "true" then
            print(response)
        end
    else
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end
end

