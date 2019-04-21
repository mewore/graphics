Label = {}
Label.__index = Label

local CARLITO_FONT_PATH = 'fonts/carlito.ttf'
local LABEL_FONT_SIZE = 14
local LABEL_FONT = love.graphics.newFont(CARLITO_FONT_PATH, LABEL_FONT_SIZE)

--- A simple label
-- @param label {string} - The text of the label
function Label:create(label)
   local text = love.graphics.newText(LABEL_FONT, label)
   local this = {
      x = 0,
      y = 0,
      textX = 0,
      textY = 0,
      width = text:getWidth(),
      height = text:getHeight(),
      text = text,
   }
   setmetatable(this, self)

   return this
end

--- Change the position of this element
-- @param x {number} The new X left position
-- @param y {number} The new Y top position
function Label:setPosition(x, y)
   local dx, dy = x - self.x, y - self.y
   self.textX, self.textY = self.textX + dx, self.textY + dy
   self.x, self.y = x, y
end

--- Get both the X and the Y position of this element
-- @returns {int}, {int}
function Label:getPosition() return self.x, self.y end

--- Change the size of this element
-- @param width {number} The new width
-- @param height {number} The new height
function Label:setSize(width, height)
   self.textX = math.floor(self.x + (width - self.text:getWidth()) / 2)
   self.textY = math.floor(self.y + (height - self.text:getHeight()) / 2)
   self.width, self.height = width, height
end

--- Get the size of this element
-- @returns {int}, {int}
function Label:getSize() return self.width, self.height end

--- LOVE update handler
function Label:update()
end

--- LOVE draw handler
function Label:draw()
   love.graphics.setColor(0.2, 0.7, 1.0)
   love.graphics.draw(self.text, self.textX, self.textY)
   love.graphics.reset()
end
