require "controls/list"
require "data/map-encoder"
require "data/native-file"
require "views/map-editor"
require "views/tile-editor"

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

--- The main menu
function MainMenu:create()
   local mapFiles = NativeFile:create(MAP_DIRECTORY):getFiles("map")
   local mapItems = {}
   for i = 1, #mapFiles do
      mapItems[i] = { value = mapFiles[i].name }
   end

   local tilesheetFiles = NativeFile:create(TILESHEET_DIRECTORY):getFiles("png")
   local tilesheetInfoFiles = NativeFile:create(TILESHEET_DIRECTORY):getFiles("json")
   local tilesheetInfoByName = {}
   for _, tilesheetInfoFile in ipairs(tilesheetInfoFiles) do
      tilesheetInfoByName[tilesheetInfoFile.name] = tilesheetInfoFile:readAsJson()
   end

   local tilesheetItems = {}
   for index, file in ipairs(tilesheetFiles) do
      local tilesheetInfo = tilesheetInfoByName[file.name]
      if not tilesheetInfo then
         error("There is no " .. file.name .. ".json file corresponding to " .. file.filename)
      end
      tilesheetItems[index] = {
         label = file.name,
         value = file.path,
         icon = file:readAsImage(),
         iconQuadWidth = tilesheetInfo.width,
         iconQuadHeight = tilesheetInfo.height,
      }
   end

   local spriteDirectories = NativeFile:create(SPRITE_DIRECTORY):getDirectories()
   local spriteItems = {}
   for _, spriteDirectory in ipairs(spriteDirectories) do
      local item = { value = spriteDirectory.name }
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

      spriteItems[#spriteItems + 1] = item
   end

   local mapList = List:create(0, LIST_Y_POSITION, love.graphics.getWidth(), mapItems)
   local tilesheetList = List:create(0, LIST_Y_POSITION, love.graphics.getWidth(), tilesheetItems)
   local spriteList = List:create(0, LIST_Y_POSITION, love.graphics.getWidth(), spriteItems, { iconSize = 32 })

   local this = {
      lists = { mapList, tilesheetList, spriteList },
      subtitles = { MAPS_SUBTITLE_TEXT, TILESHEET_SUBTITLE_TEXT, SPRITES_SUBTITLE_TEXT },
   }
   setmetatable(this, self)

   this:repositionIfNecessary()

   mapList:onSelect(function(value)
      local mapEditor = MapEditor:create(MAP_DIRECTORY .. "/" .. value, TILESHEET_DIRECTORY)
      viewStack:pushView(mapEditor)
      mapEditor.onClose = function() viewStack:popView(mapEditor) end
   end)

   tilesheetList:onSelect(function(value)
      local imageEditor = ImageEditor:create(value)
      viewStack:pushView(imageEditor)
      imageEditor.onClose = function() viewStack:popView(imageEditor) end
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
      list:setX(currentX)
      list:setWidth(listWidth)
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