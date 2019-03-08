require "tile-controls"
require "native-file"
require "navigator"

ImageEditor = {}
ImageEditor.__index = ImageEditor

local SAVE_BUTTON = "s"
local LEFT_MOUSE_BUTTON = 1

local TILE_WIDTH = 5
local TILE_HEIGHT = 5

local WHITE = {r = 1, g = 1, b = 1}
local BLACK = {r = 0, g = 0, b = 0}
local BORDER_VALUE = 0.7

--- Displays a map and allows the user to edit it
-- @param filename {string} - The path to the file that should be edited
function ImageEditor:create(filename)
   local file = NativeFile:create(filename)
   local fileData = love.filesystem.newFileData(file:read(), filename)
   local imageData = love.image.newImageData(fileData)
   local width = imageData:getWidth()
   local height = imageData:getHeight()

   local mainColour = {r = 0, g = 0, b = 0, a = 1}
   local secondaryColour = {r = 0, g = 0, b = 0, a = 1 }

   local navigator = Navigator:create(width * TILE_WIDTH, height * TILE_HEIGHT)
   local this = {
      filename = filename,
      imageData = imageData,
      imageWidth = width,
      imageHeight = height,
      drawControls = TileControls:create(WHITE, TILE_WIDTH, TILE_HEIGHT, width, height, navigator, false),
      filePickerControls = TileControls:create(WHITE, TILE_WIDTH, TILE_HEIGHT, width, height, navigator, false),
      isPickingColour = false,
      navigator = navigator,
      mainColour = mainColour,
      secondaryColour = secondaryColour,
   }
   setmetatable(this, self)

   this.drawControls:onDrawProgress(function(points, button)
      local colour = button == LEFT_MOUSE_BUTTON and this.mainColour or this.secondaryColour
      for i = 1, #points do
         this.imageData:setPixel(points[i].x - 1, points[i].y - 1, colour.r, colour.g, colour.b, colour.a)
      end
   end)
   this.filePickerControls:onDrawProgress(function(points, button)
      if points and #points >= 1 then
         local colour = button == LEFT_MOUSE_BUTTON and this.mainColour or this.secondaryColour
         colour.r, colour.g, colour.b, colour.a = this.imageData:getPixel(points[1].x - 1, points[1].y - 1)
      end
   end)

   return this
end

--- LOVE update callback
-- @param dt {float} - The amount of time (in seconds) since the last update
function ImageEditor:update(dt)
   if love.keyboard.escapeIsPressed then
      self.onClose()
   end

   if love.keyboard.controlIsDown or love.keyboard.commandIsDown then
      if love.keyboard.keysPressed[SAVE_BUTTON] then
         local fileData = self.imageData:encode("png")
         local file = NativeFile:create(self.filename)
         file:write(fileData:getString())
      end
      if not self.isPickingColour then
         self.drawControls:zoom(love.mouse.wheel.dy)
      end
   end

   self.isPickingColour = love.keyboard.altIsDown

   self.navigator:update(dt)
   local activeControls = self.isPickingColour and self.filePickerControls or self.drawControls
   activeControls:update()
end

local function getPixelLightness(imageData, x, y)
   if x >= 1 and y >= 1 and x <= imageData:getWidth() and y <= imageData:getHeight() then
      local r, g, b, a = imageData:getPixel(x - 1, y - 1)
      -- Blending with the background, which is white
      r = a * r + (1.0 - a)
      g = a * g + (1.0 - a)
      b = a * b + (1.0 - a)
      return (math.max(r, g, b) + math.min(r, g, b)) / 2
   end
   return BORDER_VALUE
end

--- LOVE draw callback
function ImageEditor:draw()
   -- Gray border
   love.graphics.clear(BORDER_VALUE, BORDER_VALUE, BORDER_VALUE)

   love.graphics.push()
   self.navigator:scaleAndTranslate()

   -- White background
   love.graphics.rectangle("fill", 0, 0, self.imageWidth * TILE_WIDTH, self.imageHeight * TILE_HEIGHT)
   -- The map itself
   for y = 0, self.imageHeight - 1 do
      for x = 0, self.imageWidth - 1 do
         local r, g, b, a = self.imageData:getPixel(x, y)
         love.graphics.setColor(r, g, b, a)
         love.graphics.rectangle("fill", x * TILE_WIDTH, y * TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT)
      end
   end
   -- The tile cursor
   local activeControls = self.isPickingColour and self.filePickerControls or self.drawControls
   if getPixelLightness(self.imageData, activeControls.leftHoveredColumn, activeControls.topHoveredRow) > 0.5 then
      activeControls.colour = BLACK
   else
      activeControls.colour = WHITE
   end
   activeControls:draw()

   love.graphics.reset()
   love.graphics.pop()
end