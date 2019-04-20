require "controls/list"
require "data/native-file"
require "main-menu-lists/map-list"
require "main-menu-lists/tilesheet-list"
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

local SPRITE_DIRECTORY = love.filesystem.getWorkingDirectory() .. "/sprites"

local NEW_SPRITE_ITEM = "(+) New sprite"

--- Open an editor at the top of the view stack and remove it when it is closed
-- @param editor The editor to open
local function openEditor(editor)
   viewStack:pushView(editor)
   editor.onClose = function() viewStack:popView(editor) end
end

--- The main menu
function MainMenu:create()
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

   local spriteList = List:create(spriteItems, { iconSize = 32 })

   local this = {
      lists = { MapList:create(), TilesheetList:create(), spriteList },
      subtitles = { MAPS_SUBTITLE_TEXT, TILESHEET_SUBTITLE_TEXT, SPRITES_SUBTITLE_TEXT },
   }
   setmetatable(this, self)

   this:repositionIfNecessary()

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
      love.graphics.draw(self.subtitles[index], math.floor(list:getX() + (list:getWidth() - self.subtitles[index]:getWidth()) / 2), SUBTITLE_Y_POSITION)
      love.graphics.reset()
      if index > 1 then
         love.graphics.line(list:getX(), SUBTITLE_Y_POSITION, list:getX(), love.graphics.getHeight())
      end
   end
end