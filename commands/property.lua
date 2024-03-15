assert(require("utils/network"))

local args = { ... }


if #args < 1 or args[1] == "help" then 
    textutils.pagedPrint(
    [[
    property help - print this text
    property set <key> <value> - add property to property system by id
    property remove <key> - remove property from property system by id
    property list - print list of properties
    property list <path> - write list of properties to file
    ]], 15)

elseif args[1] == "list" then
    -- List of storages
    
    local data = Send("property_list", true)
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
    
elseif args[1] == "set" then
    --Add storage
    if #args ~= 3 then
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end
    local response = Send("property_set " .. args[2] .. " " .. args[3], true)
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
    local response = Send("property_remove " .. args[2], true)
    if Properties["Log.Info"] == "true" then
        print(response)
    end
end