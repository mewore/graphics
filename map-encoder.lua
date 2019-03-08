require "native-file"
require "properties-encoder"

MapEncoder = {}
MapEncoder.__index = MapEncoder

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
      tileArray[index] = string.char(127 - value)
   end
   return table.concat(tileArray, "")
end

--- Encodes and saves map data into a file
-- @param filename {string}
-- @param map {table}
function MapEncoder:saveToFile(filename, map)
   local mapData = encodeMapTiles(map.tiles, map.mapWidth, map.mapHeight)
   local mapPropertiesData = PropertiesEncoder:create():encode({
      mapWidth = map.mapWidth,
      mapHeight = map.mapHeight,
   })

   local mapFile = NativeFile:create(filename .. ".map")
   local mapPropertiesFile = NativeFile:create(filename .. ".properties")

   mapFile:write(mapData)
   mapPropertiesFile:write(mapPropertiesData)
end

--- Decode a tile string into an array of tiles
-- @param rawTiles {string} - The source encoded tiles
-- @returns {int[]} - The decoded tiles
local function decodeMapTiles(rawTiles)
   local tiles = {}
   local length = string.len(rawTiles)
   for index = 1, length do
--      tiles[index] = string.byte(rawTiles, index) - TILE_BYTE_OFFSET
      tiles[index] = 127 - string.byte(rawTiles, index)
   end
   return tiles
end

--- Load map data from a file
-- @param filename {string} - The file to load the map from
-- @returns {table} - The decoded data
function MapEncoder:loadFromFile(filename)
   local mapFile = NativeFile:create(filename .. ".map")
   local mapPropertiesFile = NativeFile:create(filename .. ".properties")

   local result = PropertiesEncoder:create():decode(mapPropertiesFile:read())
   result.tiles = decodeMapTiles(mapFile:read())
   return result
end