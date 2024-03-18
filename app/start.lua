local basalt = require("basalt")
local sha = require("sha2")
require("network")
local split
split = function(pString, pPattern)
  local Table = { }
  local fpat = "(.-)" .. pPattern
  local last_end = 1
  local s, e, cap = pString:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
      table.insert(Table, cap)
    end
    last_end = e + 1
    s, e, cap = pString:find(fpat, last_end)
  end
  if last_end <= #pString then
    cap = pString:sub(last_end)
    table.insert(Table, cap)
  end
  return Table
end
local word_dst
word_dst = function(request, word)
  local count = 0
  for i = 1, #request - 2 do
    if word:find(request:sub(i, i + 2)) then
      count = count + 1
    end
  end
  return count
end
local theme = {
  FrameBG = colors.lightGray,
  FrameFG = colors.black
}
local main = basalt.createFrame():setTheme(theme)
local closeAfterUpdate = false
if not http then
  logWarning("HTTP API disabled!")
else
  local response = http.get("https://gist.githubusercontent.com/Alexander1248/9cbed5f35877c8ad70982aa3888bcd66/raw")
  local code, message = response.getResponseCode()
  if code ~= 200 then
    logWarning("Update Error! " .. message)
  else
    local data = response.readAll()
    local downloadHash = sha.sha256(data)
    local program = fs.open(shell.getRunningProgram(), "r")
    local currentHash = sha.sha256(program.readAll())
    program.close()
    if downloadHash ~= currentHash then
      if Properties["AutoUpdate"] == "true" then
        program = fs.open(shell.getRunningProgram(), "w")
        program.write(data)
        program.close()
        shell.execute(shell.getRunningProgram())
        return 
      else
        local update = main:addFrame()
        update:setPosition(1, "parent.h")
        update:setSize("parent.w", 1)
        update:setZIndex(100)
        update:setBackground(colors.yellow)
        update:addLabel():setPosition(1, 1):setSize("parent.w * 0.7 - 1", 1):setText("Exists new version!")
        update:addButton():setPosition("parent.w * 0.7", 1):setSize("parent.w * 0.3 - 1", 1):setText("Update"):setBackground(colors.green):setForeground(colors.black):onClick(function()
          program = fs.open(shell.getRunningProgram(), "w")
          program.write(data)
          program.close()
          shell.execute(shell.getRunningProgram())
          return basalt.stop()
        end)
        update:addButton():setSize(1, 1):setText("X"):setBackground(update:getBackground()):setForeground(colors.red):setPosition("parent.w", 1):onClick(function()
          return update:remove()
        end)
      end
    end
  end
end
local data = { }
local run = true
local windows = {
  main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"),
  main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"):hide(),
  main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"):hide(),
  main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"):hide(),
  main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"):hide()
}
local menubar = main:addMenubar():setScrollable():setSize("parent.w"):onChange(function(self, val)
  local id = self:getItemIndex()
  if not windows[id] then
    return 
  end
  for k, v in pairs(windows) do
    v:hide()
  end
  return windows[id]:show()
end):addItem("Item"):addItem("Alias"):addItem("Storage"):addItem("Transfer"):addItem("Settings")
local requestLock = { }
local requests = { }
local responses = { }
local addRequest
addRequest = function(request, state)
  if state == nil then
    state = true
  end
  if requestLock[request] ~= nil then
    return 
  end
  requestLock[request] = state
  return table.insert(requests, request)
end
local itemList = windows[1]:addScrollableFrame()
itemList:setPosition("parent.w * 0.1", 5)
itemList:setSize("parent.w * 0.8", "parent.h * 0.9")
itemList:setBackground(colors.gray)
local itemSearch = windows[1]:addInput()
itemSearch:setPosition("parent.w * 0.1", 2)
itemSearch:setSize("parent.w * 0.5", 1)
itemSearch:setInputType("text")
local updateItemList
updateItemList = function(items)
  local searchRequest = itemSearch:getValue()
  table.sort(items, function(a, b)
    return word_dst(searchRequest, a[1]) > word_dst(searchRequest, b[1])
  end)
  itemList:removeChildren()
  for i, v in ipairs(items) do
    local item = itemList:addFrame()
    item:setSize("parent.w - 2", 3)
    item:setPosition(2, i * 4 - 2)
    item:setBackground(colors.lightGray)
    item:addLabel():setPosition(1, 1):setSize("parent.w * 0.4 - 1", 3):setText(v[1])
    item:addLabel():setPosition("1 + parent.w * 0.4", 1):setSize("parent.w * 0.4 - 2", 3):setText(tostring(v[2]))
    item:addButton():setPosition("1 + parent.w * 0.8", 1):setSize("parent.w * 0.1", 3):setText("+"):setBackground(colors.green):setForeground(colors.black):onClick(function(self, event, button, x, y)
      if event == "mouse_click" and button == 1 then
        local frame = windows[1]:addMovableFrame()
        frame:setPosition("parent.w * 0.2", "parent.h * 0.3")
        frame:setSize("parent.w * 0.6", "parent.w * 0.3")
        frame:addLabel():setSize("parent.w", 1):setBackground(colors.black):setForeground(colors.lightGray):setText("Add item")
        frame:addButton():setSize(1, 1):setText("X"):setBackground(colors.black):setForeground(colors.red):setPosition("parent.w - 1", 1):onClick(function()
          return frame:remove()
        end)
        frame:addLabel():setPosition(1, "parent.h * 0.25"):setSize("parent.w * 0.3", 1):setText("Count")
        local countInput = frame:addInput():setPosition("parent.w * 0.3", "parent.h * 0.25"):setSize("parent.w * 0.7", 1):setInputType("number")
        local execute = frame:addButton():setPosition("parent.w * 0.3", "parent.h * 0.75"):setSize("parent.w * 0.4", 3):setText("Execute")
        execute:setBackground(colors.red):setForeground(colors.black)
        return execute:onClick(function(self, event, button, x, y)
          if event == "mouse_click" and button == 1 then
            local count = tonumber(countInput:getValue())
            if not count then
              return 
            end
            addRequest("item_add " .. v[1] .. " " .. count)
            addRequest("item_list")
            return frame:remove()
          end
        end)
      end
    end)
    item:addButton():setPosition("1 + parent.w * 0.9", 1):setSize("parent.w * 0.1", 3):setText("-"):setBackground(colors.red):setForeground(colors.black):onClick(function(self, event, button, x, y)
      if event == "mouse_click" and button == 1 then
        local frame = windows[1]:addMovableFrame()
        frame:setPosition("parent.w * 0.2", "parent.h * 0.3")
        frame:setSize("parent.w * 0.6", "parent.w * 0.3")
        frame:addLabel():setSize("parent.w", 1):setBackground(colors.black):setForeground(colors.lightGray):setText("Add item")
        frame:addButton():setSize(1, 1):setText("X"):setBackground(colors.black):setForeground(colors.red):setPosition("parent.w - 1", 1):onClick(function()
          return frame:remove()
        end)
        frame:addLabel():setPosition(1, "parent.h * 0.25"):setSize("parent.w * 0.3", 1):setText("Count")
        local countInput = frame:addInput():setPosition("parent.w * 0.3", "parent.h * 0.25"):setSize("parent.w * 0.7", 1):setInputType("number")
        frame:addLabel():setPosition(1, "parent.h * 0.5"):setSize("parent.w * 0.3", 1):setText("Terminal")
        local terminal = frame:addInput():setPosition("parent.w * 0.3", "parent.h * 0.5"):setSize("parent.w * 0.7", 1)
        local execute = frame:addButton():setPosition("parent.w * 0.3", "parent.h * 0.75"):setSize("parent.w * 0.4", 3):setText("Execute")
        execute:setBackground(colors.red):setForeground(colors.black)
        return execute:onClick(function(self, event, button, x, y)
          if event == "mouse_click" and button == 1 then
            local count = tonumber(countInput:getValue())
            if not count then
              return 
            end
            if v[2] < count then
              return 
            end
            addRequest("item_get " .. v[1] .. " " .. count .. " " .. terminal:getValue())
            addRequest("item_list")
            return frame:remove()
          end
        end)
      end
    end)
  end
end
itemSearch:onChange(function(self, val)
  addRequest("item_list")
  local items = data.items
  if not items then
    return 
  end
  return updateItemList(items)
end)
local addAll = windows[1]:addButton()
addAll:setPosition("parent.w * 0.7", 2)
addAll:setSize("parent.w * 0.2", 1)
addAll:setText("Add All")
addAll:onClick(function(self, event, button, x, y)
  if event == "mouse_click" and button == 1 then
    addRequest("item_add_all")
    return addRequest("item_list")
  end
end)
local aliasList = windows[2]:addScrollableFrame()
aliasList:setPosition("parent.w * 0.1", 5)
aliasList:setSize("parent.w * 0.8", "parent.h * 0.9")
aliasList:setBackground(colors.gray)
local aliasSearch = windows[2]:addInput()
aliasSearch:setPosition("parent.w * 0.1", 2)
aliasSearch:setSize("parent.w * 0.5", 1)
aliasSearch:setInputType("text")
local updateAliasList
updateAliasList = function(aliases)
  local searchRequest = aliasSearch:getValue()
  table.sort(aliases, function(a, b)
    if not a or not b then
      return false
    end
    return word_dst(searchRequest, a[1]) > word_dst(searchRequest, b[1]) or word_dst(searchRequest, a[2]) > word_dst(searchRequest, b[2])
  end)
  aliasList:removeChildren()
  for i, v in ipairs(aliases) do
    local item = aliasList:addFrame()
    item:setSize("parent.w - 2", 3)
    item:setPosition(2, i * 4 - 2)
    item:setBackground(colors.lightGray)
    item:addLabel():setPosition(1, 1):setSize("parent.w * 0.45", 3):setText(v[1])
    item:addLabel():setPosition("1 + parent.w * 0.45", 1):setSize("parent.w * 0.45 - 2", 3):setText(tostring(v[2]))
    item:addButton():setPosition("1 + parent.w * 0.9", 1):setSize("parent.w * 0.1", 3):setText("-"):setBackground(colors.red):setForeground(colors.black):onClick(function(self, event, button, x, y)
      if event == "mouse_click" and button == 1 then
        addRequest("alias_remove_alias " .. v[1])
        return addRequest("alias_list")
      end
    end)
  end
end
aliasSearch:onChange(function(self, val)
  addRequest("alias_list")
  local aliases = data.aliases
  if not aliases then
    return 
  end
  return updateAliasList(aliases)
end)
local add = windows[2]:addButton()
add:setPosition("parent.w * 0.7", 2)
add:setSize("parent.w * 0.2", 1)
add:setText("Add")
add:onClick(function(self, event, button, x, y)
  if event == "mouse_click" and button == 1 then
    local frame = windows[2]:addMovableFrame()
    frame:setPosition("parent.w * 0.2", "parent.h * 0.3")
    frame:setSize("parent.w * 0.6", "parent.w * 0.3")
    frame:addLabel():setSize("parent.w", 1):setBackground(colors.black):setForeground(colors.lightGray):setText("Add alias")
    frame:addButton():setSize(1, 1):setText("X"):setBackground(colors.black):setForeground(colors.red):setPosition("parent.w - 1", 1):onClick(function()
      return frame:remove()
    end)
    frame:addLabel():setPosition(1, "parent.h * 0.25"):setSize("parent.w * 0.3", 1):setText("Alias")
    local alias = frame:addInput():setPosition("parent.w * 0.3", "parent.h * 0.25"):setSize("parent.w * 0.7", 1)
    frame:addLabel():setPosition(1, "parent.h * 0.5"):setSize("parent.w * 0.3", 1):setText("Item")
    local item = frame:addInput():setPosition("parent.w * 0.3", "parent.h * 0.5"):setSize("parent.w * 0.7", 1)
    local execute = frame:addButton():setPosition("parent.w * 0.3", "parent.h * 0.75"):setSize("parent.w * 0.4", 3):setText("Execute")
    execute:setBackground(colors.red):setForeground(colors.black)
    return execute:onClick(function(self, event, button, x, y)
      if event == "mouse_click" and button == 1 then
        addRequest("alias_add " .. alias:getValue() .. " " .. item:getValue())
        addRequest("alias_list")
        return frame:remove()
      end
    end)
  end
end)
local storageList = windows[3]:addScrollableFrame()
storageList:setPosition("parent.w * 0.1", 5)
storageList:setSize("parent.w * 0.8", "parent.h * 0.9")
storageList:setBackground(colors.gray)
local storageListSelector = windows[3]:addDropdown()
storageListSelector:setZIndex(100)
storageListSelector:setPosition("parent.w * 0.1", 2)
storageListSelector:setSize("parent.w * 0.5", 1)
storageListSelector:addItem("Input")
storageListSelector:addItem("Storage")
storageListSelector:addItem("Output")
local updateStorageList
updateStorageList = function()
  local database = nil
  local listOp = nil
  local removeOp = nil
  local segmented = false
  local _exp_0 = storageListSelector:getItemIndex()
  if 1 == _exp_0 then
    database = data.inputs
    removeOp = "input_remove "
    listOp = "input_list"
    segmented = false
  elseif 2 == _exp_0 then
    database = data.storages
    removeOp = "storage_remove "
    listOp = "storage_list"
    segmented = false
  elseif 3 == _exp_0 then
    database = data.outputs
    removeOp = "output_remove "
    listOp = "output_list"
    segmented = true
  end
  if not database then
    return 
  end
  storageList:removeChildren()
  for i, v in ipairs(database) do
    local item = storageList:addFrame()
    item:setSize("parent.w - 2", 3)
    item:setPosition(2, i * 4 - 2)
    item:setBackground(colors.lightGray)
    if segmented then
      item:addLabel():setPosition(1, 1):setSize("parent.w * 0.45", 3):setText(v[1])
      item:addLabel():setPosition("1 + parent.w * 0.45", 1):setSize("parent.w * 0.45 - 2", 3):setText(tostring(v[2]))
    else
      item:addLabel():setPosition(1, 1):setSize("parent.w * 0.9", 3):setText(v)
    end
    item:addButton():setPosition("1 + parent.w * 0.9", 1):setSize("parent.w * 0.1", 3):setText("-"):setBackground(colors.red):setForeground(colors.black):onClick(function(self, event, button, x, y)
      if event == "mouse_click" and button == 1 then
        if segmented then
          addRequest(removeOp .. v[1])
        else
          addRequest(removeOp .. v)
        end
        return addRequest(listOp)
      end
    end)
  end
end
storageListSelector:onChange(function(self, item)
  local _exp_0 = storageListSelector:getItemIndex()
  if 1 == _exp_0 then
    addRequest("input_list")
  elseif 2 == _exp_0 then
    addRequest("storage_list")
  elseif 3 == _exp_0 then
    addRequest("output_list")
  end
  return updateStorageList()
end)
add = windows[3]:addButton()
add:setPosition("parent.w * 0.7", 2)
add:setSize("parent.w * 0.2", 1)
add:setText("Add")
add:onClick(function(self, event, button, x, y)
  if event == "mouse_click" and button == 1 then
    local frame = windows[3]:addMovableFrame()
    frame:setPosition("parent.w * 0.2", "parent.h * 0.3")
    frame:setSize("parent.w * 0.6", "parent.w * 0.3")
    frame:addButton():setSize(1, 1):setText("X"):setBackground(colors.black):setForeground(colors.red):setPosition("parent.w - 1", 1):onClick(function()
      return frame:remove()
    end)
    local _exp_0 = storageListSelector:getItemIndex()
    if 1 == _exp_0 then
      frame:addLabel():setSize("parent.w", 1):setBackground(colors.black):setForeground(colors.lightGray):setText("Add input")
      frame:addLabel():setPosition(1, "parent.h * 0.25"):setSize("parent.w * 0.3", 1):setText("ID")
      local id = frame:addInput():setPosition("parent.w * 0.3", "parent.h * 0.25"):setSize("parent.w * 0.7", 1)
      local execute = frame:addButton():setPosition("parent.w * 0.3", "parent.h * 0.75"):setSize("parent.w * 0.4", 3):setText("Execute")
      execute:setBackground(colors.red):setForeground(colors.black)
      return execute:onClick(function(self, event, button, x, y)
        if event == "mouse_click" and button == 1 then
          addRequest("input_add " .. id:getValue())
          addRequest("input_list")
          return frame:remove()
        end
      end)
    elseif 2 == _exp_0 then
      frame:addLabel():setSize("parent.w", 1):setBackground(colors.black):setForeground(colors.lightGray):setText("Add storage")
      frame:addLabel():setPosition(1, "parent.h * 0.25"):setSize("parent.w * 0.3", 1):setText("ID")
      local id = frame:addInput():setPosition("parent.w * 0.3", "parent.h * 0.25"):setSize("parent.w * 0.7", 1)
      local execute = frame:addButton():setPosition("parent.w * 0.3", "parent.h * 0.75"):setSize("parent.w * 0.4", 3):setText("Execute")
      execute:setBackground(colors.red):setForeground(colors.black)
      return execute:onClick(function(self, event, button, x, y)
        if event == "mouse_click" and button == 1 then
          addRequest("storage_add " .. id:getValue())
          addRequest("storage_list")
          return frame:remove()
        end
      end)
    elseif 3 == _exp_0 then
      frame:addLabel():setSize("parent.w", 1):setBackground(colors.black):setForeground(colors.lightGray):setText("Add output")
      frame:addLabel():setPosition(1, "parent.h * 0.25"):setSize("parent.w * 0.3", 1):setText("Name")
      local name = frame:addInput():setPosition("parent.w * 0.3", "parent.h * 0.25"):setSize("parent.w * 0.7", 1)
      frame:addLabel():setPosition(1, "parent.h * 0.5"):setSize("parent.w * 0.3", 1):setText("ID")
      local id = frame:addInput():setPosition("parent.w * 0.3", "parent.h * 0.5"):setSize("parent.w * 0.7", 1)
      local execute = frame:addButton():setPosition("parent.w * 0.3", "parent.h * 0.75"):setSize("parent.w * 0.4", 3):setText("Execute")
      execute:setBackground(colors.red):setForeground(colors.black)
      return execute:onClick(function(self, event, button, x, y)
        if event == "mouse_click" and button == 1 then
          addRequest("output_add " .. name:getValue() .. " " .. id:getValue())
          addRequest("output_list")
          return frame:remove()
        end
      end)
    end
  end
end)
local transferList = windows[4]:addScrollableFrame()
transferList:setPosition("parent.w * 0.1", 5)
transferList:setSize("parent.w * 0.8", "parent.h * 0.9")
transferList:setBackground(colors.gray)
local transferListSelector = windows[4]:addDropdown()
transferListSelector:setZIndex(100)
transferListSelector:setPosition("parent.w * 0.1", 2)
transferListSelector:setSize("parent.w * 0.5", 1)
transferListSelector:addItem("Loaders")
transferListSelector:addItem("Unloaders")
local updateTransferList
updateTransferList = function()
  local _exp_0 = transferListSelector:getItemIndex()
  if 1 == _exp_0 then
    local database = data.loaders
    if not database then
      return 
    end
    transferList:removeChildren()
    for i, v in ipairs(database) do
      local item = transferList:addFrame()
      item:setSize("parent.w - 2", 6)
      item:setPosition(2, i * 7 - 5)
      item:setBackground(colors.lightGray)
      item:addLabel():setPosition(1, 1):setSize("parent.w * 0.87", 3):setText("to " .. v[1] .. " add " .. v[2] .. " in the amount of " .. tostring(v[3]))
      item:addLabel():setPosition(1, 4):setSize("parent.w * 0.87", 3):setText("if " .. v[4] .. " less than " .. tostring(v[5]))
      item:addButton():setPosition("1 + parent.w * 0.9", 1):setSize("parent.w * 0.1", 6):setText("-"):setBackground(colors.red):setForeground(colors.black):onClick(function(self, event, button, x, y)
        if event == "mouse_click" and button == 1 then
          addRequest("loader_remove_si " .. v[1] .. " " .. v[2])
          return addRequest("loader_list")
        end
      end)
    end
  elseif 2 == _exp_0 then
    local database = data.unloaders
    if not database then
      return 
    end
    transferList:removeChildren()
    for i, v in ipairs(database) do
      local item = transferList:addFrame()
      item:setSize("parent.w - 2", 3)
      item:setPosition(2, i * 4 - 2)
      item:setBackground(colors.lightGray)
      item:addLabel():setPosition(1, 1):setSize("parent.w * 0.9", 3):setText(v)
      item:addButton():setPosition("1 + parent.w * 0.9", 1):setSize("parent.w * 0.1", 3):setText("-"):setBackground(colors.red):setForeground(colors.black):onClick(function(self, event, button, x, y)
        if event == "mouse_click" and button == 1 then
          addRequest("unloader_remove " .. v)
          return addRequest("unloader_list")
        end
      end)
    end
  end
end
transferListSelector:onChange(function(self, item)
  local _exp_0 = transferListSelector:getItemIndex()
  if 1 == _exp_0 then
    addRequest("loader_list")
  elseif 2 == _exp_0 then
    addRequest("unloader_list")
  end
  return updateTransferList()
end)
add = windows[4]:addButton()
add:setPosition("parent.w * 0.7", 2)
add:setSize("parent.w * 0.2", 1)
add:setText("Add")
add:onClick(function(self, event, button, x, y)
  if event == "mouse_click" and button == 1 then
    local frame = windows[4]:addMovableFrame()
    frame:setPosition("parent.w * 0.2", "parent.h * 0.3")
    frame:setSize("parent.w * 0.6", "parent.w * 0.3")
    frame:addButton():setSize(1, 1):setText("X"):setBackground(colors.black):setForeground(colors.red):setPosition("parent.w - 1", 1):onClick(function()
      return frame:remove()
    end)
    local _exp_0 = transferListSelector:getItemIndex()
    if 1 == _exp_0 then
      frame:addLabel():setSize("parent.w", 1):setBackground(colors.black):setForeground(colors.lightGray):setText("Add loader")
      frame:addLabel():setPosition(1, "parent.h * 0.1429"):setSize("parent.w * 0.3", 1):setText("Storage")
      local storage = frame:addInput():setPosition("parent.w * 0.3", "parent.h * 0.1429"):setSize("parent.w * 0.7", 1)
      frame:addLabel():setPosition(1, "parent.h * 0.2857"):setSize("parent.w * 0.3", 1):setText("Item")
      local item = frame:addInput():setPosition("parent.w * 0.3", "parent.h * 0.2857"):setSize("parent.w * 0.7", 1)
      frame:addLabel():setPosition(1, "parent.h * 0.4286"):setSize("parent.w * 0.3", 1):setText("Count")
      local count = frame:addInput():setPosition("parent.w * 0.3", "parent.h * 0.4286"):setSize("parent.w * 0.7", 1):setInputType("number")
      frame:addLabel():setPosition(1, "parent.h * 0.5714"):setSize("parent.w * 0.3", 1):setText("If Item")
      local cond_item = frame:addInput():setPosition("parent.w * 0.3", "parent.h * 0.5714"):setSize("parent.w * 0.7", 1)
      frame:addLabel():setPosition(1, "parent.h * 0.7143"):setSize("parent.w * 0.3", 1):setText("Count")
      local cond_count = frame:addInput():setPosition("parent.w * 0.3", "parent.h * 0.7143"):setSize("parent.w * 0.7", 1):setInputType("number")
      local execute = frame:addButton():setPosition("parent.w * 0.3", "parent.h * 0.8571"):setSize("parent.w * 0.4", 3):setText("Execute")
      execute:setBackground(colors.red):setForeground(colors.black)
      return execute:onClick(function(self, event, button, x, y)
        if event == "mouse_click" and button == 1 then
          if cond_item:getValue() == "" then
            cond_item:setValue("item_not_exists_")
          end
          if cond_count:getValue() == "" then
            cond_count:setValue("3000000000")
          end
          addRequest("loader_add " .. storage:getValue() .. " " .. item:getValue() .. " " .. count:getValue() .. " " .. cond_item:getValue() .. " " .. cond_count:getValue() .. " ")
          addRequest("loader_list")
          return frame:remove()
        end
      end)
    elseif 2 == _exp_0 then
      frame:addLabel():setSize("parent.w", 1):setBackground(colors.black):setForeground(colors.lightGray):setText("Add unloader")
      frame:addLabel():setPosition(1, "parent.h * 0.25"):setSize("parent.w * 0.3", 1):setText("ID")
      local id = frame:addInput():setPosition("parent.w * 0.3", "parent.h * 0.25"):setSize("parent.w * 0.7", 1)
      local execute = frame:addButton():setPosition("parent.w * 0.3", "parent.h * 0.75"):setSize("parent.w * 0.4", 3):setText("Execute")
      execute:setBackground(colors.red):setForeground(colors.black)
      return execute:onClick(function(self, event, button, x, y)
        if event == "mouse_click" and button == 1 then
          addRequest("unloader_add " .. id:getValue())
          addRequest("unloader_list")
          return frame:remove()
        end
      end)
    end
  end
end)
local settingsList = windows[5]:addScrollableFrame()
settingsList:setPosition("parent.w * 0.1", 5)
settingsList:setSize("parent.w * 0.8", "parent.h * 0.9")
settingsList:setBackground(colors.gray)
local settingsListSelector = windows[5]:addDropdown()
settingsListSelector:setZIndex(100)
settingsListSelector:setPosition("parent.w * 0.1", 2)
settingsListSelector:setSize("parent.w * 0.5", 1)
settingsListSelector:addItem("App")
settingsListSelector:addItem("Server")
local updateSettingsList
updateSettingsList = function()
  local database
  local _exp_0 = settingsListSelector:getItemIndex()
  if 1 == _exp_0 then
    database = Properties
  elseif 2 == _exp_0 then
    database = data.properties
  end
  if not database then
    return 
  end
  settingsList:removeChildren()
  local y = 2
  for k, v in pairs(database) do
    local item = settingsList:addFrame()
    item:setSize("parent.w - 2", 1)
    item:setPosition(2, y)
    item:setBackground(colors.lightGray)
    item:addLabel():setPosition(1, 1):setSize("parent.w * 0.5", 1):setText(k)
    local valueInput = item:addInput():setPosition("1 + parent.w * 0.5", 1):setSize("parent.w * 0.5", 1):setValue(v)
    valueInput:onChange(function(self, val)
      local _exp_1 = settingsListSelector:getItemIndex()
      if 1 == _exp_1 then
        Properties[k] = valueInput:getValue()
        local pwd = fs.getDir(shell.getRunningProgram())
        local file = fs.open(pwd .. "/config.properties", "w")
        for key, value in pairs(Properties) do
          file.writeLine(key .. ": " .. value)
        end
        file.flush()
        return file.close()
      elseif 2 == _exp_1 then
        addRequest("property_set " .. k .. " " .. valueInput:getValue())
        return addRequest("property_list")
      end
    end)
    y = y + 2
  end
end
settingsListSelector:onChange(function(self, item)
  if settingsListSelector:getItemIndex() == 2 then
    addRequest("property_list")
  end
  return updateSettingsList()
end)
local logFrame = main:addMovableFrame()
logFrame:hide()
logFrame:setPosition("parent.w * 0.1", "parent.h * 0.1")
logFrame:setSize("parent.w * 0.8", "parent.h * 0.8")
logFrame:addLabel():setSize("parent.w", 1):setBackground(colors.black):setForeground(colors.lightGray):setText("Log")
logFrame:addButton():setSize(1, 1):setText("X"):setBackground(colors.black):setForeground(colors.red):setPosition("parent.w - 1", 1):onClick(function()
  return logFrame:hide()
end)
local logField = logFrame:addTextfield()
logField:setPosition(1, 2)
logField:setSize("parent.w", "parent.h - 1")
local updateLog
updateLog = function()
  while #Lines > 0 do
    logField:addLine(Lines[1])
    table.remove(Lines, 1)
  end
end
local log = windows[5]:addButton()
log:setPosition("parent.w * 0.7", 2)
log:setSize("parent.w * 0.2", 1)
log:setText("Log")
log:onClick(function(self, event, button, x, y)
  if event == "mouse_click" and button == 1 then
    return logFrame:show()
  end
end)
local networking = main:addThread()
networking:start(function()
  while run do
    if #requests > 0 then
      local request = requests[1]
      table.remove(requests, 1)
      local response = Send(request, requestLock[request])
      responses[request] = response
      requestLock[request] = nil
      updateLog()
    end
    if responses["storage_list"] then
      local response = responses["storage_list"]
      responses["storage_list"] = nil
      local database = { }
      local lines = split(response, "\n")
      for i, v in ipairs(lines) do
        local _continue_0 = false
        repeat
          if v == "" then
            _continue_0 = true
            break
          end
          table.insert(database, v)
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      data.storages = database
      updateStorageList()
    end
    if responses["input_list"] then
      local response = responses["input_list"]
      responses["input_list"] = nil
      local database = { }
      local lines = split(response, "\n")
      for i, v in ipairs(lines) do
        local _continue_0 = false
        repeat
          if v == "" then
            _continue_0 = true
            break
          end
          table.insert(database, v)
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      data.inputs = database
      updateStorageList()
    end
    if responses["output_list"] then
      local response = responses["output_list"]
      responses["output_list"] = nil
      local outputs = { }
      local lines = split(response, "\n")
      for i, v in ipairs(lines) do
        local _continue_0 = false
        repeat
          if v == "" then
            _continue_0 = true
            break
          end
          local segments = split(v, " ")
          table.insert(outputs, {
            segments[1],
            segments[2]
          })
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      data.outputs = outputs
      updateStorageList()
    end
    if responses["item_list"] then
      local response = responses["item_list"]
      responses["item_list"] = nil
      local items = { }
      local lines = split(response, "\n")
      for i, v in ipairs(lines) do
        local _continue_0 = false
        repeat
          if v == "" then
            _continue_0 = true
            break
          end
          local segments = split(v, " ")
          table.insert(items, {
            segments[1],
            tonumber(segments[2])
          })
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      data.items = items
      updateItemList(items)
    end
    if responses["alias_list"] then
      local response = responses["alias_list"]
      responses["alias_list"] = nil
      local aliases = { }
      local lines = split(response, "\n")
      for i, v in ipairs(lines) do
        local _continue_0 = false
        repeat
          if v == "" then
            _continue_0 = true
            break
          end
          local segments = split(v, " ")
          table.insert(aliases, {
            segments[1],
            segments[2]
          })
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      data.aliases = aliases
      updateAliasList(aliases)
    end
    if responses["loader_list"] then
      local response = responses["loader_list"]
      responses["loader_list"] = nil
      local loaders = { }
      local lines = split(response, "\n")
      for i, v in ipairs(lines) do
        local _continue_0 = false
        repeat
          if v == "" then
            _continue_0 = true
            break
          end
          local segments = split(v, " ")
          table.insert(loaders, {
            segments[1],
            segments[2],
            tonumber(segments[3]),
            segments[4],
            tonumber(segments[5])
          })
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      data.loaders = loaders
      updateTransferList()
    end
    if responses["unloader_list"] then
      local response = responses["unloader_list"]
      responses["unloader_list"] = nil
      local unloaders = { }
      local lines = split(response, "\n")
      for i, v in ipairs(lines) do
        local _continue_0 = false
        repeat
          if v == "" then
            _continue_0 = true
            break
          end
          table.insert(unloaders, v)
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      data.unloaders = unloaders
      updateTransferList()
    end
    if responses["property_list"] then
      local response = responses["property_list"]
      responses["property_list"] = nil
      local properties = { }
      local lines = split(response, "\n")
      for i, v in ipairs(lines) do
        local _continue_0 = false
        repeat
          if v == "" then
            _continue_0 = true
            break
          end
          local segments = split(v, " ")
          properties[segments[1]] = segments[2]
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      data.properties = properties
      updateSettingsList()
    end
    sleep(1)
  end
end)
addRequest("storage_list")
addRequest("input_list")
addRequest("output_list")
addRequest("item_list")
addRequest("alias_list")
addRequest("loader_list")
addRequest("unloader_list")
addRequest("property_list")
return basalt.autoUpdate()
