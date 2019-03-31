List = {}
List.__index = List

local CARLITO_FONT_PATH = 'fonts/carlito.ttf'
local ITEM_FONT_SIZE = 14
local ITEM_FONT = love.graphics.newFont(CARLITO_FONT_PATH, ITEM_FONT_SIZE)
local ICON_SIZE = 16
local ICON_MARGIN_RIGHT = 4

local HOVER_CURSOR = love.mouse.getSystemCursor("hand")

local ITEM_VERTICAL_PADDING = 3
local ITEM_HORIZONTAL_PADDING = 3

--- A simple List
-- @param x {number} - The (leftmost) X position of the list
-- @param y {number} - The (topmost) Y position of the list
-- @param width {number} - The width of the list
-- @param itemValues {{value: string, label?: string, iconQuad?, iconQuadWidth?: number, iconQuadHeight?: number}[]} - The items in the list
function List:create(x, y, width, items)
   for _, item in ipairs(items) do
      if not item.icon and item.iconData then
         item.icon = love.graphics.newImage(item.iconData)
      end

      if item.icon then
         if item.iconQuadWidth and item.iconQuadHeight then
            item.iconQuad = love.graphics.newQuad(0, 0, item.iconQuadWidth, item.iconQuadHeight,
               item.icon:getDimensions())

            item.iconScale = ICON_SIZE / math.max(item.iconQuadWidth, item.iconQuadHeight)
            item.iconOffsetX = math.floor((ICON_SIZE - item.iconQuadWidth * item.iconScale) / 2)
            item.iconOffsetY = math.floor((ICON_SIZE - item.iconQuadHeight * item.iconScale) / 2)
         else
            item.iconScale = ICON_SIZE / math.max(item.icon:getWidth(), item.icon:getHeight())
            item.iconOffsetX = math.floor((ICON_SIZE - item.icon:getWidth() * item.iconScale) / 2)
            item.iconOffsetY = math.floor((ICON_SIZE - item.icon:getHeight() * item.iconScale) / 2)
         end
      end
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
      if item.icon then
         item.textX = item.textX + ICON_SIZE + ICON_MARGIN_RIGHT
      end
   end
end

--- Change the width of this list
-- @param newWidth {number} The new width
function List:setWidth(newWidth)
   self.width = newWidth

   local currentY = self.y
   for _, item in ipairs(self.items) do
      local textWidth = newWidth - ITEM_HORIZONTAL_PADDING * 2
      if item.icon then
         textWidth = textWidth - ICON_SIZE - ICON_MARGIN_RIGHT
      end
      local _, wrappedItemValue = ITEM_FONT:getWrap(item.label or item.value, textWidth)
      item.y = currentY
      item.text = love.graphics.newText(ITEM_FONT, wrappedItemValue)
      item.height = math.max(item.text:getHeight(), item.icon and ICON_SIZE or 0) + ITEM_VERTICAL_PADDING * 2
      item.width = newWidth
      item.textY = item.y + math.floor((item.height - item.text:getHeight()) / 2)
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
      if item.icon then
         local iconX = item.x + ITEM_HORIZONTAL_PADDING + item.iconOffsetX
         local iconY = item.y + ITEM_VERTICAL_PADDING + item.iconOffsetY
         if item.iconQuad then
            love.graphics.draw(item.icon, item.iconQuad, iconX, iconY, 0, item.iconScale, item.iconScale)
         else
            love.graphics.draw(item.icon, iconX, iconY, 0, item.iconScale, item.iconScale)
         end
      end
      love.graphics.draw(item.text, item.textX, item.textY)
   end
end
