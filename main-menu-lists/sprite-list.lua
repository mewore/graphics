require "controls/list"
require "data/native-file"
require "views/sprite-editor"

SpriteList = {}
SpriteList.__index = SpriteList

local SPRITE_DIRECTORY = love.filesystem.getWorkingDirectory() .. "/sprites"
local NEW_SPRITE_ITEM = "(+) New sprite"

--- Open an editor at the top of the view stack and remove it when it is closed
-- @param editor The editor to open
local function openEditor(editor)
   viewStack:pushView(editor)
   editor.onClose = function() viewStack:popView(editor) end
end

--- A list of sprites in the current working directory
function SpriteList:create()
   local spriteDirectories = NativeFile:create(SPRITE_DIRECTORY):getDirectories()
   local spriteDirectoryTable = {}
   local spriteItems = { { value = NEW_SPRITE_ITEM } }
   for _, spriteDirectory in ipairs(spriteDirectories) do
      spriteDirectoryTable[spriteDirectory.name] = spriteDirectory
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

   local list
   local renameButton = {
      label = "Rename",
      colour = { r = 0.6, g = 0.8, b = 1 },
      appliesToItem = function(item) return item.value ~= NEW_SPRITE_ITEM end,
      clickHandler = function(item)
         local dialog
         local nameInput = TextInput:create(300, "Name", item.value, {
            kebabCase = true,
            validations = { function(value) return not list:containsValue(value) end }
         })

         local okButton = Button:create("OK", "solid", function()
            if not (nameInput.isValid) then return end
            local oldName, newName = item.value, nameInput.value

            if spriteDirectoryTable[oldName] then
               spriteDirectoryTable[newName] = spriteDirectoryTable[oldName]:rename(newName)
               spriteDirectoryTable[oldName] = nil
            end

            list:removeItem(item)
            item.value = newName
            list:addItemAndKeepSorted(item)
            viewStack:popView(dialog)
         end)
         local cancelButton = Button:create("Cancel", nil, function() viewStack:popView(dialog) end)

         dialog = Dialog:create("Rename sprite '" .. item.value .. "'", "What should the new name of the sprite be?",
            { nameInput }, { cancelButton, okButton })
      end,
   }
   list = List:create(spriteItems, { iconSize = 32, buttons = { renameButton } })
   local this = {
      list = list,
   }
   setmetatable(this, self)

   list:onSelect(function(value)
      if value == NEW_SPRITE_ITEM then
         local dialog
         local nameInput = TextInput:create(300, "Name", "", {
            kebabCase = true,
            validations = { function(value) return not list:containsValue(value) end }
         })

         local okButton = Button:create("OK", "solid", function()
            if not nameInput.isValid then return end

            local directory = NativeFile:create(SPRITE_DIRECTORY .. "/" .. nameInput.value)
            directory:createDirectory()

            list:addItemAndKeepSorted({ label = directory.name, value = directory.path })

            viewStack:popView(dialog)
            openEditor(SpriteEditor:create(directory.path))
         end)
         local cancelButton = Button:create("Cancel", nil, function() viewStack:popView(dialog) end)

         dialog = Dialog:create("Create a new sprite", nil, { nameInput }, { cancelButton, okButton })
      else
         openEditor(SpriteEditor:create(SPRITE_DIRECTORY .. "/" .. value))
      end
   end)

   return this
end

function SpriteList:setPosition(x, y) self.list:setPosition(x, y) end

function SpriteList:setSize(width, height) self.list:setSize(width, height) end

function SpriteList:setSize(width, height) self.list:setSize(width, height) end

function SpriteList:getX() return self.list:getX() end

function SpriteList:getY() return self.list:getY() end

function SpriteList:getWidth() return self.list:getWidth() end

function SpriteList:getHeight() return self.list:getHeight() end

--- LOVE update handler
-- @param dt {float} - The amount of time (in seconds) since the last update
function SpriteList:update(dt)
   self.list:update(dt)
end

--- LOVE draw handler
function SpriteList:draw()
   self.list:draw()
end