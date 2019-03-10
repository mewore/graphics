require "tools/tile-controls"
require "data/native-file"
require "navigator"

ImageEditor = {}
ImageEditor.__index = ImageEditor

local SAVE_BUTTON = "s"
local LEFT_MOUSE_BUTTON = 1

local TILE_WIDTH = 5
local TILE_HEIGHT = 5

local WHITE = { r = 1, g = 1, b = 1 }
local BLACK = { r = 0, g = 0, b = 0 }
local BORDER_VALUE = 0.7

local CHECKERBOARD_SIZE = 8
local CHECKERBOARD_VALUE = 0.8

local TOOL_PIXEL_EDITOR = 1
local TOOL_PIPETTE = 2

--- Displays a map and allows the user to edit it
-- @param filename {string} - The path to the file that should be edited
function ImageEditor:create(filename)
   local file = NativeFile:create(filename)
   local fileData = love.filesystem.newFileData(file:read(), filename)
   local imageData = love.image.newImageData(fileData)
   local width = imageData:getWidth()
   local height = imageData:getHeight()

   local mainColour = { r = 0, g = 0, b = 0, a = 1 }
   local secondaryColour = { r = 0, g = 0, b = 0, a = 1 }

   local paintDisplay = PaintDisplay:create(mainColour, secondaryColour, function(x, y, colour, width, height)
      love.graphics.setColor(colour.r, colour.g, colour.b, colour.a)
      love.graphics.rectangle("fill", x, y, width, height)
   end, nil)

   local navigator = Navigator:create(width * TILE_WIDTH, height * TILE_HEIGHT)
   local this = {
      filename = filename,
      imageData = imageData,
      imageWidth = width,
      imageHeight = height,
      activeTool = TOOL_PIXEL_EDITOR,
      tools = {
         [TOOL_PIXEL_EDITOR] = TileControls:create(WHITE, TILE_WIDTH, TILE_HEIGHT, width, height, navigator, false),
         [TOOL_PIPETTE] = TileControls:create(WHITE, TILE_WIDTH, TILE_HEIGHT, width, height, navigator, false),
      },
      navigator = navigator,
      sidebar = Sidebar:create({ paintDisplay }),
      onSave = function() end,
   }
   setmetatable(this, self)

   this.tools[TOOL_PIXEL_EDITOR]:onDrawProgress(function(points, button)
      local colour = button == LEFT_MOUSE_BUTTON and paintDisplay.front or paintDisplay.back
      for i = 1, #points do
         this.imageData:setPixel(points[i].x - 1, points[i].y - 1, colour.r, colour.g, colour.b, colour.a)
      end
   end)
   this.tools[TOOL_PIPETTE]:onDrawProgress(function(points, button)
      if points and #points >= 1 then
         local colour = button == LEFT_MOUSE_BUTTON and paintDisplay.front or paintDisplay.back
         colour.r, colour.g, colour.b, colour.a = this.imageData:getPixel(points[1].x - 1, points[1].y - 1)
      end
   end)

   return this
end

--- LOVE update handler
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
         self.onSave(self.imageData)
      end
      if self.activeTool == TOOL_PIXEL_EDITOR then
         self.tools[TOOL_PIXEL_EDITOR]:zoom(love.mouse.wheel.dy)
      end
   end

   self.activeTool = love.keyboard.altIsDown and TOOL_PIPETTE or TOOL_PIXEL_EDITOR

   self.tools[self.activeTool].isSidebarHovered = self.sidebar:isHovered()
   self.sidebar.isOpaque = self.sidebar:isHovered() and self.tools[self.activeTool].drawingWith == nil

   self.tools[self.activeTool]:update(dt)
   self.navigator:update(dt)
   self.sidebar:update(dt)
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

local function drawCheckerboard(width, height)
   love.graphics.setColor(CHECKERBOARD_VALUE, CHECKERBOARD_VALUE, CHECKERBOARD_VALUE, 1)

   local totalWidth, totalHeight = width * TILE_WIDTH, height * TILE_HEIGHT
   local stepX, stepY = CHECKERBOARD_SIZE * TILE_WIDTH * 2, CHECKERBOARD_SIZE * TILE_HEIGHT * 2
   local x, y
   local squareHeight

   y = 0
   while y < totalHeight do
      squareHeight = math.min(CHECKERBOARD_SIZE * TILE_HEIGHT, totalHeight - y)
      x = 0
      while x < totalWidth do
         love.graphics.rectangle("fill", x, y, math.min(CHECKERBOARD_SIZE * TILE_WIDTH, totalWidth - x), squareHeight)
         x = x + stepX
      end
      y = y + stepY
   end

   y = CHECKERBOARD_SIZE * TILE_WIDTH
   while y < totalHeight do
      squareHeight = math.min(CHECKERBOARD_SIZE * TILE_HEIGHT, totalHeight - y)
      x = CHECKERBOARD_SIZE * TILE_WIDTH
      while x < totalWidth do
         love.graphics.rectangle("fill", x, y, math.min(CHECKERBOARD_SIZE * TILE_WIDTH, totalWidth - x), squareHeight)
         x = x + stepX
      end
      y = y + stepY
   end
end

--- LOVE draw handler
function ImageEditor:draw()
   -- Gray border
   love.graphics.clear(BORDER_VALUE, BORDER_VALUE, BORDER_VALUE)

   love.graphics.push()
   self.navigator:scaleAndTranslate()

   -- White background
   love.graphics.rectangle("fill", 0, 0, self.imageWidth * TILE_WIDTH, self.imageHeight * TILE_HEIGHT)
   drawCheckerboard(self.imageWidth, self.imageHeight)
   -- The image
   for y = 0, self.imageHeight - 1 do
      for x = 0, self.imageWidth - 1 do
         local r, g, b, a = self.imageData:getPixel(x, y)
         love.graphics.setColor(r, g, b, a)
         love.graphics.rectangle("fill", x * TILE_WIDTH, y * TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT)
      end
   end
   -- The tile cursor
   local activeTool = self.tools[self.activeTool]
   if getPixelLightness(self.imageData, activeTool.leftHoveredColumn, activeTool.topHoveredRow) > 0.5 then
      activeTool.colour = BLACK
   else
      activeTool.colour = WHITE
   end
   activeTool:draw()

   love.graphics.reset()
   love.graphics.pop()

   self.sidebar:draw()
end