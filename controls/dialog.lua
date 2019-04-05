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
-- @param message {string | nil} - The message in the body of the dialog
-- @param controls {any[]} - Controls to display after the message (in the body
-- @param buttons {Button[]} - Buttons to display in the footer of the dialog
function Dialog:create(title, message, controls, buttons)
   local this = {
      x = 0,
      y = 0,
      width = DEFAULT_WIDTH,
      contentWidth = DEFAULT_WIDTH,
      height = 0,
      value = "",
      titleText = love.graphics.newText(TITLE_FONT, title),
      messageText = nil,
      messageHeight = 0,
      controls = controls,
      buttons = buttons,
      isOpaque = false,
      lastScreenWidth = nil,
      lastScreenHeight = nil,
   }
   setmetatable(this, self)

   if controls and #controls > 0 then
      this.contentWidth = 0
      for _, control in ipairs(controls) do
         this.contentWidth = math.max(this.contentWidth, control.width)
      end
   end
   this.width = this.contentWidth + PADDING_SIDES * 2

   if message then
      local _, wrappedMessage = MESSAGE_FONT:getWrap(message, this.contentWidth)
      this.messageText = love.graphics.newText(MESSAGE_FONT, table.concat(wrappedMessage, "\n"))
      this.messageHeight = this.messageText:getHeight()
   end

   this.height = TITLE_HEIGHT + MARGIN_PER_ELEMENT + this.messageHeight

   for i = 1, #controls do
      this.height = this.height + MARGIN_PER_ELEMENT + controls[i].height
   end

   this.height = this.height + MARGIN_PER_ELEMENT + FOOTER_PADDING_TOP + buttons[1].height +
         math.floor(buttons[1].height / 3)
   this:repositionIfNecessary()

   viewStack:pushView(this)

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

   self:repositionIfNecessary()

   for i = 1, #self.controls do
      self.controls[i]:update(dt)
   end

   for i = #self.buttons, 1, -1 do
      self.buttons[i]:update(dt)
   end
end

function Dialog:repositionIfNecessary()
   local screenWidth, screenHeight = love.graphics.getDimensions()
   if screenWidth == self.lastScreenWidth and screenHeight == self.lastScreenHeight then
      return
   end

   self.lastScreenWidth, self.lastScreenHeight = screenWidth, screenHeight

   self.x = math.floor((screenWidth - self.width) / 2)
   self.y = math.floor((screenHeight - self.height) / 2)

   local y = self.y + TITLE_HEIGHT + MARGIN_PER_ELEMENT + self.messageHeight

   for i = 1, #self.controls do
      y = y + MARGIN_PER_ELEMENT
      self.controls[i].x = self.x + PADDING_SIDES
      self.controls[i].y = y
      y = y + self.controls[i].height
      self.controls[i]:update()
   end

   y = y + MARGIN_PER_ELEMENT + FOOTER_PADDING_TOP
   local rightX = self.x + self.width - PADDING_SIDES
   for i = #self.buttons, 1, -1 do
      local leftX = rightX - self.buttons[i].width
      self.buttons[i].x = leftX
      self.buttons[i].y = y
      rightX = leftX - MARGIN_PER_ELEMENT
   end
end

--- LOVE draw handler
function Dialog:draw()
   self:repositionIfNecessary()
   love.graphics.setColor(OVERLAY.r, OVERLAY.g, OVERLAY.b, OVERLAY.a)
   love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

   love.graphics.setColor(DIALOG_BACKGROUND.r, DIALOG_BACKGROUND.g, DIALOG_BACKGROUND.b, DIALOG_BACKGROUND.a)
   love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, BORDER_RADIUS, BORDER_RADIUS)

   love.graphics.setColor(TEXT_COLOUR.r, TEXT_COLOUR.g, TEXT_COLOUR.b, TEXT_COLOUR.a)
   love.graphics.draw(self.titleText, self.x + PADDING_SIDES, self.y + TITLE_PADDING)
   if self.messageText then
      love.graphics.draw(self.messageText, self.x + PADDING_SIDES, self.y + TITLE_HEIGHT + MARGIN_PER_ELEMENT)
   end

   love.graphics.setColor(TITLE_LINE_COLOUR.r, TITLE_LINE_COLOUR.g, TITLE_LINE_COLOUR.b, TITLE_LINE_COLOUR.a)
   love.graphics.line(self.x, self.y + TITLE_HEIGHT, self.x + self.width, self.y + TITLE_HEIGHT)
   love.graphics.reset()

   for i = 1, #self.buttons do
      self.buttons[i]:draw()
   end
   for i = 1, #self.controls do
      self.controls[i]:draw()
   end
end
