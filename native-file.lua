require "properties-encoder"

NativeFile = {}
NativeFile.__index = NativeFile

local OS_WINDOWS = "Windows"
local CHECK_ATTRIBUTES_FILE_NAME = "check-attributes.bat";
local CHECK_ATTRIBUTES_FILE_LOCATION = love.filesystem.getSaveDirectory() .. "/" .. CHECK_ATTRIBUTES_FILE_NAME;

--- Wrapper of the native (Lua) file operations to avoid using the limited love.filesystem
--
-- Mostly useful for writing in directories different than the save directory or reading from directories that are
-- neither in the save directory nor under the directory Graphics is in.
--
-- The interface of this class is similar to Java"s File
-- @param path {string} - The path to the file
function NativeFile:create(path)
   local filename = string.gsub(path, ".*[/\\]", "")
   local nameParts = {}
   for part in string.gmatch(filename, "([^.]+)") do
      nameParts[#nameParts + 1] = part
   end
   local extension
   if #nameParts > 1 then
      extension = nameParts[#nameParts]
      nameParts[#nameParts] = nil
   end
   local name = table.concat(nameParts, ".")
   local this = {
      path = path,
      filename = filename,
      name = name,
      extension = extension,
   }
   setmetatable(this, self)
   return this
end

--- Open the file at the spcified path with a mode (r/w/a/w+/a+).
-- On SUCCESS, returns the file
-- On FAILURE, throws an error
-- @param path {string}
-- @param mode {string} - A string that consists of one character - "r" for read, "w" for write, "a" for append, etc.
-- @returns {io.file}
local function openFile(path, mode)
   local file, errorMessage, errorCode = io.open(path, mode)
   if file == nil then
      error("Encountered error with code " .. errorCode .. " while opening file " .. path .. ": " .. errorMessage)
   end
   return file
end

--- Open the file and read it.
-- On SUCCESS, returns the file contents as a string
-- On FAILURE, throws an error
-- @returns {string} - The contents of the file
function NativeFile:read()
   local file = openFile(self.path, "rb")
   local contents = file:read("*all")
   file:close()
   return contents
end

--- If this is a .properties file, it can be read as a table. Currently, only single-line properties are supported.
-- @returns {string} - The properties described in the file
function NativeFile:readAsTable()
   local contents = self:read()
   return PropertiesEncoder:create():decode(contents)
end

--- Create or overwrite the file with the specified contents.
-- On SUCCESS, returns nil
-- On FAILURE, throws an error
-- @param contents {string} - What to write into the file
function NativeFile:write(contents)
   local file = openFile(self.path, "wb")
   file:write(contents)
   file:close()
end

--- Checks whether the path corresponds to a directory
-- @returns {boolean}
function NativeFile:isDirectory()
   return self:getAttributes() == "d--------"
end

--- Gets the attributes of the file/directory
-- @returns {boolean}
function NativeFile:getAttributes()
   if love.system.getOS() ~= OS_WINDOWS then
      error("Checking whether paths correspond to directories in OSs different than Windows is not implemented")
   end
   local file = io.popen(CHECK_ATTRIBUTES_FILE_LOCATION .. " " .. self.path, "r")
   -- There are two unnecessary lines
   file:read("*l")
   file:read("*l")
   local output = file:read("*l")
   file:close()
   return output
end

--- Lists the files in this directory (assuming this NativeFile instance corresponds to a directory)
-- @param extension {string} - The extension to filter the files by
function NativeFile:getFiles(extension)
   if love.system.getOS() ~= OS_WINDOWS then
      error("Listing the children of directories in OSs different than Windows is not supported yet")
   elseif not self:isDirectory() then
      error("Cannot get the sub-files of a non-directory (" .. self.path .. ")")
   end
   local file = io.popen("dir \"" .. self.path .. "\" /b /a-d", "r")
   local output = file:read("*a")
   file:close()
   local result = {}
   for match in string.gmatch(output, (extension == nil) and "([^\n]+)\n" or ("([^\n]-%." .. extension .. ")\n")) do
      result[#result + 1] = NativeFile:create(self.path .. "/" .. match)
   end
   return result
end

--- Lists the directories in this directory (assuming this NativeFile instance corresponds to a directory)
function NativeFile:getDirectories()
   if love.system.getOS() ~= OS_WINDOWS then
      error("Listing the children of directories in OSs different than Windows is not supported yet")
   elseif not self:isDirectory() then
      error("Cannot get the sub-directories of a non-directory (" .. self.path .. ")")
   end
   local file = io.popen("dir \"" .. self.path .. "\" /b /ad", "r")
   local output = file:read("*a")
   file:close()
   local result = {}
   for match in string.gmatch(output, "(..-)\n") do
      result[#result + 1] = NativeFile:create(self.path .. "/" .. match)
   end
   return result
end

-- Batch file necessary for checking attributes... ugh -.-
local success, message = love.filesystem.write(CHECK_ATTRIBUTES_FILE_NAME, "echo %~a1")
if not success then
   error("Failed to create file " .. CHECK_ATTRIBUTES_FILE_NAME .. " due to: " .. message)
end