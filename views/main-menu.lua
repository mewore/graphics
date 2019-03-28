require "data/map-encoder"
require "data/native-file"
require "views/map-editor"

MainMenu = {}
MainMenu.__index = MainMenu

local CARLITO_FONT_PATH = 'fonts/carlito.ttf'
local MAP_NAME_FONT = love.graphics.newFont(CARLITO_FONT_PATH, 14)
local TITLE_FONT = love.graphics.newFont(CARLITO_FONT_PATH, 32)
local TITLE_PADDING_TOP = 10
local TITLE_TEXT = love.graphics.newText(TITLE_FONT, "Choose a map to edit")
local PADDING_TOP = TITLE_PADDING_TOP + TITLE_TEXT:getHeight() + 10

local MARGIN_BOTTOM = 0

local MAP_ITEM_PADDING = 3
local MAP_ITEM_WIDTH = 300

local BACKGROUND_VALUE = 0.2

local MAP_DIRECTORY = love.filesystem.getWorkingDirectory() .. "/maps"
local SPRITESHEET_DIRECTORY = love.filesystem.getWorkingDirectory() .. "/tilesheets"
local HAND_CURSOR = love.mouse.getSystemCursor("hand")

--- The main menu
function MainMenu:create()
   local mapFiles = NativeFile:create(MAP_DIRECTORY):getFiles("map")

   local y = PADDING_TOP
   local mapListItems = {}
   for i = 1, #mapFiles do
      local text = love.graphics.newText(MAP_NAME_FONT, mapFiles[i].name)
      mapListItems[i] = {
         path = MAP_DIRECTORY .. "/" .. mapFiles[i].name,
         text = text,
         y = y,
         textY = y + MAP_ITEM_PADDING,
         width = math.max(text:getWidth() + MAP_ITEM_PADDING * 2, MAP_ITEM_WIDTH),
         height = text:getHeight() + MAP_ITEM_PADDING * 2,
         isHovered = false,
      }
      y = y + mapListItems[i].height + MARGIN_BOTTOM
   end

   local this = {
      mapListItems = mapListItems,
      mapEditor = nil,
   }
   setmetatable(this, self)

   this:repositionIfNecessary()

   return this
end

--- LOVE update handler
function MainMenu:update()
   if love.keyboard.escapeIsPressed and self.onClose then
      self.onClose()
   end

   self:repositionIfNecessary()

   for _, mapItem in ipairs(self.mapListItems) do
      local mouseInfo = love.mouse.registerSolid(mapItem)
      mapItem.isHovered = mouseInfo.isHovered
      if mapItem.isHovered then
         love.mouse.cursor = HAND_CURSOR
      end
      if mapItem.isHovered and mouseInfo.dragConfirmed then
         self.mapEditor = MapEditor:create(mapItem.path, SPRITESHEET_DIRECTORY)
         viewStack:pushView(self.mapEditor)
         self.mapEditor.onClose = function()
            viewStack:popView(self.mapEditor)
            self.mapEditor = nil
         end
      end
   end
end

function MainMenu:repositionIfNecessary()
   local screenWidth, screenHeight = love.graphics.getDimensions()
   if screenWidth == self.lastScreenWidth and screenHeight == self.lastScreenHeight then
      return
   end
   self.lastScreenWidth, self.lastScreenHeight = screenWidth, screenHeight

   for _, mapItem in ipairs(self.mapListItems) do
      mapItem.x = math.floor((screenWidth - mapItem.width) / 2)
      mapItem.textX = mapItem.x + math.floor((mapItem.width - mapItem.text:getWidth()) / 2)
   end
end

--- LOVE draw handler
function MainMenu:draw()
   love.graphics.clear(BACKGROUND_VALUE * 1.1, BACKGROUND_VALUE, BACKGROUND_VALUE * 1.2)

   love.graphics.draw(TITLE_TEXT, math.floor((love.graphics.getWidth() - TITLE_TEXT:getWidth()) / 2), TITLE_PADDING_TOP)

   for _, mapItem in ipairs(self.mapListItems) do
      if mapItem.isHovered then
         love.graphics.setColor(1, 1, 1, 0.1)
         love.graphics.rectangle("fill", mapItem.x, mapItem.y, mapItem.width, mapItem.height)
         love.graphics.reset()
      end
      love.graphics.draw(mapItem.text, mapItem.textX, mapItem.textY)
   end
end