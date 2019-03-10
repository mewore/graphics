require "views/map-editor"
require "util/view-stack"

local NORMAL_CURSOR = love.mouse.getSystemCursor("arrow")

love.keyboard.keysPressed = {}
love.keyboard.keysReleased = {}
love.keyboard.input = ""
love.mouse.buttonsPressed = {}
love.mouse.wheel = { dx = 0, dy = 0 }

--- LOVE load handler
function love.load()
   love.graphics.setDefaultFilter("nearest", "nearest")
end

--- LOVE key pressed handler
-- @param key {string} - The pressed key
function love.keypressed(key)
   print("Pressed:", key)
   love.keyboard.keysPressed[key] = true
end

--- LOVE key released handler
-- @param key {string} - The released key
function love.keyreleased(key)
   print("Released:", key)
   love.keyboard.keysReleased[key] = true
end

--- LOVE text input handler
-- @param text {string} - The input
function love.textinput(text)
   love.keyboard.input = love.keyboard.input .. text
end

--- LOVE mouse wheel scroll handler
-- @param dx {int} - The horizontal movement of the wheel scroll
-- @param dy {int} - The vertical movement of the wheel scroll (positive ~ forwards, negative ~ backwards)
function love.wheelmoved(dx, dy)
   love.mouse.wheel.dx, love.mouse.wheel.dy = love.mouse.wheel.dx + dx, love.mouse.wheel.dy + dy
end

--- LOVE mouse click handler
-- @param x {int} - Mouse x position, in pixels
-- @param y {int} - Mouse y position, in pixels
-- @param button {int} - The button index that was pressed. 1 is the primary mouse button,
-- 2 is the secondary mouse button and 3 is the middle button. Further buttons are mouse dependent
-- @param isTouch {boolean} - True if the mouse button press originated from a touchscreen touch-press
-- @param presses {int} - The number of presses in a short time frame and small area, used to simulate double, triple
-- clicks
function love.mousepressed(x, y, button, isTouch, presses)
   love.mouse.buttonsPressed[button] = { x = x, y = y, isTouch = isTouch, presses = presses }
end

function love.mouse.isInside(leftX, topY, bottomX, bottomY)
   return love.mouse.getX() >= leftX and love.mouse.getX() <= bottomX
         and love.mouse.getY() >= topY and love.mouse.getY() <= bottomY
end

function love.mouse.isInsideObject(object)
   return love.mouse.isInside(object.x, object.y, object.x + object.width, object.y + object.height)
end

function love.mouse.hasPressedInside(leftX, topY, bottomX, bottomY, buttons)
   buttons = buttons or { 1, 2, 3 }
   for _, button in ipairs(buttons) do
      local mousePress = love.mouse.buttonsPressed[button]
      if mousePress
            and mousePress.x >= leftX and mousePress.x <= bottomX
            and mousePress.y >= topY and mousePress.y <= bottomY then
         return true
      end
   end
   return false
end

function love.mouse.hasPressedInsideObject(object, buttons)
   return love.mouse.hasPressedInside(object.x, object.y, object.x + object.width, object.y + object.height, buttons)
end

function love.mouse.hasPressedInside(leftX, topY, bottomX, bottomY, buttons)
   buttons = buttons or { 1, 2, 3 }
   for _, button in ipairs(buttons) do
      local mousePress = love.mouse.buttonsPressed[button]
      if mousePress
            and mousePress.x >= leftX and mousePress.x <= bottomX
            and mousePress.y >= topY and mousePress.y <= bottomY then
         return true
      end
   end
   return false
end

local mapEditor = MapEditor:create(love.filesystem.getWorkingDirectory() .. "/tilesheets")
mapEditor.onClose = function() love.event.quit() end
viewStack = ViewStack:create(mapEditor)

--- LOVE update handler
-- @param dt {float} - The amount of time (in seconds) since the last update
function love.update(dt)
   love.mouse.cursor = NORMAL_CURSOR
   love.keyboard.controlIsDown = love.keyboard.isDown("rctrl") or love.keyboard.isDown("lctrl")
   love.keyboard.shiftIsDown = love.keyboard.isDown("rshift") or love.keyboard.isDown("lshift")
   love.keyboard.altIsDown = love.keyboard.isDown("ralt") or love.keyboard.isDown("lalt")
   love.keyboard.commandIsDown = love.keyboard.isDown("rgui") or love.keyboard.isDown("lgui")
   love.keyboard.escapeIsPressed = love.keyboard.keysPressed["escape"]
   love.keyboard.returnIsPressed = love.keyboard.keysPressed["return"]

   viewStack:update(dt)
   love.keyboard.keysPressed = {}
   love.keyboard.keysReleased = {}
   love.keyboard.input = ""
   love.mouse.buttonsPressed = {}
   love.mouse.wheel.dx, love.mouse.wheel.dy = 0, 0
   love.mouse.setCursor(love.mouse.cursor)
end

--- LOVE draw handler
function love.draw()
   love.graphics.clear(1, 1, 1, 1)
   viewStack:draw()
end
