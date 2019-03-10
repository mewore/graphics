PaintDisplay = {}
PaintDisplay.__index = PaintDisplay

local SQUARE_SIZE = 56
local LEFT_MOUSE_BUTTON = 1
local SWAP_KEY = "x"
local SQUARE_SHADOW_SIZE = 2
local SQUARE_SHADOW_OPACITY = 0.8

local CHECKERBOARD_DARK_VALUE = 0.3
local CHECKERBOARD = love.graphics.newImage("graphics/checkerboard-pattern-64.png")
local CHECKERBOARD_QUAD = love.graphics.newQuad(0, 0, math.min(SQUARE_SIZE, CHECKERBOARD:getWidth()),
   math.min(SQUARE_SIZE, CHECKERBOARD:getHeight()), CHECKERBOARD:getDimensions())

--- A preview of the currently used "front" and "back" paint ("paint" can mean colour, tile, etc.), and allows them to
-- be configured
-- @param initialFront {string} - The initial front paint
-- @param initialBack {string} - The intiial back paint
-- @param drawFunction {function} - A callback that draws a paint preview
-- @param paintPicker {Object} - An object that supports picking a paint, e.g. TilePicker
function PaintDisplay:create(initialFront, initialBack, drawFunction, paintPicker)
   if drawFunction == nil then
      error("The draw function cannot be nil!")
   end
   local totalSize = math.floor(SQUARE_SIZE * (3 / 2))
   local this = {
      x = 0,
      y = 0,
      width = totalSize,
      height = totalSize,
      previewWidth = SQUARE_SIZE,
      previewHeight = SQUARE_SIZE,
      front = initialFront,
      back = initialBack,
      drawFunction = drawFunction,
      hoveredFront = false,
      hoveredBack = false,
      frontLeft = 0,
      frontTop = 0,
      frontRight = 0,
      frontBottom = 0,
      backLeft = 0,
      backTop = 0,
      backRight = 0,
      backBottom = 0,
      paintPicker = paintPicker,
   }
   setmetatable(this, self)

   if paintPicker then
      paintPicker.onClose = function() viewStack:popView(paintPicker) end
   end

   return this
end

--- LOVE update handler
function PaintDisplay:update()
   self.frontLeft = self.x
   self.frontTop = self.x
   self.frontRight = self.x + SQUARE_SIZE
   self.frontBottom = self.y + SQUARE_SIZE
   self.backLeft = self.x + self.width - SQUARE_SIZE
   self.backTop = self.y + self.height - SQUARE_SIZE
   self.backRight = self.x + self.width
   self.backBottom = self.y + self.height

   local mouseX, mouseY = love.mouse.getX(), love.mouse.getY()
   local isOverFront = mouseX >= self.frontLeft and mouseX <= self.frontRight and mouseY >= self.frontTop and mouseY <= self.frontBottom
   local isOverBack = mouseX >= self.backLeft and mouseX <= self.backRight and mouseY >= self.backTop and mouseY <= self.backBottom
   self.hoveredFront = isOverFront
   self.hoveredBack = isOverBack and not isOverFront

   if love.mouse.buttonsPressed[LEFT_MOUSE_BUTTON] and self.paintPicker then
      if self.hoveredFront then
         viewStack:pushView(self.paintPicker)
         self.paintPicker.onPick = function(newPaint)
            self.front = newPaint
            viewStack:popView(self.paintPicker)
         end
      elseif self.hoveredBack then
         viewStack:pushView(self.paintPicker)
         self.paintPicker.onPick = function(newPaint)
            self.back = newPaint
            viewStack:popView(self.paintPicker)
         end
      end
   end

   if love.keyboard.keysPressed[SWAP_KEY] then
      self.front, self.back = self.back, self.front
   end
end

local function drawSquareShadow(fromX, fromY, toX, toY)
   love.graphics.setColor(0, 0, 0, SQUARE_SHADOW_OPACITY)
   love.graphics.rectangle("fill", fromX, fromY, toX - fromX, toY - fromY)
end

function PaintDisplay:__drawBackSquare()
   love.graphics.setColor(CHECKERBOARD_DARK_VALUE, CHECKERBOARD_DARK_VALUE, CHECKERBOARD_DARK_VALUE)
   love.graphics.rectangle("fill", self.backLeft, self.backTop, SQUARE_SIZE, SQUARE_SIZE)
   love.graphics.setColor(1, 1, 1)
   love.graphics.draw(CHECKERBOARD, CHECKERBOARD_QUAD, self.backLeft, self.backTop)

   self.drawFunction(self.backLeft, self.backTop, self.back, SQUARE_SIZE, SQUARE_SIZE)
   love.graphics.setColor(not (self.hoveredBack and self.paintPicker ~= nil) and 1 or 0, 1, 1, 1)
   love.graphics.rectangle("line", self.backLeft, self.backTop, SQUARE_SIZE, SQUARE_SIZE)
end

function PaintDisplay:__drawFrontSquare()
   drawSquareShadow(self.backLeft, self.backTop, self.frontRight + SQUARE_SHADOW_SIZE, self.frontBottom + SQUARE_SHADOW_SIZE)

   love.graphics.setColor(CHECKERBOARD_DARK_VALUE, CHECKERBOARD_DARK_VALUE, CHECKERBOARD_DARK_VALUE)
   love.graphics.rectangle("fill", self.frontLeft, self.frontTop, SQUARE_SIZE, SQUARE_SIZE)
   love.graphics.setColor(1, 1, 1)
   love.graphics.draw(CHECKERBOARD, CHECKERBOARD_QUAD, self.frontLeft, self.frontTop)

   self.drawFunction(self.frontLeft, self.frontTop, self.front, SQUARE_SIZE, SQUARE_SIZE)
   love.graphics.setColor(not (self.hoveredFront and self.paintPicker ~= nil) and 1 or 0, 1, 1, 1)
   love.graphics.rectangle("line", self.frontLeft, self.frontTop, SQUARE_SIZE, SQUARE_SIZE)
end

--- LOVE draw handler
function PaintDisplay:draw()
   self:__drawBackSquare()
   self:__drawFrontSquare()

   love.graphics.reset()
end