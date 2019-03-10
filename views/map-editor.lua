require "controls/paint-display"
require "controls/sidebar"
require "controls/tile-picker"
require "data/map-encoder"
require "data/spritesheet"
require "navigator"
require "tools/point-editor"
require "tools/tile-controls"
require "views/image-editor"

MapEditor = {}
MapEditor.__index = MapEditor

local MAP_WIDTH = 256
local MAP_HEIGHT = 32

local COLUMN_COUNT = 4

local SAVE_BUTTON = "s"
local LOAD_BUTTON = "l"
local MAP_SAVE_FILE_NAME = love.filesystem.getWorkingDirectory() .. "/maps/test"
local mapEncoder = MapEncoder:create()

--- Get the index of a tile if counting started at 1 and continued from left to right and top to bottom as text does.
-- @param row {int}
-- @param column {int}
-- @returns {int}
local function getTileIndex(row, column)
   return (row - 1) * COLUMN_COUNT + column
end

local function map(array, functionToApply)
   local newArray = {}
   for index, value in ipairs(array) do
      newArray[index] = functionToApply(value)
   end
   return newArray
end

local TILE_EMPTY = 0
local TILE_GROUND_CORNER_TOP_LEFT = getTileIndex(5, 1)
local TILE_GROUND_CORNER_TOP_RIGHT = getTileIndex(5, 2)
local TILE_GROUND_CORNER_BOTTOM_RIGHT = getTileIndex(5, 3)
local TILE_GROUND_CORNER_BOTTOM_LEFT = getTileIndex(5, 4)

local LEFT_MOUSE_BUTTON = 1

local TOOL_MAP_EDITOR = 1
local TOOL_IMAGE_EDITOR = 2
local TOOL_POINT_EDITOR = 3

local TOOL_HOTKEYS = {
   q = TOOL_MAP_EDITOR,
   e = TOOL_IMAGE_EDITOR,
   r = TOOL_POINT_EDITOR,
}

--- Displays a map and allows the user to edit it
-- @param spritesheetDirectoryPath {string} - The path to the directroy that contains all of the spritesheets
function MapEditor:create(spritesheetDirectoryPath)
   local tileNameToInfoFile = {}
   local spritesheetDirectory = NativeFile:create(spritesheetDirectoryPath)
   for _, jsonFile in ipairs(spritesheetDirectory:getFiles("json")) do
      tileNameToInfoFile[jsonFile.name] = jsonFile
   end

   local tileWidth, tileHeight
   local allTilesheetFiles = spritesheetDirectory:getFiles("png")
   local spritesheets = map(allTilesheetFiles, function(file)
      local infoFile = tileNameToInfoFile[file.name]
      if infoFile == nil then
         error("There is no '" .. file.name .. ".json' file in " .. spritesheetDirectory.path)
      end
      local info = infoFile:readAsJson()
      if tileWidth == nil then
         tileWidth = info.width
         tileHeight = info.height
      elseif tileWidth ~= info.width then
         error("Tile '" .. file.name .. "' has a width of " .. info.width ..
               ", which is not consistent with the established width - " .. tileWidth)
      elseif tileHeight ~= info.height then
         error("Tile '" .. file.name .. "' has a height of " .. info.height ..
               ", which is not consistent with the established height - " .. tileHeight)
      end
      local fileData = love.filesystem.newFileData(file:read(), file.path)
      local imageData = love.image.newImageData(fileData)
      return Spritesheet:create(imageData, tileWidth, tileHeight, file.name, true)
   end)
   local navigator = Navigator:create(MAP_WIDTH * tileWidth, MAP_HEIGHT, tileHeight)

   local tileNames = map(allTilesheetFiles, function(file) return file.name end)

   local paintDisplayPreviews = {}
   local paintDisplay = PaintDisplay:create(#spritesheets >= 1 and 1 or 0, #spritesheets >= 2 and 2 or 0, function(x, y, tile)
      if tile ~= TILE_EMPTY then
         love.graphics.draw(spritesheets[tile].originalImage, paintDisplayPreviews[tile], x, y)
      end
   end, TilePicker:create(spritesheets, tileNames))

   for i = 1, #spritesheets do
      paintDisplayPreviews[i] = love.graphics.newQuad(0, 0, paintDisplay.previewWidth, paintDisplay.previewHeight,
         spritesheets[i].originalImage:getDimensions())
   end

   local this = {
      directory = spritesheetDirectory,
      spritesheetFiles = allTilesheetFiles,
      spritesheets = spritesheets,
      tileWidth = tileWidth,
      tileHeight = tileHeight,
      mapWidth = MAP_WIDTH,
      mapHeight = MAP_HEIGHT,
      spriteBatches = map(spritesheets, function(spritesheet)
         return love.graphics.newSpriteBatch(spritesheet.image, MAP_WIDTH * MAP_WIDTH)
      end),
      tiles = {},
      tileSprites = nil,
      navigator = navigator,
      shouldRecreate = false,
      activeTool = TOOL_MAP_EDITOR,
      previousTool = TOOL_MAP_EDITOR,
      tools = {
         [TOOL_MAP_EDITOR] = TileControls:create({ r = 1, g = 0, b = 0 }, tileWidth, tileHeight,
            MAP_WIDTH, MAP_HEIGHT, navigator, false),
         [TOOL_IMAGE_EDITOR] = TileControls:create({ r = 0.2, g = 1, b = 0 }, tileWidth, tileHeight,
            MAP_WIDTH, MAP_HEIGHT, navigator, true),
         [TOOL_POINT_EDITOR] = PointEditor:create(navigator),
      },
      imageEditor = nil,
      sidebar = Sidebar:create({ paintDisplay }),
      tileControlsAreDisabled = false,
      paintDisplay = paintDisplay,
      onClose = function() end,
   }
   setmetatable(this, self)

   this.tools[TOOL_MAP_EDITOR]:onDrawProgress(function(points, button)
      local tileToCreate = (button == LEFT_MOUSE_BUTTON) and paintDisplay.front or paintDisplay.back
      for _, point in pairs(points) do
         if this:getTile(point.x, point.y) ~= tileToCreate then
            this:setTile(point.x, point.y, tileToCreate)
            this.shouldRecreate = true
         end
      end
   end)
   this.tools[TOOL_MAP_EDITOR]:onDrawDone(function()
      if this.shouldRecreate then
         this:recreateSpriteBatches()
         this.shouldRecreate = false
      end
   end)

   this.tools[TOOL_IMAGE_EDITOR]:onDrawProgress(function(points)
      if points and #points >= 1 then
         local tile = this:getTile(points[1].x, points[1].y)
         if tile ~= TILE_EMPTY then
            this.activeTool = this.previousTool
            this.previousTool = TOOL_IMAGE_EDITOR
            this.imageEditor = ImageEditor:create(allTilesheetFiles[tile].path)
            this.imageEditor.onClose = function() this.imageEditor = nil end
            this.imageEditor.onSave = function(imageData)
               spritesheets[tile] = Spritesheet:create(imageData, tileWidth, tileHeight, tileNames[tile], true)
               paintDisplayPreviews[tile] = love.graphics.newQuad(0, 0, paintDisplay.previewWidth,
                  paintDisplay.previewHeight, spritesheets[tile].originalImage:getDimensions())
               this.spriteBatches[tile] = love.graphics.newSpriteBatch(spritesheets[tile].image, MAP_WIDTH * MAP_WIDTH)
               this:recreateSpriteBatches()
            end
         end
      end
   end)

   this.tileSprites = map(spritesheets, function(spritesheet) return spritesheet:getQuads() end)

   math.randomseed(1)
   for row = 1, this.mapHeight do
      for column = 1, this.mapWidth do
         this:setTile(column, row, math.floor(math.random(0, #spritesheets)))
         if this:getTile(column, row) == nil then
            print("BAD at:", column, row)
         end
      end
   end

   this:recreateSpriteBatches()
   return this
end

--- LOVE update handler
-- @param dt {float} - The amount of time (in seconds) since the last update
function MapEditor:update(dt)
   if self.tools[TOOL_POINT_EDITOR].dialog then
      self.tools[TOOL_POINT_EDITOR].dialog:update(dt)
      return
   end
   if self.imageEditor then
      self.imageEditor:update(dt)
      return
   end
   if self.paintDisplay.isPickingPaint then
      self.paintDisplay.paintPicker:update(dt)
      return
   end

   if love.keyboard.escapeIsPressed then
      self.onClose()
   end

   for hotkey, tool in pairs(TOOL_HOTKEYS) do
      if love.keyboard.keysPressed[hotkey] then
         self.tools[self.activeTool].drawingWith = nil
         self.activeTool = tool
      end
   end

   self.tools[self.activeTool].isSidebarHovered = self.sidebar:isHovered()
   self.sidebar.isOpaque = self.sidebar:isHovered() and self.tools[self.activeTool].drawingWith == nil

   if love.keyboard.controlIsDown or love.keyboard.commandIsDown then
      if love.keyboard.keysPressed[SAVE_BUTTON] then
         print("Saving to file: ", MAP_SAVE_FILE_NAME)
         mapEncoder:saveToFile(MAP_SAVE_FILE_NAME, {
            mapWidth = self.mapWidth,
            mapHeight = self.mapHeight,
            tiles = self.tiles,
            points = self.tools[TOOL_POINT_EDITOR].points,
         })
      elseif love.keyboard.keysPressed[LOAD_BUTTON] then
         print("Loading from file: ", MAP_SAVE_FILE_NAME)
         local data = mapEncoder:loadFromFile(MAP_SAVE_FILE_NAME)
         self.mapWidth = data.mapWidth
         self.mapHeight = data.mapHeight
         self.tiles = data.tiles
         self.tools[TOOL_POINT_EDITOR]:setPoints(data.points)
         self:recreateSpriteBatches()
      end
      if not self.sidebar.isOpaque and self.activeTool == TOOL_MAP_EDITOR then
         self.tools[TOOL_MAP_EDITOR]:zoom(love.mouse.wheel.dy)
      end
   end

   self.tools[self.activeTool]:update(dt)
   self.navigator:update(dt)
   self.sidebar:update(dt)
end

--- Gets the tile from a specified cell
-- @param column {int} - The column of the cell
-- @param row {int} - The row of the cell
-- @returns {int}
function MapEditor:getTile(column, row)
   if column <= 0 or row <= 0 or column > self.mapWidth or row > self.mapHeight then
      return TILE_EMPTY
   end
   return self.tiles[(row - 1) * self.mapWidth + column]
end

--- Sets the tile at a specified cell
-- @param column {int} - The column of the cell
-- @param row {int} - The row of the cell
-- @param tile {int} - The ID/index of the new tile
function MapEditor:setTile(column, row, tile)
   if column <= 0 or row <= 0 or column > self.mapWidth or row > self.mapHeight then
      return
   end
   self.tiles[(row - 1) * self.mapWidth + column] = tile
end

--- Updates the sprite batch with sprites corresponding to the current tiles.
-- NOTE: A sprite batch is used for efficient rendering.
function MapEditor:recreateSpriteBatches()
   for i = 1, #self.spriteBatches do
      self.spriteBatches[i]:clear()
   end

   for row = 1, self.mapHeight do
      for column = 1, self.mapWidth do
         local x = (column - 1) * self.tileWidth
         local y = (row - 1) * self.tileHeight
         local tile = self:getTile(column, row)
         if tile == nil then
            error("nil tile at column " .. column .. ", row " .. row)
         elseif not (tile == TILE_EMPTY) then
            if tile > #self.tileSprites then
               error("Tile '" .. tile .. "' is not valid. There are only " .. #self.tileSprites .. " tile types.")
            end
            local hasLeft = self:getTile(column - 1, row) == tile
            local hasRight = self:getTile(column + 1, row) == tile
            local hasUp = self:getTile(column, row - 1) == tile
            local hasDown = self:getTile(column, row + 1) == tile
            local sprite = self.tileSprites[tile][1 +
                  ((hasUp and 1 or 0) * 2 + (hasDown and 1 or 0)) * 4 +
                  ((hasLeft and 1 or 0) * 2 + (hasRight and 1 or 0))]

            self.spriteBatches[tile]:add(sprite, x, y)

            if not (self:getTile(column - 1, row - 1) == tile) and hasUp and hasLeft then
               self.spriteBatches[tile]:add(self.tileSprites[tile][TILE_GROUND_CORNER_TOP_LEFT], x, y)
            end

            if not (self:getTile(column + 1, row - 1) == tile) and hasUp and hasRight then
               self.spriteBatches[tile]:add(self.tileSprites[tile][TILE_GROUND_CORNER_TOP_RIGHT], x, y)
            end

            if not (self:getTile(column - 1, row + 1) == tile) and hasDown and hasLeft then
               self.spriteBatches[tile]:add(self.tileSprites[tile][TILE_GROUND_CORNER_BOTTOM_LEFT], x, y)
            end

            if not (self:getTile(column + 1, row + 1) == tile) and hasDown and hasRight then
               self.spriteBatches[tile]:add(self.tileSprites[tile][TILE_GROUND_CORNER_BOTTOM_RIGHT], x, y)
            end
         end
      end
   end
end

--- LOVE draw handler
function MapEditor:draw()
   if self.imageEditor then
      self.imageEditor:draw()
      return
   end
   if self.paintDisplay.isPickingPaint then
      self.paintDisplay.paintPicker:draw()
      return
   end

   -- Gray border
   local BORDER_VALUE = 0.7
   love.graphics.clear(BORDER_VALUE, BORDER_VALUE, BORDER_VALUE)

   love.graphics.push()
   self.navigator:scaleAndTranslate()

   -- White background
   love.graphics.rectangle("fill", 0, 0, self.mapWidth * self.tileWidth, self.mapHeight * self.tileHeight)
   -- The map itself
   for _, spriteBatch in ipairs(self.spriteBatches) do
      love.graphics.draw(spriteBatch)
   end
   -- TOOL
   if self.activeTool == TOOL_POINT_EDITOR then
      love.graphics.pop()
      self.tools[TOOL_POINT_EDITOR]:draw()
   else
      self.tools[self.activeTool]:draw()
      love.graphics.pop()
   end

   if not self.tools[TOOL_POINT_EDITOR].dialog then
      self.sidebar:draw()
   end
end