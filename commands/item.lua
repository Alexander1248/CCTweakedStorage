assert(require("utils/network"))

local args = { ... }


if #args < 1 or args[1] == "help" then 
    textutils.pagedPrint(
    [[
        item help - print this text
        item list - returns list of items 
        item list <path> - returns list of items and saves it to file
        item count <item> - returns count of item <item> 
        item add all - adds all items to Storage from IO
        item add <item> <count> - adding of item with id <item> to Storage from IO in the amount of <count>
        item get <item> <count> <terminal> - geting of item with id <item> from Storage to IO in the amount of <count>
    ]], 15)

elseif args[1] == "list" then
    -- List of items
    local data = Send("item_list", true)
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
elseif args[1] == "count" then
    if #args ~= 2 then
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end

    local data = Send("item_count " .. args[2], true)
    if data then
        print(args[2] .. " - " .. data)
    end

elseif args[1] == "add" then
    if #args < 2 then
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end

    if args[2] == "all" then
        --Add all items
        local response = Send("item_add_all", true)
        if Properties["Log.Info"] == "true" then
            print(response)
        end
    else
        --Add item
        if #args ~= 3 then 
            print("Wrong command!")
            return
        end
        local response = Send("item_add " .. args[2] .. " " .. args[3], true)
        if Properties["Log.Info"] == "true" then
            print(response)
        end
    end

elseif args[1] == "get" then
    --Get item
    if #args ~= 4 then
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end
    local response = Send("item_get " .. args[2] .. " " .. args[3] .. " " .. args[4], true)
    if Properties["Log.Info"] == "true" then
        print(response)
    end
end