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

function PaintDisplaySquare:update()
   if self.paintPicker then
      local mouseInfo = love.mouse.registerSolid(self)
      self.isActive = mouseInfo.isHovered

      if mouseInfo.dragConfirmed and mouseInfo.isHovered then
         viewStack:pushView(self.paintPicker)
         self.paintPicker.onPick = function(newPaint)
            self.value = newPaint
            viewStack:popView(self.paintPicker)
         end
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
