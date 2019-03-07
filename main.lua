require "map-editor"

local mapEditor = MapEditor:create(love.filesystem.getWorkingDirectory() .. "/tilesheets")

love.keyboard.keysPressed = {}
love.keyboard.keysReleased = {}
love.mouse.wheel = { dx = 0, dy = 0 }

--- LOVE load callback
function love.load()
   love.graphics.setDefaultFilter("nearest", "nearest")
end

--- LOVE key pressed callback
-- @param key {string} - The pressed key
function love.keypressed(key)
   if key == "escape" then
      love.event.quit()
   end
   print("Pressed:", key)
   love.keyboard.keysPressed[key] = true
end

--- LOVE key released callback
-- @param key {string} - The released key
function love.keyreleased(key)
   print("Released:", key)
   love.keyboard.keysReleased[key] = true
end

--- LOVE mouse wheel scroll callback
-- @param dx {int} - The horizontal movement of the wheel scroll
-- @param dy {int} - The vertical movement of the wheel scroll (positive ~ forwards, negative ~ backwards)
function love.wheelmoved(dx, dy)
   love.mouse.wheel.dx, love.mouse.wheel.dy = love.mouse.wheel.dx + dx, love.mouse.wheel.dy + dy
end

--- LOVE update callback
-- @param dt {float} - The amount of time (in seconds) since the last update
function love.update(dt)
   love.keyboard.controlIsDown = love.keyboard.isDown("rctrl") or love.keyboard.isDown("lctrl")
   love.keyboard.shiftIsDown = love.keyboard.isDown("rshift") or love.keyboard.isDown("lshift")
   love.keyboard.altIsDown = love.keyboard.isDown("ralt") or love.keyboard.isDown("lalt")
   love.keyboard.commandIsDown = love.keyboard.isDown("rgui") or love.keyboard.isDown("lgui")

   mapEditor:update(dt)
   love.keyboard.keysPressed = {}
   love.keyboard.keysReleased = {}
   love.mouse.wheel.dx, love.mouse.wheel.dy = 0, 0
end

--- LOVE draw callback
function love.draw()
   love.graphics.clear(1, 1, 1, 1)
   mapEditor:draw()
end
