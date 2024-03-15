assert(require("utils/network"))

local args = { ... }


if #args < 1 or args[1] == "help" then 
    textutils.pagedPrint(
    [[
    storage help - print this text
    storage add <id> - add storage to storage system by id
    storage remove <id> - remove storage from storage system by id
    storage list - print list of storages
    storage list <path> - write list of storages to file
    ]], 15)

elseif args[1] == "list" then
    -- List of storages
    
    local data = Send("storage_list", true)
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
    --Add storage
    if #args ~= 2 then
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end
    local response = Send("storage_add " .. args[2], true)
    if Properties["Log.Info"] == "true" then
        print(response)
    end
elseif args[1] == "remove" then
    --Delete storage
    if #args ~= 2 then 
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end
    local response = Send("storage_remove " .. args[2], true)
    if Properties["Log.Info"] == "true" then
        print(response)
    end
end