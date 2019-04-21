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
local HOVER_CURSOR_HALF_WIDTH = 2

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
      caretIndex = 0,
      selectionFromIndex = 0,
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

--- Change the position of this element
-- @param x {number} The new X left position
-- @param y {number} The new Y top position
function TextInput:setPosition(x, y) self.x, self.y = x, y end

--- Get both the X and the Y position of this element
-- @returns {int}, {int}
function TextInput:getPosition() return self.x, self.y end

--- Change the size of this element
-- @param width {number} The new width
-- @param height {number} The new height
function TextInput:setSize(width, height) self.width, self.height = width, height end

--- Get the size of this element
-- @returns {int}, {int}
function TextInput:getSize() return self.width, self.height end

local function getClickedIndex(text, relativeMouseX)
   relativeMouseX = relativeMouseX + HOVER_CURSOR_HALF_WIDTH
   local from, to = 0, #text
   local closestIndex, closestDistance, mid
   while from <= to do
      mid = math.floor((from + to) / 2)
      local x = TEXT_FONT:getWidth(string.sub(text, 1, mid))
      local distance = math.abs(relativeMouseX - x)
      if closestIndex == nil or distance < closestDistance then
         closestIndex, closestDistance = mid, distance
      end
      if relativeMouseX < x then to = mid - 1 else from = mid + 1 end
   end
   return closestIndex
end

--- LOVE update handler
function TextInput:update()
   local mouseInfo = love.mouse.registerSolid(self)

   if mouseInfo.dragStarted then
      love.keyboard.focus(self)
      self.selectionFromIndex = getClickedIndex(self.value, mouseInfo.drag.fromX - self.x - TEXT_PADDING_LEFT)
   end
   if mouseInfo.drag then
      self.caretIndex = getClickedIndex(self.value, mouseInfo.drag.toX - self.x - TEXT_PADDING_LEFT)
   end

   if love.keyboard.focusedOnto == self then
      -- Typing
      if #love.keyboard.input > 0 then
         if self:hasSelectedText() then
            self:deleteSelectedText()
         end
         self:setValue(string.sub(self.value, 1, self.caretIndex) ..
               love.keyboard.input ..
               string.sub(self.value, self.caretIndex + 1))
         self.caretIndex = self.caretIndex + #love.keyboard.input
         self.selectionFromIndex = self.caretIndex
      end

      -- Caret movement
      if love.keyboard.keysPressed["left"] then
         if love.keyboard.shiftIsDown then
            self.caretIndex = math.max(self.caretIndex - 1, 0)
         elseif self:hasSelectedText() then
            self.caretIndex = math.min(self.caretIndex, self.selectionFromIndex)
            self.selectionFromIndex = self.caretIndex
         else
            self.caretIndex = math.max(self.caretIndex - 1, 0)
            self.selectionFromIndex = self.caretIndex
         end
      end
      if love.keyboard.keysPressed["right"] then
         if love.keyboard.shiftIsDown then
            self.caretIndex = math.min(self.caretIndex + 1, #self.value)
         elseif self:hasSelectedText() then
            self.caretIndex = math.max(self.caretIndex, self.selectionFromIndex)
            self.selectionFromIndex = self.caretIndex
         else
            self.caretIndex = math.min(self.caretIndex + 1, #self.value)
            self.selectionFromIndex = self.caretIndex
         end
      end
      if love.keyboard.keysPressed["up"] then
         self.caretIndex = 0
         if not love.keyboard.shiftIsDown then
            self.selectionFromIndex = self.caretIndex
         end
      end
      if love.keyboard.keysPressed["down"] then
         self.caretIndex = #self.value
         if not love.keyboard.shiftIsDown then
            self.selectionFromIndex = self.caretIndex
         end
      end

      if love.keyboard.keysPressed["a"] and love.keyboard.controlIsDown then
         self.selectionFromIndex, self.caretIndex = 0, #self.value
      end

      -- Deletion
      if love.keyboard.keysPressed["backspace"] then
         if self:hasSelectedText() then
            self:deleteSelectedText()
         else
            self:setValue(string.sub(self.value, 1, self.caretIndex - 1) .. string.sub(self.value, self.caretIndex + 1))
            self.caretIndex = math.max(self.caretIndex - 1, 0)
            self.selectionFromIndex = self.caretIndex
         end
      end
      if love.keyboard.keysPressed["delete"] then
         if self:hasSelectedText() then
            self:deleteSelectedText()
         else
            self:setValue(string.sub(self.value, 1, self.caretIndex) .. string.sub(self.value, self.caretIndex + 2))
         end
      end
   end

   self.isHovered = mouseInfo.isHovered
   if self.isHovered then
      love.mouse.cursor = HOVER_CURSOR
   end
end

--- Returns whether there is any selected text (i.e. a non-zero-length selection).
-- @return {boolean}
function TextInput:hasSelectedText()
   return self.caretIndex ~= self.selectionFromIndex
end

--- Deletes all text that is selected. If none is selected, nothing happens.
function TextInput:deleteSelectedText()
   local selectionFrom = math.min(self.caretIndex, self.selectionFromIndex)
   local selectionTo = math.max(self.caretIndex, self.selectionFromIndex)
   self:setValue(string.sub(self.value, 1, selectionFrom) .. string.sub(self.value, selectionTo + 1))
   self.caretIndex, self.selectionFromIndex = selectionFrom, selectionFrom
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

   if love.keyboard.focusedOnto == self and self.selectionFromIndex ~= self.caretIndex then
      local x1 = self.x + TEXT_PADDING_LEFT + TEXT_FONT:getWidth(string.sub(self.value, 1, self.caretIndex))
      local x2 = self.x + TEXT_PADDING_LEFT + TEXT_FONT:getWidth(string.sub(self.value, 1, self.selectionFromIndex))
      local xFrom, xTo = math.min(x1, x2), math.max(x1, x2)
      local topY = self.y + TEXT_PADDING_TOP
      love.graphics.setColor(0.2, 0.6, 1)
      love.graphics.rectangle("fill", xFrom, topY, xTo - xFrom, TEXT_FONT_SIZE)
      love.graphics.reset()
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
      local x = self.x + TEXT_PADDING_LEFT + TEXT_FONT:getWidth(string.sub(self.value, 1, self.caretIndex))
      local topY = self.y + TEXT_PADDING_TOP
      love.graphics.line(x, topY, x, topY + TEXT_FONT_SIZE)
   end

   local outlineColour = self.isValid and BOX_OUTLINE_COLOUR or BOX_OUTLINE_COLOUR_INVALID
   love.graphics.setColor(outlineColour.r, outlineColour.g, outlineColour.b, outlineColour.a)
   love.graphics.rectangle("line", self.x, self.y, self.width, self.height, BORDER_RADIUS, BORDER_RADIUS)
   love.graphics.reset()
end
