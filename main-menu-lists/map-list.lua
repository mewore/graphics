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
   local mapFiles = {}
   local mapJsonFiles = {}
   local mapTable = {}

   for _, mapFile in ipairs(NativeFile:create(MAP_DIRECTORY):getFiles("map")) do
      local mapJsonFile = NativeFile:create(MAP_DIRECTORY):getChild(mapFile.name .. ".json")
      mapTable[mapFile.name] = true

      if not mapJsonFile:isFile() then
         print("Map " .. mapFile.name .. " has no JSON file. Pretending it doesn't exist...")
      else
         mapFiles[#mapFiles + 1] = mapFile
         mapJsonFiles[#mapJsonFiles + 1] = mapJsonFile
      end
   end
   for _, jsonFile in ipairs(NativeFile:create(MAP_DIRECTORY):getFiles("json")) do
      mapTable[jsonFile.name] = true
   end

   local list
   local mapItems = { { value = NEW_MAP_ITEM } }
   for i = 1, #mapFiles do
      local mapItem = { value = mapFiles[i].name }

      local renameHandler = function()
         local nameInput = TextInput:create(300, "Name", mapFiles[i].name, {
            kebabCase = true,
            validations = { function(value) return not mapTable[value] end }
         })

         local okButton = Button:create("OK", "solid", function()
            if not (nameInput.isValid) then
               return
            end

            mapFiles[i] = mapFiles[i]:rename(nameInput.value .. ".map")
            mapJsonFiles[i] = mapJsonFiles[i]:rename(nameInput.value .. ".json")

            mapTable[mapItem.value] = nil
            list:removeItem(mapItem)
            mapItem.value = nameInput.value
            mapTable[mapItem.value] = true
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
            validations = { function(value) return not mapTable[value] end }
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