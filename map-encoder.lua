require "native-file"
require "properties-encoder"

MapEncoder = {}
MapEncoder.__index = MapEncoder

local TILE_BYTE_OFFSET = 65

--- A map encoder handles the ENcoding and DEcoding of maps to/from files
function MapEncoder:create()
   local this = {}
   setmetatable(this, self)
   return this
end

--- Turns an array of tiles into a string, where each character is an ASCII encoding of the corresponding tile int value
-- @param tiles {int[]} - The source tiles
-- @returns {string}
local function encodeMapTiles(tiles)
   local tileArray = {}
   for index, value in ipairs(tiles) do
      tileArray[index] = string.char(TILE_BYTE_OFFSET + value)
   end
   return table.concat(tileArray, "")
end

--- Encodes and saves map data into a file
-- @param filename {string}
-- @param map {table}
function MapEncoder:saveToFile(filename, map)
   local encoded = PropertiesEncoder:create():encode({
      tileWidth = map.tileWidth,
      tileHeight = map.tileHeight,
      mapWidth = map.mapWidth,
      mapHeight = map.mapHeight,
      tiles = encodeMapTiles(map.tiles, map.mapWidth, map.mapHeight),
   })
   local file = NativeFile:create(filename)
   file:write(encoded)
end

--- Decode a tile string into an array of tiles
-- @param rawTiles {string} - The source encoded tiles
-- @returns {int[]} - The decoded tiles
local function decodeMapTiles(rawTiles)
   local tiles = {}
   local length = string.len(rawTiles)
   for index = 1, length do
      tiles[index] = string.byte(rawTiles, index) - TILE_BYTE_OFFSET
   end
   return tiles
end

--- Load map data from a file
-- @param filename {string} - The file to load the map from
-- @returns {table} - The decoded data
function MapEncoder:loadFromFile(filename)
   local file = NativeFile:create(filename)
   local encoded = file:read(filename)
   local data = PropertiesEncoder:create():decode(encoded)
   data.tiles = decodeMapTiles(data.tiles)
   return data
end