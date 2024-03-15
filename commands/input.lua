assert(require("utils/network"))

local args = { ... }


if #args < 1 or args[1] == "help" then 
    textutils.pagedPrint(
    [[
    input help - print this text
    input add <id> - add input to storage system by id
    input remove <id> - remove input from storage system by id
    input list - print list of inputs
    input list <path> - write list of inputs to file
    ]], 15)

elseif args[1] == "list" then
    -- List of inputs
    
    local data = Send("input_list", true)
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
    --Add input
    if #args ~= 2 then 
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end
    local response = Send("input_add " .. args[2], true)
    if Properties["Log.Info"] == "true" then
        print(response)
    end
elseif args[1] == "remove" then
    --Delete input
    if #args ~= 2 then 
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end
    local response = Send("input_remove " .. args[2], true)
    if Properties["Log.Info"] == "true" then
        print(response)
    end
end