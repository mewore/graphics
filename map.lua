require "data/map-encoder"
require "data/spritesheet"

Map = {}
Map.__index = Map

local COLUMN_COUNT = 4

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

--- Displays a map and allows the user to edit it
-- @param spritesheetDirectoryPath {string} - The path to the directroy that contains all of the spritesheets
function Map:create(width, height, tileWidth, tileHeight, spritesheets)
   local this = {
      spritesheets = spritesheets,
      tileWidth = tileWidth,
      tileHeight = tileHeight,
      width = width,
      height = height,
      spriteBatches = map(spritesheets, function(spritesheet)
         return love.graphics.newSpriteBatch(spritesheet.image, width * height)
      end),
      tiles = {},
      tileSprites = nil,
      points = {},
      tileOrder = {},
   }
   setmetatable(this, self)

   this.tileSprites = map(spritesheets, function(spritesheet) return spritesheet:getQuads() end)
   for index, spritesheet in ipairs(spritesheets) do
      this.tileOrder[index] = spritesheet.name
   end

   math.randomseed(1)
   for row = 1, this.height do
      for column = 1, this.width do
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
function Map:update()
end

function Map:saveTo(file)
   print("Saving to file: ", file)
   mapEncoder:saveToFile(file, {
      width = self.width,
      height = self.height,
      tiles = self.tiles,
      points = self.points,
      tileOrder = self.tileOrder,
   })
end

function Map:loadFrom(file)
   print("Loading from file: ", file)
   local data = mapEncoder:loadFromFile(file)
   self.width = data.width
   self.height = data.height
   self.tiles = data.tiles
   self.points = data.points
   self.tileOrder = data.tileOrder or {}

   -- Reorder the spritesheets(tilesheets) as their order has been defined in tileOrder
   local spritesheetMap = {}
   for _, spritesheet in ipairs(self.spritesheets) do
      spritesheetMap[spritesheet.name] = spritesheet
   end
   self.spritesheets = {}
   local nilTiles = 0
   for index, name in ipairs(self.tileOrder) do
      if spritesheetMap[name] then
         self.spritesheets[index] = spritesheetMap[name]
         spritesheetMap[name] = nil
      else
         print("Could not find tilesheet " .. name .. " for tile ID " .. index .. ". Erasing all tiles with this ID.")
         self:changeTiles(index, TILE_EMPTY)
         nilTiles = nilTiles + 1
      end
   end

   -- Although it should never happen unless the game dev has renamed/deleted tilesheets manually, in the case that
   -- there are tile names that used to have a mapping and are now gone, they should be removed.
   local rightIndex = #self.tileOrder
   local leftIndex = 1
   while nilTiles > 0 do
      while rightIndex > 0 and self.spritesheets[rightIndex] == nil do
         self.tileOrder[rightIndex] = nil
         rightIndex = rightIndex - 1
         nilTiles = nilTiles - 1
      end
      if nilTiles == 0 then break end
      while self.spritesheets[leftIndex] ~= nil do leftIndex = leftIndex + 1 end
      self:changeTiles(rightIndex, leftIndex)

      self.tileOrder[leftIndex] = self.tileOrder[rightIndex]
      self.tileOrder[rightIndex] = nil
      --      print("Swapping " .. leftIndex .. " and " .. rightIndex)
      nilTiles = nilTiles - 1
   end

   -- Add the newly introduced (previously not mentioned in the tile order) spritesheets.
   for _, spritesheet in pairs(spritesheetMap) do
      self.tileOrder[#self.tileOrder + 1] = spritesheet.name
      self.spritesheets[#self.spritesheets + 1] = spritesheet
   end

   -- Make sprite batches corresponding to the tilesheets.
   self.spriteBatches = map(self.spritesheets, function(spritesheet)
      return love.graphics.newSpriteBatch(spritesheet.image, self.width * self.height)
   end)
   self:recreateSpriteBatches()
end

--- Switch tiles of type 'from' to tiles of type 'to'
function Map:changeTiles(from, to)
   for i = 1, #self.tiles do
      if self.tiles[i] == from then
         self.tiles[i] = to
      end
   end
end

--- Gets the tile from a specified cell
-- @param column {int} - The column of the cell
-- @param row {int} - The row of the cell
-- @returns {int}
function Map:getTile(column, row)
   if column <= 0 or row <= 0 or column > self.width or row > self.height then
      return TILE_EMPTY
   end
   return self.tiles[(row - 1) * self.width + column]
end

--- Sets the tile at a specified cell
-- @param column {int} - The column of the cell
-- @param row {int} - The row of the cell
-- @param tile {int} - The ID/index of the new tile
function Map:setTile(column, row, tile)
   if column <= 0 or row <= 0 or column > self.width or row > self.height then
      return
   end
   self.tiles[(row - 1) * self.width + column] = tile
end

--- Updates the sprite batch with sprites corresponding to the current tiles.
-- NOTE: A sprite batch is used for efficient rendering.
function Map:recreateSpriteBatches()
   for i = 1, #self.spriteBatches do
      self.spriteBatches[i]:clear()
   end

   for row = 1, self.height do
      for column = 1, self.width do
         local x = (column - 1) * self.tileWidth
         local y = (row - 1) * self.tileHeight
         local tile = self:getTile(column, row)
         if tile == nil then
            error("nil tile at column " .. column .. ", row " .. row)
         elseif not (tile == TILE_EMPTY) then
            if tile > #self.tileSprites then
               error("Tile '" .. tile .. "' is not valid. There are only " .. #self.tileSprites .. " tile types.")
            end
            if #self.tileSprites[tile] == 1 then
               self.spriteBatches[tile]:add(self.tileSprites[tile][1], x, y)
            else
               local hasLeft = self:getTile(column - 1, row) == tile
               local hasRight = self:getTile(column + 1, row) == tile
               local hasUp = self:getTile(column, row - 1) == tile
               local hasDown = self:getTile(column, row + 1) == tile
               local sprite = self.tileSprites[tile][1 +
                     ((hasUp and 1 or 0) * 2 + (hasDown and 1 or 0)) * 4 +
                     ((hasLeft and 1 or 0) * 2 + (hasRight and 1 or 0))]

               self.spriteBatches[tile]:add(sprite, x, y)

               if #self.tileSprites[tile] > 16 then
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
   end
end

--- LOVE draw handler
function Map:draw()
   for _, spriteBatch in ipairs(self.spriteBatches) do
      love.graphics.draw(spriteBatch)
   end
end