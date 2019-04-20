require "controls/list"
require "controls/button"
require "controls/text-input"
require "data/native-file"
require "views/tile-editor"

TilesheetList = {}
TilesheetList.__index = TilesheetList


--- Open an editor at the top of the view stack and remove it when it is closed
-- @param editor The editor to open
local function openEditor(editor)
   viewStack:pushView(editor)
   editor.onClose = function() viewStack:popView(editor) end
end

local TILESHEET_DIRECTORY = love.filesystem.getWorkingDirectory() .. "/tilesheets"
local NEW_TILESHEET_ITEM = "(+) New tilesheet"

--- A list of maps in the current working directory
function TilesheetList:create()
   local tilesheetFiles = NativeFile:create(TILESHEET_DIRECTORY):getFiles("png")
   local tilesheetInfoFiles = NativeFile:create(TILESHEET_DIRECTORY):getFiles("json")
   local tilesheetInfoByName = {}
   for _, tilesheetInfoFile in ipairs(tilesheetInfoFiles) do
      tilesheetInfoByName[tilesheetInfoFile.name] = tilesheetInfoFile:readAsJson()
   end

   local tilesheetTable = {}
   local tilesheetItems = { { value = NEW_TILESHEET_ITEM } }
   for _, file in ipairs(tilesheetFiles) do
      local tilesheetInfo = tilesheetInfoByName[file.name]
      if not tilesheetInfo then
         error("There is no " .. file.name .. ".json file corresponding to " .. file.filename)
      end
      tilesheetTable[file.name] = true
      tilesheetItems[#tilesheetItems + 1] = {
         label = file.name,
         value = file.path,
         icon = file:readAsImage(),
         iconQuadWidth = tilesheetInfo.width,
         iconQuadHeight = tilesheetInfo.height,
      }
   end

   local list = List:create(tilesheetItems)
   local this = {
      list = list,
   }
   setmetatable(this, self)

   list:onSelect(function(value)
      if value == NEW_TILESHEET_ITEM then
         local nameInput = TextInput:create(300, "Name", "", {
            kebabCase = true,
            validations = { function(value) return not tilesheetTable[value] end }
         })
         local widthInput = TextInput:create(50, "Tile width", "32", { positive = true, integer = true })
         local heightInput = TextInput:create(50, "Tile height", "32", { positive = true, integer = true })

         local dialog
         local okButton = Button:create("OK", "solid", function()
            if not (nameInput.isValid and widthInput.isValid and heightInput.isValid) then
               return
            end

            local tilesheetPath = TILESHEET_DIRECTORY .. "/" .. nameInput.value
            local width, height = tonumber(widthInput.value), tonumber(heightInput.value)

            local pngFilePath = tilesheetPath .. ".png"
            local pngFileData = love.image.newImageData(width, height)
            for y = 0, height - 1 do
               for x = 0, width - 1 do
                  pngFileData:setPixel(x, y, 0, 0, 0, 0)
               end
            end

            local jsonFilePath = tilesheetPath .. ".json"
            NativeFile:create(pngFilePath):write(pngFileData:encode("png"):getString())
            NativeFile:create(jsonFilePath):writeAsJson({ width = width, height = height })
            list:addItemAndKeepSorted({ label = nameInput.value, value = pngFilePath })

            viewStack:popView(dialog)
            openEditor(ImageEditor:create(pngFilePath))
         end)
         local cancelButton = Button:create("Cancel", nil, function() viewStack:popView(dialog) end)

         dialog = Dialog:create("Create a new tilesheet", nil,
            { nameInput, widthInput, heightInput }, { cancelButton, okButton })
      else
         openEditor(ImageEditor:create(value))
      end
   end)

   return this
end

function TilesheetList:setPosition(x, y) self.list:setPosition(x, y) end

function TilesheetList:setSize(width, height) self.list:setSize(width, height) end

function TilesheetList:setSize(width, height) self.list:setSize(width, height) end

function TilesheetList:getX() return self.list:getX() end

function TilesheetList:getY() return self.list:getY() end

function TilesheetList:getWidth() return self.list:getWidth() end

function TilesheetList:getHeight() return self.list:getHeight() end

--- LOVE update handler
-- @param dt {float} - The amount of time (in seconds) since the last update
function TilesheetList:update(dt) self.list:update(dt) end

--- LOVE draw handler
function TilesheetList:draw() self.list:draw() end