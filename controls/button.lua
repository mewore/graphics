Button = {}
Button.__index = Button

local WHITE = { r = 1, g = 1, b = 1 }
local BLUE = { r = 0, g = 0.3, b = 0.6 }
local RED = { r = 0.6, g = 0, b = 0 }
local BUTTON_FILL_COLOUR_PER_TYPE = {
   danger = RED,
   solid = BLUE,
   outline = nil,
   bare = nil,
}
local BUTTON_OUTLINE_COLOUR_PER_TYPE = {
   danger = RED,
   solid = BLUE,
   outline = BLUE,
   bare = BLUE,
}
local TEXT_COLOUR_PER_TYPE = {
   danger = WHITE,
   solid = WHITE,
   outline = BLUE,
   bare = BLUE,
}

local MIN_WIDTH = 50
local BORDER_RADIUS = 3
local TEXT_PADDING_SIDES = 5
local TEXT_PADDING_UP_DOWN = 5

local CARLITO_FONT_PATH = 'fonts/carlito.ttf'
local TEXT_FONT_SIZE = 14
local TEXT_FONT = love.graphics.newFont(CARLITO_FONT_PATH, TEXT_FONT_SIZE)

local BUTTON_HEIGHT = TEXT_FONT_SIZE + TEXT_PADDING_UP_DOWN * 2

local HOVER_CURSOR = love.mouse.getSystemCursor("hand")

--- A simple button
-- @param label {string} - The displayed label of the button
-- @param type {string} - The button type ("danger"/"solid"/"outline"/"bare"); "outline" by default (if set to nil)
-- @param onClick {function} - The click handler
function Button:create(label, type, onClick)
   if type == nil or BUTTON_FILL_COLOUR_PER_TYPE[type] == nil then
      type = "outline"
   end

   local text = love.graphics.newText(TEXT_FONT, label)
   local width = math.max(text:getWidth() + TEXT_PADDING_SIDES * 2, MIN_WIDTH)
   local this = {
      x = 0,
      y = 0,
      width = width,
      height = BUTTON_HEIGHT,
      label = "",
      text = text,
      onClick = onClick,
      type = type,
      textOffsetX = math.floor((width - text:getWidth()) / 2)
   }
   setmetatable(this, self)

   return this
end

--- Change the position of this element
-- @param x {number} The new X left position
-- @param y {number} The new Y top position
function Button:setPosition(x, y) self.x, self.y = x, y end

--- Get both the X and the Y position of this element
-- @returns {int}, {int}
function Button:getPosition() return self.x, self.y end

--- Change the size of this element
-- @param width {number} The new width
-- @param height {number} The new height
function Button:setSize(width, height) self.width, self.height = width, height end

--- Get the size of this element
-- @returns {int}, {int}
function Button:getSize() return self.width, self.height end

--- LOVE update handler
function Button:update()
   self.isFocused = love.keyboard.registerFocusable(self)

   local mouseInfo = love.mouse.registerSolid(self)
   if mouseInfo.isHovered then
      love.mouse.cursor = HOVER_CURSOR
   end

   if self.onClick and ((self.isFocused and love.keyboard.returnIsPressed)
         or (mouseInfo.isHovered and mouseInfo.dragConfirmed)) then
      self.onClick()
   end
end

local function setColour(colour)
   if not colour then
      return false
   end
   love.graphics.setColor(colour.r, colour.g, colour.b, 1)
   return true
end

--- LOVE draw handler
function Button:draw()
   love.graphics.drawFocusOutline(self)

   if setColour(BUTTON_FILL_COLOUR_PER_TYPE[self.type]) then
      love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, BORDER_RADIUS, BORDER_RADIUS)
   end
   if self.text and setColour(TEXT_COLOUR_PER_TYPE[self.type]) then
      love.graphics.draw(self.text, self.x + self.textOffsetX, self.y + TEXT_PADDING_UP_DOWN)
   end
   setColour(BUTTON_OUTLINE_COLOUR_PER_TYPE[self.type])
   love.graphics.rectangle("line", self.x, self.y, self.width, self.height, BORDER_RADIUS, BORDER_RADIUS)
   love.graphics.reset()
end
