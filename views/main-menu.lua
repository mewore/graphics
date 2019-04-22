require "main-menu-lists/map-list"
require "main-menu-lists/tilesheet-list"
require "main-menu-lists/sprite-list"

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

--- The main menu
function MainMenu:create()
   local this = {
      lists = { MapList:create(), TilesheetList:create(), SpriteList:create() },
      subtitles = { MAPS_SUBTITLE_TEXT, TILESHEET_SUBTITLE_TEXT, SPRITES_SUBTITLE_TEXT },
   }
   setmetatable(this, self)

   this:repositionIfNecessary()

   return this
end

--- LOVE update handler
function MainMenu:update()
   if love.keyboard.closeIsPressed and self.onClose then
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
      love.graphics.draw(self.subtitles[index], math.floor(list:getX() + (list:getWidth() - self.subtitles[index]:getWidth()) / 2), SUBTITLE_Y_POSITION)
      love.graphics.reset()
      if index > 1 then
         love.graphics.line(list:getX(), SUBTITLE_Y_POSITION, list:getX(), love.graphics.getHeight())
      end
   end
end