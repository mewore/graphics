require "native-file"

MapEncoder = {}
MapEncoder.__index = MapEncoder

local KEY_VALUE_SEPARATOR = " = "
local TILE_BYTE_OFFSET = 65

function MapEncoder:create()
   local this = {}
   setmetatable(this, self)
   return this
end

-- ENCODING

local function encodeMapTiles(tiles)
   local tileArray = {}
   for index, value in ipairs(tiles) do
      tileArray[index] = string.char(TILE_BYTE_OFFSET + value)
   end
   return table.concat(tileArray, "")
end

-- Turns a table into a set of key-value pairs. The values must be string or cast-able to string
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

function MapEncoder:saveToFile(filename, map)
   print("Saving to " .. filename)
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

local function decodeMapTiles(rawTiles, width, height)
   local tiles = {}
   local length = width * height
   for index = 1, length do
      tiles[index] = string.byte(rawTiles, index) - TILE_BYTE_OFFSET
   end
   return tiles
end

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

function MapEncoder:loadFromFile(filename)
   print("Loading from " .. filename)
   local file = NativeFile:create(filename)
   local encoded = file:read(filename)
   local data = decode(encoded)
   data.tiles = decodeMapTiles(data.tiles, data.mapWidth, data.mapHeight)
   return data
end