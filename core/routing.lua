local function findItemSlotsInStorage(name)
    local slots = {}

    for i = 1, #Storages do 
        local items = peripheral.wrap(Storages[i]).list();
        for slot, item in pairs(items) do
            if item["name"] == name and slot ~= nil then
                table.insert(slots, {Storages[i], slot })
            end
        end
    end

    return slots
end

local function findItemSlotsInInput(name)
    local slots = {}

    for index, inputName in pairs(Inputs) do
        local items = peripheral.wrap(inputName).list();
        for slot, item in pairs(items) do
            if item["name"] == name and slot ~= nil then
                table.insert(slots, {inputName, slot })
            end
        end
    end

    return slots
end

function GetDatabase()
    local db = {}

    for i = 1, #Storages do 
        local items = peripheral.wrap(Storages[i]).list();
        for slot, item in pairs(items) do
            local name = item["name"]
            if db[name] == nil then
                db[name] = item["count"]
            else
                db[name] = db[name] + item["count"]
            end
        end
    end
    return db
end

function Deliver(countMul)
    for k, v in pairs(Loaders) do
        local count = 0
        if Items[v[4]] ~= nil then 
            count = Items[v[4]]
        end

        if peripheral.isPresent(v[1]) and count < v[5] then
            local slots = findItemSlotsInStorage(v[2])
            if #slots > 0 then 
                local used = v[3] * countMul
                local chest = peripheral.wrap(slots[1][1])
                local size = chest.list()[slots[1][2]]["count"]
                local placementSize = chest.pushItems(v[1], slots[1][2], math.min(used, size))
                used = used - placementSize
                size = size - placementSize
            
            
                while #slots > 0 and size <= 0 do 
                    table.remove(slots, 1)
                    if #slots > 0 then 
                        chest = peripheral.wrap(slots[1][1]);
                        size = chest.list()[slots[1][2]]["count"]
                
                        placementSize = chest.pushItems(v[1], slots[1][2], math.min(used, size))
                        used = used - placementSize
                        size = size - placementSize
                    end
                end
            end
        end
    end

    for k, v in pairs(Unloaders) do
        if peripheral.isPresent(v) then
            local chest = peripheral.wrap(v);
            local items = chest.list();
        
            for i = 1, #items do
                local size = items[i]["count"]
                for j = 1, #Storages do 
                    local placementSize = chest.pushItems(Storages[j], i, size)
                    size = size - placementSize
        
                    if size <= 0 then break end
                end
            end
        end
    end
end

function AddItem(name, count)
    local slots = findItemSlotsInInput(name)
    if #slots > 0 then 
        local itemCount = 0
        for i = 1, #slots do
            local ioChest = peripheral.wrap(slots[i][1]);
            local items = ioChest.list();
            itemCount = itemCount + items[slots[i][2]]["count"]
        end

        if count > itemCount then return "Not enough items" end


        local used = count

        local ioChest = peripheral.wrap(slots[1][1]);
        local items = ioChest.list();
        local size = items[slots[1][2]]["count"]
        for i = 1, #Storages do 
        
            local placementSize = ioChest.pushItems(Storages[i], slots[1][2], math.min(used, size))
            used = used - placementSize
            size = size - placementSize

            if used <= 0 then break end

            while #slots > 0 and size <= 0 do 
                table.remove(slots, 1)
                if #slots > 0 then 
                    ioChest = peripheral.wrap(slots[1][1]);
                    items = ioChest.list();
                    size = items[slots[1][2]]["count"]
                    placementSize = ioChest.pushItems(Storages[i], slots[1][2], math.min(used, size))
                    used = used - placementSize
                    size = size - placementSize
                end
            end
        end
    
        if used == nil or used > 0 then return "Not enough storage space" end
    end

    return "Successful"
end

function AddAllItems()
    for mask, inputName in pairs(Inputs) do
        local ioChest = peripheral.wrap(inputName);
        local items = ioChest.list();
    
        for i = 1, #items do
            local size = items[i]["count"]
            for j = 1, #Storages do 
                local placementSize = ioChest.pushItems(Storages[j], i, size)
                size = size - placementSize
    
                if size <= 0 then break end
            end
        end
    end
    return "Successful"
end

function GetItem(name, count, to)
    local slots = findItemSlotsInStorage(name)
    
    if #slots > 0 then 
        local itemCount = 0;
        for k, v in pairs(slots) do
            itemCount = itemCount + peripheral.wrap(v[1]).list()[v[2]]["count"];
        end

        if count > itemCount then return "Not enough items" end


        local used = count;
        local chest = peripheral.wrap(slots[1][1])
        local size = chest.list()[slots[1][2]]["count"]
        local placementSize = chest.pushItems(Outputs[to], slots[1][2], math.min(used, size))
        used = used - placementSize
        size = size - placementSize


        while #slots > 0 and size <= 0 do 
            table.remove(slots, 1)
            if #slots > 0 then 
                chest = peripheral.wrap(slots[1][1]);
                size = chest.list()[slots[1][2]]["count"]

                placementSize = chest.pushItems(Outputs[to], slots[1][2], math.min(used, size))
                used = used - placementSize
                size = size - placementSize
            end
        end

        if used == nil or used > 0 then return "Not enough storage space" end
    end

    return "Successful"
end
