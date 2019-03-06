require 'tile-controls'
require 'map-encoder'

MapEditor = {}
MapEditor.__index = MapEditor

local MAP_WIDTH = 256
local MAP_HEIGHT = 32

local COLUMN_COUNT = 4

local SAVE_BUTTON = 's'
local LOAD_BUTTON = 'l'
local MAP_SAVE_FILE_NAME = love.filesystem.getWorkingDirectory() .. '/maps/test.map'
local mapEncoder = MapEncoder:create()

local function getTileIndex(row, column)
   return (row - 1) * COLUMN_COUNT + column
end

local function generateQuads(spritesheet, tileWidth, tileHeight)
   local sheetWidth = spritesheet:getWidth() / tileWidth
   local sheetHeight = spritesheet:getHeight() / tileHeight

   local sheetCounter = 1
   local quads = {}

   for y = 0, sheetHeight - 1 do
      for x = 0, sheetWidth - 1 do
         quads[sheetCounter] = love.graphics.newQuad(x * tileWidth, y * tileHeight, tileWidth, tileHeight,
            spritesheet:getDimensions())
         sheetCounter = sheetCounter + 1
      end
   end

   return quads
end

local TILE_EMPTY = 0
local TILE_GROUND = 1
local TILE_GROUND_CORNER_TOP_LEFT = getTileIndex(5, 1)
local TILE_GROUND_CORNER_TOP_RIGHT = getTileIndex(5, 2)
local TILE_GROUND_CORNER_BOTTOM_RIGHT = getTileIndex(5, 3)
local TILE_GROUND_CORNER_BOTTOM_LEFT = getTileIndex(5, 4)

local LEFT_MOUSE_BUTTON = 1

function MapEditor:create(spritesheetName)
   local spritesheet = love.graphics.newImage(spritesheetName .. '.png')

   local this = {
      spritesheet = spritesheet,
      tileWidth = 32,
      tileHeight = 32,
      mapWidth = MAP_WIDTH,
      mapHeight = MAP_HEIGHT,
      spriteBatch = love.graphics.newSpriteBatch(spritesheet, MAP_WIDTH * MAP_HEIGHT),
      tiles = {},
      playerSpawnX = -1,
      playerSpawnY = -1,
      tileControls = TileControls:create({ r = 1, g = 0, b = 0 }, 32, 32),
   }
   setmetatable(this, self)

   this.tileControls:onMouseDown(function(points, button)
      local tileToCreate = (button == LEFT_MOUSE_BUTTON) and TILE_GROUND or TILE_EMPTY
      for _, point in pairs(points) do
         if this:getTile(point.x, point.y) ~= tileToCreate then
            this:setTile(point.x, point.y, tileToCreate)
            this:recreateSpriteBatch()
         end
      end
   end)

   this.tileSprites = generateQuads(spritesheet, 32, 32)

   math.randomseed(1)
   for row = 1, this.mapHeight do
      for column = 1, this.mapWidth do
         this:setTile(column, row, (math.random() > 0.3) and TILE_EMPTY or TILE_GROUND)
         if this:getTile(column, row) == nil then
            print('BAD at:', column, row)
         end
      end
   end

   this:recreateSpriteBatch()

   return this
end

function MapEditor:update()
   if love.keyboard.keysPressed[SAVE_BUTTON] then
      mapEncoder:saveToFile(MAP_SAVE_FILE_NAME, self)
   elseif love.keyboard.keysPressed[LOAD_BUTTON] then
      local data = mapEncoder:loadFromFile(MAP_SAVE_FILE_NAME)
      self.tileWidth = data.tileWidth
      self.tileHeight = data.tileHeight
      self.mapWidth = data.mapWidth
      self.mapHeight = data.mapHeight
      self.tiles = data.tiles
      self:recreateSpriteBatch()
   end
   self.tileControls:update()
end

function MapEditor:getTile(column, row)
   if column <= 0 or row <= 0 or column > self.mapWidth or row > self.mapHeight then
      return TILE_EMPTY
   end
   return self.tiles[(row - 1) * self.mapWidth + column]
end

function MapEditor:setTile(column, row, tile)
   self.tiles[(row - 1) * self.mapWidth + column] = tile
end

function MapEditor:recreateSpriteBatch()
   self.spriteBatch = love.graphics.newSpriteBatch(self.spritesheet, self.mapWidth * self.mapHeight)
   for row = 1, self.mapHeight do
      for column = 1, self.mapWidth do
         local x = (column - 1) * self.tileWidth
         local y = (row - 1) * self.tileHeight
         local tile = self:getTile(column, row)
         if tile == nil then
            error('nil tile at column ' .. column .. ', row ' .. row)
         elseif tile == TILE_GROUND then
            local hasLeft = self:getTile(column - 1, row) == TILE_GROUND
            local hasRight = self:getTile(column + 1, row) == TILE_GROUND
            local hasUp = self:getTile(column, row - 1) == TILE_GROUND
            local hasDown = self:getTile(column, row + 1) == TILE_GROUND
            local sprite = self.tileSprites[1 +
                  ((hasUp and 1 or 0) * 2 + (hasDown and 1 or 0)) * 4 +
                  ((hasLeft and 1 or 0) * 2 + (hasRight and 1 or 0))]

            self.spriteBatch:add(sprite, x, y)

            if not (self:getTile(column - 1, row - 1) == TILE_GROUND) and hasUp and hasLeft then
               self.spriteBatch:add(self.tileSprites[TILE_GROUND_CORNER_TOP_LEFT], x, y)
            end

            if not (self:getTile(column + 1, row - 1) == TILE_GROUND) and hasUp and hasRight then
               self.spriteBatch:add(self.tileSprites[TILE_GROUND_CORNER_TOP_RIGHT], x, y)
            end

            if not (self:getTile(column - 1, row + 1) == TILE_GROUND) and hasDown and hasLeft then
               self.spriteBatch:add(self.tileSprites[TILE_GROUND_CORNER_BOTTOM_LEFT], x, y)
            end

            if not (self:getTile(column + 1, row + 1) == TILE_GROUND) and hasDown and hasRight then
               self.spriteBatch:add(self.tileSprites[TILE_GROUND_CORNER_BOTTOM_RIGHT], x, y)
            end
         elseif not (tile == TILE_EMPTY) then
            self.spriteBatch:add(self.tileSprites[tile], x, y)
         end
      end
   end
end

function MapEditor:render()
   love.graphics.draw(self.spriteBatch)
   self.tileControls:render()
end