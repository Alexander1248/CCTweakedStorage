assert(require("utils/network"))

local args = { ... }


if #args < 1 or args[1] == "help" then 
    textutils.pagedPrint(
    [[
    output help - print this text
    output add <name> <id> - add input to storage system by name and id
    output remove <name> - remove input from storage system by name
    output list - print list of inputs
    output list <path> - write list of inputs to file
    ]], 15)

elseif args[1] == "list" then
    -- List of outputs
    
    local data = Send("output_list", true)
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
    --Add output
    if #args ~= 3 then 
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end
    local response = Send("output_add " .. args[2] .. " " .. args[3], true)
    if Properties["Log.Info"] == "true" then
        print(response)
    end
elseif args[1] == "remove" then
    --Delete output
    if #args ~= 2 then 
        if Properties["Log.Warnings"] == "true" then
            warning("Wrong command!")
        end
        return
    end
    local response = Send("output_remove " .. args[2], true)
    if Properties["Log.Info"] == "true" then
        print(response)
    end
end