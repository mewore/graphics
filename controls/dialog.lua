Dialog = {}
Dialog.__index = Dialog

local CARLITO_FONT_PATH = 'fonts/carlito.ttf'
local MESSAGE_FONT_SIZE = 14
local MESSAGE_FONT = love.graphics.newFont(CARLITO_FONT_PATH, MESSAGE_FONT_SIZE)
local TITLE_FONT_SIZE = 18
local TITLE_PADDING = 5
local TITLE_FONT = love.graphics.newFont(CARLITO_FONT_PATH, TITLE_FONT_SIZE)

local DEFAULT_WIDTH = 400
local OVERLAY = { r = 0, g = 0, b = 0, a = 0.8 }

local TITLE_LINE_COLOUR = { r = 0.3, g = 0.3, b = 0.3, a = 0.5 }

local DIALOG_BACKGROUND = { r = 1, g = 1, b = 1, a = 1 }
local BORDER_RADIUS = 5
local TEXT_COLOUR = { r = 0.2, g = 0.2, b = 0.2, a = 1 }

local TITLE_HEIGHT = TITLE_FONT_SIZE + TITLE_PADDING * 2
local PADDING_SIDES = 10
local MARGIN_PER_ELEMENT = 5
local FOOTER_PADDING_TOP = 5

--- A simple dialog
-- @param title {string} - The dialog title
-- @param message {string} - The message in the body of the dialog
-- @param controls {any[]} - Controls to display after the message (in the body
-- @param buttons {Button[]} - Buttons to display in the footer of the dialog
function Dialog:create(title, message, controls, buttons)
   local _, wrappedMessage = MESSAGE_FONT:getWrap(message, DEFAULT_WIDTH - PADDING_SIDES * 2)
   local this = {
      x = 0,
      y = 0,
      width = DEFAULT_WIDTH,
      height = 0,
      value = "",
      titleText = love.graphics.newText(TITLE_FONT, title),
      messageText = love.graphics.newText(MESSAGE_FONT, table.concat(wrappedMessage, "\n")),
      controls = controls,
      buttons = buttons,
   }
   setmetatable(this, self)

   return this
end

--- LOVE update handler
function Dialog:update(dt)
   if love.keyboard.returnIsPressed then
      self.buttons[#self.buttons].onClick()
   end
   if love.keyboard.escapeIsPressed then
      self.buttons[1].onClick()
   end
   self.height = TITLE_HEIGHT + MARGIN_PER_ELEMENT + self.messageText:getHeight()

   for i = 1, #self.controls do
      self.height = self.height + MARGIN_PER_ELEMENT
      self.controls[i].x = self.x + PADDING_SIDES
      self.controls[i].y = self.y + self.height
      self.controls[i]:update(dt)
      self.height = self.height + self.controls[i].height
   end

   self.height = self.height + MARGIN_PER_ELEMENT + FOOTER_PADDING_TOP
   local rightX = self.x + self.width - PADDING_SIDES
   for i = #self.buttons, 1, -1 do
      local leftX = rightX - self.buttons[i].width
      self.buttons[i].x = leftX
      self.buttons[i].y = self.y + self.height
      self.buttons[i]:update(dt)
      rightX = leftX - MARGIN_PER_ELEMENT
   end

   self.height = self.height + self.buttons[1].height + math.floor(self.buttons[1].height / 3)

   self.x = math.floor((love.graphics.getWidth() - self.width) / 2)
   self.y = math.floor((love.graphics.getHeight() - self.height) / 2)
end

--- LOVE draw handler
function Dialog:draw()
   love.graphics.setColor(OVERLAY.r, OVERLAY.g, OVERLAY.b, OVERLAY.a)
   love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

   love.graphics.setColor(DIALOG_BACKGROUND.r, DIALOG_BACKGROUND.g, DIALOG_BACKGROUND.b, DIALOG_BACKGROUND.a)
   love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, BORDER_RADIUS, BORDER_RADIUS)

   love.graphics.setColor(TEXT_COLOUR.r, TEXT_COLOUR.g, TEXT_COLOUR.b, TEXT_COLOUR.a)
   love.graphics.draw(self.titleText, self.x + PADDING_SIDES, self.y + TITLE_PADDING)
   love.graphics.draw(self.messageText, self.x + PADDING_SIDES, self.y + TITLE_HEIGHT + MARGIN_PER_ELEMENT)

   love.graphics.setColor(TITLE_LINE_COLOUR.r, TITLE_LINE_COLOUR.g, TITLE_LINE_COLOUR.b, TITLE_LINE_COLOUR.a)
   love.graphics.line(self.x, self.y + TITLE_HEIGHT, self.x + self.width, self.y + TITLE_HEIGHT)
   love.graphics.reset()

   for i = 1, #self.controls do
      self.controls[i]:draw()
   end
   for i = 1, #self.buttons do
      self.buttons[i]:draw()
   end
end