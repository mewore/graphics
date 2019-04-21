ColourPickerHueSlider = {}
ColourPickerHueSlider.__index = ColourPickerHueSlider

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

local BOX_OUTLINE_COLOUR = { r = 0, g = 0, b = 0, a = 1 }

local HOVER_CURSOR = love.mouse.getSystemCursor("sizens")
local DRAG_CURSOR = love.mouse.getSystemCursor("sizens")

local WIDTH = 32
local HEIGHT = 300

local MAX_HUE = 360

--- The square in the colour picker that is used to select a certain lightness and saturation.
function ColourPickerHueSlider:create(correspondingSquare, options)
   options = options or {}

   local this = {
      x = 0,
      y = 0,
      correspondingSquare = correspondingSquare,
      hue = correspondingSquare.hue,
   }
   setmetatable(this, self)

   this:setSize(WIDTH, HEIGHT)
   return this
end

--- Change the position of this element
-- @param x {number} The new X left position
-- @param y {number} The new Y top position
function ColourPickerHueSlider:setPosition(x, y) self.x, self.y = x, y end

--- Get both the X and the Y position of this element
-- @returns {int}, {int}
function ColourPickerHueSlider:getPosition() return self.x, self.y end

--- Change the size of this element
-- @param width {number} The new width
-- @param height {number} The new height
function ColourPickerHueSlider:setSize(width, height)
   local imageData = love.image.newImageData(width, height)
   for y = 0, height - 1 do
      local red, green, blue = hslToRgb((y / height) * MAX_HUE, 1, 0.7)
      for x = 0, width - 1 do
         imageData:setPixel(x, y, red, green, blue, 1)
      end
   end
   self.image = love.graphics.newImage(imageData)

   self.width, self.height = width, height
end

--- Get the size of this element
-- @returns {int}, {int}
function ColourPickerHueSlider:getSize() return self.width, self.height end

--- LOVE update handler
function ColourPickerHueSlider:update()
   local mouseInfo = love.mouse.registerSolid(self)
   if mouseInfo.drag then
      love.mouse.cursor = DRAG_CURSOR
      local newHue = math.min(1, math.max(0, (mouseInfo.drag.toY - self.y) / self.height)) * MAX_HUE
      if newHue ~= self.hue then
         self.hue = newHue
         self.correspondingSquare:setHue(newHue)
      end
   elseif mouseInfo.isHovered then
      love.mouse.cursor = HOVER_CURSOR
   end
end

--- LOVE draw handler
function ColourPickerHueSlider:draw()
   love.graphics.draw(self.image, self.x, self.y)

   -- Black selection line
   love.graphics.setColor(0, 0, 0)
   local lineY = self.y + math.floor((self.hue / MAX_HUE) * self.height)
   love.graphics.line(self.x, lineY, self.x + self.width, lineY)
   love.graphics.reset()

   -- Border
   love.graphics.setColor(BOX_OUTLINE_COLOUR.r, BOX_OUTLINE_COLOUR.g, BOX_OUTLINE_COLOUR.b, BOX_OUTLINE_COLOUR.a)
   love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
   love.graphics.reset()
end
