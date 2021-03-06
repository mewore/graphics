require "controls/paint-display"
require "controls/sidebar"
require "controls/tile-picker"
require "data/spritesheet"
require "navigator"
require "map"
require "tools/point-editor"
require "tools/tile-controls"
require "views/tile-editor"

MapEditor = {}
MapEditor.__index = MapEditor

local MAP_WIDTH = 256
local MAP_HEIGHT = 32

local SAVE_BUTTON = "s"
local LOAD_BUTTON = "l"

local TILE_EMPTY = 0

local LEFT_MOUSE_BUTTON = 1

local TOOL_MAP_EDITOR = 1
local TOOL_IMAGE_EDITOR = 2
local TOOL_POINT_EDITOR = 3

local TOOL_HOTKEYS = {
   q = TOOL_MAP_EDITOR,
   e = TOOL_IMAGE_EDITOR,
   r = TOOL_POINT_EDITOR,
}

--- Displays a map and allows the user to edit it
-- @param mapPath {string} - The path to the map file
-- @param spritesheetDirectoryPath {string} - The path to the directroy that contains all of the spritesheets
function MapEditor:create(mapPath, spritesheetDirectoryPath)
   local tileNameToInfoFile = {}
   local spritesheetDirectory = NativeFile:create(spritesheetDirectoryPath)
   for _, jsonFile in ipairs(spritesheetDirectory:getFiles("json")) do
      tileNameToInfoFile[jsonFile.name] = jsonFile
   end

   local tileWidth, tileHeight
   local allTilesheetFiles = spritesheetDirectory:getFiles("png")
   local spritesheets = {}
   for _, file in ipairs(allTilesheetFiles) do
      local infoFile = tileNameToInfoFile[file.name]
      if infoFile == nil then
         print("There is no '" .. file.name .. ".json' file in " .. spritesheetDirectory.path)
      else
         local info = infoFile:readAsJson()
         if tileWidth == nil then
            tileWidth = info.width
            tileHeight = info.height
         elseif tileWidth ~= info.width then
            error("Tile '" .. file.name .. "' has a width of " .. info.width ..
                  ", which is not consistent with the established width - " .. tileWidth)
         elseif tileHeight ~= info.height then
            error("Tile '" .. file.name .. "' has a height of " .. info.height ..
                  ", which is not consistent with the established height - " .. tileHeight)
         end
         local fileData = love.filesystem.newFileData(file:read(), file.path)
         local imageData = love.image.newImageData(fileData)
         spritesheets[#spritesheets + 1] = Spritesheet:create(imageData, tileWidth, tileHeight, file.name, true)
      end
   end

   local paintDisplayPreviews = {}
   local paintDisplayScales = {}
   local paintDisplay = PaintDisplay:create(#spritesheets >= 1 and 1 or 0, #spritesheets >= 2 and 2 or 0, function(x, y, tile)
      if tile ~= TILE_EMPTY then
         love.graphics.draw(spritesheets[tile].originalImage, paintDisplayPreviews[tile], x, y, 0,
            paintDisplayScales[tile], paintDisplayScales[tile])
      end
   end, TilePicker:create(spritesheets))

   for i = 1, #spritesheets do
      local tileWidth, tileHeight = spritesheets[i].tileWidth, spritesheets[i].tileHeight
      paintDisplayScales[i] = math.min(paintDisplay.previewWidth / tileWidth, paintDisplay.previewHeight / tileHeight)
      paintDisplayPreviews[i] = love.graphics.newQuad(0, 0, tileWidth, tileHeight,
         spritesheets[i].originalImage:getDimensions())
   end

   local sidebar = Sidebar:create({ paintDisplay })
   local navigator = Navigator:create(MAP_WIDTH * tileWidth, MAP_HEIGHT * tileHeight, sidebar.width)

   local map = Map:create(MAP_WIDTH, MAP_HEIGHT, tileWidth, tileHeight, spritesheets)

   local this = {
      mapPath = mapPath,
      directory = spritesheetDirectory,
      spritesheetFiles = allTilesheetFiles,
      navigator = navigator,
      shouldRecreate = false,
      activeTool = TOOL_MAP_EDITOR,
      previousTool = TOOL_MAP_EDITOR,
      tools = {
         [TOOL_MAP_EDITOR] = TileControls:create({ r = 1, g = 0, b = 0 }, tileWidth, tileHeight,
            MAP_WIDTH, MAP_HEIGHT, navigator, false),
         [TOOL_IMAGE_EDITOR] = TileControls:create({ r = 0.2, g = 1, b = 0 }, tileWidth, tileHeight,
            MAP_WIDTH, MAP_HEIGHT, navigator, true),
         [TOOL_POINT_EDITOR] = PointEditor:create(navigator),
      },
      imageEditor = nil,
      sidebar = sidebar,
      tileControlsAreDisabled = false,
      paintDisplay = paintDisplay,
      onClose = function() end,
      map = map,
   }
   setmetatable(this, self)

   this.tools[TOOL_MAP_EDITOR]:onDrawProgress(function(points, button)
      local tileToCreate = (button == LEFT_MOUSE_BUTTON) and paintDisplay.front.value or paintDisplay.back.value
      for _, point in pairs(points) do
         if this.map:getTile(point.x, point.y) ~= tileToCreate then
            this.map:setTile(point.x, point.y, tileToCreate)
            this.shouldRecreate = true
         end
      end
   end)
   this.tools[TOOL_MAP_EDITOR]:onDrawDone(function()
      if this.shouldRecreate then
         map:recreateSpriteBatches()
         this.shouldRecreate = false
      end
   end)

   this.tools[TOOL_IMAGE_EDITOR]:onDrawProgress(function(points)
      if points and #points >= 1 then
         local tile = this.map:getTile(points[1].x, points[1].y)
         if tile ~= TILE_EMPTY then
            this.activeTool = this.previousTool
            this.imageEditor = TileEditor:create(allTilesheetFiles[tile].path)
            viewStack:pushView(this.imageEditor)
            this.imageEditor.onClose = function()
               viewStack:popView(this.imageEditor)
               this.imageEditor = nil
            end
            this.imageEditor.onSave = function(imageData)
               spritesheets[tile] = Spritesheet:create(imageData, tileWidth, tileHeight, spritesheets[tile].name, true)
               paintDisplayPreviews[tile] = love.graphics.newQuad(0, 0, paintDisplay.previewWidth,
                  paintDisplay.previewHeight, spritesheets[tile].originalImage:getDimensions())
               map.spriteBatches[tile] = love.graphics.newSpriteBatch(spritesheets[tile].image, MAP_WIDTH * MAP_WIDTH)
               map:recreateSpriteBatches()
            end
         end
      end
   end)

   map:loadFrom(mapPath)
   this.tools[TOOL_POINT_EDITOR]:setPoints(map.points)

   return this
end

--- LOVE update handler
-- @param dt {float} - The amount of time (in seconds) since the last update
function MapEditor:update(dt)
   if love.keyboard.closeIsPressed then
      self.onClose()
   end

   for hotkey, tool in pairs(TOOL_HOTKEYS) do
      if love.keyboard.keysPressed[hotkey] then
         self.tools[self.activeTool].drawingWith = nil
         if self.activeTool ~= TOOL_IMAGE_EDITOR then
            self.previousTool = self.activeTool
         end
         self.activeTool = tool
      end
   end

   self.sidebar.isActive = self.tools[self.activeTool].drawingWith == nil

   if love.keyboard.controlIsDown or love.keyboard.commandIsDown then
      if love.keyboard.keysPressed[SAVE_BUTTON] then
         self.map:saveTo(self.mapPath)
      elseif love.keyboard.keysPressed[LOAD_BUTTON] then
         self.map:loadFrom(self.mapPath)
         self.tools[TOOL_POINT_EDITOR]:setPoints(self.map.points)
      end
      if not self.sidebar.isOpaque and self.activeTool == TOOL_MAP_EDITOR then
         self.tools[TOOL_MAP_EDITOR]:zoom(love.mouse.wheel.dy)
      end
   end

   self.sidebar:update(dt)
   self.tools[self.activeTool]:update(dt)
   self.navigator:update(dt)
end

--- LOVE draw handler
function MapEditor:draw()
   -- Gray border
   local BORDER_VALUE = 0.7
   love.graphics.clear(BORDER_VALUE, BORDER_VALUE, BORDER_VALUE)

   love.graphics.push()
   self.navigator:scaleAndTranslate()

   -- White background
   love.graphics.rectangle("fill", 0, 0, self.map.width * self.map.tileWidth, self.map.height * self.map.tileHeight)
   -- The map itself
   self.map:draw()

   -- TOOL
   if self.activeTool == TOOL_POINT_EDITOR then
      love.graphics.pop()
      self.tools[TOOL_POINT_EDITOR]:draw()
   else
      self.tools[self.activeTool]:draw()
      love.graphics.pop()
   end

   self.sidebar:draw()
end