PropertiesEncoder = {}
PropertiesEncoder.__index = PropertiesEncoder

local KEY_VALUE_SEPARATOR = " = "

--- Reads/writes .properties files
function PropertiesEncoder:create()
   local this = {}
   setmetatable(this, self)
   return this
end

--- Turns a table into a set of key-value pairs. The values must be string or cast-able to string
-- @param tableToEncode {table}
-- @returns {string}
function PropertiesEncoder:encode(tableToEncode)
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

--- Decode map data from a string
-- @param rawData {string} - The source encoded data
-- @returns {table} - The decoded data
function PropertiesEncoder:decode(rawData)
   local result = {}
   for k, v in string.gmatch(rawData .. "\n", "([^\n]+) = ([^\n]+)") do
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