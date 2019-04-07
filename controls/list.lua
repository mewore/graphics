List = {}
List.__index = List

local CARLITO_FONT_PATH = 'fonts/carlito.ttf'
local ITEM_FONT_SIZE = 14
local ITEM_FONT = love.graphics.newFont(CARLITO_FONT_PATH, ITEM_FONT_SIZE)
local DEFAULT_ICON_SIZE = 16
local ICON_MARGIN_RIGHT = 4

local HOVER_CURSOR = love.mouse.getSystemCursor("hand")

local ITEM_VERTICAL_PADDING = 3
local ITEM_HORIZONTAL_PADDING = 3

--- A simple List
-- @param x {number} - The (leftmost) X position of the list
-- @param y {number} - The (topmost) Y position of the list
-- @param width {number} - The width of the list
-- @param items {{value: string, label?: string, icon?, iconQuad?, iconQuadWidth?: number, iconQuadHeight?: number}[]} - The items in the list
-- @param options {{iconSize?: int} | nil} - Some additional options for the list items.
function List:create(x, y, width, items, options)
   options = options or {}

   local this = {
      y = y,
      items = items,
      selection = nil,
      selectCallbacks = {},
      iconSize = options.iconSize or DEFAULT_ICON_SIZE,
      hasIcons = false,
      height = 0,
      lastY = y,
      isActive = false,
      selectedItem = nil,
   }
   setmetatable(this, self)

   for _, item in ipairs(items) do
      this:initializeItemIcon(item)
   end

   this:setX(x)
   this:setWidth(width)

   return this
end

function List:initializeItemIcon(item)
   if item.icon then
      self.hasIcons = true
      if item.iconQuadWidth and item.iconQuadHeight then
         item.iconQuad = love.graphics.newQuad(0, 0, item.iconQuadWidth, item.iconQuadHeight,
            item.icon:getDimensions())

         item.iconScale = self.iconSize / math.max(item.iconQuadWidth, item.iconQuadHeight)
         item.iconOffsetX = math.floor((self.iconSize - item.iconQuadWidth * item.iconScale) / 2)
         item.iconOffsetY = math.floor((self.iconSize - item.iconQuadHeight * item.iconScale) / 2)
      else
         item.iconScale = self.iconSize / math.max(item.icon:getWidth(), item.icon:getHeight())
         item.iconOffsetX = math.floor((self.iconSize - item.icon:getWidth() * item.iconScale) / 2)
         item.iconOffsetY = math.floor((self.iconSize - item.icon:getHeight() * item.iconScale) / 2)
      end
   end
end

--- LOVE update handler
function List:update()
   if self.lastY ~= self.y then
      local dy = self.y - self.lastY
      for _, item in ipairs(self.items) do
         item.y, item.textY = item.y + dy, item.textY + dy
      end
      self.lastY = self.y
   end

   self.isActive = false
   for _, item in ipairs(self.items) do
      local mouseInfo = love.mouse.registerSolid(item)
      item.isHovered = mouseInfo.isHovered
      self.isActive = self.isActive or item.isHovered

      if mouseInfo.isHovered and #self.selectCallbacks > 0 then
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
      item.textX = item.x + ITEM_HORIZONTAL_PADDING + (self.hasIcons and (self.iconSize + ICON_MARGIN_RIGHT) or 0)
   end
end

--- Change the width of this list
-- @param newWidth {number} The new width
function List:setWidth(newWidth)
   self.width = newWidth
   self.height = 0

   local currentY = self.y
   for _, item in ipairs(self.items) do
      local textWidth = newWidth - ITEM_HORIZONTAL_PADDING * 2
      if item.icon then
         textWidth = textWidth - self.iconSize - ICON_MARGIN_RIGHT
      end
      local _, wrappedItemValue = ITEM_FONT:getWrap(item.label or item.value, textWidth)
      item.y = currentY
      item.text = love.graphics.newText(ITEM_FONT, wrappedItemValue)
      item.height = math.max(item.text:getHeight(), item.icon and self.iconSize or 0) + ITEM_VERTICAL_PADDING * 2
      item.width = newWidth
      item.textY = item.y + math.floor((item.height - item.text:getHeight()) / 2)
      currentY = currentY + item.height
      self.height = self.height + item.height
   end
end

--- Add an item at such a position that the list remains sorted
-- @param newItem {Item} The new item
function List:addItemAndKeepSorted(newItem)
   local currentItem = newItem
   for i = 1, #self.items do
      if self.items[i].value > currentItem.value then
         currentItem, self.items[i] = self.items[i], currentItem
      end
   end
   self.items[#self.items + 1] = currentItem

   self:initializeItemIcon(newItem)
   self:setX(self.x)
   self:setWidth(self.width)
end

--- Mark an item as select
-- @param itemToSelect {table | string} The item or value to select.
function List:select(itemToSelect)
   self.selectedItem = nil
   for index, item in ipairs(self.items) do
      if item == itemToSelect or item.value == itemToSelect then
         self.selectedItem = index
         return
      end
   end
end

--- LOVE draw handler
function List:draw()
   for index, item in ipairs(self.items) do
      local backgroundRectangleOpacity = math.max(self.selectedItem == index and 0.2 or 0, item.isHovered and 0.1 or 0)
      if backgroundRectangleOpacity > 0 then
         love.graphics.setColor(1, 1, 1, backgroundRectangleOpacity)
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
