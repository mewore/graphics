require "controls/list"
require "controls/button"
require "controls/text-input"
require "data/native-file"
require "views/tile-editor"

TilesheetList = {}
TilesheetList.__index = TilesheetList


--- Open an editor at the top of the view stack and remove it when it is closed
-- @param editor The editor to open
local function openEditor(editor)
   viewStack:pushView(editor)
   editor.onClose = function() viewStack:popView(editor) end
end

local TILESHEET_DIRECTORY = love.filesystem.getWorkingDirectory() .. "/tilesheets"
local NEW_TILESHEET_ITEM = "(+) New tilesheet"

--- A list of tilesheets in the current working directory
function TilesheetList:create()
   local files, pngFileTable, jsonFileTable = {}, {}, {}
   for _, pngFile in ipairs(NativeFile:create(TILESHEET_DIRECTORY):getFiles("png")) do
      pngFileTable[pngFile.name] = pngFile
      files[#files + 1] = pngFile.name
   end
   for _, jsonFile in ipairs(NativeFile:create(TILESHEET_DIRECTORY):getFiles("json")) do
      jsonFileTable[jsonFile.name] = jsonFile
      if not pngFileTable[jsonFile.name] then files[#files + 1] = jsonFile.name end
   end
   table.sort(files)

   local tilesheetItems = { { value = NEW_TILESHEET_ITEM } }
   for _, name in ipairs(files) do
      if not pngFileTable[name] or not jsonFileTable[name] then
         print("Tilesheet " .. name .. " has no .json or no .map file.")
         tilesheetItems[#tilesheetItems + 1] = { value = name, disabled = true }
      else
         local tilesheetInfo = jsonFileTable[name]:readAsJson()
         tilesheetItems[#tilesheetItems + 1] = {
            value = name,
            icon = pngFileTable[name]:readAsImage(),
            iconQuadWidth = tilesheetInfo.width,
            iconQuadHeight = tilesheetInfo.height,
         }
      end
   end

   local list
   local renameButton = {
      label = "Rename",
      colour = { r = 0.6, g = 0.8, b = 1 },
      appliesToItem = function(item) return item.value ~= NEW_TILESHEET_ITEM end,
      clickHandler = function(item)
         local dialog
         local nameInput = TextInput:create(300, "Name", item.value, {
            kebabCase = true,
            validations = { function(value) return not list:containsValue(value) end }
         })

         local okButton = Button:create("OK", "solid", function()
            if not (nameInput.isValid) then return end
            local oldName, newName = item.value, nameInput.value

            if pngFileTable[oldName] then
               pngFileTable[oldName], pngFileTable[newName] = nil, pngFileTable[oldName]:rename(newName .. ".png")
            end
            if jsonFileTable[oldName] then
               jsonFileTable[oldName], jsonFileTable[newName] = nil, jsonFileTable[oldName]:rename(newName .. ".json")
            end

            list:removeItem(item)
            item.value = newName
            list:addItemAndKeepSorted(item)
            viewStack:popView(dialog)
         end)
         local cancelButton = Button:create("Cancel", nil, function() viewStack:popView(dialog) end)

         dialog = Dialog:create("Rename tilesheet '" .. item.value .. "'", "What should the new name be?",
            { nameInput }, { cancelButton, okButton })
      end,
   }
   list = List:create(tilesheetItems, { buttons = { renameButton } })
   local this = {
      list = list,
   }
   setmetatable(this, self)

   list:onSelect(function(value)
      if value == NEW_TILESHEET_ITEM then
         local nameInput = TextInput:create(300, "Name", "", {
            kebabCase = true,
            validations = { function(value) return not list:containsValue(value) end }
         })
         local widthInput = TextInput:create(50, "Tile width", "32", { positive = true, integer = true })
         local heightInput = TextInput:create(50, "Tile height", "32", { positive = true, integer = true })

         local dialog
         local okButton = Button:create("OK", "solid", function()
            if not (nameInput.isValid and widthInput.isValid and heightInput.isValid) then
               return
            end

            local tilesheetPath = TILESHEET_DIRECTORY .. "/" .. nameInput.value
            local width, height = tonumber(widthInput.value), tonumber(heightInput.value)

            local pngFilePath = tilesheetPath .. ".png"
            local pngFileData = love.image.newImageData(width, height)
            for y = 0, height - 1 do
               for x = 0, width - 1 do
                  pngFileData:setPixel(x, y, 0, 0, 0, 0)
               end
            end

            local jsonFilePath = tilesheetPath .. ".json"
            NativeFile:create(pngFilePath):write(pngFileData:encode("png"):getString())
            NativeFile:create(jsonFilePath):writeAsJson({ width = width, height = height })
            list:addItemAndKeepSorted({ value = nameInput.value })

            viewStack:popView(dialog)
            openEditor(TileEditor:create(pngFilePath))
         end)
         local cancelButton = Button:create("Cancel", nil, function() viewStack:popView(dialog) end)

         dialog = Dialog:create("Create a new tilesheet", nil,
            { nameInput, widthInput, heightInput }, { cancelButton, okButton })
      else
         openEditor(TileEditor:create(TILESHEET_DIRECTORY .. "/" .. value .. ".png"))
      end
   end)

   return this
end

function TilesheetList:setPosition(x, y) self.list:setPosition(x, y) end

function TilesheetList:setSize(width, height) self.list:setSize(width, height) end

function TilesheetList:setSize(width, height) self.list:setSize(width, height) end

function TilesheetList:getX() return self.list:getX() end

function TilesheetList:getY() return self.list:getY() end

function TilesheetList:getWidth() return self.list:getWidth() end

function TilesheetList:getHeight() return self.list:getHeight() end

--- LOVE update handler
-- @param dt {float} - The amount of time (in seconds) since the last update
function TilesheetList:update(dt) self.list:update(dt) end

--- LOVE draw handler
function TilesheetList:draw() self.list:draw() end