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

--- A controller that keeps track of an X and Y offset as well as a zoom ratio
function Navigator:create()
   local this = {
      x = 0,
      y = 0,
      zoom = 1,
   }
   setmetatable(this, self)

   return this
end

--- LOVE update callback
-- @param dt {float} - The amount of time (in seconds) since the last update
function Navigator:update(dt)
   if love.keyboard.controlIsDown then
      return
   end
   local wantsToZoomWithScroll = love.keyboard.altIsDown or love.keyboard.commandIsDown
   local wantsToPanHorizontallyWithScroll = love.keyboard.shiftIsDown

   local dx, dy = 0, 0
   for key, value in pairs(MOVEMENT_KEYMAP) do
      if love.keyboard.isDown(key) then
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

--- Convert screen (x, y) coordinates to absolute ones
-- @param x {number} - The X coordinate from the left of the screen
-- @param y {number} - The Y coordinate from the top of the screen
-- @returns {number, number} - The absolute coordinates
function Navigator:screenToAbsolute(x, y)
   return self.x + x / self.zoom, self.y + y / self.zoom
end

--- Scale the rendering process according to the position and zoom
function Navigator:scaleAndTranslate()
   love.graphics.scale(self.zoom)
   love.graphics.translate(-self.x, -self.y)
end