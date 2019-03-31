List = {}
List.__index = List

local CARLITO_FONT_PATH = 'fonts/carlito.ttf'
local ITEM_FONT_SIZE = 14
local ITEM_FONT = love.graphics.newFont(CARLITO_FONT_PATH, ITEM_FONT_SIZE)

local HOVER_CURSOR = love.mouse.getSystemCursor("hand")

local ITEM_VERTICAL_PADDING = 3
local ITEM_HORIZONTAL_PADDING = 3

--- A simple List
-- @param x {number} - The (leftmost) X position of the list
-- @param y {number} - The (topmost) Y position of the list
-- @param width {number} - The width of the list
-- @param itemValues {string[]} - The items in the list
function List:create(x, y, width, itemValues)
   local items = {}
   for index, value in ipairs(itemValues) do
      items[index] = {
         value = value,
      }
   end

   local this = {
      y = y,
      items = items,
      selection = nil,
      selectCallbacks = {},
   }
   setmetatable(this, self)

   this:setX(x)
   this:setWidth(width)

   return this
end

--- LOVE update handler
function List:update()
   for _, item in ipairs(self.items) do
      local mouseInfo = love.mouse.registerSolid(item)
      item.isHovered = mouseInfo.isHovered

      if mouseInfo.isHovered then
         love.mouse.cursor = HOVER_CURSOR
         if mouseInfo.dragConfirmed then
            for _, callback in ipairs(self.selectCallbacks) do
               callback(item.value)
            end
         end
      end
   end
end

function List:onSelect(callback)
   self.selectCallbacks[#self.selectCallbacks + 1] = callback
end

--- Change the X position of this list
-- @param newX {number} The new (leftmost) X position
function List:setX(newX)
   self.x = newX

   for _, item in ipairs(self.items) do
      item.x = newX
      item.textX = item.x + ITEM_HORIZONTAL_PADDING
   end
end

--- Change the width of this list
-- @param newWidth {number} The new width
function List:setWidth(newWidth)
   self.width = newWidth

   local currentY = self.y
   for _, item in ipairs(self.items) do
      local _, wrappedItemValue = ITEM_FONT:getWrap(item.value, newWidth - ITEM_HORIZONTAL_PADDING * 2)
      item.y = currentY
      item.text = love.graphics.newText(ITEM_FONT, wrappedItemValue)
      item.height = item.text:getHeight() + ITEM_VERTICAL_PADDING * 2
      item.width = newWidth
      item.textY = item.y + ITEM_VERTICAL_PADDING
      currentY = currentY + item.height
   end
end

--- LOVE draw handler
function List:draw()
   for _, item in ipairs(self.items) do
      if item.isHovered then
         love.graphics.setColor(1, 1, 1, 0.1)
         love.graphics.rectangle("fill", item.x, item.y, item.width, item.height)
         love.graphics.reset()
      end
      love.graphics.draw(item.text, item.textX, item.textY)
   end
end
