Navigator = {}
Navigator.__index = Navigator

local ZOOM_SPEED = 1.1 -- [times / scroll value]
local MOVEMENT_SPEED = 100 -- [px/s]
local MOVEMENT_KEYMAP = {
   left = { x = -1, y = 0 },
   a = { x = -1, y = 0 },
   right = { x = 1, y = 0 },
   d = { x = 1, y = 0 },
   up = { x = 0, y = -1 },
   w = { x = 0, y = -1 },
   down = { x = 0, y = 1 },
   s = { x = 0, y = 1 },
}
local MOUSE_SCROLL_PAN_MULTIPLIER = 25

local INITIAL_ZOOM_MULTIPLIER = 0.95

local CONTROL_PRESS_MOVEMENT_DELAY = 0.2

--- A controller that keeps track of an X and Y offset as well as a zoom ratio
function Navigator:create(canvasWidth, canvasHeight)
   local this = {
      x = 0,
      y = 0,
      zoom = 1,
      controlLastDown = 0,
   }
   setmetatable(this, self)

   if canvasWidth ~= nil and canvasHeight ~= nil then
      this:setDimensionsAndReposition(canvasWidth, canvasHeight)
   end

   return this
end

--- LOVE update handler
-- @param dt {float} - The amount of time (in seconds) since the last update
function Navigator:update(dt)
   if love.keyboard.controlIsDown then
      self.controlLastDown = love.timer.getTime()
      return
   end
   local wantsToZoomWithScroll = love.keyboard.altIsDown or love.keyboard.commandIsDown
   local wantsToPanHorizontallyWithScroll = love.keyboard.shiftIsDown

   local dx, dy = 0, 0
   for key, value in pairs(MOVEMENT_KEYMAP) do
      if love.keyboard.isDown(key) and
            (#key > 1 or love.timer.getTime() > self.controlLastDown + CONTROL_PRESS_MOVEMENT_DELAY) then
         dx, dy = dx + value.x, dy + value.y
      end
   end
   local mouseDx, mouseDy = 0, 0
   if not wantsToZoomWithScroll then
      if wantsToPanHorizontallyWithScroll then
         mouseDx = -love.mouse.wheel.dy * MOUSE_SCROLL_PAN_MULTIPLIER
      else
         mouseDy = -love.mouse.wheel.dy * MOUSE_SCROLL_PAN_MULTIPLIER
      end
   end
   self.x = self.x + (math.min(math.max(dx, -1), 1) + mouseDx) * dt * MOVEMENT_SPEED / self.zoom
   self.y = self.y + (math.min(math.max(dy, -1), 1) + mouseDy) * dt * MOVEMENT_SPEED / self.zoom

   if wantsToZoomWithScroll then
      if love.mouse.wheel.dy ~= 0 then
         local oldAbsoluteMouseX, oldAbsoluteMouseY = self:screenToAbsolute(love.mouse.getX(), love.mouse.getY())
         self.zoom = self.zoom * ZOOM_SPEED ^ love.mouse.wheel.dy
         local newAbsoluteMouseX, newAbsoluteMouseY = self:screenToAbsolute(love.mouse.getX(), love.mouse.getY())
         self.x = self.x - newAbsoluteMouseX + oldAbsoluteMouseX
         self.y = self.y - newAbsoluteMouseY + oldAbsoluteMouseY
      end
   end
end

--- Set the canvas width and height and re-center the navigator to it
-- @param canvasWidth {int} The canvas width
-- @param canvasHeight {int} The canvas height
function Navigator:setDimensionsAndReposition(canvasWidth, canvasHeight)
   local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()
   self.zoom = math.min(screenWidth / canvasWidth, screenHeight / canvasHeight) * INITIAL_ZOOM_MULTIPLIER

   self.x, self.y = 0, 0
   local rightX, bottomY = self:screenToAbsolute(screenWidth, screenHeight)
   self.x, self.y = -math.floor((rightX - canvasWidth) / 2), -math.floor((bottomY - canvasHeight) / 2)
end

--- Convert screen (x, y) coordinates to absolute ones
-- @param xScreen {number} - The X coordinate from the left of the screen
-- @param yScreen {number} - The Y coordinate from the top of the screen
-- @returns {number, number} - The absolute coordinates
function Navigator:screenToAbsolute(xScreen, yScreen)
   return self.x + xScreen / self.zoom, self.y + yScreen / self.zoom
end

--- Convert absolute (x, y) coordinates to screen ones
-- @param xAbsolute {number} - The X coordinate from the left of the canvas
-- @param yAbsolute {number} - The Y coordinate from the top of the canvas
-- @returns {number, number} - The screen coordinates
function Navigator:absoluteToScreen(xAbsolute, yAbsolute)
   return (xAbsolute - self.x) * self.zoom, (yAbsolute - self.y) * self.zoom
end

--- Scale the rendering process according to the position and zoom
function Navigator:scaleAndTranslate()
   love.graphics.scale(self.zoom)
   love.graphics.translate(-self.x, -self.y)
end