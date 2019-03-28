require "controls/paint-display-square"

PaintDisplay = {}
PaintDisplay.__index = PaintDisplay

local SQUARE_SIZE = 56
local SWAP_KEY = "x"
local SQUARE_SHADOW_SIZE = 2
local SQUARE_SHADOW_OPACITY = 0.8

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
      front = PaintDisplaySquare:create(initialFront, drawFunction, paintPicker),
      back = PaintDisplaySquare:create(initialBack, drawFunction, paintPicker),
      isActive = false,
   }
   setmetatable(this, self)

   if paintPicker then
      paintPicker.onClose = function() viewStack:popView(paintPicker) end
   end

   return this
end

--- LOVE update handler
function PaintDisplay:update()
   self.front.x, self.front.y = self.x, self.y
   self.front:update()
   self.back.x, self.back.y = self.x + SQUARE_SIZE / 2, self.y + SQUARE_SIZE / 2
   self.back:update()

   self.isActive = self.front.isActive or self.back.isActive

   if love.keyboard.keysPressed[SWAP_KEY] then
      self.front.value, self.back.value = self.back.value, self.front.value
   end
end

local function drawSquareShadow(fromX, fromY, toX, toY)
   love.graphics.setColor(0, 0, 0, SQUARE_SHADOW_OPACITY)
   love.graphics.rectangle("fill", fromX, fromY, toX - fromX, toY - fromY)
end

--- LOVE draw handler
function PaintDisplay:draw()
   self.back:draw()
   drawSquareShadow(self.back.x, self.back.y, self.front.x + self.front.width + SQUARE_SHADOW_SIZE,
      self.front.y + self.front.height + SQUARE_SHADOW_SIZE)
   self.front:draw()

   love.graphics.reset()
end