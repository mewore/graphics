require "controls/list"
require "data/map-encoder"
require "data/native-file"
require "views/map-editor"
require "views/tile-editor"
require "views/sprite-editor"

MainMenu = {}
MainMenu.__index = MainMenu

local CARLITO_FONT_PATH = 'fonts/carlito.ttf'

local TITLE_FONT = love.graphics.newFont(CARLITO_FONT_PATH, 32)
local TITLE_PADDING_TOP = 10
local TITLE_TEXT = love.graphics.newText(TITLE_FONT, "Main Menu")

local SUBTITLE_FONT = love.graphics.newFont(CARLITO_FONT_PATH, 18)
local SUBTITLE_PADDING_TOP = 10
local MAPS_SUBTITLE_TEXT = love.graphics.newText(SUBTITLE_FONT, "Maps")
local TILESHEET_SUBTITLE_TEXT = love.graphics.newText(SUBTITLE_FONT, "Tiles")
local SPRITES_SUBTITLE_TEXT = love.graphics.newText(SUBTITLE_FONT, "Sprites")
local SUBTITLE_Y_POSITION = TITLE_PADDING_TOP + TITLE_TEXT:getHeight() + SUBTITLE_PADDING_TOP

local LIST_Y_POSITION = SUBTITLE_Y_POSITION + MAPS_SUBTITLE_TEXT:getHeight()

local BACKGROUND_VALUE = 0.2

local MAP_DIRECTORY = love.filesystem.getWorkingDirectory() .. "/maps"
local TILESHEET_DIRECTORY = love.filesystem.getWorkingDirectory() .. "/tilesheets"
local SPRITE_DIRECTORY = love.filesystem.getWorkingDirectory() .. "/sprites"

local NEW_MAP_ITEM = "(+) New map"
local NEW_TILESHEET_ITEM = "(+) New tilesheet"
local NEW_SPRITE_ITEM = "(+) New sprite"

--- Open an editor at the top of the view stack and remove it when it is closed
-- @param editor The editor to open
local function openEditor(editor)
   viewStack:pushView(editor)
   editor.onClose = function() viewStack:popView(editor) end
end

--- The main menu
function MainMenu:create()
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

   local mapList
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
            mapList:removeItem(mapItem)
            mapItem.value = nameInput.value
            mapTable[mapItem.value] = true
            mapList:addItemAndKeepSorted(mapItem)
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

   local tilesheetFiles = NativeFile:create(TILESHEET_DIRECTORY):getFiles("png")
   local tilesheetInfoFiles = NativeFile:create(TILESHEET_DIRECTORY):getFiles("json")
   local tilesheetInfoByName = {}
   for _, tilesheetInfoFile in ipairs(tilesheetInfoFiles) do
      tilesheetInfoByName[tilesheetInfoFile.name] = tilesheetInfoFile:readAsJson()
   end

   local tilesheetTable = {}
   local tilesheetItems = { { value = NEW_TILESHEET_ITEM } }
   for _, file in ipairs(tilesheetFiles) do
      local tilesheetInfo = tilesheetInfoByName[file.name]
      if not tilesheetInfo then
         error("There is no " .. file.name .. ".json file corresponding to " .. file.filename)
      end
      tilesheetTable[file.name] = true
      tilesheetItems[#tilesheetItems + 1] = {
         label = file.name,
         value = file.path,
         icon = file:readAsImage(),
         iconQuadWidth = tilesheetInfo.width,
         iconQuadHeight = tilesheetInfo.height,
      }
   end

   local spriteDirectories = NativeFile:create(SPRITE_DIRECTORY):getDirectories()
   local spriteTable = {}
   local spriteItems = { { value = NEW_SPRITE_ITEM } }
   for _, spriteDirectory in ipairs(spriteDirectories) do
      local item = { label = spriteDirectory.name, value = spriteDirectory.path }
      local spriteIconFile = spriteDirectory:getChild("icon.png")
      if not spriteIconFile:isFile() then
         spriteIconFile = spriteDirectory:getChild("idle.png")
      end
      if spriteIconFile:isFile() then
         local icon = spriteIconFile:readAsImage()
         item.icon = icon
         item.iconQuadWidth = icon:getHeight()
         item.iconQuadHeight = icon:getHeight()
      end

      spriteTable[spriteDirectory.name] = true
      spriteItems[#spriteItems + 1] = item
   end

   mapList = List:create(mapItems)
   local tilesheetList = List:create(tilesheetItems)
   local spriteList = List:create(spriteItems, { iconSize = 32 })

   local this = {
      lists = { mapList, tilesheetList, spriteList },
      subtitles = { MAPS_SUBTITLE_TEXT, TILESHEET_SUBTITLE_TEXT, SPRITES_SUBTITLE_TEXT },
   }
   setmetatable(this, self)

   this:repositionIfNecessary()

   mapList:onSelect(function(value)
      if value == NEW_MAP_ITEM then
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
            mapList:addItemAndKeepSorted({ value = nameInput.value })
            viewStack:popView(self.dialog)
            self.dialog = nil
            openEditor(MapEditor:create(MAP_DIRECTORY .. "/" .. nameInput.value, TILESHEET_DIRECTORY))
         end)
         local cancelButton = Button:create("Cancel", nil, function()
            viewStack:popView(self.dialog)
            self.dialog = nil
         end)

         self.dialog = Dialog:create("Create a new map", "What should the name of the map be?",
            { nameInput, widthInput, heightInput }, { cancelButton, okButton })
      else
         openEditor(MapEditor:create(MAP_DIRECTORY .. "/" .. value, TILESHEET_DIRECTORY))
      end
   end)

   tilesheetList:onSelect(function(value)
      if value == NEW_TILESHEET_ITEM then
         local nameInput = TextInput:create(300, "Name", "", {
            kebabCase = true,
            validations = { function(value) return not tilesheetTable[value] end }
         })
         local widthInput = TextInput:create(50, "Tile width", "32", { positive = true, integer = true })
         local heightInput = TextInput:create(50, "Tile height", "32", { positive = true, integer = true })

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
            tilesheetList:addItemAndKeepSorted({ label = nameInput.value, value = pngFilePath })

            viewStack:popView(self.dialog)
            self.dialog = nil
            openEditor(ImageEditor:create(pngFilePath))
         end)
         local cancelButton = Button:create("Cancel", nil, function()
            viewStack:popView(self.dialog)
            self.dialog = nil
         end)

         self.dialog = Dialog:create("Create a new tilesheet", nil,
            { nameInput, widthInput, heightInput }, { cancelButton, okButton })
      else
         openEditor(ImageEditor:create(value))
      end
   end)

   spriteList:onSelect(function(value)
      if value == NEW_SPRITE_ITEM then
         local nameInput = TextInput:create(300, "Name", "", {
            kebabCase = true,
            validations = { function(value) return not spriteTable[value] end }
         })

         local okButton = Button:create("OK", "solid", function()
            if not nameInput.isValid then
               return
            end

            local directory = NativeFile:create(SPRITE_DIRECTORY .. "/" .. nameInput.value)
            directory:createDirectory()

            spriteList:addItemAndKeepSorted({ label = directory.name, value = directory.path })
            spriteTable[nameInput.value] = true
            viewStack:popView(self.dialog)
            self.dialog = nil
            openEditor(SpriteEditor:create(directory.path))
         end)
         local cancelButton = Button:create("Cancel", nil, function()
            viewStack:popView(self.dialog)
            self.dialog = nil
         end)

         self.dialog = Dialog:create("Create a new sprite", nil, { nameInput }, { cancelButton, okButton })
      else
         openEditor(SpriteEditor:create(value))
      end
   end)

   return this
end

--- LOVE update handler
function MainMenu:update()
   if love.keyboard.escapeIsPressed and self.onClose then
      self.onClose()
   end

   self:repositionIfNecessary()

   for _, list in ipairs(self.lists) do
      list:update()
   end
end

function MainMenu:repositionIfNecessary()
   local windowWidth = love.graphics.getDimensions()
   if windowWidth == self.lastWidth then
      return
   end
   self.lastWidth = windowWidth

   local listWidth = math.floor(love.graphics.getWidth() / 3)
   local currentX = 0
   for _, list in ipairs(self.lists) do
      list:setPosition(currentX, LIST_Y_POSITION)
      list:setSize(listWidth)
      currentX = currentX + listWidth
   end
end

--- LOVE draw handler
function MainMenu:draw()
   love.graphics.clear(BACKGROUND_VALUE * 1.1, BACKGROUND_VALUE, BACKGROUND_VALUE * 1.2)

   love.graphics.setColor(0.2, 0.7, 1.0)
   love.graphics.draw(TITLE_TEXT, math.floor((love.graphics.getWidth() - TITLE_TEXT:getWidth()) / 2), TITLE_PADDING_TOP)
   love.graphics.reset()

   for index, list in ipairs(self.lists) do
      list:draw()
      love.graphics.setColor(0.2, 0.7, 1.0)
      love.graphics.draw(self.subtitles[index], math.floor(list.x + (list.width - self.subtitles[index]:getWidth()) / 2), SUBTITLE_Y_POSITION)
      love.graphics.reset()
      if index > 1 then
         love.graphics.line(list.x, SUBTITLE_Y_POSITION, list.x, love.graphics.getHeight())
      end
   end
end