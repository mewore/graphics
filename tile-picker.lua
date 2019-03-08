TilePicker = {}
TilePicker.__index = TilePicker

local CARLITO_FONT_PATH = 'fonts/carlito.ttf'
local TILE_NAME_FONT = love.graphics.newFont(CARLITO_FONT_PATH, 14)
local TITLE_FONT = love.graphics.newFont(CARLITO_FONT_PATH, 32)
local TITLE_PADDING_TOP = 10
local TITLE_TEXT = love.graphics.newText(TITLE_FONT, "Pick a paint")

local SQUARE_SIZE = 128
local LEFT_MOUSE_BUTTON = 1

local BACKGROUND_VALUE = 0.2

local PADDING_TOP = TITLE_PADDING_TOP + TITLE_TEXT:getHeight() + 10
local PADDING_SIDES = 300
local ROW_HEIGHT = SQUARE_SIZE + 40
local COLUMN_WIDTH = SQUARE_SIZE + 40

local SQUARE_TOP_OFFSET = 10
local SQUARE_LEFT_OFFSET = math.floor((COLUMN_WIDTH - SQUARE_SIZE) / 2)

local CHECKERBOARD = love.graphics.newImage("graphics/checkerboard-pattern-128.png")
local CHECKERBOARD_QUAD = love.graphics.newQuad(0, 0, math.min(SQUARE_SIZE, CHECKERBOARD:getWidth()), math.min(SQUARE_SIZE, CHECKERBOARD:getHeight()), CHECKERBOARD:getDimensions())

local function map(array, functionToApply)
   local newArray = {}
   for index, value in ipairs(array) do
      newArray[index] = functionToApply(value)
   end
   return newArray
end

--- A picker of tiles, including the empty one (0)
function TilePicker:create(tilesheets, tileNames)
   local tileNameTexts = { love.graphics.newText(TILE_NAME_FONT, "NONE") }
   for i = 1, #tileNames do
      tileNameTexts[i + 1] = love.graphics.newText(TILE_NAME_FONT, tileNames[i])
   end

   local this = {
      tilesheets = tilesheets,
      tilesheetQuads = map(tilesheets, function(tilesheet)
         local width, height = tilesheet.originalImage:getDimensions()
         return love.graphics.newQuad(0, 0, math.min(width, SQUARE_SIZE), math.min(height, SQUARE_SIZE), width, height)
      end),
      hoveredTile = nil,
      onPick = function() end,
      onClose = function() end,
      tileNameTexts = tileNameTexts,
   }
   setmetatable(this, self)

   return this
end

--- LOVE update callback
function TilePicker:update()
   if love.keyboard.escapeIsPressed then
      self.onClose()
   end

   local mouseX = love.mouse.getX()
   local mouseY = love.mouse.getY()
   local LIMIT_RIGHT = love.graphics.getWidth() - PADDING_SIDES
   if mouseX < PADDING_SIDES or mouseY < PADDING_TOP or mouseX > LIMIT_RIGHT then
      self.hoveredTile = nil
      return
   end

   local columnsPerRow = math.floor((love.graphics.getWidth() - 2 * PADDING_SIDES) / COLUMN_WIDTH)
   local column = math.floor((mouseX - PADDING_SIDES) / COLUMN_WIDTH)
   local row = math.floor((mouseY - PADDING_TOP) / ROW_HEIGHT)

   self.hoveredTile = row * columnsPerRow + column
   if self.hoveredTile < 0 or self.hoveredTile > #self.tilesheets then
      self.hoveredTile = nil
   end

   if love.mouse.buttonsPressed[LEFT_MOUSE_BUTTON] and self.hoveredTile ~= nil then
      self.onPick(self.hoveredTile)
   end
end

--- LOVE draw callback
function TilePicker:draw()
   love.graphics.clear(BACKGROUND_VALUE * 1.1, BACKGROUND_VALUE, BACKGROUND_VALUE * 1.2)

   love.graphics.draw(TITLE_TEXT, math.floor((love.graphics.getWidth() - TITLE_TEXT:getWidth()) / 2), TITLE_PADDING_TOP)

   local x = PADDING_SIDES
   local y = PADDING_TOP
   local LIMIT_RIGHT = love.graphics.getWidth() - PADDING_SIDES

   for i = 0, #self.tilesheets do
      if i == self.hoveredTile then
         love.graphics.setColor(1, 1, 1, 0.1)
         love.graphics.rectangle("fill", x, y, COLUMN_WIDTH, ROW_HEIGHT)
      end

      if i > 0 then
         love.graphics.setColor(1, 1, 1, 1)
         love.graphics.draw(CHECKERBOARD, CHECKERBOARD_QUAD, x + SQUARE_LEFT_OFFSET, y + SQUARE_TOP_OFFSET)
         love.graphics.draw(self.tilesheets[i].originalImage, self.tilesheetQuads[i], x + SQUARE_LEFT_OFFSET, y + SQUARE_TOP_OFFSET)
      end

      love.graphics.setColor(not (i == self.hoveredTile) and 1 or 0, 1, 1, 1)
      love.graphics.rectangle("line", x + SQUARE_LEFT_OFFSET, y + SQUARE_TOP_OFFSET, SQUARE_SIZE, SQUARE_SIZE)

      love.graphics.draw(self.tileNameTexts[i + 1],
         x + math.floor((COLUMN_WIDTH - self.tileNameTexts[i + 1]:getWidth()) / 2),
         y + SQUARE_TOP_OFFSET + SQUARE_SIZE + 5)

      x = x + COLUMN_WIDTH
      if x + COLUMN_WIDTH > LIMIT_RIGHT then
         x = PADDING_SIDES
         y = y + ROW_HEIGHT
      end
   end

   love.graphics.reset()
end