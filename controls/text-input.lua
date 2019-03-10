TextInput = {}
TextInput.__index = TextInput

local BOX_NOT_FOCUSED_OR_HOVER_FILL_COLOUR = { r = 0.9, g = 0.95, b = 1, a = 1 }
local BOX_OUTLINE_COLOUR = { r = 0, g = 0, b = 0, a = 1 }

local TEXT_COLOUR = { r = 0.2, g = 0.2, b = 0.2, a = 1 }
local PLACEHOLDER_COLOUR = { r = 0.2, g = 0.2, b = 0.2, a = 0.7 }
local BORDER_RADIUS = 5
local TEXT_PADDING_LEFT = 5
local TEXT_PADDING_TOP = 5
local TEXT_PADDING_DOWN = 5
local CARLITO_FONT_PATH = 'fonts/carlito.ttf'
local TEXT_FONT_SIZE = 14
local TEXT_FONT = love.graphics.newFont(CARLITO_FONT_PATH, TEXT_FONT_SIZE)

local INPUT_HEIGHT = TEXT_FONT_SIZE + TEXT_PADDING_TOP + TEXT_PADDING_DOWN
local BLINKER_INTERVAL = 0.5 -- [s]

local HOVER_CURSOR = love.mouse.getSystemCursor("ibeam")

--- A simple single-line text input
-- be configured
-- @param width {int} - The width of the input
-- @param placeholder {string} - The text to display when the input is empty
-- @param initialValue {string} - The initial value
function TextInput:create(width, placeholder, initialValue)
   local this = {
      x = 0,
      y = 0,
      width = width,
      height = INPUT_HEIGHT,
      value = initialValue or "",
      text = nil,
      placeholderText = placeholder and love.graphics.newText(TEXT_FONT, placeholder) or nil,
      focusedSince = nil,
      valid = true,
   }
   setmetatable(this, self)
   this.text = love.graphics.newText(TEXT_FONT, this.value)

   return this
end

--- LOVE update callback
function TextInput:update()
   if love.mouse.hasPressedInsideObject(self) then
      self.focusedSince = love.timer.getTime()
   elseif love.mouse.buttonsPressed[1] or love.mouse.buttonsPressed[2] then
      self.focusedSince = nil
   end

   if self.focusedSince ~= nil then
      if #love.keyboard.input > 0 then
         self.value = self.value .. love.keyboard.input
         self.text = love.graphics.newText(TEXT_FONT, self.value)
      end
      if love.keyboard.keysPressed["backspace"] then
         self.value = string.sub(self.value, 1, #self.value - 1)
         self.text = love.graphics.newText(TEXT_FONT, self.value)
      end
   end

   if love.mouse.isInsideObject(self) then
      love.mouse.cursor = HOVER_CURSOR
   end
end

local function setColour(colour)
   if not colour then
      return false
   end
   love.graphics.setColor(colour.r, colour.g, colour.b, colour.a == nil and 1 or colour.a)
   return true
end

--- LOVE draw callback
function TextInput:draw()
   if self.focusedSince == nil and not love.mouse.isInsideObject(self) then
      setColour(BOX_NOT_FOCUSED_OR_HOVER_FILL_COLOUR)
      love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, BORDER_RADIUS, BORDER_RADIUS)
   end

   if self.value and #self.value > 0 then
      setColour(TEXT_COLOUR)
      love.graphics.draw(self.text, self.x + TEXT_PADDING_LEFT, self.y + TEXT_PADDING_TOP)
   elseif self.placeholderText then
      setColour(PLACEHOLDER_COLOUR)
      love.graphics.draw(self.placeholderText, self.x + TEXT_PADDING_LEFT, self.y + TEXT_PADDING_TOP)
   end

   if self.focusedSince ~= nil and math.floor((love.timer.getTime() - self.focusedSince) / BLINKER_INTERVAL) % 2 == 0 then
      setColour(TEXT_COLOUR)
      local x = self.x + TEXT_PADDING_LEFT + (self.text ~= nil and self.text:getWidth() or 0)
      local topY = self.y + TEXT_PADDING_TOP
      love.graphics.line(x, topY, x, topY + TEXT_FONT_SIZE)
   end

   love.graphics.setColor(BOX_OUTLINE_COLOUR.r, BOX_OUTLINE_COLOUR.g, BOX_OUTLINE_COLOUR.b, BOX_OUTLINE_COLOUR.a)
   love.graphics.rectangle("line", self.x, self.y, self.width, self.height, BORDER_RADIUS, BORDER_RADIUS)
   love.graphics.reset()
end
