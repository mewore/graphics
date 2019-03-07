require "native-file"

MapEncoder = {}
MapEncoder.__index = MapEncoder

local KEY_VALUE_SEPARATOR = " = "
local TILE_BYTE_OFFSET = 65

--- A map encoder handles the ENcoding and DEcoding of maps to/from files
function MapEncoder:create()
   local this = {}
   setmetatable(this, self)
   return this
end

-- ENCODING

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

--- Turns a table into a set of key-value pairs. The values must be string or cast-able to string
-- @param tableToEncode {table}
-- @returns {string}
local function encode(tableToEncode)
   local encodedArray = {}
   for k, v in pairs(tableToEncode) do
      if type(v) == "table" then
         error("Cannot encode a table value")
      elseif v == nil then
         error("Cannot encode a nil value")
      end
      encodedArray[#encodedArray + 1] = k .. KEY_VALUE_SEPARATOR .. v
   end
   return table.concat(encodedArray, "\n") .. "\n"
end

--- Encodes and saves map data into a file
-- @param filename {string}
-- @param map {table}
function MapEncoder:saveToFile(filename, map)
   local encoded = encode({
      tileWidth = map.tileWidth,
      tileHeight = map.tileHeight,
      mapWidth = map.mapWidth,
      mapHeight = map.mapHeight,
      tiles = encodeMapTiles(map.tiles, map.mapWidth, map.mapHeight),
   })
   local file = NativeFile:create(filename)
   file:write(encoded)
end

-- DECODING

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

--- Decode map data from a string
-- @param rawData {string} - The source encoded data
-- @returns {table} - The decoded data
local function decode(rawData)
   local result = {}
   for k, v in string.gmatch(rawData, "([^\n]+) = ([^\n]+)\n") do
      result[k] = v
   end

   for k, v in pairs(result) do
      local asNumber = tonumber(v)
      if asNumber ~= nil then
         result[k] = asNumber
      end
   end
   return result
end

--- Load map data from a file
-- @param filename {string} - The file to load the map from
-- @returns {table} - The decoded data
function MapEncoder:loadFromFile(filename)
   local file = NativeFile:create(filename)
   local encoded = file:read(filename)
   local data = decode(encoded)
   data.tiles = decodeMapTiles(data.tiles)
   return data
end