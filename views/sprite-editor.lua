require "controls/colour-picker"
require "controls/label"
require "controls/list"
require "controls/paint-display"
require "tools/tile-controls"
require "data/native-file"
require "navigator"

SpriteEditor = {}
SpriteEditor.__index = SpriteEditor

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

local SIDEBAR_WIDTH = 200

--- Displays a map and allows the user to edit it
-- @param spriteDirectory {string} - The directory containing the sprite images
function SpriteEditor:create(spriteDirectory)
   local imageFiles = NativeFile:create(spriteDirectory):getFiles("png")
   if #imageFiles == 0 then
      error("There are no images in " .. spriteDirectory .. " and image creation is not supported yet")
   end

   local mainColour = { r = 0, g = 0, b = 0, a = 1 }
   local secondaryColour = { r = 0, g = 0, b = 0, a = 1 }

   local paintDisplay = PaintDisplay:create(mainColour, secondaryColour, function(x, y, colour, width, height)
      love.graphics.setColor(colour.r, colour.g, colour.b, colour.a)
      love.graphics.rectangle("fill", x, y, width, height)
   end, ColourPicker:create())

   local animationListLabel = Label:create("Animations/Images")
   animationListLabel.marginTop = 40
   local animationListItems = {}
   for _, imageFile in ipairs(imageFiles) do
      animationListItems[#animationListItems + 1] = { value = imageFile.path, label = imageFile.name }
   end
   local animationList = List:create(0, 0, SIDEBAR_WIDTH, animationListItems)

   local navigator = Navigator:create()
   local this = {
      filename = nil,
      imageData = nil,
      imageWidth = nil,
      imageHeight = nil,
      activeTool = TOOL_PIXEL_EDITOR,
      tools = {
         [TOOL_PIXEL_EDITOR] = TileControls:create(WHITE, TILE_WIDTH, TILE_HEIGHT, nil, nil, navigator, false),
         [TOOL_PIPETTE] = TileControls:create(WHITE, TILE_WIDTH, TILE_HEIGHT, nil, nil, navigator, false),
      },
      navigator = navigator,
      sidebar = Sidebar:create({ paintDisplay, animationListLabel, animationList }, SIDEBAR_WIDTH),
      onSave = function() end,
   }
   setmetatable(this, self)

   this:openImage(imageFiles[1].path)

   animationList:onSelect(function(value)
      this:openImage(value)
   end)

   this.tools[TOOL_PIXEL_EDITOR]:onDrawProgress(function(points, button)
      local colour = button == LEFT_MOUSE_BUTTON and paintDisplay.front.value or paintDisplay.back.value
      for i = 1, #points do
         this.imageData:setPixel(points[i].x - 1, points[i].y - 1, colour.r, colour.g, colour.b, colour.a)
      end
   end)
   this.tools[TOOL_PIPETTE]:onDrawProgress(function(points, button)
      if points and #points >= 1 then
         local colour = button == LEFT_MOUSE_BUTTON and paintDisplay.front.value or paintDisplay.back.value
         colour.r, colour.g, colour.b, colour.a = this.imageData:getPixel(points[1].x - 1, points[1].y - 1)
      end
   end)

   return this
end

--- Open an image/animation from a specific path
-- @param filePath {string} The image path
function SpriteEditor:openImage(filePath)
   local file = NativeFile:create(filePath)
   local fileData = love.filesystem.newFileData(file:read(), file.path)
   local imageData = love.image.newImageData(fileData)
   local width = imageData:getWidth()
   local height = imageData:getHeight()

   self.filename = filePath
   self.imageWidth = width
   self.imageHeight = height
   self.imageData = imageData
   self.navigator:setDimensionsAndReposition(width * TILE_WIDTH, height * TILE_HEIGHT)

   for _, tool in pairs(self.tools) do
      tool:setCanvasDimensions(width, height)
   end
end

--- LOVE update handler
-- @param dt {float} - The amount of time (in seconds) since the last update
function SpriteEditor:update(dt)
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
   self.sidebar.isActive = self.tools[self.activeTool].drawingWith == nil

   self.sidebar:update(dt)
   self.tools[self.activeTool]:update(dt)
   self.navigator:update(dt)
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
function SpriteEditor:draw()
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