assert(require("utils/network"))

local args = { ... }


if #args < 1 or args[1] == "help" then 
    textutils.pagedPrint(
    [[
        alias help - print this text
        alias list - returns list of aliases
        alias list <path> - returns list of aliases and saves it to file
        alias add <item> <alias> - adding of alias <alias> to id <item> 
        alias get <item> - get aliases for item <item>
        alias remove i <item> - delete all aliases of <item>
        alias remove a <alias> - delete alias <alias>
    ]], 15)

elseif args[1] == "list" then
    -- List of aliases
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
    --Add alias
    if #args ~= 3 then
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end
    
    local response = Send("alias_add " .. args[3] .. " " .. args[2], true)
    if Properties["Log.Info"] == "true" then
        print(response)
    end

elseif args[1] == "remove" then
    --Delete alias
    if #args ~= 3 then
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end
    if args[2] == "i" then
        local response = Send("alias_remove_item " .. args[2], true)
        if Properties["Log.Info"] == "true" then
            print(response)
        end
    elseif args[2] == "a" then
        local response = Send("alias_remove_alias " .. args[2], true)
        if Properties["Log.Info"] == "true" then
            print(response)
        end
    else
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end
elseif args[1] == "get" then
    --Get alias
    if #args ~= 2 then
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end
    local data = Send("alias_get " .. args[2], true)
    textutils.pagedPrint(data, 15)
end