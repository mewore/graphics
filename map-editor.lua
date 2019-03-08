require "tile-controls"
require "map-encoder"
require "navigator"
require "image-editor"
require "draw-overlay"
require "controls/paint-display"
require "tile-picker"

MapEditor = {}
MapEditor.__index = MapEditor

local MAP_WIDTH = 256
local MAP_HEIGHT = 32

local COLUMN_COUNT = 4

local EDIT_BUTTON = "e"
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

--- Divide a spritesheet into quads. The dimensions of the spritesheet must be divisible by the tile dimensions!
-- @param spritesheet {LOVE.Image} - https://love2d.org/wiki/Image
-- @param tileWidth {int}
-- @param tileHeight {int}
-- @returns {LOVE.Quad[]} - https://love2d.org/wiki/Quad
local function generateQuads(spritesheet, tileWidth, tileHeight)
   local sheetWidth = spritesheet:getWidth() / tileWidth
   local sheetHeight = spritesheet:getHeight() / tileHeight

   local quads = {}

   for y = 0, sheetHeight - 1 do
      for x = 0, sheetWidth - 1 do
         quads[#quads + 1] = love.graphics.newQuad(x * tileWidth, y * tileHeight, tileWidth, tileHeight,
            spritesheet:getDimensions())
      end
   end

   return quads
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

--- Displays a map and allows the user to edit it
-- @param spritesheetDirectoryPath {string} - The path to the directroy that contains all of the spritesheets
function MapEditor:create(spritesheetDirectoryPath)
   local tileNameToInfoFile = {}
   local spritesheetDirectory = NativeFile:create(spritesheetDirectoryPath)
   for _, propertiesFile in ipairs(spritesheetDirectory:getFiles("properties")) do
      tileNameToInfoFile[propertiesFile.name] = propertiesFile
   end

   local tileWidth, tileHeight
   local allTilesheetFiles = spritesheetDirectory:getFiles("png")
   local spritesheets = map(allTilesheetFiles, function(file)
      local infoFile = tileNameToInfoFile[file.name]
      if infoFile == nil then
         error("There is no '" .. file.name .. ".properties' file in " .. spritesheetDirectory.path)
      end
      local info = infoFile:readAsTable()
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
      return love.graphics.newImage(imageData)
   end)
   local navigator = Navigator:create(MAP_WIDTH * tileWidth, MAP_HEIGHT, tileHeight)

   local tileNames = map(allTilesheetFiles, function(file) return file.name end)

   local paintDisplayPreviews = {}
   local paintDisplay = PaintDisplay:create(#spritesheets >= 1 and 1 or 0, #spritesheets >= 2 and 2 or 0, function(x, y, tile)
      if tile ~= TILE_EMPTY then
         love.graphics.draw(spritesheets[tile], paintDisplayPreviews[tile], x, y)
      end
   end, TilePicker:create(spritesheets, tileNames))

   for i = 1, #spritesheets do
      paintDisplayPreviews[i] = love.graphics.newQuad(0, 0, paintDisplay.previewWidth, paintDisplay.previewHeight,
         spritesheets[i]:getDimensions())
   end

   local this = {
      directory = spritesheetDirectory,
      spritesheets = spritesheets,
      tileWidth = tileWidth,
      tileHeight = tileHeight,
      mapWidth = MAP_WIDTH,
      mapHeight = MAP_HEIGHT,
      spriteBatches = nil,
      tiles = {},
      tileSprites = nil,
      playerSpawnX = -1,
      playerSpawnY = -1,
      editMapTileControls = TileControls:create({ r = 1, g = 0, b = 0 }, tileWidth, tileHeight,
         MAP_WIDTH, MAP_HEIGHT, navigator, false),
      editImageTileControls = TileControls:create({ r = 0.2, g = 1, b = 0 }, tileWidth, tileHeight,
         MAP_WIDTH, MAP_HEIGHT, navigator, true),
      navigator = navigator,
      shouldRecreate = false,
      imageEditMode = false,
      imageEditor = nil,
      drawOverlay = DrawOverlay:create({ paintDisplay }),
      tileControlsAreDisabled = false,
      paintDisplay = paintDisplay,
      onClose = function() end,
   }
   setmetatable(this, self)

   this.editMapTileControls:onDrawProgress(function(points, button)
      local tileToCreate = (button == LEFT_MOUSE_BUTTON) and paintDisplay.front or paintDisplay.back
      for _, point in pairs(points) do
         if this:getTile(point.x, point.y) ~= tileToCreate then
            this:setTile(point.x, point.y, tileToCreate)
            this.shouldRecreate = true
         end
      end
   end)
   this.editMapTileControls:onDrawDone(function()
      if this.shouldRecreate then
         this:recreateSpriteBatch()
         this.shouldRecreate = false
      end
   end)

   this.editImageTileControls:onDrawProgress(function(points)
      if points and #points >= 1 then
         local tile = this:getTile(points[1].x, points[1].y)
         if tile ~= TILE_EMPTY then
            this.imageEditor = ImageEditor:create(allTilesheetFiles[tile].path)
            this.imageEditor.onClose = function() this.imageEditor = nil end
         end
      end
   end)

   this.tileSprites = map(spritesheets, function(spritesheet) return generateQuads(spritesheet, tileWidth, tileHeight) end)

   math.randomseed(1)
   for row = 1, this.mapHeight do
      for column = 1, this.mapWidth do
         this:setTile(column, row, math.floor(math.random(0, #spritesheets)))
         if this:getTile(column, row) == nil then
            print("BAD at:", column, row)
         end
      end
   end

   this:recreateSpriteBatch()

   return this
end

--- LOVE update callback
-- @param dt {float} - The amount of time (in seconds) since the last update
function MapEditor:update(dt)
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

   local activeControls = self.imageEditMode and self.editImageTileControls or self.editMapTileControls

   if love.keyboard.keysPressed[EDIT_BUTTON] then
      activeControls.drawingWith = nil

      self.imageEditMode = not self.imageEditMode
      activeControls = self.imageEditMode and self.editImageTileControls or self.editMapTileControls
   end

   self.tileControlsAreDisabled = self.drawOverlay:isHovered() and activeControls.drawingWith == nil
   self.drawOverlay:update(dt)

   if love.keyboard.controlIsDown or love.keyboard.commandIsDown then
      if love.keyboard.keysPressed[SAVE_BUTTON] then
         print("Saving to file: ", MAP_SAVE_FILE_NAME)
         mapEncoder:saveToFile(MAP_SAVE_FILE_NAME, self)
      elseif love.keyboard.keysPressed[LOAD_BUTTON] then
         print("Loading from file: ", MAP_SAVE_FILE_NAME)
         local data = mapEncoder:loadFromFile(MAP_SAVE_FILE_NAME)
         self.mapWidth = data.mapWidth
         self.mapHeight = data.mapHeight
         self.tiles = data.tiles
         self:recreateSpriteBatch()
      end
      if not self.tileControlsAreDisabled and not self.imageEditMode then
         self.editMapTileControls:zoom(love.mouse.wheel.dy)
      end
   end

   self.navigator:update(dt)
   if not self.tileControlsAreDisabled then
      activeControls:update()
   end
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
function MapEditor:recreateSpriteBatch()
   self.spriteBatches = map(self.spritesheets, function(spritesheet)
      return love.graphics.newSpriteBatch(spritesheet, self.mapWidth * self.mapHeight)
   end)
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

--- LOVE draw callback
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
   -- The tile cursor
   if not self.tileControlsAreDisabled then
      local activeControls = self.imageEditMode and self.editImageTileControls or self.editMapTileControls
      activeControls:draw()
   end

   love.graphics.pop()
   self.drawOverlay.isOpaque = self.tileControlsAreDisabled
   self.drawOverlay:draw()
end