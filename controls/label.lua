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
      text = text,
      width = text:getWidth(),
      height = text:getHeight(),
   }
   setmetatable(this, self)

   return this
end

--- LOVE update handler
function Label:update()
end

--- LOVE draw handler
function Label:draw()
   love.graphics.setColor(0.2, 0.7, 1.0)
   love.graphics.draw(self.text, self.x, self.y)
   love.graphics.reset()
end
