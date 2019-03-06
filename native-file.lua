NativeFile = {}
NativeFile.__index = NativeFile

-- Wrapper of the native (Lua) file operations to avoid using the limited love.filesystem
--
-- Mostly useful for writing in directories different than the save directory or reading from directories that are
-- neither in the save directory nor under the directory Graphics is in.
--
-- The interface of this class is similar to Java's File
function NativeFile:create(path)
   local this = {
      path = path,
   }
   setmetatable(this, self)
   return this
end

-- Open the file at the spcified path with a mode (r/w/a/w+/a+).
-- On SUCCESS, returns the file
-- On FAILURE, throws an error
local function openFile(path, mode)
   local file, errorMessage, errorCode = io.open(path, mode)
   if file == nil then
      error('Encountered error with code ' .. errorCode .. ' while opening file ' .. file .. ': ' .. errorMessage)
   end
   return file
end

-- Open the file and read it.
-- On SUCCESS, returns the file contents as a string
-- On FAILURE, throws an error
function NativeFile:read()
   local file = openFile(self.path, 'r')
   local contents = file:read('*all')
   file:close()
   return contents
end

-- Create or overwrite the file with the specified contents.
-- On SUCCESS, returns nil
-- On FAILURE, throws an error
function NativeFile:write(contents)
   print ('Writing ' )
   local file = openFile(self.path, 'w')
   file:write(contents)
   file:close()
end