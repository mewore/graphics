require "controls/list"
require "data/map-encoder"
require "data/native-file"
require "views/map-editor"

MapList = {}
MapList.__index = MapList

local MAP_DIRECTORY = love.filesystem.getWorkingDirectory() .. "/maps"
local TILESHEET_DIRECTORY = love.filesystem.getWorkingDirectory() .. "/tilesheets"
local NEW_MAP_ITEM = "(+) New map"

--- A list of maps in the current working directory
function MapList:create()
   local list

   local files, mapFileTable, jsonFileTable = {}, {}, {}
   for _, mapFile in ipairs(NativeFile:create(MAP_DIRECTORY):getFiles("map")) do
      mapFileTable[mapFile.name] = mapFile
      files[#files + 1] = mapFile.name
   end
   for _, jsonFile in ipairs(NativeFile:create(MAP_DIRECTORY):getFiles("json")) do
      jsonFileTable[jsonFile.name] = jsonFile
      if not mapFileTable[jsonFile.name] then files[#files + 1] = jsonFile.name end
   end
   table.sort(files)

   local mapItems = { { value = NEW_MAP_ITEM } }
   local list

   for _, name in ipairs(files) do
      if not jsonFileTable[name] or not mapFileTable[name] then
         print("Map " .. name .. " has no .json or no .map file.")
         mapItems[#mapItems + 1] = { value = name, disabled = true }
      else
         local mapItem = { value = name }

         local renameHandler = function()
            local nameInput = TextInput:create(300, "Name", mapFileTable[name].name, {
               kebabCase = true,
               validations = { function(value) return not list:containsValue(value) end }
            })

            local okButton = Button:create("OK", "solid", function()
               if not (nameInput.isValid) then
                  return
               end

               mapFileTable[name] = mapFileTable[name]:rename(nameInput.value .. ".map")
               jsonFileTable[name] = jsonFileTable[name]:rename(nameInput.value .. ".json")

               list:removeItem(mapItem)
               mapItem.value = nameInput.value
               list:addItemAndKeepSorted(mapItem)
               viewStack:popView(self.dialog)
               self.dialog = nil
            end)
            local cancelButton = Button:create("Cancel", nil, function()
               viewStack:popView(self.dialog)
               self.dialog = nil
            end)

            self.dialog = Dialog:create("Rename map '" .. mapItem.value .. "'", "What should the new name of the map be?",
               { nameInput }, { cancelButton, okButton })
         end
         mapItem.buttons = { { label = "Rename", clickHandler = renameHandler, colour = { r = 0.6, g = 0.8, b = 1 } } }
         mapItems[#mapItems + 1] = mapItem
      end
   end

   list = List:create(mapItems)
   local this = {
      list = list,
   }
   setmetatable(this, self)

   list:onSelect(function(value)
      if value == NEW_MAP_ITEM then
         local dialog
         local nameInput = TextInput:create(300, "Name", "", {
            kebabCase = true,
            validations = { function(value) return not list:containsValue(value) end }
         })
         local widthInput = TextInput:create(50, "Width", "256", { positive = true, integer = true })
         local heightInput = TextInput:create(50, "Height", "32", { positive = true, integer = true })

         local okButton = Button:create("OK", "solid", function()
            if not (nameInput.isValid and widthInput.isValid and heightInput.isValid) then
               return
            end

            local mapPath = MAP_DIRECTORY .. "/" .. nameInput.value
            local width, height = tonumber(widthInput.value), tonumber(heightInput.value)

            local mapTiles = {}
            local mapTileCount = width * height
            for i = 1, mapTileCount do
               mapTiles[i] = 0
            end
            MapEncoder:create():saveToFile(mapPath, { points = {}, width = width, height = height, tiles = mapTiles })
            list:addItemAndKeepSorted({ value = nameInput.value })
            viewStack:popView(dialog)

            local editor = MapEditor:create(MAP_DIRECTORY .. "/" .. nameInput.value, TILESHEET_DIRECTORY)
            viewStack:pushView(editor)
            editor.onClose = function() viewStack:popView(editor) end
         end)
         local cancelButton = Button:create("Cancel", nil, function()
            viewStack:popView(dialog)
         end)

         dialog = Dialog:create("Create a new map", "What should the name of the map be?",
            { nameInput, widthInput, heightInput }, { cancelButton, okButton })
      else
         local editor = MapEditor:create(MAP_DIRECTORY .. "/" .. value, TILESHEET_DIRECTORY)
         viewStack:pushView(editor)
         editor.onClose = function() viewStack:popView(editor) end
      end
   end)

   return this
end

function MapList:setPosition(x, y) self.list:setPosition(x, y) end

function MapList:setSize(width, height) self.list:setSize(width, height) end

function MapList:setSize(width, height) self.list:setSize(width, height) end

function MapList:getX() return self.list:getX() end

function MapList:getY() return self.list:getY() end

function MapList:getWidth() return self.list:getWidth() end

function MapList:getHeight() return self.list:getHeight() end

--- LOVE update handler
-- @param dt {float} - The amount of time (in seconds) since the last update
function MapList:update(dt) self.list:update(dt) end

--- LOVE draw handler
function MapList:draw() self.list:draw() end