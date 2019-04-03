ColourPickerSquare = {}
ColourPickerSquare.__index = ColourPickerSquare

--- Convert HSL (Hue, Saturation, Lightness/Luminosity/Luminance) to RGB (Red, Green, Blue)
-- @param hue {number} The hue of the colour (from 0 to 360)
-- @param saturation {number} The saturation of the colour (from 0 to 1)
-- @param lightness {number} The lightness of the colour (from 0 to 1)
-- @return {number, number, number} - The corresponding RGB values
local function hslToRgb(hue, saturation, lightness)
   local largestWithoutOffset = (1 - math.abs(2 * lightness - 1.0)) * saturation
   local middleWithoutOffset = largestWithoutOffset * (1.0 - math.abs((hue / 60.0) % 2 - 1))
   local offset = lightness - largestWithoutOffset / 2.0
   local largest, middle, lowest = largestWithoutOffset + offset, middleWithoutOffset + offset, offset
   -- Split the different hues into 6 segments
   if hue < 60 then
      return largest, middle, lowest
   elseif hue < 120 then
      return middle, largest, lowest
   elseif hue < 180 then
      return lowest, largest, middle
   elseif hue < 240 then
      return lowest, middle, largest
   elseif hue < 300 then
      return middle, lowest, largest
   else
      return largest, lowest, middle
   end
end

local EPSILON = 0.00000001

--- Convert RGB (Red, Green, Blue) to HSL (Hue, Saturation, Lightness/Luminosity/Luminance)
-- @param red {number} The red component of the colour (from 0 to 1)
-- @param green {number} The green component of the colour (from 0 to 1)
-- @param blue {number} The blue component of the colour (from 0 to 1)
-- @return {number, number, number} - The corresponding HSL values
local function rgbToHsl(red, green, blue)
   local minColour = math.min(red, green, blue)
   local maxColour = math.max(red, green, blue)

   local delta = maxColour - minColour
   local lightness = (minColour + maxColour) / 2
   local saturation = 0
   local hue = 0

   if delta > EPSILON then
      if maxColour - red < EPSILON then
         hue = ((green - blue) / delta)
      elseif maxColour - green < EPSILON then
         hue = ((blue - red) / delta) + 2
      else
         hue = ((red - green) / delta) + 4
      end
      hue = (hue * 60) % 360

      if delta < 0.5 then
         saturation = delta / (minColour + maxColour)
      else
         saturation = delta / (2 - (minColour + maxColour))
      end
   end

   return hue, saturation, lightness
end

local SELECTION_CIRCLE_RADIUS = 8
local SELECTION_CIRCLE_RADIUS_DRAGGING = 12
local SELECTION_CIRCLE_SIDES = 30
local SIZE = 300

--- The square in the colour picker that is used to select a certain lightness and saturation.
function ColourPickerSquare:create(options)
   options = options or {}

   local this = {
      x = 0,
      y = 0,
      width = SIZE,
      height = SIZE,
      imageData = nil,
      image = nil,
      value = { r = 0, g = 0, b = 0 },
      selectionX = 1,
      selectionY = 0,
      isSelecting = false,
   }
   setmetatable(this, self)

   if options.initialValue then
      local value = options.initialValue
      local hue, saturation, lightness = rgbToHsl(value.r, value.g, value.b)
      local lightnessAtTop = 1.0 - saturation * 0.5
      lightness = lightness / lightnessAtTop
      this:setHue(hue)
      this:select(saturation, 1.0 - lightness)
   else
      local hue = options.initialHue or 0
      this:setHue(hue)
      this:select(1.0, 0.0)
   end

   return this
end

--- LOVE update handler
function ColourPickerSquare:update()
   local mouseInfo = love.mouse.registerSolid(self)
   if mouseInfo.drag then
      self:select((mouseInfo.drag.toX - self.x) / self.width, (mouseInfo.drag.toY - self.y) / self.height)
   end
   self.isSelecting = mouseInfo.drag ~= nil
end

function ColourPickerSquare:select(x, y)
   self.selectionX = math.min(1, math.max(0, x))
   self.selectionY = math.min(1, math.max(0, y))
   local pixelX = math.min(math.floor(self.selectionX * self.imageData:getWidth()), self.imageData:getWidth() - 1)
   local pixelY = math.min(math.floor(self.selectionY * self.imageData:getHeight()), self.imageData:getHeight() - 1)
   self.value.r, self.value.g, self.value.b = self.imageData:getPixel(pixelX, pixelY)
end

function ColourPickerSquare:setHue(newHue)
   self.imageData = love.image.newImageData(SIZE, SIZE)
   for y = 0, SIZE - 1 do
      for x = 0, SIZE - 1 do
         local saturation = x / (SIZE - 1)
         -- Usually the user would want to focus on one of the corners for the most "prominent" colour (lightness = 0.5,
         -- saturation = 1.0) but they might also want to pick white, black, or any variation, so set the top-right
         -- corner to lightness = 0.5, the top-left to lightness = 1.0, and bottom corners to lightness = 0.
         local lightnessAtTop = 1.0 - saturation * 0.5
         local lightness = lightnessAtTop * (SIZE - y - 1) / (SIZE - 1)
         local red, green, blue = hslToRgb(newHue, saturation, lightness)
         self.imageData:setPixel(x, y, red, green, blue, 1)
      end
   end
   self.image = love.graphics.newImage(self.imageData)
end

--- LOVE draw handler
function ColourPickerSquare:draw()
   love.graphics.draw(self.image, self.x, self.y)

   local circleX = self.x + self.selectionX * self.width
   local circleY = self.y + self.selectionY * self.height
   local circleRadius = self.isSelecting and SELECTION_CIRCLE_RADIUS_DRAGGING or SELECTION_CIRCLE_RADIUS
   -- Fill that has the same colour as the selection
   love.graphics.setColor(self.value.r, self.value.g, self.value.b)
   love.graphics.circle("fill", circleX, circleY, circleRadius, SELECTION_CIRCLE_SIDES)
   -- Black shadow/border
   love.graphics.setColor(0, 0, 0)
   love.graphics.circle("line", circleX, circleY, circleRadius - 1, SELECTION_CIRCLE_SIDES)
   love.graphics.circle("line", circleX, circleY, circleRadius, SELECTION_CIRCLE_SIDES)
   love.graphics.circle("line", circleX, circleY, circleRadius + 1, SELECTION_CIRCLE_SIDES)
   -- White icon
   love.graphics.setColor(1, 1, 1)
   love.graphics.circle("line", circleX, circleY, circleRadius, SELECTION_CIRCLE_SIDES)
   love.graphics.reset()
end
