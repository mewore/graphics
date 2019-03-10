JsonEncoder = {}
JsonEncoder.__index = JsonEncoder

local INDENTAITON_PER_LEVEL = 3
local INDENTATION_STRING = string.rep(" ", INDENTAITON_PER_LEVEL)
local TABLE_OPEN = "{"
local TABLE_CLOSE = "}"
local ARRAY_OPEN = "["
local ARRAY_CLOSE = "]"

--- Reads/writes .properties files
function JsonEncoder:create()
   local this = {}
   setmetatable(this, self)
   return this
end

local IGNORED_TYPES = {
   ["function"] = true,
   ["userdata"] = true,
   ["thread"] = true,
}

local function escapeString(str)
   str = string.gsub(str, "\\", "\\\\")
   str = string.gsub(str, "\"", "\\\"")
   str = string.gsub(str, "\n", "\\n")
   str = string.gsub(str, "\r", "\\r")
   return str
end

local EPS = 0.00000000001

--- Checks whether a table is an array or a generic table.
-- @param table {table}
-- @returns {boolean}
local function isArray(table)
   local length = #table
   local tableKeys = {}
   for key, _ in pairs(table) do
      if type(key) ~= "number" or key < 1 or key > length or key - math.floor(key) > EPS or tableKeys[key] then
         return false
      end
      tableKeys[key] = true
   end
   return true
end

local JSON_LINE_LIMIT = 120

--- Turns any value into a JSON string.
-- @param valueToEncode {*}
-- @param indentation {int}
-- @param visitedTables {table} - The set of already visited tables. The purpose of this is to avoid cycles.
-- @param path {string[]} - An array of visited keys/indices. Used for the cyclic reference error message.
-- @returns {string}
local function encode(valueToEncode, indentation, visitedTables, path)
   if valueToEncode == nil then return "null", false end
   local valueType = type(valueToEncode)
   if IGNORED_TYPES[valueType] then return "", false end
   if valueType == "string" then return "\"" .. escapeString(valueToEncode) .. "\"", false end
   if valueType == "number" then return "" .. valueToEncode, false end
   if valueType == "boolean" then return (valueToEncode and "true" or "false"), false end

   -- valueType is "table"
   local tableId = tostring(valueToEncode)
   if visitedTables[tableId] ~= nil then
      local errorParts = { "0" }
      for i = 1, #path do
         errorParts[#errorParts + 1] = "--[" .. path[i] .. "]-->"
         if i == #path then
            errorParts[#errorParts + 1] = visitedTables[tableId]
         else
            errorParts[#errorParts + 1] = i
         end
      end
      error("Cannot convert value to JSON because it contains a cyclic reference: " .. table.concat(errorParts, " "))
   end
   visitedTables[tableId] = #path

   local openingCharacter, closingCharacter
   local innerLines = {}
   local currentIndentationString = string.rep(INDENTATION_STRING, indentation)
   local totalChildLength = 0
   local hasMultilineChild = false
   local containsOnlyPrimitives = true
   if isArray(valueToEncode) then
      openingCharacter, closingCharacter = ARRAY_OPEN, ARRAY_CLOSE
      for index, value in ipairs(valueToEncode) do
         path[#path + 1] = index
         local encoded, isMultiline = encode(value, indentation + 1, visitedTables, path)
         path[#path] = nil
         if encoded ~= nil and #encoded > 0 then
            innerLines[#innerLines + 1] = encoded
            totalChildLength = totalChildLength + #innerLines[#innerLines] + 2
            hasMultilineChild = hasMultilineChild or isMultiline
            if type(value) == "table" then
               containsOnlyPrimitives = false
            end
         end
      end
   else
      containsOnlyPrimitives = false
      openingCharacter, closingCharacter = TABLE_OPEN, TABLE_CLOSE
      for key, value in pairs(valueToEncode) do
         path[#path + 1] = key
         local encoded, isMultiline = encode(value, indentation + 1, visitedTables, path)
         path[#path] = nil
         if encoded ~= nil and #encoded > 0 then
            innerLines[#innerLines + 1] = encode(key) .. ": " .. encoded
            totalChildLength = totalChildLength + #innerLines[#innerLines] + 2
            hasMultilineChild = hasMultilineChild or isMultiline
         end
      end
   end

   visitedTables[tableId] = nil

   if #innerLines == 0 then
      return openingCharacter .. closingCharacter, false
   end

   local nextIndentationString = string.rep(INDENTATION_STRING, indentation + 1)
   local shouldBeMultiline = (hasMultilineChild or totalChildLength > JSON_LINE_LIMIT) and not containsOnlyPrimitives
   if shouldBeMultiline then
      for i = 1, #innerLines do
         innerLines[i] = nextIndentationString .. innerLines[i]
      end
   end
   return table.concat({
      openingCharacter,
      table.concat(innerLines, shouldBeMultiline and ",\n" or ", "),
      shouldBeMultiline and (currentIndentationString .. closingCharacter) or closingCharacter
   }, shouldBeMultiline and "\n" or ""), shouldBeMultiline
end

--- Turns a value into a JSON string.
-- @param valueToEncode {*} - The decoded value
-- @returns {string} - The encoded JSON
function JsonEncoder:encode(valueToEncode)
   return encode(valueToEncode, 0, {}, {})
end

local CHAR_0 = string.byte("0")
local CHAR_9 = string.byte("9")
local CHAR_BACKSLASH = string.byte("\\")
local CHAR_LOWERCASE_A = string.byte("a")
local CHAR_LOWERCASE_Z = string.byte("z")
local CHAR_DOT = string.byte(".")
local CHAR_SPACE = string.byte(" ")
local CHAR_RETURN = string.byte("\r")
local CHAR_NEWLINE = string.byte("\n")
local CHAR_TABLE_OPEN = string.byte(TABLE_OPEN)
local CHAR_TABLE_CLOSE = string.byte(TABLE_CLOSE)
local CHAR_ARRAY_OPEN = string.byte(ARRAY_OPEN)
local CHAR_ARRAY_CLOSE = string.byte(ARRAY_CLOSE)
local CHAR_COMMA = string.byte(",")
local CHAR_COLON = string.byte(":")
local CHAR_DOUBLE_QUOTE = string.byte("\"")

local ESCAPABLE_CHARACTERS = [[nrbt"\\]]
local CHARACTER_ESCAPES = {}
for i = 1, #ESCAPABLE_CHARACTERS do
   CHARACTER_ESCAPES[string.byte(ESCAPABLE_CHARACTERS, i)] = ESCAPABLE_CHARACTERS[i]
end

local SPECIAL_CHARACTERS = {}
for _, character in ipairs({ CHAR_COMMA, CHAR_COLON, CHAR_ARRAY_CLOSE, CHAR_ARRAY_OPEN, CHAR_TABLE_CLOSE, CHAR_TABLE_OPEN }) do
   SPECIAL_CHARACTERS[character] = true
end

local TOKEN_VALUE = 1
local TOKEN_STRING = 2
local TOKEN_SPECIAL = 3

local function getLineColumnString(lineOrToken, column)
   return type(lineOrToken) == "table"
         and getLineColumnString(lineOrToken[3], lineOrToken[4])
         or "line " .. lineOrToken .. ", column " .. column
end

local function tokenize(rawData)
   --- @type {[int, int, int, int][]} - An array of 4-int tuples. The first values in the tuples are as follows:
   -- - The token type
   -- - The token value
   -- - The line of the first character of the token (used for the error message)
   -- - The column of the first character of the token (used for the error message)
   local tokens = {}
   local tokenStartLine
   local tokenStartColumn
   local currentString
   local nonStringStartIndex -- number/boolean/nil
   local isEscaping = false
   local line = 1
   local column = 1

   -- Adding a "padding" of one in order to easily imagine an extra newline at the end
   for i = 1, #rawData + 1 do
      local byte = string.byte(rawData, i) or CHAR_NEWLINE
      if currentString == nil and nonStringStartIndex ~= nil then
         if not ((byte >= CHAR_0 and byte <= CHAR_9)
               or (byte >= CHAR_LOWERCASE_A and byte <= CHAR_LOWERCASE_Z)
               or byte == CHAR_DOT) then
            local valueString = string.sub(rawData, nonStringStartIndex, i - 1)
            local value
            if valueString == "null" then
               value = nil
            elseif valueString == "false" then
               value = false
            elseif valueString == "true" then
               value = true
            else
               value = tonumber(valueString)
               if value == nil then
                  error("'" .. valueString .. "', which starts at " ..
                        getLineColumnString(tokenStartLine, tokenStartColumn) ..
                        ", is not a valid number, null, string or boolean")
               end
            end
            tokens[#tokens + 1] = { TOKEN_VALUE, value, tokenStartLine, tokenStartColumn }
            nonStringStartIndex = nil
         end
      end

      if currentString ~= nil then
         if isEscaping then
            currentString[#currentString + 1] = CHARACTER_ESCAPES[byte] or string.char(byte)
            isEscaping = false
         elseif byte == CHAR_BACKSLASH then
            isEscaping = true
         elseif byte == CHAR_DOUBLE_QUOTE then
            tokens[#tokens + 1] = { TOKEN_STRING, table.concat(currentString, ""), tokenStartLine, tokenStartColumn }
            currentString = nil
         elseif byte == CHAR_NEWLINE or byte == CHAR_RETURN then
            error("At " .. getLineColumnString(line, column) .. " there is a newline in a string, which starts at " ..
                  getLineColumnString(tokenStartLine, tokenStartColumn))
         else
            currentString[#currentString + 1] = string.char(byte)
         end
      elseif byte == CHAR_NEWLINE then
         line, column = line + 1, 0
      elseif byte == CHAR_RETURN then
         line, column = line + 1, 0
         if string.byte(rawData, i + 1) == CHAR_NEWLINE then
            i = i + 1
         end
      elseif SPECIAL_CHARACTERS[byte] then
         tokens[#tokens + 1] = { TOKEN_SPECIAL, byte, line, column }
      elseif byte == CHAR_DOUBLE_QUOTE then
         tokenStartLine, tokenStartColumn = line, column
         currentString = {}
      elseif byte ~= CHAR_SPACE and nonStringStartIndex == nil then
         tokenStartLine, tokenStartColumn = line, column
         nonStringStartIndex = i
      end

      column = column + 1
   end

   return tokens
end

local function assertTokenExists(token)
   if token == nil then
      error("JSON ends prematurely")
   end
   return token
end

local function isSpecialToken(token, tokenType)
   assertTokenExists(token)
   return token[1] == TOKEN_SPECIAL and token[2] == tokenType
end

local function assertSpecialToken(token, tokenType)
   if not isSpecialToken(token, tokenType) then
      error("Expected '" .. string.char(tokenType) .. "' at " .. getLineColumnString(token))
   end
   return token
end

local function assertString(token)
   assertTokenExists(token)
   if token[1] ~= TOKEN_STRING then
      error("Expected a string at " .. getLineColumnString(token))
   end
   return token
end

--- Decode JSON tokens
-- @param tokens {string} - The JSON tokens
-- @param start {int} - The index at which to start (ignore all tokens before it)
-- @returns {*} - The decoded data
local function decodeTokens(tokens, start)
   local firstToken = assertTokenExists(tokens[start])
   local firstTokenType, firstTokenValue = firstToken[1], firstToken[2]

   if firstTokenType == TOKEN_VALUE or firstTokenType == TOKEN_STRING then
      return firstTokenValue, start + 1
   end

   -- The token is special
   if firstTokenValue == CHAR_TABLE_OPEN then
      if isSpecialToken(tokens[start + 1], CHAR_TABLE_CLOSE) then
         return {}, start + 2
      end

      local key = assertString(tokens[start + 1])[2]
      assertSpecialToken(tokens[start + 2], CHAR_COLON)
      local value, indexAfterValue = decodeTokens(tokens, start + 3)
      local result = { [key] = value }

      local commaOrCloseToken = assertTokenExists(tokens[indexAfterValue])
      while isSpecialToken(commaOrCloseToken, CHAR_COMMA) do
         key = assertString(tokens[indexAfterValue + 1])[2]
         assertSpecialToken(tokens[indexAfterValue + 2], CHAR_COLON)
         value, indexAfterValue = decodeTokens(tokens, indexAfterValue + 3)
         result[key] = value
         commaOrCloseToken = assertTokenExists(tokens[indexAfterValue])
      end
      assertSpecialToken(commaOrCloseToken, CHAR_TABLE_CLOSE)
      return result, indexAfterValue + 1
   end

   if firstTokenValue == CHAR_ARRAY_OPEN then
      if isSpecialToken(tokens[start + 1], CHAR_ARRAY_CLOSE) then
         return {}, start + 2
      end

      local value, indexAfterValue = decodeTokens(tokens, start + 1)
      local result = { value }

      local commaOrCloseToken = assertTokenExists(tokens[indexAfterValue])
      while isSpecialToken(commaOrCloseToken, CHAR_COMMA) do
         value, indexAfterValue = decodeTokens(tokens, indexAfterValue + 1)
         result[#result + 1] = value
         commaOrCloseToken = assertTokenExists(tokens[indexAfterValue])
      end
      assertSpecialToken(commaOrCloseToken, CHAR_ARRAY_CLOSE)

      return result, indexAfterValue + 1
   end

   error("Invalid character at " .. getLineColumnString(firstToken))
end

--- Decode JSON from a string
-- @param rawData {string} - The source encoded data
-- @returns {*} - The decoded data
function JsonEncoder:decode(rawData)
   local tokens = tokenize(rawData)

   local result, firstUnusedIndex = decodeTokens(tokens, 1)
   if firstUnusedIndex <= #tokens then
      error("Invalid (redundant) character at " .. getLineColumnString(tokens[firstUnusedIndex]))
   end

   return result
end