TextInput = {}
TextInput.__index = TextInput

local BOX_NOT_FOCUSED_OR_HOVER_FILL_COLOUR = { r = 0.9, g = 0.95, b = 1, a = 1 }
local BOX_OUTLINE_COLOUR = { r = 0, g = 0, b = 0, a = 1 }
local BOX_OUTLINE_COLOUR_INVALID = { r = 0.8, g = 0, b = 0.1, a = 1 }

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

local function isKebabCase(value)
   return string.find(value, "^[a-z0-9][-a-z0-9]*$") ~= nil
         and string.find(value, "%-%-") == nil
         and value:sub(#value, #value) ~= "-"
end

local function isNotEmpty(value)
   return #value > 0
end

local function isPositiveNumber(value)
   local asNumber = tonumber(value)
   return asNumber ~= nil and asNumber > 0
end

local function isInteger(value)
   local asNumber = tonumber(value)
   return asNumber ~= nil and math.floor(asNumber) == asNumber
end

--- A simple single-line text input
-- be configured
-- @param width {int} - The width of the input
-- @param placeholder {string} - The text to display when the input is empty
-- @param initialValue {string} - The initial value
function TextInput:create(width, placeholder, initialValue, options)
   options = options or {}

   local this = {
      x = 0,
      y = 0,
      width = width,
      height = INPUT_HEIGHT,
      value = nil,
      text = nil,
      placeholderText = placeholder and love.graphics.newText(TEXT_FONT, placeholder) or nil,
      focusedSince = nil,
      valid = true,
      isHovered = false,
      isValid = true,
      validations = options.validations or {},
   }
   setmetatable(this, self)

   if options.kebabCase then
      this.validations[#this.validations + 1] = isKebabCase
   end

   if options.nonEmpty then
      this.validations[#this.validations + 1] = isNotEmpty
   end

   if options.positive then
      this.validations[#this.validations + 1] = isPositiveNumber
   end

   if options.integer then
      this.validations[#this.validations + 1] = isInteger
   end

   this:setValue(initialValue)

   return this
end

--- LOVE update handler
function TextInput:update()
   local mouseInfo = love.mouse.registerSolid(self)

   if mouseInfo.clicksPerButton[1] or mouseInfo.clicksPerButton[2] then
      love.keyboard.focus(self)
   end

   if love.keyboard.focusedOnto == self then
      if #love.keyboard.input > 0 then
         self:setValue(self.value .. love.keyboard.input)
      end
      if love.keyboard.keysPressed["backspace"] then
         self:setValue(string.sub(self.value, 1, #self.value - 1))
      end
   end

   self.isHovered = mouseInfo.isHovered
   if self.isHovered then
      love.mouse.cursor = HOVER_CURSOR
   end
end

function TextInput:setValue(newValue)
   self.value = newValue
   self.text = love.graphics.newText(TEXT_FONT, newValue)
   for _, validation in ipairs(self.validations) do
      self.isValid = validation(newValue)
      if not self.isValid then
         break
      end
   end
end

local function setColour(colour)
   if not colour then
      return false
   end
   love.graphics.setColor(colour.r, colour.g, colour.b, colour.a == nil and 1 or colour.a)
   return true
end

--- LOVE draw handler
function TextInput:draw()
   if love.keyboard.focusedOnto ~= self and not self.isHovered then
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

   if love.keyboard.focusedOnto == self and
         math.floor((love.timer.getTime() - love.keyboard.focusedSince) / BLINKER_INTERVAL) % 2 == 0 then
      setColour(TEXT_COLOUR)
      local x = self.x + TEXT_PADDING_LEFT + (self.text ~= nil and self.text:getWidth() or 0)
      local topY = self.y + TEXT_PADDING_TOP
      love.graphics.line(x, topY, x, topY + TEXT_FONT_SIZE)
   end

   local outlineColour = self.isValid and BOX_OUTLINE_COLOUR or BOX_OUTLINE_COLOUR_INVALID
   love.graphics.setColor(outlineColour.r, outlineColour.g, outlineColour.b, outlineColour.a)
   love.graphics.rectangle("line", self.x, self.y, self.width, self.height, BORDER_RADIUS, BORDER_RADIUS)
   love.graphics.reset()
end
