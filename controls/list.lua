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
local BUTTON_HORIZONTAL_PADDING = 3

--- A simple List
-- @param x {number} - The (leftmost) X position of the list
-- @param y {number} - The (topmost) Y position of the list
-- @param width {number} - The width of the list
-- @param items {{value: string, label?: string, icon?, iconQuad?, iconQuadWidth?: number, iconQuadHeight?: number,
-- buttons?: {label: string, handler: function, colour?: {r: number, g: number, b: number}}[]}[]} - The items in the list
-- @param options {{iconSize?: int} | nil} - Some additional options for the list items.
function List:create(items, options)
   options = options or {}

   local this = {
      x = 0,
      y = 0,
      height = 0,
      width = 0,
      items = items,
      selection = nil,
      selectCallbacks = {},
      iconSize = options.iconSize or DEFAULT_ICON_SIZE,
      hasIcons = false,
      lastY = 0,
      isActive = false,
      selectedItem = nil,
   }
   setmetatable(this, self)

   for _, item in ipairs(items) do
      this:initializeItemIcon(item)
      item.buttonElements = {}
      print(item.buttons and #item.buttons)
      for _, button in ipairs(item.buttons or {}) do
         button.text = button.text or love.graphics.newText(ITEM_FONT, button.label)
         item.buttonElements[#item.buttonElements + 1] = {
            width = button.text:getWidth() + BUTTON_HORIZONTAL_PADDING * 2,
            text = button.text,
            colour = button.colour or { r = 1, g = 0.8, b = 0.5 },
            clickHandler = button.clickHandler,
         }
      end
   end

   this:repositionItems()

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
      local newY = self.y
      self.y = self.lastY
      self:setPosition(self.x, newY)
   end

   self.isActive = false
   for index, item in ipairs(self.items) do
      for _, buttonElement in ipairs(item.buttonElements) do
         local mouseInfo = love.mouse.registerSolid(buttonElement)
         buttonElement.isHovered = mouseInfo.isHovered
         self.isActive = self.isActive or buttonElement.isHovered
         buttonElement.isHeldDown = mouseInfo.drag ~= nil

         if mouseInfo.isHovered and buttonElement.clickHandler then
            love.mouse.cursor = HOVER_CURSOR
            if mouseInfo.dragConfirmed then
               buttonElement.clickHandler()
            end
         end
      end
      local mouseInfo = love.mouse.registerSolid(item)
      item.isHovered = mouseInfo.isHovered
      self.isActive = self.isActive or item.isHovered

      if self.selectedItem ~= index and mouseInfo.isHovered and #self.selectCallbacks > 0 then
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

--- Change the position of this list
-- @param x {number} The new X left position
-- @param y {number} The new Y top position
function List:setPosition(x, y)
   local dx, dy = x - self.x, y - self.y
   self.x, self.y, self.lastY = x, y, y

   for _, item in ipairs(self.items) do
      item.x, item.y = item.x + dx, item.y + dy
      item.textX, item.textY = item.textX + dx, item.textY + dy

      for _, buttonElement in ipairs(item.buttonElements) do
         buttonElement.x, buttonElement.y = buttonElement.x + dx, buttonElement.y + dy
         buttonElement.textX, buttonElement.textY = buttonElement.textX + dx, buttonElement.textY + dy
      end
   end
end

--- Change the width of this list
-- @param width {number} The new width
function List:setSize(width, _)
   self.width = width
   self.height = 0
   self:repositionItems()
end

--- Recalculate the position of all items
function List:repositionItems()
   local currentY = self.y
   for _, item in ipairs(self.items) do
      item.x, item.y = self.x, currentY
      item.textX = item.x + ITEM_HORIZONTAL_PADDING + (self.hasIcons and (self.iconSize + ICON_MARGIN_RIGHT) or 0)
      item.width = self.width

      local buttonElementX = item.x + self.width
      for _, buttonElement in ipairs(item.buttonElements) do
         buttonElementX = buttonElementX - buttonElement.width
         buttonElement.x, buttonElement.y = buttonElementX, currentY
         buttonElement.textX = buttonElementX + BUTTON_HORIZONTAL_PADDING
      end

      local textWidth = buttonElementX - ITEM_HORIZONTAL_PADDING - item.textX
      for _, buttonElement in ipairs(item.buttonElements) do
         buttonElement.y = currentY
      end
      local _, wrappedItemValue = ITEM_FONT:getWrap(item.label or item.value, textWidth)
      item.text = love.graphics.newText(ITEM_FONT, wrappedItemValue)
      item.height = math.max(item.text:getHeight(), item.icon and self.iconSize or 0) + ITEM_VERTICAL_PADDING * 2
      item.textY = item.y + math.floor((item.height - item.text:getHeight()) / 2)
      for _, buttonElement in ipairs(item.buttonElements) do
         buttonElement.height = item.height
      end
      currentY = currentY + item.height
      self.height = self.height + item.height

      for _, buttonElement in ipairs(item.buttonElements) do
         buttonElement.height = item.height
         buttonElement.textY = buttonElement.y + math.floor((item.height - buttonElement.text:getHeight()) / 2)
      end
   end
end

--- Remove an item, shifting all next items left
-- @param itemToRemove {Item} The item that must be removed
function List:removeItem(itemToRemove)
   local hasRemovedItem = false
   for i = 1, #self.items do
      if hasRemovedItem then
         self.items[i - 1] = self.items[i]
      elseif self.items[i] == itemToRemove then
         hasRemovedItem = true
      end
   end
   self.items[#self.items] = nil

   self:repositionItems()
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
   self:repositionItems()
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
      local backgroundRectangleOpacity = (self.selectedItem == index and 0.2 or (item.isHovered and 0.1 or 0))
      if backgroundRectangleOpacity > 0 then
         love.graphics.setColor(1, 1, 1, backgroundRectangleOpacity)
         love.graphics.rectangle("fill", item.x, item.y, item.width, item.height)
         love.graphics.reset()
      end
      for _, buttonElement in ipairs(item.buttonElements) do
         local buttonRectangleOpacity = buttonElement.isHeldDown and 0.2 or (buttonElement.isHovered and 0.1 or 0)
         if buttonRectangleOpacity > 0 then
            love.graphics.setColor(1, 1, 1, buttonRectangleOpacity)
            love.graphics.rectangle("fill", buttonElement.x, buttonElement.y, buttonElement.width, buttonElement.height)
            love.graphics.reset()
         end
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
      for _, buttonElement in ipairs(item.buttonElements) do
         local colour = buttonElement.colour;
         love.graphics.setColor(colour.r, colour.g, colour.b, 1)
         love.graphics.draw(buttonElement.text, buttonElement.textX, buttonElement.textY)
      end
      love.graphics.reset()
   end
end
