assert(require("utils/network"))
local args = { ... }

if #args < 1 or args[1] == "help" then 
    textutils.pagedPrint(
    [[
    unloader help - print this text
    unloader list - returns list of unloaders
    unloader list <path> - returns list of unloaders and saves it to file
    unloader add <storage> - unloader adding
    unloader remove <storage> - remove unloader
    ]], 15)

elseif args[1] == "list" then
    -- List of pollers
    local data = Send("unloader_list", true)
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
    if #args ~= 2 then
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end

    local response = Send("unloader_add " .. args[2], true)
    if Properties["Log.Info"] == "true" then
        print(response)
    end
elseif args[1] == "remove" then
    if #args ~= 2 then
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end

    local response = Send("unloader_remove " .. args[2], true)
    if Properties["Log.Info"] == "true" then
        print(response)
    end
end

