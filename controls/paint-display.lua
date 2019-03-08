PaintDisplay = {}
PaintDisplay.__index = PaintDisplay

local SQUARE_SIZE = 50
local LEFT_MOUSE_BUTTON = 1
local SWAP_KEY = "x"
local SQUARE_SHADOW_SIZE = 5
local SQUARE_SHADOW_OPACITY = 0.8

--- A controller that keeps track of an X and Y offset as well as a zoom ratio
function PaintDisplay:create(initialFront, initialBack, drawFunction)
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
      frontTile = initialFront,
      backTile = initialBack,
      drawFunction = drawFunction,
      hoveredFront = false,
      hoveredBack = false,
      frontRight = 0,
      frontBottom = 0,
      backLeft = 0,
      backTop = 0,
   }
   setmetatable(this, self)

   return this
end

--- LOVE update callback
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

   if love.mouse.buttonsPressed[LEFT_MOUSE_BUTTON] then
   end

   if love.keyboard.keysPressed[SWAP_KEY] then
      self.frontTile, self.backTile = self.backTile, self.frontTile
   end
end

local function drawSquareShadow(fromX, fromY, toX, toY)
   love.graphics.setColor(0, 0, 0, SQUARE_SHADOW_OPACITY)
   love.graphics.rectangle("fill", fromX, fromY, toX - fromX, toY - fromY)
end

function PaintDisplay:__drawBackSquare()
   love.graphics.setColor(1, 1, 1, 1)
   self.drawFunction(self.backLeft, self.backTop, self.backTile)
   love.graphics.setColor(not self.hoveredBack and 1 or 0, 1, 1, 1)
   love.graphics.rectangle("line", self.backLeft, self.backTop, SQUARE_SIZE, SQUARE_SIZE)
end

function PaintDisplay:__drawFrontSquare()
   drawSquareShadow(self.backLeft, self.backTop, self.frontRight + SQUARE_SHADOW_SIZE, self.frontBottom + SQUARE_SHADOW_SIZE)

   love.graphics.setColor(1, 1, 1, 1)
   self.drawFunction(self.frontLeft, self.frontTop, self.frontTile)
   love.graphics.setColor(not self.hoveredFront and 1 or 0, 1, 1, 1)
   love.graphics.rectangle("line", self.frontLeft, self.frontTop, SQUARE_SIZE, SQUARE_SIZE)
end

--- LOVE draw callback
function PaintDisplay:draw()
   self:__drawBackSquare()
   self:__drawFrontSquare()

   love.graphics.reset()
end