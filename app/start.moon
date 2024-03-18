basalt = require "basalt"
sha = require "sha2"
require "network"
    

split = (pString, pPattern) ->
    Table = {}  
    fpat = "(.-)" .. pPattern
    last_end = 1
    s, e, cap = pString\find fpat, 1
    while s
        if s ~= 1 or cap ~= ""
            table.insert(Table,cap)
        last_end = e + 1
        s, e, cap = pString\find fpat, last_end
    if last_end <= #pString then
        cap = pString\sub last_end
        table.insert(Table, cap)
    return Table

word_dst = (request, word) ->
    count = 0
    for i = 1, #request - 2
        if word\find request\sub i, i + 2
            count += 1

    return count




theme = {
    FrameBG: colors.lightGray,
    FrameFG: colors.black
}

main = basalt.createFrame()\setTheme(theme)

closeAfterUpdate = false
if not http
    logWarning "HTTP API disabled!"
else
    response = http.get("https://gist.githubusercontent.com/Alexander1248/9cbed5f35877c8ad70982aa3888bcd66/raw")
    code, message = response.getResponseCode()
    if code ~= 200
        logWarning "Update Error! " .. message
    else
        data = response.readAll!
        downloadHash = sha.sha256 data

        program = fs.open shell.getRunningProgram(), "r"
        currentHash = sha.sha256 program.readAll!
        program.close!
        if downloadHash ~= currentHash 
            if Properties["AutoUpdate"] == "true"
                program = fs.open shell.getRunningProgram(), "w"
                program.write data
                program.close!

                shell.execute shell.getRunningProgram!
                return
            else
                update = main\addFrame!
                update\setPosition 1, "parent.h"
                update\setSize "parent.w", 1
                update\setZIndex 100
                update\setBackground colors.yellow
                update\addLabel!\setPosition(1, 1)\setSize("parent.w * 0.7 - 1", 1)\setText("Exists new version!")
                update\addButton!\setPosition("parent.w * 0.7", 1)\setSize("parent.w * 0.3 - 1", 1)\setText("Update")\setBackground(colors.green)\setForeground(colors.black)\onClick(() -> 
                    program = fs.open shell.getRunningProgram!, "w"
                    program.write data
                    program.close!

                    shell.execute shell.getRunningProgram!
                    basalt.stop!
                )
                update\addButton!\setSize(1, 1)\setText("X")\setBackground(update\getBackground!)\setForeground(colors.red)\setPosition("parent.w", 1)\onClick(() -> update\remove!)


data = {}
run = true

windows = {
    main\addFrame!\setPosition(1, 2)\setSize("parent.w", "parent.h - 1"),        -- Item
    main\addFrame!\setPosition(1, 2)\setSize("parent.w", "parent.h - 1")\hide!, -- Alias
    main\addFrame!\setPosition(1, 2)\setSize("parent.w", "parent.h - 1")\hide!, -- Storage
    main\addFrame!\setPosition(1, 2)\setSize("parent.w", "parent.h - 1")\hide!, -- Transfer
    main\addFrame!\setPosition(1, 2)\setSize("parent.w", "parent.h - 1")\hide!, -- Settings
}

menubar = main\addMenubar!\setScrollable!\setSize("parent.w")\onChange((val) => 
    id = @\getItemIndex!
    if not windows[id] return
    for k,v in pairs(windows)
        v\hide!
    windows[id]\show!
)\addItem("Item")\addItem("Alias")\addItem("Storage")\addItem("Transfer")\addItem("Settings")


requestLock = {}
requests = {}
responses = {}

addRequest = (request, state = true) ->
    if requestLock[request] ~= nil return
    requestLock[request] = state
    table.insert requests, request

-- Item window
itemList = windows[1]\addScrollableFrame!
itemList\setPosition "parent.w * 0.1", 5
itemList\setSize "parent.w * 0.8", "parent.h * 0.9"
itemList\setBackground colors.gray

itemSearch = windows[1]\addInput!
itemSearch\setPosition "parent.w * 0.1", 2
itemSearch\setSize "parent.w * 0.5", 1
itemSearch\setInputType "text"

updateItemList = (items) -> 
    searchRequest = itemSearch\getValue!
    table.sort items, (a, b) -> return word_dst(searchRequest, a[1]) > word_dst(searchRequest, b[1])
    itemList\removeChildren!
    for i, v in ipairs items
        item = itemList\addFrame!
        item\setSize "parent.w - 2", 3
        item\setPosition 2, i * 4 - 2
        item\setBackground colors.lightGray
        item\addLabel!\setPosition(1, 1)\setSize("parent.w * 0.4 - 1", 3)\setText(v[1])
        item\addLabel!\setPosition("1 + parent.w * 0.4", 1)\setSize("parent.w * 0.4 - 2", 3)\setText(tostring(v[2]))
        item\addButton!\setPosition("1 + parent.w * 0.8", 1)\setSize("parent.w * 0.1", 3)\setText("+")\setBackground(colors.green)\setForeground(colors.black)\onClick(
            (event, button, x, y) =>
            if event=="mouse_click" and button==1
                frame = windows[1]\addMovableFrame!
                frame\setPosition "parent.w * 0.2", "parent.h * 0.3"
                frame\setSize("parent.w * 0.6", "parent.w * 0.3")
                frame\addLabel!\setSize("parent.w", 1)\setBackground(colors.black)\setForeground(colors.lightGray)\setText("Add item")
                frame\addButton!\setSize(1, 1)\setText("X")\setBackground(colors.black)\setForeground(colors.red)\setPosition("parent.w - 1", 1)\onClick(() -> frame\remove())
                
                frame\addLabel!\setPosition(1, "parent.h * 0.25")\setSize("parent.w * 0.3", 1)\setText("Count")
                countInput = frame\addInput!\setPosition("parent.w * 0.3", "parent.h * 0.25")\setSize("parent.w * 0.7", 1)\setInputType("number")
                
                execute = frame\addButton!\setPosition("parent.w * 0.3", "parent.h * 0.75")\setSize("parent.w * 0.4", 3)\setText("Execute")
                execute\setBackground(colors.red)\setForeground(colors.black)
                execute\onClick (event, button, x, y) =>
                    if event=="mouse_click" and button==1
                        count = tonumber countInput\getValue!
                        if not count return
                        addRequest("item_add " .. v[1] .. " " .. count)
                        addRequest("item_list")
                        frame\remove()
            
        )
        item\addButton!\setPosition("1 + parent.w * 0.9", 1)\setSize("parent.w * 0.1", 3)\setText("-")\setBackground(colors.red)\setForeground(colors.black)\onClick(
            (event, button, x, y) =>
            if event=="mouse_click" and button==1
                frame = windows[1]\addMovableFrame!
                frame\setPosition "parent.w * 0.2", "parent.h * 0.3"
                frame\setSize("parent.w * 0.6", "parent.w * 0.3")
                frame\addLabel!\setSize("parent.w", 1)\setBackground(colors.black)\setForeground(colors.lightGray)\setText("Add item")
                frame\addButton!\setSize(1, 1)\setText("X")\setBackground(colors.black)\setForeground(colors.red)\setPosition("parent.w - 1", 1)\onClick(() -> frame\remove())
                
                frame\addLabel!\setPosition(1, "parent.h * 0.25")\setSize("parent.w * 0.3", 1)\setText("Count")
                countInput = frame\addInput!\setPosition("parent.w * 0.3", "parent.h * 0.25")\setSize("parent.w * 0.7", 1)\setInputType("number")

                frame\addLabel!\setPosition(1, "parent.h * 0.5")\setSize("parent.w * 0.3", 1)\setText("Terminal")
                terminal = frame\addInput!\setPosition("parent.w * 0.3", "parent.h * 0.5")\setSize("parent.w * 0.7", 1)
                
                execute = frame\addButton!\setPosition("parent.w * 0.3", "parent.h * 0.75")\setSize("parent.w * 0.4", 3)\setText("Execute")
                execute\setBackground(colors.red)\setForeground(colors.black)
                execute\onClick (event, button, x, y) =>
                    if event=="mouse_click" and button==1
                        count = tonumber countInput\getValue!
                        if not count return
                        if v[2] < count return
                        addRequest("item_get " .. v[1] .. " " .. count .. " " .. terminal\getValue!)
                        addRequest("item_list")
                        frame\remove()
            
        )
itemSearch\onChange (val) =>       
    addRequest("item_list")
    items = data.items
    if not items return
    updateItemList items
        

addAll = windows[1]\addButton!
addAll\setPosition "parent.w * 0.7", 2
addAll\setSize "parent.w * 0.2", 1
addAll\setText "Add All"
addAll\onClick (event, button, x, y) =>
    if event=="mouse_click" and button==1
        addRequest("item_add_all")
        addRequest("item_list")

  

-- Alias window
aliasList = windows[2]\addScrollableFrame!
aliasList\setPosition "parent.w * 0.1", 5
aliasList\setSize "parent.w * 0.8", "parent.h * 0.9"
aliasList\setBackground colors.gray



aliasSearch = windows[2]\addInput!
aliasSearch\setPosition "parent.w * 0.1", 2
aliasSearch\setSize "parent.w * 0.5", 1
aliasSearch\setInputType "text"

updateAliasList = (aliases) ->
    searchRequest = aliasSearch\getValue!
    table.sort aliases, (a, b) -> 
        if not a or not b then return false
        return word_dst(searchRequest, a[1]) > word_dst(searchRequest, b[1]) or word_dst(searchRequest, a[2]) > word_dst(searchRequest, b[2]) 
    aliasList\removeChildren!
    for i, v in ipairs aliases
        item = aliasList\addFrame!
        item\setSize "parent.w - 2", 3
        item\setPosition 2, i * 4 - 2
        item\setBackground colors.lightGray
        item\addLabel!\setPosition(1, 1)\setSize("parent.w * 0.45", 3)\setText(v[1])
        item\addLabel!\setPosition("1 + parent.w * 0.45", 1)\setSize("parent.w * 0.45 - 2", 3)\setText(tostring(v[2]))
        item\addButton!\setPosition("1 + parent.w * 0.9", 1)\setSize("parent.w * 0.1", 3)\setText("-")\setBackground(colors.red)\setForeground(colors.black)\onClick(
            (event, button, x, y) =>
            if event=="mouse_click" and button==1
                addRequest("alias_remove_alias " .. v[1])
                addRequest("alias_list")
            
        )
aliasSearch\onChange (val) =>    
    addRequest("alias_list")
    aliases = data.aliases
    if not aliases return
    updateAliasList aliases
        

add = windows[2]\addButton!
add\setPosition "parent.w * 0.7", 2
add\setSize "parent.w * 0.2", 1
add\setText "Add"
add\onClick (event, button, x, y) =>
    if event=="mouse_click" and button==1
        frame = windows[2]\addMovableFrame!
        frame\setPosition "parent.w * 0.2", "parent.h * 0.3"
        frame\setSize("parent.w * 0.6", "parent.w * 0.3")
        frame\addLabel!\setSize("parent.w", 1)\setBackground(colors.black)\setForeground(colors.lightGray)\setText("Add alias")
        frame\addButton!\setSize(1, 1)\setText("X")\setBackground(colors.black)\setForeground(colors.red)\setPosition("parent.w - 1", 1)\onClick(() -> frame\remove())
        
        frame\addLabel!\setPosition(1, "parent.h * 0.25")\setSize("parent.w * 0.3", 1)\setText("Alias")
        alias = frame\addInput!\setPosition("parent.w * 0.3", "parent.h * 0.25")\setSize("parent.w * 0.7", 1)

        frame\addLabel!\setPosition(1, "parent.h * 0.5")\setSize("parent.w * 0.3", 1)\setText("Item")
        item = frame\addInput!\setPosition("parent.w * 0.3", "parent.h * 0.5")\setSize("parent.w * 0.7", 1)
        
        execute = frame\addButton!\setPosition("parent.w * 0.3", "parent.h * 0.75")\setSize("parent.w * 0.4", 3)\setText("Execute")
        execute\setBackground(colors.red)\setForeground(colors.black)
        execute\onClick (event, button, x, y) =>
            if event=="mouse_click" and button==1
                addRequest("alias_add " .. alias\getValue! .. " " .. item\getValue!)
                addRequest("alias_list")
                frame\remove()


-- Storage window
storageList = windows[3]\addScrollableFrame!
storageList\setPosition "parent.w * 0.1", 5
storageList\setSize "parent.w * 0.8", "parent.h * 0.9"
storageList\setBackground colors.gray

storageListSelector = windows[3]\addDropdown!
storageListSelector\setZIndex 100
storageListSelector\setPosition "parent.w * 0.1", 2
storageListSelector\setSize "parent.w * 0.5", 1
storageListSelector\addItem "Input"
storageListSelector\addItem "Storage"
storageListSelector\addItem "Output"


updateStorageList = ->
    database = nil
    listOp = nil
    removeOp = nil
    segmented = false
    switch storageListSelector\getItemIndex!
        when 1
            database = data.inputs
            removeOp = "input_remove "
            listOp = "input_list"
            segmented = false
        when 2
            database = data.storages
            removeOp = "storage_remove "
            listOp = "storage_list"
            segmented = false

        when 3
            database = data.outputs
            removeOp = "output_remove "
            listOp = "output_list"
            segmented = true

    if not database return
    storageList\removeChildren!
    for i, v in ipairs database
        item = storageList\addFrame!
        item\setSize "parent.w - 2", 3
        item\setPosition 2, i * 4 - 2
        item\setBackground colors.lightGray
        if segmented
            item\addLabel!\setPosition(1, 1)\setSize("parent.w * 0.45", 3)\setText(v[1])
            item\addLabel!\setPosition("1 + parent.w * 0.45", 1)\setSize("parent.w * 0.45 - 2", 3)\setText(tostring(v[2]))
        else
            item\addLabel!\setPosition(1, 1)\setSize("parent.w * 0.9", 3)\setText(v)
        item\addButton!\setPosition("1 + parent.w * 0.9", 1)\setSize("parent.w * 0.1", 3)\setText("-")\setBackground(colors.red)\setForeground(colors.black)\onClick(
        (event, button, x, y) =>
            if event=="mouse_click" and button==1
                if segmented 
                    addRequest(removeOp .. v[1])
                else 
                    addRequest(removeOp .. v)
                addRequest(listOp)
        )

storageListSelector\onChange (item) =>
    switch storageListSelector\getItemIndex!
        when 1
            addRequest("input_list")
        when 2
            addRequest("storage_list")
        when 3
            addRequest("output_list")
    updateStorageList!
    

add = windows[3]\addButton!
add\setPosition "parent.w * 0.7", 2
add\setSize "parent.w * 0.2", 1
add\setText "Add"
add\onClick (event, button, x, y) =>
    if event=="mouse_click" and button==1
        frame = windows[3]\addMovableFrame!
        frame\setPosition "parent.w * 0.2", "parent.h * 0.3"
        frame\setSize("parent.w * 0.6", "parent.w * 0.3")
        frame\addButton!\setSize(1, 1)\setText("X")\setBackground(colors.black)\setForeground(colors.red)\setPosition("parent.w - 1", 1)\onClick(() -> frame\remove())
        switch storageListSelector\getItemIndex!
            when 1
                frame\addLabel!\setSize("parent.w", 1)\setBackground(colors.black)\setForeground(colors.lightGray)\setText("Add input")

                frame\addLabel!\setPosition(1, "parent.h * 0.25")\setSize("parent.w * 0.3", 1)\setText("ID")
                id = frame\addInput!\setPosition("parent.w * 0.3", "parent.h * 0.25")\setSize("parent.w * 0.7", 1)
                
                execute = frame\addButton!\setPosition("parent.w * 0.3", "parent.h * 0.75")\setSize("parent.w * 0.4", 3)\setText("Execute")
                execute\setBackground(colors.red)\setForeground(colors.black)
                execute\onClick (event, button, x, y) =>
                    if event=="mouse_click" and button==1
                        addRequest("input_add " .. id\getValue!)
                        addRequest("input_list")
                        frame\remove()
            when 2
                frame\addLabel!\setSize("parent.w", 1)\setBackground(colors.black)\setForeground(colors.lightGray)\setText("Add storage")

                frame\addLabel!\setPosition(1, "parent.h * 0.25")\setSize("parent.w * 0.3", 1)\setText("ID")
                id = frame\addInput!\setPosition("parent.w * 0.3", "parent.h * 0.25")\setSize("parent.w * 0.7", 1)
                
                execute = frame\addButton!\setPosition("parent.w * 0.3", "parent.h * 0.75")\setSize("parent.w * 0.4", 3)\setText("Execute")
                execute\setBackground(colors.red)\setForeground(colors.black)
                execute\onClick (event, button, x, y) =>
                    if event=="mouse_click" and button==1
                        addRequest("storage_add " .. id\getValue!)
                        addRequest("storage_list")
                        frame\remove()
            when 3
                frame\addLabel!\setSize("parent.w", 1)\setBackground(colors.black)\setForeground(colors.lightGray)\setText("Add output")

                frame\addLabel!\setPosition(1, "parent.h * 0.25")\setSize("parent.w * 0.3", 1)\setText("Name")
                name = frame\addInput!\setPosition("parent.w * 0.3", "parent.h * 0.25")\setSize("parent.w * 0.7", 1)

                frame\addLabel!\setPosition(1, "parent.h * 0.5")\setSize("parent.w * 0.3", 1)\setText("ID")
                id = frame\addInput!\setPosition("parent.w * 0.3", "parent.h * 0.5")\setSize("parent.w * 0.7", 1)
                
                execute = frame\addButton!\setPosition("parent.w * 0.3", "parent.h * 0.75")\setSize("parent.w * 0.4", 3)\setText("Execute")
                execute\setBackground(colors.red)\setForeground(colors.black)
                execute\onClick (event, button, x, y) =>
                    if event=="mouse_click" and button==1
                        addRequest("output_add " .. name\getValue! .. " " .. id\getValue!)
                        addRequest("output_list")
                        frame\remove()
        


-- Transfer window
transferList = windows[4]\addScrollableFrame!
transferList\setPosition "parent.w * 0.1", 5
transferList\setSize "parent.w * 0.8", "parent.h * 0.9"
transferList\setBackground colors.gray

transferListSelector = windows[4]\addDropdown!
transferListSelector\setZIndex 100
transferListSelector\setPosition "parent.w * 0.1", 2
transferListSelector\setSize "parent.w * 0.5", 1
transferListSelector\addItem "Loaders"
transferListSelector\addItem "Unloaders"


updateTransferList = ->
    switch transferListSelector\getItemIndex!
        when 1
            database = data.loaders
            if not database return
            transferList\removeChildren!
            for i, v in ipairs database
                item = transferList\addFrame!
                item\setSize "parent.w - 2", 6
                item\setPosition 2, i * 7 - 5
                item\setBackground colors.lightGray
                item\addLabel!\setPosition(1, 1)\setSize("parent.w * 0.87", 3)\setText("to " .. v[1] .. " add " .. v[2] .. " in the amount of ".. tostring(v[3]))
                item\addLabel!\setPosition(1, 4)\setSize("parent.w * 0.87", 3)\setText("if " .. v[4]  .. " less than " .. tostring(v[5]))
                item\addButton!\setPosition("1 + parent.w * 0.9", 1)\setSize("parent.w * 0.1", 6)\setText("-")\setBackground(colors.red)\setForeground(colors.black)\onClick(
                (event, button, x, y) =>
                    if event=="mouse_click" and button==1
                        addRequest("loader_remove_si " .. v[1] .. " " .. v[2])
                        addRequest("loader_list")
                )
        when 2
            database = data.unloaders
            if not database return
            transferList\removeChildren!
            for i, v in ipairs database
                item = transferList\addFrame!
                item\setSize "parent.w - 2", 3
                item\setPosition 2, i * 4 - 2
                item\setBackground colors.lightGray
                item\addLabel!\setPosition(1, 1)\setSize("parent.w * 0.9", 3)\setText(v)
                item\addButton!\setPosition("1 + parent.w * 0.9", 1)\setSize("parent.w * 0.1", 3)\setText("-")\setBackground(colors.red)\setForeground(colors.black)\onClick(
                (event, button, x, y) =>
                    if event=="mouse_click" and button==1
                        addRequest("unloader_remove " .. v)
                        addRequest("unloader_list")
                )

    

transferListSelector\onChange (item) =>
    switch transferListSelector\getItemIndex!
        when 1
            addRequest("loader_list")
        when 2
            addRequest("unloader_list")
    updateTransferList!
    

add = windows[4]\addButton!
add\setPosition "parent.w * 0.7", 2
add\setSize "parent.w * 0.2", 1
add\setText "Add"
add\onClick (event, button, x, y) =>
    if event=="mouse_click" and button==1
        frame = windows[4]\addMovableFrame!
        frame\setPosition "parent.w * 0.2", "parent.h * 0.3"
        frame\setSize("parent.w * 0.6", "parent.w * 0.3")
        frame\addButton!\setSize(1, 1)\setText("X")\setBackground(colors.black)\setForeground(colors.red)\setPosition("parent.w - 1", 1)\onClick(() -> frame\remove())
        switch transferListSelector\getItemIndex!
            when 1
                frame\addLabel!\setSize("parent.w", 1)\setBackground(colors.black)\setForeground(colors.lightGray)\setText("Add loader")

                frame\addLabel!\setPosition(1, "parent.h * 0.1429")\setSize("parent.w * 0.3", 1)\setText("Storage")
                storage = frame\addInput!\setPosition("parent.w * 0.3", "parent.h * 0.1429")\setSize("parent.w * 0.7", 1)

                frame\addLabel!\setPosition(1, "parent.h * 0.2857")\setSize("parent.w * 0.3", 1)\setText("Item")
                item = frame\addInput!\setPosition("parent.w * 0.3", "parent.h * 0.2857")\setSize("parent.w * 0.7", 1)

                frame\addLabel!\setPosition(1, "parent.h * 0.4286")\setSize("parent.w * 0.3", 1)\setText("Count")
                count = frame\addInput!\setPosition("parent.w * 0.3", "parent.h * 0.4286")\setSize("parent.w * 0.7", 1)\setInputType("number")

                frame\addLabel!\setPosition(1, "parent.h * 0.5714")\setSize("parent.w * 0.3", 1)\setText("If Item")
                cond_item = frame\addInput!\setPosition("parent.w * 0.3", "parent.h * 0.5714")\setSize("parent.w * 0.7", 1)

                frame\addLabel!\setPosition(1, "parent.h * 0.7143")\setSize("parent.w * 0.3", 1)\setText("Count")
                cond_count = frame\addInput!\setPosition("parent.w * 0.3", "parent.h * 0.7143")\setSize("parent.w * 0.7", 1)\setInputType("number")
                
                execute = frame\addButton!\setPosition("parent.w * 0.3", "parent.h * 0.8571")\setSize("parent.w * 0.4", 3)\setText("Execute")
                execute\setBackground(colors.red)\setForeground(colors.black)
                execute\onClick (event, button, x, y) =>
                    if event=="mouse_click" and button==1
                        if cond_item\getValue! == ""
                            cond_item\setValue "item_not_exists_"
                        if cond_count\getValue! == ""
                            cond_count\setValue "3000000000"
                        addRequest("loader_add " .. storage\getValue! .. " " .. item\getValue! .. " " .. count\getValue! .. " " .. cond_item\getValue! .. " " .. cond_count\getValue! .. " ")
                        addRequest("loader_list")
                        frame\remove()
            when 2
                frame\addLabel!\setSize("parent.w", 1)\setBackground(colors.black)\setForeground(colors.lightGray)\setText("Add unloader")

                frame\addLabel!\setPosition(1, "parent.h * 0.25")\setSize("parent.w * 0.3", 1)\setText("ID")
                id = frame\addInput!\setPosition("parent.w * 0.3", "parent.h * 0.25")\setSize("parent.w * 0.7", 1)
                
                execute = frame\addButton!\setPosition("parent.w * 0.3", "parent.h * 0.75")\setSize("parent.w * 0.4", 3)\setText("Execute")
                execute\setBackground(colors.red)\setForeground(colors.black)
                execute\onClick (event, button, x, y) =>
                    if event=="mouse_click" and button==1
                        addRequest("unloader_add " .. id\getValue!)
                        addRequest("unloader_list")
                        frame\remove()

-- Settings window
settingsList = windows[5]\addScrollableFrame!
settingsList\setPosition "parent.w * 0.1", 5
settingsList\setSize "parent.w * 0.8", "parent.h * 0.9"
settingsList\setBackground colors.gray

settingsListSelector = windows[5]\addDropdown!
settingsListSelector\setZIndex 100
settingsListSelector\setPosition "parent.w * 0.1", 2
settingsListSelector\setSize "parent.w * 0.5", 1
settingsListSelector\addItem "App"
settingsListSelector\addItem "Server"


updateSettingsList = ->
    database = switch settingsListSelector\getItemIndex!
        when 1
            Properties
        when 2
            data.properties 

    if not database return
    settingsList\removeChildren!
    y = 2
    for k, v in pairs database
        item = settingsList\addFrame!
        item\setSize "parent.w - 2", 1
        item\setPosition 2, y
        item\setBackground colors.lightGray
        item\addLabel!\setPosition(1, 1)\setSize("parent.w * 0.5", 1)\setText(k)
        valueInput = item\addInput!\setPosition("1 + parent.w * 0.5", 1)\setSize("parent.w * 0.5", 1)\setValue(v)
        valueInput\onChange (val) => 
            switch settingsListSelector\getItemIndex!
                when 1
                    Properties[k] = valueInput\getValue!

                    pwd = fs.getDir shell.getRunningProgram!
                    file = fs.open pwd .. "/config.properties", "w"
                    for key, value in pairs Properties
                        file.writeLine key .. ": " .. value
                    file.flush()
                    file.close()
                when 2
                    addRequest("property_set " .. k .. " " .. valueInput\getValue!)
                    addRequest("property_list")

        y += 2

    
settingsListSelector\onChange (item) =>
    if settingsListSelector\getItemIndex! == 2
        addRequest("property_list")
    updateSettingsList!
    

logFrame = main\addMovableFrame!
logFrame\hide!
logFrame\setPosition "parent.w * 0.1", "parent.h * 0.1"
logFrame\setSize("parent.w * 0.8", "parent.h * 0.8")
logFrame\addLabel!\setSize("parent.w", 1)\setBackground(colors.black)\setForeground(colors.lightGray)\setText("Log")
logFrame\addButton!\setSize(1, 1)\setText("X")\setBackground(colors.black)\setForeground(colors.red)\setPosition("parent.w - 1", 1)\onClick(() -> logFrame\hide!)
logField = logFrame\addTextfield!
logField\setPosition 1, 2
logField\setSize("parent.w", "parent.h - 1")

updateLog = () ->
    while #Lines > 0
        logField\addLine Lines[1]
        table.remove Lines, 1

log = windows[5]\addButton!
log\setPosition "parent.w * 0.7", 2
log\setSize "parent.w * 0.2", 1
log\setText "Log"
log\onClick (event, button, x, y) =>
    if event=="mouse_click" and button==1
        logFrame\show!

-- Network     
networking = main\addThread! 
networking\start () -> 
    while run
        if #requests > 0
            request = requests[1]
            table.remove requests, 1
            response = Send request, requestLock[request]
            responses[request] = response
            requestLock[request] = nil
            updateLog!
    
        if responses["storage_list"] 
            response = responses["storage_list"]
            responses["storage_list"] = nil
    
            database = {}
            lines = split response, "\n"
            for i, v in ipairs lines
                if v == "" continue
                table.insert database, v -- storage
            data.storages = database
            updateStorageList!
    
        if responses["input_list"] 
            response = responses["input_list"]
            responses["input_list"] = nil
            
            database = {}
            lines = split response, "\n"
            for i, v in ipairs lines
                if v == "" continue
                table.insert database, v -- storage
            data.inputs = database
            updateStorageList!
            
        if responses["output_list"]
            response = responses["output_list"]
            responses["output_list"] = nil
    
            outputs = {}
            lines = split response, "\n"
            for i, v in ipairs lines
                if v == "" continue
                segments = split v, " "
                table.insert outputs, { segments[1], segments[2] } -- name, storage
            data.outputs = outputs
            updateStorageList!
    
        if responses["item_list"]
            response = responses["item_list"]
            responses["item_list"] = nil
    
            items = {}
            lines = split response, "\n"
            for i, v in ipairs lines
                if v == "" continue
                segments = split v, " "
                table.insert items, { segments[1], tonumber(segments[2]) } -- item_id, count
            data.items = items
            updateItemList items
            
        if responses["alias_list"]
            response = responses["alias_list"]
            responses["alias_list"] = nil
    
            aliases = {}
            lines = split response, "\n"
            for i, v in ipairs lines
                if v == "" continue
                segments = split v, " "
                table.insert aliases, { segments[1], segments[2] } -- alias, id
            data.aliases = aliases
            updateAliasList aliases
    
        if responses["loader_list"]
            response = responses["loader_list"]
            responses["loader_list"] = nil
                
            loaders = {}
            lines = split response, "\n"
            for i, v in ipairs lines
                if v == "" continue
                segments = split v, " "
                table.insert loaders, { segments[1], segments[2], tonumber(segments[3]), segments[4], tonumber(segments[5]) } -- storage_id, item_id, count, condition_item_id, condition_count
            data.loaders = loaders
            updateTransferList!
    
        if responses["unloader_list"]
            response = responses["unloader_list"]
            responses["unloader_list"] = nil
                
            unloaders = {}
            lines = split response, "\n"
            for i, v in ipairs lines
                if v == "" continue
                table.insert unloaders, v -- storage_id
            data.unloaders = unloaders
            updateTransferList!
            
        if responses["property_list"]
            response = responses["property_list"]
            responses["property_list"] = nil
                
            properties = {}
            lines = split response, "\n"
            for i, v in ipairs lines
                if v == "" continue
                segments = split v, " "
                properties[segments[1]] = segments[2] -- key, value
            data.properties = properties
            updateSettingsList!
        sleep 1


addRequest("storage_list")
addRequest("input_list")
addRequest("output_list")
addRequest("item_list")
addRequest("alias_list")
addRequest("loader_list")
addRequest("unloader_list")
addRequest("property_list")


basalt.autoUpdate()
