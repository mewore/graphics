PaintDisplaySquare = {}
PaintDisplaySquare.__index = PaintDisplaySquare

local SQUARE_SIZE = 56
local CHECKERBOARD_DARK_VALUE = 0.3
local CHECKERBOARD = love.graphics.newImage("graphics/checkerboard-pattern-64.png")
local CHECKERBOARD_QUAD = love.graphics.newQuad(0, 0, math.min(SQUARE_SIZE, CHECKERBOARD:getWidth()),
   math.min(SQUARE_SIZE, CHECKERBOARD:getHeight()), CHECKERBOARD:getDimensions())

function PaintDisplaySquare:create(value, drawFunction, paintPicker)
   local this = {
      x = 0,
      y = 0,
      width = SQUARE_SIZE,
      height = SQUARE_SIZE,
      drawFunction = drawFunction,
      paintPicker = paintPicker,
      value = value,
      isActive = false,
   }
   setmetatable(this, self)

   return this
end

--- Change the position of this element
-- @param x {number} The new X left position
-- @param y {number} The new Y top position
function PaintDisplaySquare:setPosition(x, y) self.x, self.y = x, y end

--- Get both the X and the Y position of this element
-- @returns {int}, {int}
function PaintDisplaySquare:getPosition() return self.x, self.y end

--- Change the size of this element
-- @param width {number} The new width
-- @param height {number} The new height
function PaintDisplaySquare:setSize(width, height) self.width, self.height = width, height end

--- Get the size of this element
-- @returns {int}, {int}
function PaintDisplaySquare:getSize() return self.width, self.height end

function PaintDisplaySquare:update()
   if self.paintPicker then
      local mouseInfo = love.mouse.registerSolid(self)
      self.isActive = mouseInfo.isHovered

      if mouseInfo.dragConfirmed and mouseInfo.isHovered then
         self.paintPicker:open(self.value, function(value) self.value = value end)
      end
   end
end

function PaintDisplaySquare:draw()
   love.graphics.setColor(CHECKERBOARD_DARK_VALUE, CHECKERBOARD_DARK_VALUE, CHECKERBOARD_DARK_VALUE)
   love.graphics.rectangle("fill", self.x, self.y, SQUARE_SIZE, SQUARE_SIZE)
   love.graphics.setColor(1, 1, 1)
   love.graphics.draw(CHECKERBOARD, CHECKERBOARD_QUAD, self.x, self.y)

   self.drawFunction(self.x, self.y, self.value, SQUARE_SIZE, SQUARE_SIZE)
   love.graphics.setColor(not (self.hoveredBack and self.paintPicker ~= nil) and 1 or 0, 1, 1, 1)
   love.graphics.rectangle("line", self.x, self.y, SQUARE_SIZE, SQUARE_SIZE)
end
